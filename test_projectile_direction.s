# ============================================================
# Regressao de direcao, velocidade e spawn dos tiros do player
# ============================================================

.include "src/constants.s"
.include "data/game_data.s"
.include "data/player_data.s"
.include "data/bullet_data.s"
.include "data/inventory_data.s"

.data
projectile_tests_pass_message: .asciz "projectile direction tests: PASS\n"
projectile_tests_fail_message: .asciz "projectile direction tests: FAIL count="

.text
.globl main

main:
    li s0, 0

    la t0, player_x
    li t1, 100
    sw t1, 0(t0)
    la t0, player_y
    sw t1, 0(t0)

    # direcao, dx, dy, spawn_x, spawn_y
    li a0, DIR_UP
    li a1, 0
    li a2, -10
    li a3, 106
    li a4, 97
    call run_projectile_case

    li a0, DIR_DOWN
    li a1, 0
    li a2, 10
    li a3, 106
    li a4, 116
    call run_projectile_case

    li a0, DIR_LEFT
    li a1, -10
    li a2, 0
    li a3, 97
    li a4, 106
    call run_projectile_case

    li a0, DIR_RIGHT
    li a1, 10
    li a2, 0
    li a3, 116
    li a4, 106
    call run_projectile_case

    beqz s0, projectile_tests_passed

    la a0, projectile_tests_fail_message
    li a7, 4
    ecall
    mv a0, s0
    li a7, 1
    ecall
    li a0, 1
    li a7, 93
    ecall

projectile_tests_passed:
    la a0, projectile_tests_pass_message
    li a7, 4
    ecall
    li a0, 0
    li a7, 93
    ecall

run_projectile_case:
    addi sp, sp, -24
    sw ra, 0(sp)
    sw a0, 4(sp)
    sw a1, 8(sp)
    sw a2, 12(sp)
    sw a3, 16(sp)
    sw a4, 20(sp)

    call init_bullets
    lw a0, 4(sp)
    li t5, BULLET_SPEED
    call set_cardinal_delta

    lw t0, 8(sp)
    bne a2, t0, projectile_case_failed
    lw t0, 12(sp)
    bne a3, t0, projectile_case_failed

    li a5, WEAPON_NORMAL_DAMAGE
    call create_bullet_with_delta

    la t0, bullet_x
    lw t1, 0(t0)
    lw t2, 16(sp)
    bne t1, t2, projectile_case_failed

    la t0, bullet_y
    lw t1, 0(t0)
    lw t2, 20(sp)
    bne t1, t2, projectile_case_failed

    la t0, bullet_direction
    lw t1, 0(t0)
    lw t2, 4(sp)
    beq t1, t2, projectile_case_done

projectile_case_failed:
    addi s0, s0, 1

projectile_case_done:
    lw ra, 0(sp)
    addi sp, sp, 24
    ret

# Stubs das dependencias de input/reload nao exercitadas neste teste.
update_player_facing_direction:
    ret

start_rifle_reload:
    ret

start_shotgun_reload:
    ret

.include "src/bullets.s"
