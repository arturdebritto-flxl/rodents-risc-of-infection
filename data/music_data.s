# ============================================================
# Dados da trilha sonora exclusiva do menu
# ============================================================

.data
.align 2

menu_music_index:       .word 0
menu_music_next_time:   .word 0
menu_drone_index:       .word 0
menu_drone_next_time:   .word 0

# Formato: pitch MIDI e duracao em ticks musicais.
menu_music_pitches:
    .byte 39, 43, 45, 50, 45, 43, 39, 43, 45, 50, 45, 43
    .byte 34, 38, 41, 45, 41, 38, 34, 38, 41, 45, 41, 38
    .byte 39, 43, 45, 50, 45, 43, 39, 43, 45, 53, 45, 43
    .byte 34, 38, 41, 45, 41, 38, 34, 38, 41, 45, 41, 38
    .byte 39, 43, 45, 50, 45, 43, 39, 43, 45, 50, 45, 43
    .byte 34, 38, 41, 45, 41, 38, 34, 38, 41, 45, 41, 38
    .byte 39, 43, 45, 50, 45, 43, 39, 43, 45, 53, 45, 43
    .byte 34, 38, 41, 45, 41, 38, 34, 38, 41, 45, 41, 38

menu_music_frames:
    .byte 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 36
    .byte 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 48
    .byte 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 36
    .byte 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 48
    .byte 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 36
    .byte 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 48
    .byte 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 36
    .byte 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 48

menu_drone_pitches:
    .byte 28, 27, 30, 31

menu_drone_frames:
    .byte 144, 144, 144, 168

# Todos os pitches distintos usados acima. Volume MIDI zero equivale a
# NOTE_OFF e permite silenciar imediatamente qualquer nota ao deixar o menu.
menu_music_stop_pitches:
    .byte 27, 28, 30, 31, 34, 38, 39, 41, 43, 45, 50, 53
