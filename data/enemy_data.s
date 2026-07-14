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

# Pontas das quatro setas do Sewer, ajustadas para o footprint 16x16 ficar
# totalmente dentro da area jogavel.
sewer_spawn_points:
sewer_enemy_spawn_points:
    .word 230,20, 288,86, 10,198, 281,200
sewer_spawn_points_end:

# Setas rosas visiveis no Lab: entrada superior esquerda, lateral direita
# e entrada junto ao sangue na lateral da estrutura grande.
lab_spawn_points:
laboratory_enemy_spawn_points:
    .word 10,20, 288,96, 176,178
lab_spawn_points_end:
