# ============================================================
# Loop principal do jogo
# ============================================================

.text

game_loop:
loop_frame:
    la t0, frame_counter
    lw t1, 0(t0)
    addi t1, t1, 1
    sw t1, 0(t0)

    call update_music

    la t0, game_state
    lw t1, 0(t0)

    li t2, STATE_MENU
    beq t1, t2, loop_menu

    li t2, STATE_LEVEL1
    beq t1, t2, loop_playing_level

    li t2, STATE_LEVEL2
    beq t1, t2, loop_playing_level

    li t2, STATE_LEVEL3
    beq t1, t2, loop_playing_level

    li t2, STATE_BOSS
    beq t1, t2, loop_playing_level

    li t2, STATE_GAME_OVER
    beq t1, t2, loop_game_over

    li t2, STATE_VICTORY
    beq t1, t2, loop_victory

    j loop_frame

loop_menu:
    call read_input
    call update_menu

    la t0, game_state
    lw t1, 0(t0)
    li t2, STATE_MENU
    bne t1, t2, loop_static_finish

    la t0, screen_dirty
    lw t1, 0(t0)
    beqz t1, loop_static_finish
    call begin_frame
    call draw_menu_screen
    call end_frame
    la t0, screen_dirty
    sw zero, 0(t0)

loop_static_finish:
    call clear_input_frame
    call frame_delay
    j loop_frame

loop_playing_level:
    call read_input
    call update_debug_cheats

    call update_player
    call update_bullets
    call update_enemy_bullets

    call spawn_wave_if_needed
    call update_enemies
    call update_boss
    call stop_if_terminal_state
    bnez a0, finish_playing_frame

    call update_powerups
    call update_inventory

    call check_bullet_enemy_collisions
    call check_bullet_boss_collisions
    call stop_if_terminal_state
    bnez a0, finish_playing_frame
    call check_enemy_player_collisions
    call stop_if_terminal_state
    bnez a0, finish_playing_frame
    call check_enemy_bullet_player_collisions
    call stop_if_terminal_state
    bnez a0, finish_playing_frame
    call check_player_powerup_collisions

    call advance_wave
    call update_animation_frame

    call begin_frame

    call draw_background
    call draw_enemies
    call draw_boss_square
    call draw_bullets
    call draw_enemy_bullets
    call draw_powerups
    call draw_player_square
    call draw_hud
    call draw_inventory

    call end_frame

finish_playing_frame:
    call clear_input_frame
    call frame_delay

    j loop_frame

loop_game_over:
    call read_input
    call update_game_over

    la t0, game_state
    lw t1, 0(t0)
    li t2, STATE_GAME_OVER
    bne t1, t2, loop_game_over_finish

    la t0, screen_dirty
    lw t1, 0(t0)
    beqz t1, loop_game_over_finish
    call begin_frame
    call draw_game_over_screen
    call end_frame
    la t0, screen_dirty
    sw zero, 0(t0)

loop_game_over_finish:
    call clear_input_frame
    call frame_delay
    j loop_frame

loop_victory:
    call read_input
    call update_victory

    la t0, game_state
    lw t1, 0(t0)
    li t2, STATE_VICTORY
    bne t1, t2, loop_victory_finish

    la t0, screen_dirty
    lw t1, 0(t0)
    beqz t1, loop_victory_finish
    call begin_frame
    call draw_victory_screen
    call end_frame
    la t0, screen_dirty
    sw zero, 0(t0)

loop_victory_finish:
    call clear_input_frame
    call frame_delay
    j loop_frame

# a0 = 1 quando o frame de gameplay deve terminar sem renderizar.
stop_if_terminal_state:
    la t0, game_state
    lw t1, 0(t0)
    li t2, STATE_GAME_OVER
    beq t1, t2, terminal_state_found
    li t2, STATE_VICTORY
    beq t1, t2, terminal_state_found
    li a0, 0
    ret
terminal_state_found:
    li a0, 1
    ret

frame_delay:
    li a0, DEBUG_FRAME_DELAY_MS
    li a7, 132
    ecall
    ret

debug_stop_after_frames:
    la t0, frame_counter
    lw t1, 0(t0)

    li t2, DEBUG_LOOP_FRAMES
    blt t1, t2, end_debug_stop_after_frames

    li a7, 10
    ecall

end_debug_stop_after_frames:
    ret

debug_draw_core_state:
    j draw_hud
