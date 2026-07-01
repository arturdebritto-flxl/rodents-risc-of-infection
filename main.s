# ============================================================
# Arquivo principal do jogo
# ============================================================

.include "System/MACROSv24.s"
.include "src/constants.s"

.include "data/game_data.s"
.include "data/player_data.s"
.include "data/bullet_data.s"
.include "data/enemy_data.s"
.include "data/enemy_bullet_data.s"
.include "data/boss_data.s"
.include "data/powerup_data.s"
.include "data/inventory_data.s"

.text
.globl main

main:
    call init_game
    call init_player
    call init_bullets
    call init_enemy_bullets
    call init_boss
    call init_enemies
    call init_powerups
    call init_inventory
    call init_video

    call set_state_menu

    call game_loop

    li a7, 10
    ecall


.include "src/game_state.s"
.include "src/level_manager.s"
.include "src/input.s"
.include "src/cheats.s"
.include "src/music.s"
.include "src/player.s"
.include "src/bullets.s"
.include "src/enemies.s"
.include "src/enemy_bullets.s"
.include "src/boss.s"
.include "src/collision.s"
.include "src/render.s"
.include "src/screens.s"
.include "src/hud.s"
.include "src/powerups.s"
.include "src/inventory.s"
.include "src/game_loop.s"

.include "System/SYSTEMv24.s"
