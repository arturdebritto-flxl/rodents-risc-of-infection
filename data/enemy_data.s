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
enemy_avoid_direction:  .space 60
enemy_avoid_timer:      .space 60
enemy_spawn_rng_state:  .word 0x6D2B79F5

# Buracos pretos do Town, ja centralizados para inimigos 16x16.
town_enemy_spawn_points:
    .word 236,25, 97,106, 37,192, 240,167
town_enemy_spawn_points_end:

sewer_enemy_spawn_points:
    .word 16,72, 48,72, 104,20, 128,20, 112,72
    .word 144,72, 176,72, 224,72, 272,72, 288,72
    .word 16,120, 64,120, 112,120, 160,120, 208,120
    .word 256,120, 288,120, 16,188, 96,188, 160,188

laboratory_enemy_spawn_points:
    .word 16,24, 56,24, 96,24, 136,24, 176,24
    .word 216,24, 280,24, 16,88, 64,88, 112,88
    .word 160,88, 208,88, 256,88, 288,88, 64,132
    .word 104,132, 160,132, 208,132, 256,132, 16,184
