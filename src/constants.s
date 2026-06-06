# ============================================================
# Constantes compartilhadas por todos os módulos
# ============================================================

# ------------------------------------------------------------
# Estados gerais do jogo
# ------------------------------------------------------------

.eqv STATE_MENU                    0
.eqv STATE_LEVEL1                  1
.eqv STATE_LEVEL2                  2
.eqv STATE_LEVEL3                  3
.eqv STATE_BOSS                    3
.eqv STATE_GAME_OVER               4
.eqv STATE_VICTORY                 5

# ------------------------------------------------------------
# Identificação dos cenários
# ------------------------------------------------------------

.eqv LEVEL_NONE                    0
.eqv LEVEL_TOWN                    1
.eqv LEVEL_SEWER                   2
.eqv LEVEL_LABORATORY              3

# ------------------------------------------------------------
# Direções de movimento e ataque
# ------------------------------------------------------------

.eqv DIR_UP                        0
.eqv DIR_RIGHT                     1
.eqv DIR_DOWN                      2
.eqv DIR_LEFT                      3

# ------------------------------------------------------------
# Dimensões da interface gráfica
# ------------------------------------------------------------

.eqv SCREEN_WIDTH                 320
.eqv SCREEN_HEIGHT                240

# ------------------------------------------------------------
# Limites iniciais de entidades simultâneas
# ------------------------------------------------------------

.eqv MAX_BULLETS                  10
.eqv MAX_ENEMIES                  15

# ------------------------------------------------------------
# Tipos de inimigos: ratos
# ------------------------------------------------------------

.eqv RAT_COMMON             1
.eqv RAT_ECHO               2
.eqv RAT_MUTANT             3
.eqv RAT_SPITTER            4
.eqv RAT_BOSS               5

# ------------------------------------------------------------
# Tipos de power-up
# ------------------------------------------------------------

.eqv POWERUP_NONE              0
.eqv POWERUP_NORMAL_AMMO       1
.eqv POWERUP_HEAL              2
.eqv POWERUP_BOSS_WEAPON       3
.eqv POWERUP_BOSS_AMMO         4
.eqv MAX_POWERUPS              8
.eqv POWERUP_SIZE              5

.eqv WEAPON_NORMAL             1
.eqv WEAPON_BOSS               2

.eqv PLAYER_MAX_LIVES          3
.eqv NORMAL_AMMO_GAIN          5
.eqv BOSS_AMMO_GAIN            3
.eqv HEAL_GAIN                 1
.eqv WEAPON_NORMAL_DAMAGE      1
.eqv WEAPON_BOSS_DAMAGE        3

# ------------------------------------------------------------
# Configuracao das waves da fase 1: town
# ------------------------------------------------------------

.eqv TOWN_TOTAL_WAVES           4
.eqv TOWN_WAVE1_ENEMIES         4
.eqv TOWN_WAVE2_ENEMIES         5
.eqv TOWN_WAVE3_ENEMIES         6
.eqv TOWN_WAVE4_ENEMIES         7

# ------------------------------------------------------------
# Configuracao das waves da fase 2: Sewer
# ------------------------------------------------------------

.eqv SEWER_TOTAL_WAVES          5
.eqv SEWER_WAVE1_ENEMIES        8
.eqv SEWER_WAVE2_ENEMIES        9
.eqv SEWER_WAVE3_ENEMIES        10
.eqv SEWER_WAVE4_ENEMIES        11
.eqv SEWER_WAVE5_ENEMIES        12

# ------------------------------------------------------------
# Configuracao das waves da fase 3: Laboratory
# ------------------------------------------------------------

.eqv LABORATORY_TOTAL_WAVES     3
.eqv LABORATORY_WAVE1_ENEMIES   13
.eqv LABORATORY_WAVE2_ENEMIES   14
.eqv LABORATORY_WAVE3_ENEMIES   15

# ------------------------------------------------------------
# Configuracao da batalha final
# ------------------------------------------------------------

.eqv BOSS_SUPPORT_ENEMIES       5

# ------------------------------------------------------------
# Configuracao de debug do loop
# ------------------------------------------------------------

.eqv DEBUG_LOOP_FRAMES          120
.eqv DEBUG_FRAME_DELAY_MS       33

# ------------------------------------------------------------
# Configuracao inicial do jogador
# ------------------------------------------------------------

.eqv PLAYER_START_X             160
.eqv PLAYER_START_Y             120
.eqv PLAYER_SPEED               8
.eqv PLAYER_SIZE                8

.eqv PLAYER_MIN_X               0
.eqv PLAYER_MAX_X               312
.eqv PLAYER_MIN_Y               0
.eqv PLAYER_MAX_Y               232

# ------------------------------------------------------------
# Configuracao dos tiros
# ------------------------------------------------------------

.eqv BULLET_SPEED               8
.eqv BULLET_SIZE                3
.eqv BULLET_INACTIVE            0
.eqv BULLET_ACTIVE              1

# ------------------------------------------------------------
# Configuracao dos inimigos
# ------------------------------------------------------------

.eqv ENEMY_SIZE                 8

# ------------------------------------------------------------
# Pontuacao
# ------------------------------------------------------------

.eqv SCORE_RAT_COMMON       100
.eqv SCORE_RAT_ECHO         150
.eqv SCORE_RAT_MUTANT       200
.eqv SCORE_RAT_SPITTER      250

# ------------------------------------------------------------
# Atributos dos ratos
# ------------------------------------------------------------

.eqv RAT_COMMON_HP          1
.eqv RAT_ECHO_HP            1
.eqv RAT_MUTANT_HP          2
.eqv RAT_SPITTER_HP         1

.eqv RAT_COMMON_SPEED       1
.eqv RAT_ECHO_SPEED         2
.eqv RAT_MUTANT_SPEED       1
.eqv RAT_SPITTER_SPEED      1

# ------------------------------------------------------------
# Projeteis inimigos
# ------------------------------------------------------------

.eqv MAX_ENEMY_BULLETS          10
.eqv ENEMY_BULLET_SPEED         4
.eqv ENEMY_BULLET_SIZE          3
.eqv ENEMY_BULLET_ACTIVE        1
.eqv ENEMY_BULLET_INACTIVE      0

.eqv SPITTER_SHOOT_DELAY        45

# ------------------------------------------------------------
# Boss Final
# ------------------------------------------------------------

.eqv BOSS_SIZE                 16
.eqv BOSS_START_X              152
.eqv BOSS_START_Y              32
.eqv BOSS_HP_START             20
.eqv BOSS_SPEED                1

.eqv BOSS_MIN_X                24
.eqv BOSS_MAX_X                280

.eqv BOSS_SHOOT_DELAY          50
.eqv SCORE_BOSS                1000
