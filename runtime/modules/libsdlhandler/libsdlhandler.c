/*
 *  Copyright © 2006-2012 SplinterGU (Fenix/Bennugd)
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

#include "bgddl.h"

#include <SDL.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>

#include "joykey.h"
#include "hwdisp.h"
#include "hwaudio.h"

/* SDL internal; the same call the SF3500 input bridge inside SDL makes. */
extern int SDL_SendKeyboardKey(Uint8 state, SDL_Scancode scancode);

/* Computer opponent for Altitude (modules/mod_grproc/sf3500_bot.inc). */
extern int sf3500_bot_tick( int level, int * z, int * x, int * alt );

/* The player's own best score (modules/mod_grproc/sf3500_score.inc). */
extern void sf3500_score_tick( void );
extern int  sf3500_pause_allowed( void );
extern void sf3500_present_paused( void );
extern void sf3500_resync_frame_clock( void );
extern void sf3500_audio_pause( int on );
extern void sf3500_score_flush( void );

/* SF3500_KEYSCRIPT="30:R,34:E,..." presses a key for three frames when the frame counter reaches
 * the number (L R U D = d-pad, E = Enter, Z X = letters). Only for headless tests. */
typedef struct { int frame; SDL_Scancode sc; } KeyStep;
static KeyStep ks_steps[128];
static int ks_count = -1;
static int ks_fake_start = 0;          /* a scripted Start press (code P), for testing the pause */

static void sf3500_keyscript( int frame )
{
    int i;
    if ( ks_count < 0 )
    {
        const char * e = getenv( "SF3500_KEYSCRIPT" );
        ks_count = 0;
        while ( e && *e && ks_count < 128 )
        {
            int f = 0; SDL_Scancode sc = SDL_SCANCODE_UNKNOWN;
            while ( *e >= '0' && *e <= '9' ) f = f * 10 + ( *e++ - '0' );
            if ( *e == ':' ) e++;
            switch ( *e )
            {
                case 'L': sc = SDL_SCANCODE_LEFT; break;
                case 'R': sc = SDL_SCANCODE_RIGHT; break;
                case 'U': sc = SDL_SCANCODE_UP; break;
                case 'D': sc = SDL_SCANCODE_DOWN; break;
                case 'E': sc = SDL_SCANCODE_RETURN; break;
                case 'Z': sc = SDL_SCANCODE_Z; break;
                case 'X': sc = SDL_SCANCODE_X; break;
                case 'P': sc = SDL_SCANCODE_F24; break;     /* not a key: a Start press */
                default: break;
            }
            if ( *e ) e++;
            if ( *e == ',' ) e++;
            if ( sc != SDL_SCANCODE_UNKNOWN ) { ks_steps[ks_count].frame = f; ks_steps[ks_count].sc = sc; ks_count++; }
        }
    }
    for ( i = 0; i < ks_count; i++ )
        if ( frame >= ks_steps[i].frame && frame < ks_steps[i].frame + 3 )
        {
            if ( ks_steps[i].sc == SDL_SCANCODE_F24 ) ks_fake_start = 1; else SDL_SendKeyboardKey( SDL_PRESSED, ks_steps[i].sc );
        }
}

/* Declared inside our own SDL2 build (src/events/sf3500/SDL_sf3500input.h)
 * but not part of SDL2's normal public install set - see dump_new_events()
 * below and DEV-NOTES.md for why this exists. */
extern unsigned int SF3500_PumpJoykeyKeyboard(void);

/* ----------------------------------------------------------------- */
/* Public functions                                                  */

/* Standing SF3500 exit combo (Select + Start), also honoured while paused. */
static void sf3500_quit_now( void )
{
    sf3500_score_flush();
    hwaudio_deinit();
    hwdisp_deinit();
    SDL_Quit();
    exit( 0 );
}

#define SF3500_START_DOWN( bits ) ( ( ( bits ) & ( 1u << JK_START ) ) != 0 )

/* Pause: the game stands still (this hook is called once per frame, so not returning stops it), the music
 * and sounds are held, and the last frame is shown dimmed with a label. Start resumes. The test hook
 * SF3500_PAUSE_TEST_ITERS=n resumes by itself after n polls, so a headless run can pause without a pad. */
static void sf3500_pause_loop( void )
{
    static int test_iters = -2;
    int start_was_down = 1, polls = 0;
    if ( test_iters == -2 ) { const char * e = getenv( "SF3500_PAUSE_TEST_ITERS" ); test_iters = e ? atoi( e ) : -1; }
    fprintf( stderr, "pause: on\n" );
    sf3500_audio_pause( 1 );
    for ( ;; )
    {
        unsigned int bits;
        if ( ( polls % 10 ) == 0 ) sf3500_present_paused();            /* now, and about twice a second after */
        SDL_Delay( 50 );
        polls++;
        bits = SF3500_PumpJoykeyKeyboard();
        if ( ( bits & ( 1u << JK_SELECT ) ) && SF3500_START_DOWN( bits ) ) sf3500_quit_now();
        if ( SF3500_START_DOWN( bits ) && !start_was_down ) break;
        start_was_down = SF3500_START_DOWN( bits );
        if ( test_iters >= 0 && polls >= test_iters ) break;
    }
    sf3500_audio_pause( 0 );
    sf3500_resync_frame_clock();
    fprintf( stderr, "pause: off\n" );
}

static void  dump_new_events()
{
    /* Remove all pendings events */

    /* We can't return -1, just return 0 (no event) on error */
    // We'll only discard events that no module knows how to handle here...
    // Otherwise some events seem to get discarded
//    SDL_FlushEvents(SDL_SYSWMEVENT, SDL_SYSWMEVENT);
//    SDL_FlushEvents(SDL_TEXTEDITING, SDL_TEXTINPUT);
//    SDL_FlushEvents(SDL_JOYDEVICEADDED, SDL_CONTROLLERDEVICEREMAPPED);
//    SDL_FlushEvents(SDL_DOLLARGESTURE, SDL_LASTEVENT);

    /* SF3500: periodic fsync + call-rate counter. A hard power-cut loses
     * anything still sitting in the filesystem's write-back cache even
     * with unbuffered stdio (write() succeeding isn't the same as the
     * bytes reaching the SD card) - confirmed this is why several
     * "device hang" logs came back completely empty despite the screen
     * visibly showing real content. Throttled to once/second by wall
     * clock, not every call, specifically because this hook may be
     * running in a tight busy-loop (the real suspect for the reported
     * CPU starvation - volume buttons still worked but "very very
     * slow") and an fsync every call would make that worse, not better.
     * The printed call count directly measures whether that's true.
     * See DEV-NOTES.md. */
    {
        static unsigned long call_count = 0;
        static time_t last_sync = 0;
        time_t now = time(NULL);
        call_count++;
        if (now != last_sync) {
            char dbg[96];
            int n = SDL_snprintf(dbg, sizeof(dbg),
                "dump_new_events: %lu calls in last ~%lds\n",
                call_count, (long)(last_sync ? (now - last_sync) : 0));
            write(2, dbg, n);

            /* SF3500: audio crackle diagnostic - tell overflow-drop apart
             * from underrun-insert instead of guessing which one is
             * producing the periodic warp/crackle reported in real
             * gameplay. See hwaudio.h's hwaudio_get_stats() comment and
             * DEV-NOTES.md. */
            {
                unsigned underruns, dropped, fill;
                hwaudio_get_stats(&underruns, &dropped, &fill);
                n = SDL_snprintf(dbg, sizeof(dbg),
                    "hwaudio: underruns=%u dropped=%u fill=%u\n",
                    underruns, dropped, fill);
                write(2, dbg, n);
            }

            fsync(2);
            call_count = 0;
            last_sync = now;
        }
    }

    /* Get new events */
    {
        unsigned int jk_bits = SF3500_PumpJoykeyKeyboard();
        /* Optional per-game button remap (SF3500_PADMAP=altitude). Altitude is a
         * one-player game on a one-player device: gameplay only reads Up, Down and Right
         * (Enter is used by menus and message screens only), so A can be both "fly up"
         * and "confirm", B is the thruster and Y is the anti-gravity down. The d-pad and
         * Start keep their normal arrow/Enter keys from the SDL bridge. */
        {
            static int padmap = -1;
            if (padmap < 0) {
                const char *e = getenv("SF3500_PADMAP");
                padmap = !e ? 0 : (strcmp(e, "altitude") == 0) ? 1 : (strcmp(e, "launcher") == 0) ? 2 : 0;
            }
            if (padmap == 2) {
                /* Launcher menus: A confirms, B goes back. */
                if (jk_bits & (1u << JK_A)) SDL_SendKeyboardKey(SDL_PRESSED, SDL_SCANCODE_RETURN);
                if (jk_bits & (1u << JK_B)) SDL_SendKeyboardKey(SDL_PRESSED, SDL_SCANCODE_ESCAPE);
            } else if (padmap) {
                if (jk_bits & (1u << JK_A)) {
                    SDL_SendKeyboardKey(SDL_PRESSED, SDL_SCANCODE_UP);
                    SDL_SendKeyboardKey(SDL_PRESSED, SDL_SCANCODE_RETURN);
                }
                if (jk_bits & (1u << JK_B)) SDL_SendKeyboardKey(SDL_PRESSED, SDL_SCANCODE_RIGHT);
                if (jk_bits & (1u << JK_Y)) SDL_SendKeyboardKey(SDL_PRESSED, SDL_SCANCODE_DOWN);
            }
        }
        /* Computer opponent (SF3500_BOT=easy|normal|hard): presses Player 2's Z / X keys. */
        {
            static int bot_level = -1;
            static int bot_was_active = 0;
            static int hook_frame = 0;
            int bz = 0, bx = 0, balt = 0, active;
            if ( bot_level < 0 )
            {
                const char * e = getenv( "SF3500_BOT" );
                bot_level = !e ? 0 : !strcmp( e, "easy" ) ? 1 : !strcmp( e, "normal" ) ? 2 : !strcmp( e, "hard" ) ? 3 : 0;
            }
            static int start_was_down = 0;
            int start_now, can_pause;
            hook_frame++;
            sf3500_score_tick();
            ks_fake_start = 0;
            sf3500_keyscript( hook_frame );
            start_now = SF3500_START_DOWN( jk_bits ) || ks_fake_start;
            can_pause = sf3500_pause_allowed();                /* every frame: it counts how long a ship has been flying */
            if ( start_now && !start_was_down && !( jk_bits & ( 1u << JK_SELECT ) ) && can_pause )
                sf3500_pause_loop();
            start_was_down = start_now;
            if ( bot_level > 0 )
            {
                active = sf3500_bot_tick( bot_level, &bz, &bx, &balt );
                if ( active || bot_was_active )
                {
                    SDL_SendKeyboardKey( bz ? SDL_PRESSED : SDL_RELEASED, SDL_SCANCODE_Z );
                    SDL_SendKeyboardKey( bx ? SDL_PRESSED : SDL_RELEASED, SDL_SCANCODE_X );
                    SDL_SendKeyboardKey( balt ? SDL_PRESSED : SDL_RELEASED, SDL_SCANCODE_LALT );
                }
                bot_was_active = active;
            }
        }
        /* Standing SF3500 exit combo - never trust a game's own in-built
         * quit path on this device (see DEV-NOTES.md: another game's own quit menu hung on real
         * hardware, needed a power-cycle). Audio now goes through
         * Mix_SetPostMix() -> hwaudio_write() directly (not the SDL2
         * device layer, see mod_sound.c), so hwaudio_deinit() needs an
         * explicit call here too - SDL_Quit() no longer reaches it via
         * CloseDevice since the dummy driver is forced. */
        if ((jk_bits & (1u << JK_SELECT)) && (jk_bits & (1u << JK_START))) sf3500_quit_now();
    }
    SDL_PumpEvents();
    SDL_JoystickUpdate();
}

/* ----------------------------------------------------------------- */
/* Funciones de inicializacion del modulo/plugin                     */

void __bgdexport( libsdlhandler, module_initialize )()
{
}

/* ----------------------------------------------------------------- */

void __bgdexport( libsdlhandler, module_finalize )()
{
    /* Normal exits (a script's exit(), end of program) must release the audio hardware too:
     * the launcher hands over to the game as a second process right after this one ends.
     * Safe to call when audio was never started or is already stopped. */
    sf3500_score_flush();
    hwaudio_deinit();
}

/* ----------------------------------------------------------------- */

/* Bigest priority first execute
   Lowest priority last execute */

HOOK __bgdexport( libsdlhandler, handler_hooks )[] =
{
    { 5000, dump_new_events                   },
    {    0, NULL                              }
} ;

/* ----------------------------------------------------------------- */
