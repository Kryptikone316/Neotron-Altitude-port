/* SPDX-License-Identifier: Unlicense */
/* ---------------------------------------------------------------------------
 * The player's own best score (a mod: the game's files are not touched).
 *
 * The game keeps one high score, in score.dat, and only ever replaces it with a higher one. It ships with the
 * author's own score, which is very hard to beat, so a player's progress below it would never be recorded.
 * This tracker follows Player 1's score (the human; Player 2 may be the computer opponent) and keeps the best
 * one seen in score-player.dat, in the same format as score.dat (one 32-bit little-endian integer). The launcher
 * shows it next to the author's score and can reset it.
 *
 * Included at the end of mod_grproc.c after the computer opponent, whose helpers find the game's variables by
 * name. It does nothing in a program without a variable called Player1Score (the launcher, say).
 * ------------------------------------------------------------------------- */

#define SCORE_FILE "score-player.dat"

static int score_off = -2;             /* -2: not looked up yet, -1: this program has no Player1Score */
static int score_best = 0, score_pending = 0, score_frames = 0, score_lastwrite = 0;

static void score_write( void )
{
    FILE * f = fopen( SCORE_FILE, "wb" );
    if ( f )
    {
        unsigned char b[4];
        b[0] = ( unsigned char ) ( score_best & 255 );         b[1] = ( unsigned char ) ( ( score_best >> 8 ) & 255 );
        b[2] = ( unsigned char ) ( ( score_best >> 16 ) & 255 ); b[3] = ( unsigned char ) ( ( score_best >> 24 ) & 255 );
        fwrite( b, 1, 4, f );
        fclose( f );
        fprintf( stderr, "score: your best is now %d\n", score_best );
    }
    score_pending = 0;
    score_lastwrite = score_frames;
}

/* Writes a pending best score at once (the game is about to exit). */
void sf3500_score_flush( void )
{
    if ( score_pending ) score_write();
}

/* Called every frame. The best score is written at most about every two seconds, and on exit. */
void sf3500_score_tick( void )
{
    int s;
    if ( score_off == -2 )
    {
        FILE * f;
        score_off = bot_global_offset( "PLAYER1SCORE" );
        f = fopen( SCORE_FILE, "rb" );
        if ( f )
        {
            unsigned char b[4];
            if ( fread( b, 1, 4, f ) == 4 ) score_best = ( int ) ( b[0] | ( b[1] << 8 ) | ( b[2] << 16 ) | ( b[3] << 24 ) );
            fclose( f );
        }
    }
    if ( score_off < 0 || !globaldata ) return;
    s = ( int ) BOT_GLO( score_off );
    if ( s > score_best ) { score_best = s; score_pending = 1; }
    score_frames++;
    if ( score_pending && score_frames - score_lastwrite >= 50 ) score_write();
}
