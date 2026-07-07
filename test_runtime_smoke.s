# ============================================================
# Smoke test headless do loop de gameplay/renderizacao no RARS
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

.data
runtime_smoke_pass_message: .asciz "runtime smoke: PASS\n"

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
    call set_state_level2

    li s0, 0

runtime_smoke_loop:
    la t0, key_pressed
    li t1, 1
    sw t1, 0(t0)
    la t0, last_key
    li t1, 'l'
    sw t1, 0(t0)

    call update_player
    call update_bullets
    call update_enemy_bullets
    call spawn_wave_if_needed
    call update_enemies
    call update_powerups
    call update_inventory
    call check_bullet_enemy_collisions
    call check_enemy_player_collisions
    call check_enemy_bullet_player_collisions
    call check_player_powerup_collisions
    call advance_wave
    call update_animation_frame

    call begin_frame
    call draw_background
    call draw_player_square
    call draw_enemies
    call draw_bullets
    call draw_enemy_bullets
    call draw_powerups
    call draw_inventory
    call draw_hud
    call end_frame

    addi s0, s0, 1
    li t0, 360
    blt s0, t0, runtime_smoke_loop

    la a0, runtime_smoke_pass_message
    li a7, 4
    ecall
    li a0, 0
    li a7, 93
    ecall

.include "src/game_state.s"
.include "src/level_manager.s"
.include "src/input.s"
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
