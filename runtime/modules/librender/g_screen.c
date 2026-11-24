/*
 *  Copyright © 2006-2012 SplinterGU (Fenix/Bennugd)
 *  Copyright © 2002-2006 Fenix Team (Fenix)
 *  Copyright © 1999-2002 José Luis Cebrián Pagüe (Fenix)
 *
 *  This file is part of Bennu - Game Development
 *
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, subject to the following restrictions:
 *
 *     1. The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *
 *     2. Altered source versions must be plainly marked as such, and must not be
 *     misrepresented as being the original software.
 *
 *     3. This notice may not be removed or altered from any source
 *     distribution.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include "hwdisp.h"

#define __LIB_RENDER
#include "librender.h"

/* --------------------------------------------------------------------------- */

static GRAPH * scrbitmap_extra = NULL ;

static int updaterects_count = 0;
static REGION updaterects[ DIRTYCOLS * DIRTYROWS ];
static SDL_Rect rects[ DIRTYCOLS * DIRTYROWS ];

/* --------------------------------------------------------------------------- */
/*
 *  FUNCTION : gr_draw_screen
 *
 *  Draw the current screen, using the given restore_type / dump_type parameters
 *
 *  PARAMS :
 *      dest            Destination graphic (MUST have a correct size)
 *
 *      restore_type
 *          -1          No background restore
 *           0          Partial (old process bounding box) background restore
 *           1          Full background restore
 *
 *      dump_type
 *           0          Partial (new process bounding box) drawing
 *           1          Full drawing
 *
 *  RETURN VALUE :
 *      None
 */

void gr_draw_screen( GRAPH * dest, int restore_type, int dump_type )
{
    int a ;
    GRAPH * orig_scrbitmap = scrbitmap;

    scrbitmap = dest ;

    if ( background && background->modified )
    {
        restore_type = 1;
        dump_type = 1;
    }

    /* Update the object list */
    gr_update_objects_mark_rects( restore_type, dump_type );

    /* Restore the background */
    if ( !dump_type || !restore_type )
    {
        updaterects_count = gr_mark_rects( updaterects );
    }
    else
    {
        updaterects_count = 1;
        updaterects[ 0 ].x = 0;
        updaterects[ 0 ].y = 0;
        updaterects[ 0 ].x2 = scr_width - 1;
        updaterects[ 0 ].y2 = scr_height - 1;
    }

    if ( !restore_type )
    {
        /* PARTIAL_RESTORE */
        if ( background->info_flags & GI_CLEAN )
        {
            for ( a = 0; a < updaterects_count; a++ )
                gr_clear_region( scrbitmap, &updaterects[ a ] );
        }
        else
        {
            for ( a = 0; a < updaterects_count; a++ )
                gr_blit( scrbitmap, &updaterects[ a ], 0, 0, B_NOCOLORKEY, background );
        }
    }
    else if ( restore_type == 1 )
    {
        /* COMPLETE_RESTORE */
        if ( background->info_flags & GI_CLEAN )
            gr_clear( scrbitmap ) ;
        else
            gr_blit( scrbitmap, NULL, 0, 0, B_NOCOLORKEY, background );

        updaterects_count = 1;
        updaterects[ 0 ].x = 0;
        updaterects[ 0 ].y = 0;
        updaterects[ 0 ].x2 = scr_width - 1;
        updaterects[ 0 ].y2 = scr_height - 1;
    }

    /* Dump the objects */
    if ( dump_type == 0 )
    {
        /* Dump only changed & enabled objects */
        gr_draw_objects( updaterects, updaterects_count );
    }
    else
    {
        /* Dump everything */
        gr_draw_objects_complete();
    }

    /* Reset the zone-to-update array for the next frame */
    gr_rects_clear();

    if ( background && background->modified ) background->modified = 0;
    if ( scrbitmap && scrbitmap->modified ) scrbitmap->modified = 0;

    scrbitmap = orig_scrbitmap;
}

/* --------------------------------------------------------------------------- */

/* Debug aid: when SF3500_SHOT_PREFIX is set, a frame is written as <prefix>_NNN.ppm each time the
 * file <prefix>.trigger exists (the trigger is deleted afterwards). Used to check layouts without a
 * device; does nothing and costs nothing when the variable is not set. */
static void sf3500_dump_if_requested( const unsigned short * src, int w, int h, int pitch )
{
    static int inited = 0, n = 0;
    static const char * prefix = NULL;
    char trig[600], name[600];
    FILE * f;
    int x, y;

    if ( !inited ) { inited = 1; prefix = getenv( "SF3500_SHOT_PREFIX" ); }
    if ( !prefix ) return;
    snprintf( trig, sizeof( trig ), "%s.trigger", prefix );
    if ( access( trig, F_OK ) != 0 ) return;
    unlink( trig );
    snprintf( name, sizeof( name ), "%s_%03d.ppm", prefix, n++ );
    f = fopen( name, "wb" );
    if ( !f ) return;
    fprintf( f, "P6\n%d %d\n255\n", w, h );
    for ( y = 0; y < h; y++ )
    {
        const unsigned short * row = ( const unsigned short * )( ( const char * ) src + y * pitch );
        for ( x = 0; x < w; x++ )
        {
            unsigned short p = row[x];
            fputc( ( ( p >> 11 ) & 31 ) * 255 / 31, f );
            fputc( ( ( p >> 5 ) & 63 ) * 255 / 63, f );
            fputc( ( p & 31 ) * 255 / 31, f );
        }
    }
    fclose( f );
}

static int screen_locked = 0 ;

/* SF3500 pause: the pause screen shows the engine's screen surface (it still holds the last frame while the game
 * stands still) dimmed, with a label on top. Nothing is recorded in the per-frame present path: adding even two
 * stores there made the computer opponent's planning about 30% slower under emulation. */
static int last_present_w = 0, last_present_h = 0;
static unsigned short * pause_buf = NULL;
static int pause_buf_pixels = 0;

/* 5x7 letters for the pause label (rows top to bottom, bit 4 is the left column) */
static const struct { char c; unsigned char r[7]; } pause_font[] = {
    { 'A', { 14, 17, 17, 31, 17, 17, 17 } }, { 'D', { 30, 17, 17, 17, 17, 17, 30 } },
    { 'E', { 31, 16, 16, 30, 16, 16, 31 } }, { 'M', { 17, 27, 21, 21, 17, 17, 17 } },
    { 'O', { 14, 17, 17, 17, 17, 17, 14 } }, { 'P', { 30, 17, 17, 30, 16, 16, 16 } },
    { 'R', { 30, 17, 17, 30, 20, 18, 17 } }, { 'S', { 15, 16, 16, 14, 1, 1, 30 } },
    { 'T', { 31, 4, 4, 4, 4, 4, 4 } },       { 'U', { 17, 17, 17, 17, 17, 17, 14 } },
    { 0, { 0 } }
};

static void pause_text( int cx, int y, int scale, const char * text, unsigned short colour )
{
    int len = ( int ) strlen( text ), x0 = cx - ( len * 6 * scale - scale ) / 2, i, r, c, k, dx, dy;
    for ( i = 0; i < len; i++ )
        for ( k = 0; pause_font[k].c; k++ )
            if ( pause_font[k].c == text[i] )
                for ( r = 0; r < 7; r++ )
                    for ( c = 0; c < 5; c++ )
                        if ( pause_font[k].r[r] & ( 16 >> c ) )
                            for ( dy = 0; dy < scale; dy++ )
                                for ( dx = 0; dx < scale; dx++ )
                                {
                                    int px = x0 + ( i * 6 + c ) * scale + dx, py = y + r * scale + dy;
                                    if ( px >= 0 && px < last_present_w && py >= 0 && py < last_present_h )
                                        pause_buf[py * last_present_w + px] = colour;
                                }
}

/* Shows the last frame dimmed with PAUSED over it. Called repeatedly while the game is stopped. */
void sf3500_present_paused( void )
{
    int w, h, x, y, s;
    if ( !screen || !screen->pixels ) return;
    w = last_present_w = screen->w;
    h = last_present_h = screen->h;
    if ( w * h > pause_buf_pixels )
    {
        free( pause_buf );
        pause_buf = ( unsigned short * ) malloc( w * h * sizeof( unsigned short ) );
        pause_buf_pixels = pause_buf ? w * h : 0;
    }
    if ( !pause_buf ) return;
    SDL_ConvertPixels( w, h, screen->format->format, screen->pixels, screen->pitch,
                       SDL_PIXELFORMAT_RGB565, pause_buf, w * 2 );
    for ( y = 0; y < h; y++ )
        for ( x = 0; x < w; x++ )
            pause_buf[y * w + x] = ( unsigned short ) ( ( pause_buf[y * w + x] >> 1 ) & 0x7BEF );   /* half as bright */
    s = w >= 300 ? 6 : 4;
    pause_text( w / 2 + s, h / 2 - 7 * s + s, s, "PAUSED", 0x0000 );                     /* shadow */
    pause_text( w / 2, h / 2 - 7 * s, s, "PAUSED", 0xFFE0 );
    s = w >= 300 ? 2 : 1;
    pause_text( w / 2, h / 2 + 10 * s, s, "PRESS START TO RESUME", 0xFFFF );
    sf3500_dump_if_requested( pause_buf, w, h, w * 2 );
    hwdisp_present( pause_buf, w, h, w * 2 );
}

/* SF3500 hw video output - converts whatever bpp the game script picked
 * into the RGB565 hwdisp_present() needs, growing the scratch buffer
 * lazily. Skips the conversion entirely when screen is already RGB565
 * (the common case for a 2D brawler), same shape as every other port, its
 * final hw-present hook. See DEV-NOTES.md. */
static unsigned short * hw_rgb565_buf = NULL;
static int hw_rgb565_buf_pixels = 0;

int gr_lock_screen()
{
    if ( screen_locked ) return 1 ;

    screen_locked = 1 ;

    if ( SDL_MUSTLOCK( screen ) ) SDL_LockSurface( screen ) ;

    if ( !scrbitmap || !( scrbitmap->info_flags & GI_EXTERNAL_DATA ) )
    {
        if ( scrbitmap ) bitmap_destroy( scrbitmap ) ;
        scrbitmap = bitmap_new_ex( 0, screen->w, screen->h, screen->format->BitsPerPixel, screen->pixels, screen->pitch );
        bitmap_add_cpoint( scrbitmap, 0, 0 ) ;
    }

    
    return 1 ;
}

/* --------------------------------------------------------------------------- */

void gr_unlock_screen()
{
    if ( !screen_locked || !screen->pixels ) return ;

    screen_locked = 0 ;
    
    // I removed the dirty rectangles code, for the time being
    if ( SDL_MUSTLOCK( screen ) ) SDL_UnlockSurface( screen ) ;
    if ( waitvsync ) gr_wait_vsync();
    if ( screen->format->format == SDL_PIXELFORMAT_RGB565 )
    {
        sf3500_dump_if_requested( screen->pixels, screen->w, screen->h, screen->pitch );
        hwdisp_present( screen->pixels, screen->w, screen->h, screen->pitch );
    }
    else
    {
        int needed_pixels = screen->w * screen->h;
        if ( needed_pixels > hw_rgb565_buf_pixels )
        {
            if ( hw_rgb565_buf ) free( hw_rgb565_buf );
            hw_rgb565_buf = (unsigned short *) malloc( needed_pixels * sizeof( unsigned short ) );
            hw_rgb565_buf_pixels = hw_rgb565_buf ? needed_pixels : 0;
        }
        if ( hw_rgb565_buf )
        {
            SDL_ConvertPixels( screen->w, screen->h,
                                screen->format->format, screen->pixels, screen->pitch,
                                SDL_PIXELFORMAT_RGB565, hw_rgb565_buf, screen->w * 2 );
            sf3500_dump_if_requested( hw_rgb565_buf, screen->w, screen->h, screen->w * 2 );
            hwdisp_present( hw_rgb565_buf, screen->w, screen->h, screen->w * 2 );
        }
    }
}

/* --------------------------------------------------------------------------- */
