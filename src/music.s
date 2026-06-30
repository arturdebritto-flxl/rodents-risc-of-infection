# ============================================================
# Musica MIDI assincrona
# ============================================================

.data
.align 2
music_notes:
    .word 64, 67, 69, 67, 62, 64, 67, 71

.text

update_music:
    addi sp, sp, -4
    sw ra, 0(sp)

    li a7, 30
    ecall
    la t0, music_next_time
    lw t1, 0(t0)
    bltu a0, t1, end_update_music

    addi t1, a0, MUSIC_NOTE_INTERVAL_MS
    sw t1, 0(t0)

    la t0, music_index
    lw t1, 0(t0)
    la t2, music_notes
    slli t3, t1, 2
    add t2, t2, t3
    lw a0, 0(t2)
    li a1, MUSIC_NOTE_DURATION_MS
    li a2, MUSIC_INSTRUMENT
    li a3, MUSIC_VOLUME
    li a7, 31
    ecall

    addi t1, t1, 1
    li t2, MUSIC_NOTE_COUNT
    blt t1, t2, store_music_index
    li t1, 0
store_music_index:
    la t0, music_index
    sw t1, 0(t0)

end_update_music:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret
