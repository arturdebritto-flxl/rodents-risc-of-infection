# ============================================================
# Teste standalone da trilha de gameplay
# Abra este arquivo no RARS e execute para ouvir somente a musica.
# ============================================================

.eqv GAME_MUSIC_ENABLED       1

.eqv GAME_BASS_LENGTH         12
.eqv GAME_BASS_STEP_MS        42
.eqv GAME_BASS_NOTE_MS        150
.eqv GAME_BASS_INSTRUMENT     48
.eqv GAME_BASS_VOLUME         42

.eqv GAME_STAB_LENGTH         24
.eqv GAME_STAB_STEP_MS        36
.eqv GAME_STAB_NOTE_MS        82
.eqv GAME_STAB_INSTRUMENT     0
.eqv GAME_STAB_VOLUME         48

.eqv PREVIEW_FRAME_DELAY_MS   16

.data

game_bass_index:       .word 0
game_bass_next_time:   .word 0
game_stab_index:       .word 0
game_stab_next_time:   .word 0

# Base de sobrevivencia: grave lento, vazio e melancolico.
game_bass_pitches:
    .byte 40, 0, 38, 0, 36, 0
    .byte 35, 0, 38, 0, 31, 0

game_bass_frames:
    .byte 80, 28, 88, 32, 92, 32
    .byte 96, 36, 84, 32, 112, 48

# Piano/lead esparso: tristeza, isolamento e tensao.
game_stab_pitches:
    .byte 0, 64, 0, 60, 62, 0
    .byte 55, 0, 0, 63, 0, 58
    .byte 60, 0, 52, 0, 0, 62
    .byte 0, 64, 67, 0, 60, 0

game_stab_frames:
    .byte 24, 22, 28, 20, 18, 34
    .byte 24, 38, 24, 22, 28, 20
    .byte 26, 40, 24, 36, 24, 22
    .byte 30, 20, 26, 36, 34, 48

.text
.globl main

main:
    call reset_gameplay_music

preview_loop:
    call update_gameplay_music

    li a0, PREVIEW_FRAME_DELAY_MS
    li a7, 32
    ecall

    j preview_loop

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

update_gameplay_music:
    li t0, GAME_MUSIC_ENABLED
    beqz t0, end_update_gameplay_music

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
    la t0, game_bass_index
    lw t1, 0(t0)
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
    sw t1, 0(t2)

    la t2, game_stab_pitches
    la t0, game_stab_index
    lw t1, 0(t0)
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
