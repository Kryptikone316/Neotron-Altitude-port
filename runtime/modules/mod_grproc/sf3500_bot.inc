/* SPDX-License-Identifier: Unlicense */
/* ---------------------------------------------------------------------------
 * Computer opponent for Altitude (a mod: it presses the keys Player 2 reads, nothing in the
 * game's files is changed).
 *
 * Included at the end of mod_grproc.c so that it can use the engine's own pixel-accurate
 * collision test. Every frame sf3500_bot_tick() is called by the input hook:
 *
 *   1. find Player 2's ship, the hazards (ground strips, Obstacle1-10, fire pillars) and the
 *      crystals among the running processes, by process name;
 *   2. estimate how each object moves from its position in the previous frame;
 *   3. simulate the ship a second or so ahead for a family of "hold this vertical speed"
 *      strategies, using the game's own flight rules, and ask the engine whether the ship
 *      would hit anything;
 *   4. pick the strategy that survives longest and then collects the most crystals, and
 *      return the keys (Z = up, X = down) for this frame.
 *
 * The flight rules below are copied from the Player2 process in altitude.prg.
 * ------------------------------------------------------------------------- */

#include <string.h>
#include <strings.h>
#include <stdio.h>
#include <time.h>

/* The game's global variables, by byte offset into the interpreter's global data. */
extern void * globaldata;
#define BOT_GLO(off) ( *( int32_t * ) ( ( uint8_t * ) globaldata + ( off ) ) )

#define BOT_MAXOBJ   48
#ifndef BOT_SIL_MARGIN
#define BOT_SIL_MARGIN 0     /* extra pixels around the ship's silhouette when testing */
#endif
#define BOT_MAXT     56
#define BOT_EXT      12     /* extra frames in which the end of a plan must still have an escape */

enum { BK_NONE = 0, BK_SHIP, BK_HAZ, BK_FIRE, BK_RED, BK_GREEN, BK_BLUE, BK_YELLOW, BK_PTRED, BK_PTGREEN };

typedef struct
{
    int horizon;      /* frames simulated ahead */
    int period;       /* frames between plans (the previous decision is held in between) */
    int near_px;      /* clearance the bot likes to keep, in pixels */
    int near_cost;    /* cost per frame spent closer than that */
    int err_pct;      /* chance per plan of a slip (the opposite key) */
    int w_point;      /* value of the small crystals */
    int w_power;      /* value of the big crystals */
    int w_blue;       /* value of the reverse gravity crystal (it flips the controls) */
    int w_shield;     /* value of the fire shield while unshielded: fire pillars cannot be dodged */
}
BotLevel;

static const BotLevel bot_levels[4] =
{
    /* off    */ {  0, 1,  0,  0,  0,     0,    0,     0,     0 },
    /* easy   */ { 18, 3,  3, 40,  6,  1200,  600,  -800,  6000 },
    /* normal */ { 26, 2,  4, 50,  2,  3000, 1200,  -400, 15000 },
    /* hard   */ { 36, 1,  7, 80,  0,  5000, 1800,     0, 30000 }
};

typedef struct
{
    INSTANCE * p;
    GRAPH    * gr;
    int kind;
    int id;
    int x, y, angle;
    int dx, dy, da;
    int rotating, angled, solid, bounce, rect;
    int ghost, g_ts, g_x, g_dir, g_s;     /* a pillar that a cannon will launch: not a real process yet */
    REGION b0;
    short ypath[BOT_MAXT + 1];
}
BotObj;

typedef struct { int id, frame, x, y, angle, dx, dy, da; } BotHist;

static BotHist bot_hist[256];
static BotObj  bot_objs[BOT_MAXOBJ];
static int     bot_nobj = 0;
static REGION  bot_box[BOT_MAXOBJ][BOT_MAXT + 1];
typedef struct { int x[4], y[4]; } BotQuad;
static BotQuad bot_quad[BOT_MAXOBJ][BOT_MAXT + 1];
static unsigned char bot_act[BOT_MAXT + 1][BOT_MAXOBJ];   /* objects that can reach the ship column at time t */
static int bot_nact[BOT_MAXT + 1];
static signed char * bot_kind = NULL;
static int ( * bot_poff )[4] = NULL;      /* per process type: offsets of Range, VerticalMove, TopRange, MinRange */

static int bot_frame = 0;
static int bot_o_p2alive = -1, bot_o_fire = -1, bot_o_anti = -1, bot_o_rev = -1, bot_o_score = -1;
static int bot_o_downforce = -1, bot_offsets_ready = 0;
static int bot_last_z = 0, bot_last_x = 0, bot_since_plan = 1000;
static unsigned bot_rng = 12345u;

/* per-tick cache of pixel checks */
static int bot_cache_key[512], bot_cache_val[512], bot_cache_gen[512], bot_gen = 0;
static int bot_pix_budget = 0, bot_pix_used = 0;

/* death report (SF3500_BOT_DEBUG): the last frames and what was near the ship */
typedef struct { int f, y, vy, z, x, surv; } BotRec;
static BotRec bot_ring[24];
static int bot_ring_n = 0, bot_prev_present = 0;
static char bot_near[600];

/* Per-sprite analysis: how much of the sprite's rectangle is opaque, the box of its opaque pixels, and the
 * opacity mask itself (used for exact, allocation-free overlap tests). */
typedef struct { GRAPH * g; int solid, rect, w, h, x0, y0, x1, y1; unsigned char * mask; } BotGInfo;
static BotGInfo bot_ginfo[256];

static BotGInfo * bot_analyse( GRAPH * g )
{
    unsigned slot = ( unsigned ) ( ( ( unsigned long ) g >> 4 ) & 255 ), tries;
    BotGInfo * gi = NULL;
    int x, y, w, h, depthb, opaque = 0;
    for ( tries = 0; tries < 256; tries++ )
    {
        BotGInfo * c = &bot_ginfo[( slot + tries ) & 255];
        if ( c->g == g ) return c;
        if ( !c->g ) { gi = c; break; }
    }
    if ( !gi ) { gi = &bot_ginfo[slot]; free( gi->mask ); gi->mask = NULL; }     /* table full (never expected): reuse */
    gi->g = g;
    w = ( int ) g->width; h = ( int ) g->height;
    gi->x0 = w; gi->y0 = h; gi->x1 = -1; gi->y1 = -1;
    gi->mask = ( unsigned char * ) calloc( ( size_t ) w * h + 1, 1 );
    depthb = g->format->depthb ? ( int ) g->format->depthb : 1;
    for ( y = 0; y < h; y++ )
    {
        const uint8_t * row = ( const uint8_t * ) g->data + y * g->pitch;
        for ( x = 0; x < w; x++ )
        {
            int px = 0, b;
            for ( b = 0; b < depthb; b++ ) px |= row[x * depthb + b];
            if ( px )
            {
                opaque++;
                if ( gi->mask ) gi->mask[y * w + x] = 1;
                if ( x < gi->x0 ) gi->x0 = x;
                if ( x > gi->x1 ) gi->x1 = x;
                if ( y < gi->y0 ) gi->y0 = y;
                if ( y > gi->y1 ) gi->y1 = y;
            }
        }
    }
    if ( gi->x1 < 0 ) { gi->x0 = gi->y0 = 0; gi->x1 = w - 1; gi->y1 = h - 1; }
    gi->solid = ( opaque * 100 >= w * h * 85 ) ? 1 : 0;
    gi->w = w; gi->h = h;
    {
        int tw = gi->x1 - gi->x0 + 1, th = gi->y1 - gi->y0 + 1;
        gi->rect = ( tw > 0 && th > 0 && opaque * 100 >= tw * th * 80 ) ? 1 : 0;   /* the opaque part is (nearly) a rectangle */
    }
    return gi;
}

static int bot_sin_tab[360];
static int bot_sin_ready = 0;
static void bot_sin_init( void )
{
    /* sine from a quarter-wave table built with integer arithmetic only: no libm on the SF3500's flaky FPU */
    static const short q[91] = { 0,18,36,54,71,89,107,125,143,160,178,195,213,230,248,265,282,299,316,333,350,367,384,400,416,433,449,465,481,496,512,527,543,558,573,587,602,616,630,644,658,672,685,698,711,724,737,749,761,773,784,796,807,818,828,839,849,859,868,878,887,896,904,912,920,928,935,943,949,956,962,968,974,979,984,989,994,998,1002,1005,1008,1011,1014,1016,1018,1020,1022,1023,1023,1024,1024 };
    int d;
    for ( d = 0; d < 360; d++ )
    {
        int r = d % 180, v;
        if ( r > 90 ) r = 180 - r;
        v = q[r];
        bot_sin_tab[d] = ( d < 180 ) ? v : -v;
    }
    bot_sin_ready = 1;
}
static int bot_sin( int mdeg ) { int d = ( mdeg / 1000 ) % 360; if ( d < 0 ) d += 360; return bot_sin_tab[d]; }
static int bot_cos( int mdeg ) { return bot_sin( mdeg + 90000 ); }

static int bot_first_frame = -1, bot_last_print = 0;

/* CPU governor: if planning is slow on this device the bot re-plans less often rather than starving the game. */
static unsigned bot_ema_us = 0;
static int bot_extra_period = 0;
static int bot_nogov = -1;
static unsigned long bot_perf_sum = 0, bot_perf_n = 0;
static unsigned bot_perf_worst = 0;
static int bot_perf_last = 0;

static int bot_dbg = -1;
static unsigned bot_dbg_worst_us = 0;
static unsigned long bot_dbg_sum_us = 0;
static int bot_dbg_plans = 0;

/* ---- lookups by name --------------------------------------------------------- */

static int bot_kind_of_name( const char * n )
{
    if ( !strcasecmp( n, "PLAYER2" ) )          return BK_SHIP;
    if ( !strncasecmp( n, "OBSTACLE", 8 ) )     return BK_HAZ;
    if ( !strncasecmp( n, "ACTIVEGROUND", 12 ) ) return BK_HAZ;
    if ( !strcasecmp( n, "FIREPILLARUP" ) || !strcasecmp( n, "FIREPILLARDOWN" ) ) return BK_FIRE;
    if ( !strcasecmp( n, "REDPOWERUP" ) )       return BK_RED;
    if ( !strcasecmp( n, "GREENPOWERUP" ) )     return BK_GREEN;
    if ( !strcasecmp( n, "BLUEPOWERUP" ) )      return BK_BLUE;
    if ( !strcasecmp( n, "YELLOWPOWERUP" ) )    return BK_YELLOW;
    if ( !strcasecmp( n, "REDPOINT" ) )         return BK_PTRED;
    if ( !strcasecmp( n, "GREENPOINT" ) )       return BK_PTGREEN;
    return BK_NONE;
}

static int bot_id_code( const char * name )
{
    unsigned n;
    for ( n = 0; n < dcb.data.NID; n++ )
        if ( !strcasecmp( ( const char * ) dcb.id[n].Name, name ) ) return ( int ) dcb.id[n].Code;
    return -1;
}

static int bot_global_offset( const char * name )
{
    unsigned n;
    int code = bot_id_code( name );
    if ( code < 0 ) return -1;
    for ( n = 0; n < dcb.data.NGloVars; n++ )
        if ( ( int ) dcb.glovar[n].ID == code ) return ( int ) dcb.glovar[n].Offset;
    return -1;
}

static int bot_private_offset( const char * proc, const char * var )
{
    PROCDEF * pd = procdef_get_by_name( ( char * ) proc );
    unsigned n;
    int code = bot_id_code( var );
    if ( !pd || code < 0 ) return -1;
    for ( n = 0; n < dcb.proc[pd->type].data.NPriVars; n++ )
        if ( ( int ) dcb.proc[pd->type].privar[n].ID == code ) return ( int ) dcb.proc[pd->type].privar[n].Offset;
    return -1;
}

static void bot_setup( void )
{
    unsigned n;
    if ( bot_offsets_ready ) return;
    bot_offsets_ready = 1;
    bot_o_p2alive    = bot_global_offset( "PLAYER2ALIVE" );
    bot_o_fire       = bot_global_offset( "FIRESHIELD2" );
    bot_o_anti       = bot_global_offset( "ANTIGRAVITY2" );
    bot_o_rev        = bot_global_offset( "REVERSEGRAVITY2" );
    bot_o_score      = bot_global_offset( "PLAYER2SCORE" );
    bot_o_downforce  = bot_private_offset( "PLAYER2", "DOWNFORCE" );
    bot_kind = ( signed char * ) calloc( dcb.data.NProcs + 1, 1 );
    bot_poff = ( int ( * )[4] ) calloc( dcb.data.NProcs + 1, sizeof( int[4] ) );
    for ( n = 0; n < dcb.data.NProcs && bot_kind; n++ )
    {
        bot_kind[n] = ( signed char ) bot_kind_of_name( procs[n].name );
        if ( bot_kind[n] != BK_NONE && bot_kind[n] != BK_SHIP && bot_poff )
        {
            bot_poff[n][0] = bot_private_offset( procs[n].name, "RANGE" );
            bot_poff[n][1] = bot_private_offset( procs[n].name, "VERTICALMOVE" );
            bot_poff[n][2] = bot_private_offset( procs[n].name, "TOPRANGE" );
            bot_poff[n][3] = bot_private_offset( procs[n].name, "MINRANGE" );
        }
        else if ( bot_poff ) { bot_poff[n][0] = bot_poff[n][1] = bot_poff[n][2] = bot_poff[n][3] = -1; }
    }
    if ( bot_dbg < 0 ) bot_dbg = getenv( "SF3500_BOT_DEBUG" ) ? 1 : 0;
    fprintf( stderr, "bot: offsets p2alive=%d fire=%d anti=%d rev=%d score=%d downforce=%d\n",
             bot_o_p2alive, bot_o_fire, bot_o_anti, bot_o_rev, bot_o_score, bot_o_downforce );
}

/* ---- game flight rules (copied from the Player2 process) ---------------------- */

static int bot_vg = 0;       /* speed the game uses to choose the ship's sprite in this step */

static void bot_flight( int * y, int * vy, int z, int xk, int anti, int rev )
{
    int v = *vy;
    if ( !rev && z ) v -= 2;
    if ( anti && xk ) v += 2;
    if ( rev && xk ) v += 2;
    if ( !anti && !rev ) v += 1;
    if ( rev ) v -= 1;
    if ( v > 7 ) v = 7;
    if ( v < -7 ) v = -7;
    bot_vg = v;
    *y += v / 2;
    if ( anti )
    {
        if ( v > 0 ) v--;
        if ( v < 0 ) v++;
    }
    *vy = v;
}

/* Keys that move the vertical speed towards vt. */
static void bot_keys_for( int vy, int vt, int anti, int rev, int * z, int * xk )
{
    *z  = ( !rev && vy > vt ) ? 1 : 0;
    *xk = ( ( anti || rev ) && vy < vt ) ? 1 : 0;
}

/* ---- object bookkeeping ------------------------------------------------------- */

static int bot_ovl( const REGION * a, const REGION * b, int m )
{
    return !( a->x2 + m < b->x || a->x - m > b->x2 || a->y2 + m < b->y || a->y - m > b->y2 );
}

/* Crystals bob up and down within a range, so their vertical movement is only extrapolated briefly. */
static int bot_ty( const BotObj * o, int t )
{
    return ( o->kind >= BK_RED && t > 20 ) ? 20 : t;
}

/* Centre of the object at time t (t = 0: now). A ghost pillar only exists from its spawn time; the numbers are the
 * script's: FirePillarUp starts at y=315 and FirePillarDown at y=-75, moves 5 pixels a frame up or down and scrolls
 * left with the cannon, and has already made one step when it is first seen. */
static void bot_pose( const BotObj * o, int t, int * cx, int * cy );

static int bot_y_at( const BotObj * o, int t )
{
    return o->bounce ? o->ypath[t] : o->y + o->dy * bot_ty( o, t );
}

static void bot_bbox_at( BotObj * o, int t, REGION * out )
{
    if ( !o->rotating )
    {
        out->x  = o->b0.x  + o->dx * t;
        out->x2 = o->b0.x2 + o->dx * t;
        out->y  = o->b0.y  + bot_y_at( o, t ) - o->y;
        out->y2 = o->b0.y2 + bot_y_at( o, t ) - o->y;
    }
    else
    {
        int sx = LOCINT32( mod_grproc, o->p, COORDX ), sy = LOCINT32( mod_grproc, o->p, COORDY ), sa = LOCINT32( mod_grproc, o->p, ANGLE );
        LOCINT32( mod_grproc, o->p, COORDX ) = o->x + o->dx * t;
        LOCINT32( mod_grproc, o->p, COORDY ) = bot_y_at( o, t );
        LOCINT32( mod_grproc, o->p, ANGLE )  = o->angle + o->da * t;
        instance_get_bbox( o->p, o->gr, out );
        LOCINT32( mod_grproc, o->p, COORDX ) = sx;
        LOCINT32( mod_grproc, o->p, COORDY ) = sy;
        LOCINT32( mod_grproc, o->p, ANGLE )  = sa;
    }
}

/* Player 2's sprites: the script picks graph 77..85 from the vertical speed. */
static int bot_sil[9][4];
static short bot_outline[9][600][2];      /* opaque pixels with a transparent neighbour: the only ones that can first touch something */
static int bot_outline_n[9];            /* x0, y0, x1, y1 of the opaque part of each sprite, relative to its box */
static int bot_sil_ready = 0, bot_sil_file = -999;
static REGION bot_sb0;               /* the ship's current full box */
static int bot_sb0_y = 0;            /* the ship's current height */

static int bot_sprite_index( int vg )
{
    if ( vg == 0 ) return 0;
    if ( vg > 0 ) return vg >= 7 ? 4 : ( vg + 1 ) / 2 + ( 0 );      /* 1,2 -> 1 ; 3,4 -> 2 ; 5,6 -> 3 ; 7 -> 4 */
    return ( -vg >= 7 ) ? 8 : 4 + ( -vg + 1 ) / 2;                  /* -1,-2 -> 5 ; -3,-4 -> 6 ; -5,-6 -> 7 ; -7 -> 8 */
}

static void bot_sil_load( INSTANCE * ship )
{
    int file = 0, k;
    if ( bot_sil_ready ) return;
    /* the game loads a single graphics library: find the one that holds sprite 77 */
    for ( k = 0; k < 32; k++ ) if ( bitmap_get( k, 77 ) ) { file = k; break; }
    bot_sil_file = file;
    bot_sil_ready = 1;
    for ( k = 0; k < 9; k++ )
    {
        GRAPH * g = bitmap_get( file, 77 + k );
        if ( g )
        {
            BotGInfo * gi = bot_analyse( g );
            int x, y, n = 0;
            bot_sil[k][0] = gi->x0; bot_sil[k][1] = gi->y0; bot_sil[k][2] = gi->x1; bot_sil[k][3] = gi->y1;
            for ( y = gi->y0; y <= gi->y1 && gi->mask; y++ )
                for ( x = gi->x0; x <= gi->x1; x++ )
                {
                    int edge;
                    if ( !gi->mask[y * gi->w + x] ) continue;
                    edge = ( x == 0 || y == 0 || x == gi->w - 1 || y == gi->h - 1 ||
                             !gi->mask[y * gi->w + x - 1] || !gi->mask[y * gi->w + x + 1] ||
                             !gi->mask[( y - 1 ) * gi->w + x] || !gi->mask[( y + 1 ) * gi->w + x] );
                    if ( edge && n < 600 ) { bot_outline[k][n][0] = ( short ) x; bot_outline[k][n][1] = ( short ) y; n++; }
                }
            bot_outline_n[k] = n;
        }
        else { bot_sil[k][0] = 0; bot_sil[k][1] = 4; bot_sil[k][2] = 49; bot_sil[k][3] = 35; bot_outline_n[k] = 0; }   /* unknown: a generous box */
    }
}

/* The silhouette of the sprite shown for speed vg when the ship is dy pixels from where it is now. */
static void bot_sil_at( int vg, int dy, REGION * out )
{
    int k = bot_sprite_index( vg );
    out->x  = bot_sb0.x + bot_sil[k][0] - BOT_SIL_MARGIN;
    out->x2 = bot_sb0.x + bot_sil[k][2] + BOT_SIL_MARGIN;
    out->y  = bot_sb0.y + bot_sil[k][1] - BOT_SIL_MARGIN + dy;
    out->y2 = bot_sb0.y + bot_sil[k][3] + BOT_SIL_MARGIN + dy;
}

static void bot_pose( const BotObj * o, int t, int * cx, int * cy )
{
    if ( o->ghost )
    {
        int j = t - o->g_ts;
        if ( j < 0 ) { *cx = 100000; *cy = 100000; return; }
        *cx = ( o->g_dir > 0 ? o->g_x + 1 : o->g_x + 2 ) - o->g_s * ( j + 1 );
        *cy = ( o->g_dir > 0 ? 315 - 5 * ( j + 1 ) : -75 + 5 * ( j + 1 ) );
        return;
    }
    *cx = o->x + o->dx * t;
    *cy = ( t == 0 ) ? o->y : bot_y_at( o, t );
}

/* The opaque rectangle of a rectangle-like sprite at time t: its corners (rotated about the sprite centre when the
 * object rotates) and their bounding box. Integer maths only. Angles are in thousandths of a degree. */
static int bot_mapv = -1;         /* experiment: 0 = integer centre, 1 = parity-aware centre for rotated sprites */
static int bot_rot_sign = 1;      /* +1: angle counts counter-clockwise on screen (the engine's convention) */

static void bot_rect_at( BotObj * o, int t, REGION * box, BotQuad * q )
{
    BotGInfo * gi = bot_analyse( o->gr );
    int cx, cy;
    int ang = o->angle + o->da * t;
    int lx0 = gi->x0 - gi->w / 2 - 1, lx1 = gi->x1 + 1 - gi->w / 2 + 1;
    int ly0 = gi->y0 - gi->h / 2 - 1, ly1 = gi->y1 + 1 - gi->h / 2 + 1;
    int lxs[4], lys[4], k;
    bot_pose( o, t, &cx, &cy );
    lxs[0] = lx0; lys[0] = ly0;  lxs[1] = lx1; lys[1] = ly0;  lxs[2] = lx1; lys[2] = ly1;  lxs[3] = lx0; lys[3] = ly1;
    if ( o->kind >= BK_RED ) { lxs[0]++; lys[0]++; lxs[1]--; lys[1]++; lxs[2]--; lys[2]--; lxs[3]++; lys[3]--; }   /* crystals: a little smaller than their box */
    {
        int sn = bot_sin( bot_rot_sign * ang ), cs = bot_cos( bot_rot_sign * ang );
        int minx = 1 << 30, miny = 1 << 30, maxx = -( 1 << 30 ), maxy = -( 1 << 30 );
        for ( k = 0; k < 4; k++ )
        {
            int X, Y;
            if ( !o->angled ) { X = cx + lxs[k]; Y = cy + lys[k]; }
            else
            {
                X = cx + ( lxs[k] * cs + lys[k] * sn ) / 1024;
                Y = cy + ( -lxs[k] * sn + lys[k] * cs ) / 1024;
            }
            q->x[k] = X; q->y[k] = Y;
            if ( X < minx ) minx = X;
            if ( X > maxx ) maxx = X;
            if ( Y < miny ) miny = Y;
            if ( Y > maxy ) maxy = Y;
        }
        box->x = minx; box->y = miny; box->x2 = maxx; box->y2 = maxy;
    }
}

/* Separating-axis test of a rotated rectangle against an axis-aligned box. */
static int bot_sat( const BotQuad * q, const REGION * a )
{
    int ax[4] = { a->x, a->x2, a->x2, a->x }, ay[4] = { a->y, a->y, a->y2, a->y2 };
    int axis, k;
    for ( axis = 0; axis < 2; axis++ )
    {
        int nx = q->x[axis + 1] - q->x[axis], ny = q->y[axis + 1] - q->y[axis];     /* an edge direction of the rectangle */
        long qmin = 1L << 60, qmax = -( 1L << 60 ), amin = 1L << 60, amax = -( 1L << 60 );
        for ( k = 0; k < 4; k++ )
        {
            long pq = ( long ) q->x[k] * nx + ( long ) q->y[k] * ny;
            long pa = ( long ) ax[k] * nx + ( long ) ay[k] * ny;
            if ( pq < qmin ) qmin = pq;
            if ( pq > qmax ) qmax = pq;
            if ( pa < amin ) amin = pa;
            if ( pa > amax ) amax = pa;
        }
        if ( qmax < amin || amax < qmin ) return 0;
    }
    return 1;                      /* the box axes were already tested by the bounding-box prefilter */
}

/* Exact overlap of the ship's sprite for speed vg (dy pixels from its current position) with object o at time t:
 * sample the ship's opaque pixels, map each into the object's sprite (inverse of the rotation validated above)
 * and look it up in the object's opacity mask. */
static int bot_mask_hit_k( BotObj * o, int t, int k, int dy )
{
    GRAPH * sg = bitmap_get( bot_sil_file, 77 + k );
    BotGInfo * si, * oi;
    int cx, cy, ang, sn = 0, cs = 1024, sx, sy;
    if ( !sg ) return 1;
    si = bot_analyse( sg );
    oi = bot_analyse( o->gr );
    if ( !si->mask || !oi->mask ) return 1;
    bot_pose( o, t, &cx, &cy );
    ang = o->angle + o->da * t;
    if ( ang % 360000 != 0 ) { sn = bot_sin( bot_rot_sign * ang ); cs = bot_cos( bot_rot_sign * ang ); }
    {
        int n, nn = bot_outline_n[k];
        if ( nn == 0 ) return 1;
        for ( n = 0; n < nn; n++ )
        {
            int wx, wy, ddx, ddy, lx, ly;
            sx = bot_outline[k][n][0]; sy = bot_outline[k][n][1];
            wx = bot_sb0.x + sx;
            wy = bot_sb0.y + dy + sy;
            ddx = wx - cx;  ddy = wy - cy;
            {
                /* Work in half pixels: the sprite's centre is on a pixel centre for odd sizes and on a pixel corner for
                 * even ones, and a world pixel is represented by its centre. */
                int d2x = 2 * ddx + 1 - ( oi->w & 1 ), d2y = 2 * ddy + 1 - ( oi->h & 1 ), l2x, l2y;
                if ( sn == 0 && cs == 1024 ) { lx = ddx + oi->w / 2; ly = ddy + oi->h / 2; }
                else if ( bot_mapv == 0 )
                {
                    lx = ( ddx * cs - ddy * sn ) / 1024 + oi->w / 2;
                    ly = ( ddx * sn + ddy * cs ) / 1024 + oi->h / 2;
                }
                else
                {
                    l2x = ( d2x * cs - d2y * sn ) >> 10; l2y = ( d2x * sn + d2y * cs ) >> 10;
                    lx = ( l2x + oi->w ) >> 1;
                    ly = ( l2y + oi->h ) >> 1;
                }
            }
            if ( sn == 0 && cs == 1024 )
            {
                if ( lx >= 0 && lx < oi->w && ly >= 0 && ly < oi->h && oi->mask[ly * oi->w + lx] ) return 1;
            }
            else if ( oi->rect )
            {
                /* a rotated rectangle: the engine's rotated drawing covers up to a pixel more at the edges, so grow it by one */
                if ( lx >= oi->x0 - 1 && lx <= oi->x1 + 1 && ly >= oi->y0 - 1 && ly <= oi->y1 + 1 ) return 1;
            }
            else
            {
                /* any other rotated shape: look one pixel around as well */
                int ox2, oy2;
                for ( oy2 = -1; oy2 <= 1; oy2++ )
                    for ( ox2 = -1; ox2 <= 1; ox2++ )
                    {
                        int mx = lx + ox2, my = ly + oy2;
                        if ( mx >= 0 && mx < oi->w && my >= 0 && my < oi->h && oi->mask[my * oi->w + mx] ) return 1;
                    }
            }
        }
    }
    return 0;
}

static unsigned bot_mc_key[4096];
static unsigned char bot_mc_val[4096];
static unsigned short bot_mc_gen[4096];
static unsigned short bot_mc_cur = 1;

static int bot_mask_hit( BotObj * o, int t, int vg, int dy )
{
    int k = bot_sprite_index( vg ), oi = ( int ) ( o - bot_objs );
    unsigned key = ( ( unsigned ) oi << 24 ) | ( ( unsigned ) t << 18 ) | ( ( unsigned ) ( ( dy + 256 ) & 0x1ff ) << 4 ) | ( unsigned ) k;
    unsigned slot = ( key * 2654435761u ) >> 20;           /* 12 bits */
    int r;
    if ( bot_mc_gen[slot] == bot_mc_cur && bot_mc_key[slot] == key ) return bot_mc_val[slot];
    r = bot_mask_hit_k( o, t, k, dy );
    bot_mc_gen[slot] = bot_mc_cur; bot_mc_key[slot] = key; bot_mc_val[slot] = ( unsigned char ) r;
    return r;
}

/* Asks the engine whether the ship at height shipy would touch object o at time t. */
static int bot_pixel_hit( INSTANCE * ship, GRAPH * sgr, BotObj * o, int oi, int t, int shipy )
{
    int key = ( oi << 20 ) | ( t << 14 ) | ( ( shipy + 2000 ) & 0x3fff );
    int slot = ( int )( ( unsigned ) ( key * 2654435761u ) >> 23 ) & 511;
    int sy0, ox0, oy0, oa0, res;
    REGION sb;

    if ( bot_cache_gen[slot] == bot_gen && bot_cache_key[slot] == key ) return bot_cache_val[slot];
    if ( bot_pix_used >= bot_pix_budget ) return 1;          /* out of budget: be careful */
    bot_pix_used++;

    sy0 = LOCINT32( mod_grproc, ship, COORDY );
    ox0 = LOCINT32( mod_grproc, o->p, COORDX );
    oy0 = LOCINT32( mod_grproc, o->p, COORDY );
    oa0 = LOCINT32( mod_grproc, o->p, ANGLE );

    LOCINT32( mod_grproc, ship, COORDY )  = shipy;
    LOCINT32( mod_grproc, o->p, COORDX )  = o->x + o->dx * t;
    LOCINT32( mod_grproc, o->p, COORDY )  = bot_y_at( o, t );
    LOCINT32( mod_grproc, o->p, ANGLE )   = o->angle + o->da * t;

    instance_get_bbox( ship, sgr, &sb );
    res = check_collision( ship, sgr, &sb, o->p ) ? 1 : 0;

    LOCINT32( mod_grproc, ship, COORDY )  = sy0;
    LOCINT32( mod_grproc, o->p, COORDX )  = ox0;
    LOCINT32( mod_grproc, o->p, COORDY )  = oy0;
    LOCINT32( mod_grproc, o->p, ANGLE )   = oa0;

    bot_cache_gen[slot] = bot_gen;
    bot_cache_key[slot] = key;
    bot_cache_val[slot] = res;
    return res;
}

static const char * bot_kind_name( const char * n ) { return n; }

/* Does the ship (full box sb, silhouette box st, centre height y) touch object o at time t? */
static int bot_touch( INSTANCE * ship, GRAPH * sgr, const REGION * st, BotObj * o, int oi, int t, int y )
{
    ( void ) ship; ( void ) sgr;
    if ( !bot_ovl( st, &bot_box[oi][t], 0 ) ) return 0;
    if ( o->rect && o->angled && !bot_sat( &bot_quad[oi][t], st ) ) return 0;      /* cheap exact reject for rotating rectangles */
    return bot_mask_hit( o, t, bot_vg, y - bot_sb0_y );
}

static unsigned bot_rand( void )
{
    bot_rng = bot_rng * 1664525u + 1013904223u;
    return bot_rng >> 8;
}

static unsigned bot_now_us( void )
{
    struct timespec ts;
    clock_gettime( CLOCK_MONOTONIC, &ts );
    return ( unsigned ) ( ts.tv_sec * 1000000u + ts.tv_nsec / 1000 );
}

/* ---- the tick ----------------------------------------------------------------- */

int sf3500_bot_tick( int level, int * out_z, int * out_x, int * out_alt )
{
    const BotLevel * L;
    INSTANCE * ptr, * ship = NULL;
    GRAPH * sgr;
    REGION sb0, st0;
    int sx, sy, svy = 0, anti = 0, rev = 0, shield = 0;
    int i, t, H, TM, plan_now;
    unsigned t0 = 0, plan_us = 0;

    *out_z = *out_x = *out_alt = 0;
    if ( level < 1 || level > 3 ) return 0;
    L = &bot_levels[level];
    if ( getenv( "SF3500_BOT_AVOID_RED" ) )
    {
        static BotLevel tmp;
        tmp = *L; tmp.w_shield = 0; L = &tmp;     /* test: pretend the red crystal is of no interest (a human took it) */
    }
    bot_setup();
    if ( !bot_sin_ready ) bot_sin_init();
    if ( bot_mapv < 0 ) bot_mapv = getenv( "SF3500_BOT_MAPV" ) ? atoi( getenv( "SF3500_BOT_MAPV" ) ) : 1;
    if ( !bot_kind ) return 0;
    bot_frame++;

    /* find the ship and the objects of interest */
    bot_nobj = 0;
    for ( ptr = first_instance; ptr; ptr = ptr->next )
    {
        int status, k;
        if ( !ptr->proc ) continue;
        k = bot_kind[ptr->proc->type];
        if ( k == BK_NONE ) continue;
        if ( k == BK_RED && getenv( "SF3500_BOT_AVOID_RED" ) ) continue;
        status = LOCDWORD( mod_grproc, ptr, STATUS ) & ~STATUS_WAITING_MASK;
        if ( status != STATUS_RUNNING && status != STATUS_FROZEN ) continue;
        if ( k == BK_SHIP ) { ship = ptr; continue; }
        if ( bot_nobj >= BOT_MAXOBJ ) continue;
        {
            BotObj * o = &bot_objs[bot_nobj];
            BotHist * h;
            memset( o, 0, sizeof( *o ) );          /* slots are reused every tick: nothing may be left over (a ghost flag, say) */
            o->p = ptr;
            o->kind = k;
            o->gr = instance_graph( ptr );
            if ( !o->gr ) continue;
            o->id    = LOCDWORD( mod_grproc, ptr, PROCESS_ID );
            o->x     = LOCINT32( mod_grproc, ptr, COORDX );
            o->y     = LOCINT32( mod_grproc, ptr, COORDY );
            o->angle = LOCINT32( mod_grproc, ptr, ANGLE );
            instance_get_bbox( ptr, o->gr, &o->b0 );
            h = &bot_hist[o->id & 255];
            if ( h->id == o->id && h->frame == bot_frame - 1 && abs( o->x - h->x ) < 60 )
            {
                o->dx = o->x - h->x;
                o->dy = o->y - h->y;
                o->da = o->angle - h->angle;
                if ( o->da > 180000 ) o->da -= 360000;
                if ( o->da < -180000 ) o->da += 360000;
            }
            else
            {
                o->dx = -3; o->dy = 0; o->da = 0;       /* new object: assume the usual scroll */
            }
            h->id = o->id; h->frame = bot_frame; h->x = o->x; h->y = o->y; h->angle = o->angle;
            o->rotating = ( o->da != 0 );
            o->angled = ( o->da != 0 || ( o->angle % 360000 ) != 0 );
            o->solid = bot_analyse( o->gr )->solid;
            o->rect = bot_analyse( o->gr )->rect;
            o->bounce = 0;
            if ( bot_poff && ptr->pridata && bot_poff[ptr->proc->type][0] >= 0 && bot_poff[ptr->proc->type][1] >= 0 &&
                 bot_poff[ptr->proc->type][2] >= 0 && bot_poff[ptr->proc->type][3] >= 0 )
            {
                int rg = ( int32_t ) PRIDWORD( ptr, bot_poff[ptr->proc->type][0] );
                int vm = ( int32_t ) PRIDWORD( ptr, bot_poff[ptr->proc->type][1] );
                int top = ( int32_t ) PRIDWORD( ptr, bot_poff[ptr->proc->type][2] );
                int mn = ( int32_t ) PRIDWORD( ptr, bot_poff[ptr->proc->type][3] );
                int yy = o->y, k;
                /* the same per-frame rule as the game's process */
                for ( k = 1; k <= BOT_MAXT; k++ )
                {
                    if ( vm == 1 ) { yy++; rg++; }
                    if ( vm == 2 ) { yy--; rg--; }
                    if ( rg == top ) vm = 1;
                    if ( rg == mn ) vm = 2;
                    o->ypath[k] = ( short ) yy;
                }
                o->bounce = 1;
            }
            bot_nobj++;
        }
    }
    if ( !ship || ( bot_o_p2alive >= 0 && !BOT_GLO( bot_o_p2alive ) ) )
    {
        if ( bot_prev_present )
            fprintf( stderr, "bot: RESULT %s level=%d alive=%d frames score=%d\n",
                     ( bot_o_p2alive >= 0 && !BOT_GLO( bot_o_p2alive ) ) ? "CRASHED" : "COMPLETED", level,
                     bot_frame - bot_first_frame, bot_o_score >= 0 ? ( int ) BOT_GLO( bot_o_score ) : -1 );
        if ( bot_dbg && bot_prev_present )
        {
            int k;
            fprintf( stderr, "bot: SHIP LOST at f=%d. last frames (f y vy z x surv):\n", bot_frame );
            for ( k = 0; k < 14 && k < bot_ring_n; k++ )
            {
                BotRec * r = &bot_ring[( bot_ring_n - 14 + k + 24 * 2 ) % 24];
                if ( bot_ring_n < 14 ) r = &bot_ring[k];
                fprintf( stderr, "bot:   %d %d %d %d %d %d\n", r->f, r->y, r->vy, r->z, r->x, r->surv );
            }
            fprintf( stderr, "bot: near at last plan: %s\n", bot_near );
        }
        bot_prev_present = 0;
        return 0;
    }
    if ( !bot_prev_present ) bot_first_frame = bot_frame;
    bot_prev_present = 1;

    sgr = instance_graph( ship );
    if ( !sgr ) return 0;
    instance_get_bbox( ship, sgr, &sb0 );
    bot_sb0 = sb0;
    bot_sil_load( ship );
    {
        /* union of all of Player 2's sprites: only used to find the objects near the ship's column */
        int k;
        st0.x = sb0.x + bot_sil[0][0] - 1; st0.y = sb0.y + bot_sil[0][1] - 1; st0.x2 = sb0.x + bot_sil[0][2] + 1; st0.y2 = sb0.y + bot_sil[0][3] + 1;
        for ( k = 1; k < 9; k++ )
        {
            if ( sb0.x + bot_sil[k][0] - 1 < st0.x )   st0.x  = sb0.x + bot_sil[k][0] - 1;
            if ( sb0.y + bot_sil[k][1] - 1 < st0.y )   st0.y  = sb0.y + bot_sil[k][1] - 1;
            if ( sb0.x + bot_sil[k][2] + 1 > st0.x2 )  st0.x2 = sb0.x + bot_sil[k][2] + 1;
            if ( sb0.y + bot_sil[k][3] + 1 > st0.y2 )  st0.y2 = sb0.y + bot_sil[k][3] + 1;
        }
    }
    sx = LOCINT32( mod_grproc, ship, COORDX );
    sy = LOCINT32( mod_grproc, ship, COORDY );
    bot_sb0_y = sy;
    {
        /* ghost pillars from the cannons (Obstacle4 on the floor launches pillars upward, Obstacle6 on the ceiling downward) */
        GRAPH * g32 = bitmap_get( bot_sil_file, 32 );
        int n0 = bot_nobj, a;
        if ( g32 && !getenv( "SF3500_BOT_NOGHOST" ) )
        {
            BotGInfo * gi32 = bot_analyse( g32 );
            for ( a = 0; a < n0; a++ )
            {
                BotObj * c = &bot_objs[a];
                const char * nm = c->p->proc->name;
                int dir = 0, trig, sp = -c->dx;
                if ( c->ghost || c->kind != BK_HAZ || sp <= 0 ) continue;
                if ( !strcasecmp( nm, "OBSTACLE4" ) ) dir = 1;
                else if ( !strcasecmp( nm, "OBSTACLE6" ) ) dir = -1;
                if ( !dir ) continue;
                for ( trig = 0; trig < 2; trig++ )
                {
                    int X = trig ? 177 : 327;
                    if ( c->x <= X || ( c->x - X ) % sp != 0 || bot_nobj >= BOT_MAXOBJ ) continue;
                    {
                        BotObj * g = &bot_objs[bot_nobj++];
                        memset( g, 0, sizeof( *g ) );
                        g->p = c->p; g->gr = g32; g->kind = BK_FIRE; g->id = -( bot_nobj );
                        g->ghost = 1; g->g_ts = ( c->x - X ) / sp; g->g_x = X; g->g_dir = dir; g->g_s = sp;
                        g->dx = -sp; g->rect = 1; g->solid = gi32->solid;
                    }
                }
            }
        }
    }
    if ( bot_o_downforce >= 0 && ship->pridata ) svy = ( int32_t ) PRIDWORD( ship, bot_o_downforce );
    if ( bot_o_anti >= 0 ) anti = BOT_GLO( bot_o_anti ) ? 1 : 0;
    if ( bot_o_rev  >= 0 ) rev  = BOT_GLO( bot_o_rev )  ? 1 : 0;
    if ( bot_o_fire >= 0 ) shield = BOT_GLO( bot_o_fire ) ? 1 : 0;

    /* plan only every L->period frames, otherwise hold the previous decision */
    bot_since_plan++;
    plan_now = ( bot_since_plan >= L->period + bot_extra_period );
    if ( !plan_now )
    {
        *out_z = bot_last_z; *out_x = bot_last_x;
        if ( bot_dbg ) { BotRec * r = &bot_ring[bot_ring_n % 24]; r->f = bot_frame; r->y = sy; r->vy = svy; r->z = bot_last_z; r->x = bot_last_x; r->surv = -1; bot_ring_n++; }
        return 1;
    }
    bot_since_plan = 0;
    t0 = bot_now_us();

    H = L->horizon;
    if ( H > BOT_MAXT - BOT_EXT ) H = BOT_MAXT - BOT_EXT;
    TM = H + BOT_EXT;
    bot_gen++;
    if ( ++bot_mc_cur == 0 ) { memset( bot_mc_gen, 0, sizeof( bot_mc_gen ) ); bot_mc_cur = 1; }
    bot_pix_budget = 60;
    bot_pix_used = 0;

    /* predicted boxes of every object for t = 1..TM, and which objects can reach the ship's column */
    for ( t = 1; t <= TM; t++ ) bot_nact[t] = 0;
    for ( i = 0; i < bot_nobj; i++ )
        for ( t = 1; t <= TM; t++ )
        {
            if ( bot_objs[i].rect ) bot_rect_at( &bot_objs[i], t, &bot_box[i][t], &bot_quad[i][t] );
            else bot_bbox_at( &bot_objs[i], t, &bot_box[i][t] );
            if ( bot_box[i][t].x2 >= st0.x - 16 && bot_box[i][t].x <= st0.x2 + 16 ) bot_act[t][bot_nact[t]++] = ( unsigned char ) i;
        }

    /* the crystal worth steering towards even if it is still far away */
    int target_y = 135, best_pull = 0;
    for ( i = 0; i < bot_nobj; i++ )
    {
        BotObj * o = &bot_objs[i];
        int val = 0, ta, ty;
        switch ( o->kind )
        {
            case BK_PTGREEN: val = L->w_point;     break;
            case BK_PTRED:   val = L->w_point / 3; break;
            case BK_RED:     val = shield ? 0 : L->w_shield; break;
            case BK_GREEN: case BK_YELLOW: val = L->w_power; break;
            case BK_BLUE:    val = L->w_blue;      break;
            default: break;
        }
        if ( val <= 0 || o->dx >= 0 ) continue;
        ta = ( o->x - ( sx + 12 ) ) / ( -o->dx );
        if ( ta < 2 || ta > ( o->kind == BK_RED ? 90 : 40 ) ) continue;
        if ( val * 10 / ( 10 + ta ) > best_pull )
        {
            best_pull = val * 10 / ( 10 + ta );
            ty = o->y + o->dy * ta;
            if ( ty < 50 ) ty = 50;
            if ( ty > 190 ) ty = 190;
            target_y = ty;
        }
    }

    /* try the strategies */
    {
        int best_score = -2000000000, best_z = 0, best_x = 0, best_surv = 0, best_ci = -1;
        int c, ncand = 0;
        int cand_vt1[96], cand_k[96], cand_vt2[96];
        int c_first_z[96], c_first_x[96], c_end_y[96], c_end_vy[96], c_surv[96], c_score[96], c_fb[96];
        static const int five[5] = { -7, -4, 0, 4, 7 };
        static const int fallback_vt[3] = { -7, 0, 7 };
        int a, b;

        for ( a = -7; a <= 7; a++ ) { cand_vt1[ncand] = a; cand_k[ncand] = 0; cand_vt2[ncand] = a; ncand++; }
        for ( a = 0; a < 5; a++ )
            for ( b = 0; b < 5; b++ )
            {
                if ( a == b ) continue;
                cand_vt1[ncand] = five[a]; cand_k[ncand] = 8;  cand_vt2[ncand] = five[b]; ncand++;
                cand_vt1[ncand] = five[a]; cand_k[ncand] = 16; cand_vt2[ncand] = five[b]; ncand++;
            }

        /* stage 1: every strategy over the horizon */
        for ( c = 0; c < ncand; c++ )
        {
            int y = sy, vy = svy, surv = H + 1, score = 0, zf = 0, xf = 0;
            unsigned picked[2] = { 0, 0 };
            for ( t = 1; t <= H && surv > H; t++ )
            {
                int z, xk, vt = ( t <= cand_k[c] ) ? cand_vt1[c] : cand_vt2[c], n;
                REGION sb;
                bot_keys_for( vy, vt, anti, rev, &z, &xk );
                if ( t == 1 ) { zf = z; xf = xk; }
                bot_flight( &y, &vy, z, xk, anti, rev );
                bot_sil_at( bot_vg, y - sy, &sb );
                for ( n = 0; n < bot_nact[t]; n++ )
                {
                    int oi = bot_act[t][n];
                    BotObj * o = &bot_objs[oi];
                    REGION * ob = &bot_box[oi][t];
                    if ( o->kind == BK_HAZ || ( o->kind == BK_FIRE && !shield ) )
                    {
                        if ( bot_touch( ship, sgr, &sb, o, oi, t, y ) ) { surv = t; break; }
                        if ( bot_ovl( &sb, ob, L->near_px ) ) score -= L->near_cost;
                    }
                    else if ( o->kind >= BK_RED && oi < 64 && !( picked[oi >> 5] & ( 1u << ( oi & 31 ) ) ) &&
                              bot_touch( ship, sgr, &sb, o, oi, t, y ) )
                    {
                        int val;
                        switch ( o->kind )
                        {
                            case BK_PTGREEN: val = L->w_point;     break;
                            case BK_PTRED:   val = L->w_point / 3; break;
                            case BK_BLUE:    val = L->w_blue;      break;
                            case BK_RED:     val = shield ? 0 : L->w_shield; break;
                            default:         val = L->w_power;     break;
                        }
                        score += val;
                        picked[oi >> 5] |= 1u << ( oi & 31 );
                    }
                }
            }
            score -= 3 * abs( y - target_y );
            score += surv * 100000;
            c_first_z[c] = zf; c_first_x[c] = xf; c_end_y[c] = y; c_end_vy[c] = vy; c_surv[c] = surv; c_score[c] = score;
        }

        /* stage 2: for every strategy that survives the horizon, check that the ship still has an escape afterwards */
        for ( c = 0; c < ncand; c++ )
        {
            int ext = 0, f, total;
            c_fb[c] = 1;
            if ( c_surv[c] > H )
            {
                for ( f = 0; f < 3 && ext < BOT_EXT; f++ )
                {
                    int y = c_end_y[c], vy = c_end_vy[c], alive = 0;
                    for ( t = H + 1; t <= TM; t++ )
                    {
                        int z, xk, n, dead = 0;
                        REGION sb;
                        bot_keys_for( vy, fallback_vt[f], anti, rev, &z, &xk );
                        bot_flight( &y, &vy, z, xk, anti, rev );
                        bot_sil_at( bot_vg, y - sy, &sb );
                        for ( n = 0; n < bot_nact[t] && !dead; n++ )
                        {
                            int oi = bot_act[t][n];
                            BotObj * o = &bot_objs[oi];
                            if ( ( o->kind == BK_HAZ || ( o->kind == BK_FIRE && !shield ) ) &&
                                 bot_touch( ship, sgr, &sb, o, oi, t, y ) ) dead = 1;
                        }
                        if ( dead ) break;
                        alive++;
                    }
                    if ( alive > ext ) { ext = alive; c_fb[c] = f; }
                }
                c_score[c] += ext * 10000;
                total = H + ext;
            }
            else total = c_surv[c];
            if ( c_score[c] > best_score ) { best_score = c_score[c]; best_z = c_first_z[c]; best_x = c_first_x[c]; best_surv = total; best_ci = c; }
        }

        plan_us = bot_now_us() - t0;
        bot_ema_us = ( bot_ema_us * 7 + plan_us ) / 8;
        /* SF3500_BOT_NOGOVERNOR=1 (tests only): never lengthen the replan interval, so a run does not depend on how
         * fast the machine running the emulator happens to be at that moment. */
        if ( bot_nogov < 0 ) bot_nogov = getenv( "SF3500_BOT_NOGOVERNOR" ) ? 1 : 0;
        if ( bot_nogov ) { /* fixed interval */ }
        else if ( bot_ema_us > 12000 && bot_extra_period < 3 ) bot_extra_period++;
        else if ( bot_ema_us < 5000 && bot_extra_period > 0 ) bot_extra_period--;
        bot_perf_sum += plan_us; bot_perf_n++;
        if ( plan_us > bot_perf_worst ) bot_perf_worst = plan_us;
        if ( bot_frame - bot_perf_last >= 250 )
        {
            fprintf( stderr, "bot: perf level=%d plans=%lu avg=%luus worst=%uus ema=%uus extra_period=%d frame=%d\n",
                     level, bot_perf_n, bot_perf_n ? bot_perf_sum / bot_perf_n : 0, bot_perf_worst, bot_ema_us, bot_extra_period, bot_frame );
            bot_perf_sum = 0; bot_perf_n = 0; bot_perf_worst = 0; bot_perf_last = bot_frame;
        }

        if ( bot_dbg && best_ci >= 0 && best_surv < H + BOT_EXT && ( best_surv <= 3 || bot_frame % 10 == 0 ) )
        {
            int y = sy, vy = svy, tt;
            for ( tt = 1; tt <= TM; tt++ )
            {
                int z, xk, vt = ( tt > H ) ? fallback_vt[c_fb[best_ci]] : ( ( tt <= cand_k[best_ci] ) ? cand_vt1[best_ci] : cand_vt2[best_ci] ), n, hitn = -1;
                REGION sb;
                bot_keys_for( vy, vt, anti, rev, &z, &xk );
                bot_flight( &y, &vy, z, xk, anti, rev );
                bot_sil_at( bot_vg, y - sy, &sb );
                for ( n = 0; n < bot_nact[tt]; n++ )
                {
                    int oi = bot_act[tt][n];
                    BotObj * o = &bot_objs[oi];
                    if ( ( o->kind == BK_HAZ || ( o->kind == BK_FIRE && !shield ) ) && bot_touch( ship, sgr, &sb, o, oi, tt, y ) ) { hitn = oi; break; }
                }
                if ( hitn >= 0 )
                {
                    BotObj * o = &bot_objs[hitn];
                    fprintf( stderr, "bot: DOOMED f=%d total=%d: best plan (vt %d/%d k=%d, then fallback %d) hits %s id=%d at t=%d: box %d,%d..%d,%d (now %d,%d..%d,%d) rect=%d rot=%d angle=%d da=%d | ship y=%d silhouette %d,%d..%d,%d\n",
                             bot_frame, best_surv, cand_vt1[best_ci], cand_vt2[best_ci], cand_k[best_ci], fallback_vt[c_fb[best_ci]], o->p->proc->name, o->id, tt,
                             bot_box[hitn][tt].x, bot_box[hitn][tt].y, bot_box[hitn][tt].x2, bot_box[hitn][tt].y2,
                             o->b0.x, o->b0.y, o->b0.x2, o->b0.y2, o->rect, o->rotating, o->angle, o->da, y, sb.x, sb.y, sb.x2, sb.y2 );
                    break;
                }
            }
        }

        if ( bot_dbg && best_ci >= 0 && getenv( "SF3500_BOT_TRACE" ) && abs( bot_frame - atoi( getenv( "SF3500_BOT_TRACE" ) ) ) <= 1 )
        {
            int y = sy, vy = svy, tt;
            fprintf( stderr, "bot: TRACE f=%d best plan vt %d/%d k=%d fallback %d, ship y=%d vy=%d, %d objects\n", bot_frame, cand_vt1[best_ci], cand_vt2[best_ci], cand_k[best_ci], fallback_vt[c_fb[best_ci]], sy, svy, bot_nobj );
            {
                int q;
                for ( q = 0; q < bot_nobj; q++ )
                    fprintf( stderr, "bot:   obj %d %s%s kind=%d x=%d y=%d dx=%d dy=%d rect=%d solid=%d now %d,%d..%d,%d  t1 %d,%d..%d,%d  t14 %d,%d..%d,%d\n", q, bot_objs[q].p->proc->name,
                             bot_objs[q].ghost ? "(ghost)" : "", bot_objs[q].kind, bot_objs[q].x, bot_objs[q].y, bot_objs[q].dx, bot_objs[q].dy, bot_objs[q].rect, bot_objs[q].solid,
                             bot_objs[q].b0.x, bot_objs[q].b0.y, bot_objs[q].b0.x2, bot_objs[q].b0.y2, bot_box[q][1].x, bot_box[q][1].y, bot_box[q][1].x2, bot_box[q][1].y2,
                             bot_box[q][14].x, bot_box[q][14].y, bot_box[q][14].x2, bot_box[q][14].y2 );
            }
            for ( tt = 1; tt <= 14; tt++ )
            {
                int z, xk, vt = ( tt > H ) ? fallback_vt[c_fb[best_ci]] : ( ( tt <= cand_k[best_ci] ) ? cand_vt1[best_ci] : cand_vt2[best_ci] ), n;
                REGION sb;
                bot_keys_for( vy, vt, anti, rev, &z, &xk );
                bot_flight( &y, &vy, z, xk, anti, rev );
                bot_sil_at( bot_vg, y - sy, &sb );
                fprintf( stderr, "bot:   t=%d y=%d vy=%d sprite=%d sil=%d,%d..%d,%d active=%d:", tt, y, vy, bot_sprite_index( bot_vg ), sb.x, sb.y, sb.x2, sb.y2, bot_nact[tt] );
                for ( n = 0; n < bot_nact[tt]; n++ )
                {
                    int oi = bot_act[tt][n];
                    fprintf( stderr, " [%s%s box %d,%d..%d,%d ovl=%d touch=%d]", bot_objs[oi].p->proc->name, bot_objs[oi].ghost ? "(ghost)" : "", bot_box[oi][tt].x, bot_box[oi][tt].y, bot_box[oi][tt].x2, bot_box[oi][tt].y2,
                             bot_ovl( &sb, &bot_box[oi][tt], 0 ), bot_touch( ship, sgr, &sb, &bot_objs[oi], oi, tt, y ) );
                }
                fprintf( stderr, "\n" );
            }
        }

        /* a slip: sometimes the weaker pilots press the wrong key */
        if ( L->err_pct && ( int )( bot_rand() % 100 ) < L->err_pct ) { best_z = !best_z; }

        bot_last_z = best_z;
        bot_last_x = best_x;
        if ( bot_dbg )
        {
            BotRec * r = &bot_ring[bot_ring_n % 24];
            char * w = bot_near; int left = ( int ) sizeof( bot_near ), n;
            r->f = bot_frame; r->y = sy; r->vy = svy; r->z = best_z; r->x = best_x; r->surv = best_surv; bot_ring_n++;
            w[0] = 0;
            for ( i = 0; i < bot_nobj && left > 60; i++ )
            {
                BotObj * o = &bot_objs[i];
                if ( o->kind == BK_NONE ) continue;
                if ( o->kind != BK_HAZ && o->kind != BK_FIRE && o->b0.x2 < sx - 10 ) continue;
                if ( o->b0.x2 < sx - 40 || o->b0.x > sx + 200 ) continue;
                n = snprintf( w, left, "[%s id=%d box=%d,%d..%d,%d d=%d,%d,%d] ", bot_kind_name( o->p->proc->name ),
                              o->id, o->b0.x, o->b0.y, o->b0.x2, o->b0.y2, o->dx, o->dy, o->da );
                if ( n > 0 ) { w += n; left -= n; }
            }
        }
        *out_z = best_z;
        *out_x = best_x;

        if ( bot_dbg && getenv( "SF3500_BOT_VALIDATE" ) )
        {
            /* compare the mask test with the engine's pixel test, for the ship's current sprite at many heights,
             * hazards as they are now (t = 0). "bad" = the engine says hit but the mask test says clear. */
            static long n_all[2] = { 0, 0 }, bad_all[2] = { 0, 0 }, cons_all[2] = { 0, 0 }, ticks = 0;
            int k = ( int ) sgr->code - 77;
            if ( k >= 0 && k < 9 )
            {
                for ( i = 0; i < bot_nobj; i++ )
                {
                    BotObj * o = &bot_objs[i];
                    int d, cls = o->rotating ? 1 : 0;
                    if ( o->kind != BK_HAZ ) continue;
                    for ( d = -60; d <= 60; d += 3 )
                    {
                        int sy0 = LOCINT32( mod_grproc, ship, COORDY ), eng, mine;
                        REGION sbx;
                        LOCINT32( mod_grproc, ship, COORDY ) = sy + d;
                        instance_get_bbox( ship, sgr, &sbx );
                        eng = check_collision( ship, sgr, &sbx, o->p ) ? 1 : 0;
                        LOCINT32( mod_grproc, ship, COORDY ) = sy0;
                        mine = bot_mask_hit_k( o, 0, k, d );
                        n_all[cls]++; if ( eng && !mine ) bad_all[cls]++; if ( mine && !eng ) cons_all[cls]++;
                        if ( eng && !mine )
                        {
                            static int shown = 0;
                            if ( shown++ < 8 )
                                fprintf( stderr, "bot: VALIDATE-BAD %s id=%d angle=%d x=%d y=%d w=%d h=%d box=%d,%d..%d,%d ship sprite=%d dy=%d ship box %d,%d..%d,%d\n", o->p->proc->name, o->id, o->angle,
                                         o->x, o->y, bot_analyse( o->gr )->w, bot_analyse( o->gr )->h, o->b0.x, o->b0.y, o->b0.x2, o->b0.y2, k, d, sbx.x, sbx.y, sbx.x2, sbx.y2 );
                        }
                    }
                }
            }
            if ( ++ticks % 20 == 0 )
                fprintf( stderr, "bot: VALIDATE mask test: fixed n=%ld bad=%ld conservative=%ld | rotating n=%ld bad=%ld conservative=%ld\n",
                         n_all[0], bad_all[0], cons_all[0], n_all[1], bad_all[1], cons_all[1] );
        }
        if ( bot_dbg )
        {
            /* shadow check: what the game itself will test on its next frame (ship moved, hazards not yet) */
            int y1 = sy, vy1 = svy;
            bot_flight( &y1, &vy1, best_z, best_x, anti, rev );
            {
                /* every running process, whatever its kind, against the ship at its next position */
                INSTANCE * q;
                for ( q = first_instance; q; q = q->next )
                {
                    int st, hitq, sy0q;
                    REGION sbq;
                    if ( q == ship || !q->proc ) continue;
                    st = LOCDWORD( mod_grproc, q, STATUS ) & ~STATUS_WAITING_MASK;
                    if ( st != STATUS_RUNNING && st != STATUS_FROZEN ) continue;
                    if ( !instance_graph( q ) ) continue;
                    sy0q = LOCINT32( mod_grproc, ship, COORDY );
                    LOCINT32( mod_grproc, ship, COORDY ) = y1;
                    instance_get_bbox( ship, sgr, &sbq );
                    hitq = ( LOCDWORD( mod_grproc, ship, CTYPE ) == LOCDWORD( mod_grproc, q, CTYPE ) ) && check_collision( ship, sgr, &sbq, q );
                    LOCINT32( mod_grproc, ship, COORDY ) = sy0q;
                    if ( hitq && bot_kind[q->proc->type] == BK_NONE )
                        fprintf( stderr, "bot: SHADOW OTHER f=%d process %s touches the ship at y1=%d\n", bot_frame, q->proc->name, y1 );
                }
            }
            for ( i = 0; i < bot_nobj; i++ )
            {
                BotObj * o = &bot_objs[i];
                int sy0, hit;
                REGION sbx;
                if ( !( o->kind == BK_HAZ || ( o->kind == BK_FIRE && !shield ) ) ) continue;
                sy0 = LOCINT32( mod_grproc, ship, COORDY );
                LOCINT32( mod_grproc, ship, COORDY ) = y1;
                instance_get_bbox( ship, sgr, &sbx );
                hit = check_collision( ship, sgr, &sbx, o->p ) ? 1 : 0;
                LOCINT32( mod_grproc, ship, COORDY ) = sy0;
                {
                    /* the same test with the hazard already moved one step (if the game updates it first) */
                    int hit1, ox0 = LOCINT32( mod_grproc, o->p, COORDX ), oy0 = LOCINT32( mod_grproc, o->p, COORDY ), oa0 = LOCINT32( mod_grproc, o->p, ANGLE );
                    LOCINT32( mod_grproc, ship, COORDY ) = y1;
                    LOCINT32( mod_grproc, o->p, COORDX ) = o->x + o->dx;
                    LOCINT32( mod_grproc, o->p, COORDY ) = bot_y_at( o, 1 );
                    LOCINT32( mod_grproc, o->p, ANGLE )  = o->angle + o->da;
                    instance_get_bbox( ship, sgr, &sbx );
                    hit1 = check_collision( ship, sgr, &sbx, o->p ) ? 1 : 0;
                    LOCINT32( mod_grproc, ship, COORDY ) = sy0;
                    LOCINT32( mod_grproc, o->p, COORDX ) = ox0;
                    LOCINT32( mod_grproc, o->p, COORDY ) = oy0;
                    LOCINT32( mod_grproc, o->p, ANGLE )  = oa0;
                    if ( hit1 && !hit )
                    {
                        int kold = ( int ) sgr->code - 77, knew, mine_old = -1, mine_new = -1, dy1 = y1 - sy;
                        { int ty = sy, tv = svy; bot_flight( &ty, &tv, best_z, best_x, anti, rev ); knew = bot_sprite_index( bot_vg ); }
                        if ( kold >= 0 && kold < 9 ) mine_old = bot_mask_hit_k( o, 1, kold, dy1 );
                        mine_new = bot_mask_hit_k( o, 1, knew, dy1 );
                        {
                            REGION sbp;
                            int ov, sat, k2;
                            bot_sil_at( bot_vg, dy1, &sbp );
                            ov = bot_ovl( &sbp, &bot_box[i][1], 0 );
                            sat = bot_sat( &bot_quad[i][1], &sbp );
                            k2 = bot_sprite_index( bot_vg );
                            fprintf( stderr, "bot:   stages for t=1: sprite=%d sil=%d,%d..%d,%d box1=%d,%d..%d,%d overlap=%d sat=%d quad=(%d,%d)(%d,%d)(%d,%d)(%d,%d) touch=%d bot_vg=%d\n",
                                     k2, sbp.x, sbp.y, sbp.x2, sbp.y2, bot_box[i][1].x, bot_box[i][1].y, bot_box[i][1].x2, bot_box[i][1].y2, ov, sat,
                                     bot_quad[i][1].x[0], bot_quad[i][1].y[0], bot_quad[i][1].x[1], bot_quad[i][1].y[1], bot_quad[i][1].x[2], bot_quad[i][1].y[2], bot_quad[i][1].x[3], bot_quad[i][1].y[3],
                                     bot_touch( ship, sgr, &sbp, o, i, 1, y1 ), bot_vg );
                        }
                        fprintf( stderr, "bot: SHADOW HIT1 f=%d with %s id=%d box=%d,%d..%d,%d plan surv=%d | engine(old sprite %d)=hit, my mask test old-sprite=%d new-sprite(%d)=%d angle=%d da=%d rect=%d rot=%d\n",
                                 bot_frame, o->p->proc->name, o->id, o->b0.x, o->b0.y, o->b0.x2, o->b0.y2, best_surv, kold, mine_old, knew,
                                 mine_new, o->angle, o->da, o->rect, o->rotating );
                    }
                }
                {
                    /* how close was it: which neighbouring heights would touch this object (current positions) */
                    int d, mask = 0;
                    for ( d = -8; d <= 8; d++ )
                    {
                        if ( d == 0 ) continue;
                        LOCINT32( mod_grproc, ship, COORDY ) = y1 + d;
                        instance_get_bbox( ship, sgr, &sbx );
                        if ( check_collision( ship, sgr, &sbx, o->p ) ) mask |= 1 << ( d + 8 );
                        LOCINT32( mod_grproc, ship, COORDY ) = sy0;
                    }
                    if ( mask && !hit )
                        fprintf( stderr, "bot: NEAR f=%d %s id=%d box=%d,%d..%d,%d would touch at dy mask=%x (bit8=0) y1=%d\n", bot_frame, o->p->proc->name, o->id,
                                 o->b0.x, o->b0.y, o->b0.x2, o->b0.y2, mask, y1 );
                }
                if ( hit )
                    fprintf( stderr, "bot: SHADOW HIT f=%d with %s id=%d box=%d,%d..%d,%d angle=%d da=%d solid=%d rot=%d ship y1=%d silhouette-y=%d..%d plan surv=%d\n",
                             bot_frame, o->p->proc->name, o->id, o->b0.x, o->b0.y, o->b0.x2, o->b0.y2, o->angle, o->da, o->solid, o->rotating,
                             y1, st0.y + ( y1 - sy ), st0.y2 + ( y1 - sy ), best_surv );
            }
        }
        if ( bot_dbg )
        {
            unsigned dt = plan_us;
            if ( dt > bot_dbg_worst_us ) bot_dbg_worst_us = dt;
            bot_dbg_sum_us += dt;
            bot_dbg_plans++;
            if ( bot_frame - bot_last_print >= ( getenv( "SF3500_BOT_DEBUG_EVERY" ) ? atoi( getenv( "SF3500_BOT_DEBUG_EVERY" ) ) : 25 ) )
            {
                bot_last_print = bot_frame;
                fprintf( stderr, "bot:   near: %s\n", bot_near );
                fprintf( stderr, "bot:   ship box %d,%d..%d,%d silhouette %d,%d..%d,%d graph %ux%u depthb=%d\n", sb0.x, sb0.y, sb0.x2, sb0.y2, st0.x, st0.y, st0.x2, st0.y2, ( unsigned ) sgr->width, ( unsigned ) sgr->height, ( int ) sgr->format->depthb );
                fprintf( stderr, "bot: f=%d y=%d vy=%d anti=%d rev=%d shield=%d objs=%d target=%d surv=%d/%d keys z=%d x=%d "
                                 "score=%d worst_plan=%uus avg_plan=%luus pix=%d\n",
                         bot_frame, sy, svy, anti, rev, shield, bot_nobj, target_y, best_surv, H,
                         best_z, best_x, bot_o_score >= 0 ? ( int ) BOT_GLO( bot_o_score ) : -1,
                         bot_dbg_worst_us, bot_dbg_plans ? bot_dbg_sum_us / bot_dbg_plans : 0, bot_pix_used );
                bot_dbg_worst_us = 0; bot_dbg_sum_us = 0; bot_dbg_plans = 0;
            }
        }
    }
    return 1;
}
