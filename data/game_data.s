# ============================================================
# Dados globais controlados pelo core
# ============================================================

.data

# ------------------------------------------------------------
# Estado atual do jogo
# ------------------------------------------------------------

game_state:             .word STATE_MENU
current_level:          .word LEVEL_NONE

# ------------------------------------------------------------
# Controle de hordas e progressão
# ------------------------------------------------------------

current_wave:           .word 0
total_waves:            .word 0
remaining_enemies:      .word 0
wave_spawned:           .word 0
boss_active:            .word 0

# ------------------------------------------------------------
# Pontuação e controle temporal
# ------------------------------------------------------------

score:                  .word 0
frame_counter:          .word 0
draw_frame:             .word 1
animation_tick:         .word 0
animation_frame:        .word 0
post_boss_explosion_timer: .word 0
level_spawn_timer:
town_spawn_timer:       .word 0
level_exit_unlocked:
town_exit_unlocked:     .word 0
level_exit_blink_timer:
town_exit_blink_timer:  .word 0
level_exit_blink_frame:
town_exit_blink_frame:  .word 0
level_exit_transitioned:
town_exit_transitioned: .word 0
game_over_retry_state:  .word STATE_LEVEL1

# Quantidades por wave. O scheduler seleciona a tabela da fase atual.
town_wave_enemy_counts:
    .word TOWN_WAVE1_ENEMIES, TOWN_WAVE2_ENEMIES
    .word TOWN_WAVE3_ENEMIES, TOWN_WAVE4_ENEMIES
sewer_wave_enemy_counts:
    .word SEWER_WAVE1_ENEMIES, SEWER_WAVE2_ENEMIES, SEWER_WAVE3_ENEMIES
    .word SEWER_WAVE4_ENEMIES, SEWER_WAVE5_ENEMIES
lab_wave_enemy_counts:
    .word LABORATORY_WAVE1_ENEMIES, LABORATORY_WAVE2_ENEMIES
    .word LABORATORY_WAVE3_ENEMIES

# Obstaculos internos autoritativos do Town: x0, y0, x1, y1.
# Intervalos semiabertos; os limites externos sao testados diretamente.
town_collision_aabbs:
    .word 182,28,203,38, 193,37,203,55
    .word 271,31,302,42, 265,40,281,54, 286,40,296,50
    .word 171,80,181,126, 179,88,199,98
    .word 179,116,197,126, 187,124,197,142
    .word 37,141,88,173, 86,154,119,160
    .word 100,196,110,217, 216,211,244,221
town_collision_aabbs_end:

# O Sewer nao possui estrutura interna SOLID adicional: paredes externas
# continuam sendo tratadas pelos limites autoritativos do mapa.
sewer_solid_aabbs:
sewer_solid_aabbs_end:

# WATER flanqueando os seis decks. So bloqueia o jogador. As AABBs recuam
# quatro pixels nas entradas e deixam corredores de 24/26 pixels de altura.
sewer_water_aabbs:
    .word 14,48,25,50, 49,48,54,50
    .word 14,74,25,76, 49,74,54,76
    .word 80,48,244,50, 80,74,244,76
    .word 269,48,306,50, 269,74,306,76
    .word 14,164,96,166, 14,192,96,194
    .word 122,164,204,166, 122,192,204,194
    .word 230,164,306,166, 230,192,306,194
sewer_water_aabbs_end:

# Estruturas do Lab: bancada, diagonal em quatro segmentos, mesa grande
# com extensao diagonal em tres segmentos e equipamento em L (dois segmentos).
lab_collision_aabbs:
    .word 38,71,91,85
    .word 252,28,259,42, 256,37,264,51
    .word 261,46,269,59, 266,55,277,66
    .word 43,154,158,202
    .word 155,197,164,205, 162,202,174,211, 171,208,182,215
    .word 235,171,286,183, 235,171,247,208
lab_collision_aabbs_end:

# ------------------------------------------------------------
# Controle de testes e apresentação
# ------------------------------------------------------------

debug_mode:             .word 1

# ------------------------------------------------------------
# Entrada de teclado
# ------------------------------------------------------------

last_key:               .word 0
key_pressed:            .word 0
cutscene_text_visible:  .word 0
shoot_request_pending:  .word 0
noise_timer:            .word 0
