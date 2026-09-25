# ============================================================
# Trilha sonora do menu
# ============================================================

.text

reset_menu_music:
    la t0, menu_music_index
    sw zero, 0(t0)

    la t0, menu_music_next_time
    sw zero, 0(t0)

    la t0, menu_drone_index
    sw zero, 0(t0)

    la t0, menu_drone_next_time
    sw zero, 0(t0)

    ret

# Em MIDI, NOTE_ON com volume zero funciona como NOTE_OFF. Todos os pitches da
# trilha sao silenciados para impedir que o drone continue nas cutscenes/fases.
stop_menu_music:
    la t0, menu_music_stop_pitches
    li t1, MENU_MUSIC_STOP_PITCH_COUNT

stop_menu_music_loop:
    lbu a0, 0(t0)
    li a1, 1
    li a2, MENU_MUSIC_INSTRUMENT
    li a3, 0
    li a7, 31
    ecall

    addi t0, t0, 1
    addi t1, t1, -1
    bnez t1, stop_menu_music_loop
    j reset_menu_music

update_menu_music:
    li t0, MENU_MUSIC_ENABLED
    beqz t0, end_update_menu_music

    # menu_wait_key tambem e usado por GAME_OVER e VICTORY. O estado impede
    # que a trilha do menu vaze para essas telas.
    la t0, game_state
    lw t1, 0(t0)
    li t2, STATE_MENU
    bne t1, t2, end_update_menu_music

    # A opcao MUSIC do menu controla a trilha em tempo real.
    la t0, music_enabled
    lw t1, 0(t0)
    beqz t1, end_update_menu_music

    li a7, 30
    ecall
    mv t6, a0

    la t0, menu_music_next_time
    lw t1, 0(t0)
    beqz t1, play_next_menu_note
    bltu t6, t1, update_menu_drone

play_next_menu_note:
    la t0, menu_music_index
    lw t1, 0(t0)

    li t2, MENU_MUSIC_LENGTH
    blt t1, t2, menu_music_index_ok
    li t1, 0
    sw t1, 0(t0)

menu_music_index_ok:
    la t2, menu_music_frames
    add t2, t2, t1
    lbu t4, 0(t2)

    li t5, MENU_MUSIC_STEP_MS
    mul t5, t4, t5

    la t2, menu_music_next_time
    add t5, t6, t5
    sw t5, 0(t2)

    addi t1, t1, 1
    la t2, menu_music_index
    sw t1, 0(t2)

    la t2, menu_music_pitches
    addi t1, t1, -1
    add t2, t2, t1
    lbu t3, 0(t2)
    beqz t3, update_menu_drone

    li t5, MENU_MUSIC_NOTE_MS
    mul t5, t4, t5
    mv a0, t3
    mv a1, t5
    li a2, MENU_MUSIC_INSTRUMENT
    li a3, MENU_MUSIC_VOLUME
    li a7, 31
    ecall
    j end_update_menu_music

update_menu_drone:
    li a7, 30
    ecall
    mv t6, a0

    la t0, menu_drone_next_time
    lw t1, 0(t0)
    beqz t1, play_next_menu_drone
    bltu t6, t1, end_update_menu_music

play_next_menu_drone:
    la t0, menu_drone_index
    lw t1, 0(t0)

    li t2, MENU_DRONE_LENGTH
    blt t1, t2, menu_drone_index_ok
    li t1, 0
    sw t1, 0(t0)

menu_drone_index_ok:
    la t2, menu_drone_frames
    add t2, t2, t1
    lbu t4, 0(t2)

    li t5, MENU_DRONE_STEP_MS
    mul t5, t4, t5

    la t2, menu_drone_next_time
    add t5, t6, t5
    sw t5, 0(t2)

    addi t1, t1, 1
    la t2, menu_drone_index
    sw t1, 0(t2)

    la t2, menu_drone_pitches
    addi t1, t1, -1
    add t2, t2, t1
    lbu t3, 0(t2)
    beqz t3, end_update_menu_music

    li t5, MENU_DRONE_NOTE_MS
    mul t5, t4, t5
    mv a0, t3
    mv a1, t5
    li a2, MENU_DRONE_INSTRUMENT
    li a3, MENU_DRONE_VOLUME
    li a7, 31
    ecall

end_update_menu_music:
    ret

# ============================================================
# Trilha exclusiva da tela de Game Over
# ============================================================

reset_game_over_music:
    la t0, game_over_music_index
    sw zero, 0(t0)
    la t0, game_over_music_loop_start
    sw zero, 0(t0)
    ret

stop_game_over_music:
    la t0, game_over_music_stop_pitches
    li t1, GAME_OVER_MUSIC_STOP_PITCH_COUNT

stop_game_over_music_loop:
    lbu a0, 0(t0)
    li a1, 1
    li a2, GAME_OVER_MUSIC_INSTRUMENT
    li a3, 0
    li a7, 31
    ecall

    addi t0, t0, 1
    addi t1, t1, -1
    bnez t1, stop_game_over_music_loop
    j reset_game_over_music

update_game_over_music:
    li t0, GAME_OVER_MUSIC_ENABLED
    beqz t0, end_update_game_over_music

    la t0, game_state
    lw t1, 0(t0)
    li t2, STATE_GAME_OVER
    bne t1, t2, end_update_game_over_music

    la t0, music_enabled
    lw t1, 0(t0)
    beqz t1, end_update_game_over_music

    li a7, 30
    ecall
    mv t6, a0

    la t0, game_over_music_loop_start
    lw t3, 0(t0)
    bnez t3, game_over_music_has_start
    sw t6, 0(t0)
    li t4, 0
    j game_over_music_event_loop

game_over_music_has_start:
    sub t4, t6, t3

game_over_music_event_loop:
    la t0, game_over_music_index
    lw t1, 0(t0)
    li t2, GAME_OVER_MUSIC_EVENT_COUNT
    bge t1, t2, game_over_music_check_loop

    la t2, game_over_music_events
    slli t3, t1, 4
    add t2, t2, t3
    lw t5, 0(t2)
    bltu t4, t5, end_update_game_over_music

    lw a1, 4(t2)
    lw a0, 8(t2)
    li a2, GAME_OVER_MUSIC_INSTRUMENT
    lw a3, 12(t2)
    li a7, 31
    ecall

    addi t1, t1, 1
    la t0, game_over_music_index
    sw t1, 0(t0)
    j game_over_music_event_loop

game_over_music_check_loop:
    li t5, GAME_OVER_MUSIC_LOOP_MS
    bltu t4, t5, end_update_game_over_music

    la t0, game_over_music_loop_start
    lw t3, 0(t0)
    add t3, t3, t5
    sw t3, 0(t0)

    la t0, game_over_music_index
    sw zero, 0(t0)
    sub t4, t4, t5
    j game_over_music_event_loop

end_update_game_over_music:
    ret

# ============================================================
# Trilha exclusiva das fases jogaveis e da batalha do boss
# ============================================================

reset_gameplay_music:
    la t0, game_bass_index
    sw zero, 0(t0)
    la t0, game_bass_next_time
    sw zero, 0(t0)
    la t0, game_stab_index
    sw zero, 0(t0)
    la t0, game_stab_next_time
    sw zero, 0(t0)
    ret

# Encerra todos os pitches possiveis das duas camadas (baixo e piano/lead).
stop_gameplay_music:
    la t0, game_music_stop_pitches
    li t1, GAME_MUSIC_STOP_PITCH_COUNT

stop_gameplay_music_loop:
    lbu a0, 0(t0)
    li a1, 1
    li a2, GAME_BASS_INSTRUMENT
    li a3, 0
    li a7, 31
    ecall

    addi t0, t0, 1
    addi t1, t1, -1
    bnez t1, stop_gameplay_music_loop
    j reset_gameplay_music

update_gameplay_music:
    li t0, GAME_MUSIC_ENABLED
    beqz t0, end_update_gameplay_music

    # Defesa extra: mesmo se for chamada fora do loop correto, a musica so
    # pode tocar nas tres fases e no boss.
    la t0, game_state
    lw t1, 0(t0)
    li t2, STATE_LEVEL1
    beq t1, t2, gameplay_music_state_ok
    li t2, STATE_LEVEL2
    beq t1, t2, gameplay_music_state_ok
    li t2, STATE_LEVEL3
    beq t1, t2, gameplay_music_state_ok
    li t2, STATE_BOSS
    bne t1, t2, end_update_gameplay_music

gameplay_music_state_ok:
    la t0, music_enabled
    lw t1, 0(t0)
    beqz t1, end_update_gameplay_music

    li a7, 30
    ecall
    mv t6, a0

    la t0, game_bass_next_time
    lw t1, 0(t0)
    beqz t1, play_next_game_bass
    bltu t6, t1, update_game_stab

play_next_game_bass:
    la t0, game_bass_index
    lw t1, 0(t0)

    li t2, GAME_BASS_LENGTH
    blt t1, t2, game_bass_index_ok
    li t1, 0
    sw t1, 0(t0)

game_bass_index_ok:
    la t2, game_bass_frames
    add t2, t2, t1
    lbu t4, 0(t2)

    li t5, GAME_BASS_STEP_MS
    mul t5, t4, t5

    la t2, game_bass_next_time
    add t5, t6, t5
    sw t5, 0(t2)

    addi t1, t1, 1
    la t2, game_bass_index
    sw t1, 0(t2)

    la t2, game_bass_pitches
    addi t1, t1, -1
    add t2, t2, t1
    lbu t3, 0(t2)
    beqz t3, update_game_stab

    li t5, GAME_BASS_NOTE_MS
    mul t5, t4, t5
    mv a0, t3
    mv a1, t5
    li a2, GAME_BASS_INSTRUMENT
    li a3, GAME_BASS_VOLUME
    li a7, 31
    ecall

update_game_stab:
    li a7, 30
    ecall
    mv t6, a0

    la t0, game_stab_next_time
    lw t1, 0(t0)
    beqz t1, play_next_game_stab
    bltu t6, t1, end_update_gameplay_music

play_next_game_stab:
    la t0, game_stab_index
    lw t1, 0(t0)

    li t2, GAME_STAB_LENGTH
    blt t1, t2, game_stab_index_ok
    li t1, 0
    sw t1, 0(t0)

game_stab_index_ok:
    la t2, game_stab_frames
    add t2, t2, t1
    lbu t4, 0(t2)

    li t5, GAME_STAB_STEP_MS
    mul t5, t4, t5

    la t2, game_stab_next_time
    add t5, t6, t5
    sw t5, 0(t2)

    addi t1, t1, 1
    la t2, game_stab_index
    sw t1, 0(t0)

    la t2, game_stab_pitches
    addi t1, t1, -1
    add t2, t2, t1
    lbu t3, 0(t2)
    beqz t3, end_update_gameplay_music

    li t5, GAME_STAB_NOTE_MS
    mul t5, t4, t5
    mv a0, t3
    mv a1, t5
    li a2, GAME_STAB_INSTRUMENT
    li a3, GAME_STAB_VOLUME
    li a7, 31
    ecall

end_update_gameplay_music:
    ret
