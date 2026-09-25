# ============================================================
# Dados da trilha sonora exclusiva do gameplay
# Fonte: assets/source/audio/test_trilha_gameplay.s
# ============================================================

.data
.align 2

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

# Todos os pitches usados pela trilha. Volume MIDI zero encerra as notas
# longas antes de qualquer tela que nao seja gameplay.
game_music_stop_pitches:
    .byte 31, 35, 36, 38, 40, 52, 55, 58, 60, 62, 63, 64, 67
