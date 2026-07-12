# ============================================================
# Dados dos inimigos
# ============================================================

.data

enemy_x:                .space 60
enemy_y:                .space 60
enemy_type:             .space 60
enemy_active:           .space 60
enemy_hp:               .space 60
enemy_attack_timer:     .space 60
enemy_direction:        .space 60
enemy_spawn_rng_state:  .word 0x6D2B79F5

# Pontos 16x16 previamente validados contra limites e obstaculos.
town_enemy_spawn_points:
    .word 8,24, 48,24, 88,24, 128,24, 168,24
    .word 208,24, 248,24, 288,24, 8,84, 48,84
    .word 144,84, 184,84, 224,84, 264,84, 8,132
    .word 48,132, 88,132, 128,132, 264,132, 288,132

sewer_enemy_spawn_points:
    .word 8,24, 40,24, 128,24, 160,24, 192,24
    .word 240,24, 272,24, 304,24, 8,72, 40,72
    .word 64,72, 128,72, 160,72, 192,72, 240,72
    .word 272,72, 304,72, 8,136, 40,136, 64,136

laboratory_enemy_spawn_points:
    .word 8,24, 48,24, 88,24, 128,24, 168,24
    .word 208,24, 248,24, 288,24, 8,76, 48,76
    .word 88,76, 128,76, 192,76, 232,76, 272,76
    .word 304,76, 8,132, 48,132, 88,132, 128,132
