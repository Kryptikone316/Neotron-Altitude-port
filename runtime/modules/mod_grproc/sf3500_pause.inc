/* SPDX-License-Identifier: Unlicense */
/* ---------------------------------------------------------------------------
 * Pause (a mod: the game has none, and its files are not touched).
 *
 * Start pauses a level that is being flown, and Start again resumes. This file answers one question for the input
 * hook in libsdlhandler.c: "is a ship flying right now?" That is true when Player 1's process is running, the game
 * says Player 1 is alive, and no Message process (the level-complete and game-over banners, which wait for
 * Start) exists. The ship must also have been flying for a few frames, so the Start press that confirmed the menu
 * cannot pause the level it just started.
 *
 * Included at the end of mod_grproc.c after the computer opponent, whose helpers find processes and variables by name.
 * ------------------------------------------------------------------------- */

int sf3500_pause_allowed( void )
{
    static int ready = 0, t_p1 = -1, t_msg = -1, o_alive = -1, flying = 0;
    INSTANCE * ptr;
    int have_p1 = 0, have_msg = 0;
    if ( !ready )
    {
        PROCDEF * pd;
        ready = 1;
        if ( ( pd = procdef_get_by_name( ( char * ) "PLAYER1" ) ) != NULL ) t_p1 = pd->type;
        if ( ( pd = procdef_get_by_name( ( char * ) "MESSAGE" ) ) != NULL ) t_msg = pd->type;
        o_alive = bot_global_offset( "PLAYER1ALIVE" );
    }
    if ( t_p1 < 0 ) return 0;                      /* a program without a Player1 (the launcher) */
    for ( ptr = first_instance; ptr; ptr = ptr->next )
    {
        int status;
        if ( !ptr->proc ) continue;
        if ( ptr->proc->type != t_p1 && ptr->proc->type != t_msg ) continue;
        status = LOCDWORD( mod_grproc, ptr, STATUS ) & ~STATUS_WAITING_MASK;
        if ( status != STATUS_RUNNING && status != STATUS_FROZEN ) continue;
        if ( ptr->proc->type == t_p1 ) have_p1 = 1; else have_msg = 1;
    }
    if ( have_p1 && o_alive >= 0 && globaldata && BOT_GLO( o_alive ) == 0 ) have_p1 = 0;
    flying = ( have_p1 && !have_msg ) ? flying + 1 : 0;
    return flying > 12;
}
