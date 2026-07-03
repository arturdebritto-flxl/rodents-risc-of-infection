# ============================================================
# Regressao deterministica do fluxo de drops e municao por fase
# ============================================================

.include "src/constants.s"
.include "data/game_data.s"
.include "data/player_data.s"
.include "data/powerup_data.s"
.include "data/inventory_data.s"

.data
drop_tests_pass_message: .asciz "powerup drop tests: PASS\n"
drop_tests_fail_message: .asciz "powerup drop tests: FAIL count="
sprite_ammo_pistol_pickup: .byte 0
sprite_ammo_shotgun_pickup: .byte 0
sprite_ammo_uzi_pickup: .byte 0
sprite_medkit_pickup: .byte 0
sprite_powerup_boss_weapon: .byte 0

.text
.globl main

main:
    li s0, 0

    # counter anterior, fase, active esperado, tipo esperado
    li a0, 0
    li a1, LEVEL_TOWN
    li a2, 0
    li a3, POWERUP_NONE
    call run_drop_case

    li a0, 4
    li a1, LEVEL_TOWN
    li a2, 1
    li a3, POWERUP_HEAL
    call run_drop_case

    li a0, 2
    li a1, LEVEL_TOWN
    li a2, 1
    li a3, POWERUP_NORMAL_AMMO
    call run_drop_case

    li a0, 2
    li a1, LEVEL_SEWER
    li a2, 1
    li a3, POWERUP_NORMAL_AMMO
    call run_drop_case

    li a0, 77
    li a1, LEVEL_SEWER
    li a2, 1
    li a3, POWERUP_SHOTGUN_AMMO
    call run_drop_case

    li a0, 98
    li a1, LEVEL_SEWER
    li a2, 1
    li a3, POWERUP_SHOTGUN_AMMO
    call run_drop_case

    li a0, 2
    li a1, LEVEL_LABORATORY
    li a2, 1
    li a3, POWERUP_NORMAL_AMMO
    call run_drop_case

    li a0, 26
    li a1, LEVEL_LABORATORY
    li a2, 1
    li a3, POWERUP_SHOTGUN_AMMO
    call run_drop_case

    li a0, 50
    li a1, LEVEL_LABORATORY
    li a2, 1
    li a3, POWERUP_BOSS_AMMO
    call run_drop_case

    beqz s0, drop_tests_passed
    la a0, drop_tests_fail_message
    li a7, 4
    ecall
    mv a0, s0
    li a7, 1
    ecall
    li a0, 1
    li a7, 93
    ecall

drop_tests_passed:
    la a0, drop_tests_pass_message
    li a7, 4
    ecall
    li a0, 0
    li a7, 93
    ecall

run_drop_case:
    addi sp, sp, -20
    sw ra, 0(sp)
    sw a0, 4(sp)
    sw a1, 8(sp)
    sw a2, 12(sp)
    sw a3, 16(sp)

    call init_powerups
    la t0, enemy_kill_counter
    lw t1, 4(sp)
    sw t1, 0(t0)
    la t0, current_level
    lw t1, 8(sp)
    sw t1, 0(t0)

    li a0, 100
    li a1, 100
    call spawn_powerup_from_enemy_death

    la t0, powerup_active
    lw t1, 0(t0)
    lw t2, 12(sp)
    bne t1, t2, drop_case_failed
    beqz t2, drop_case_done

    la t0, powerup_type
    lw t1, 0(t0)
    lw t2, 16(sp)
    beq t1, t2, drop_case_done

drop_case_failed:
    addi s0, s0, 1

drop_case_done:
    lw ra, 0(sp)
    addi sp, sp, 20
    ret

# Dependencias de renderizacao nao exercitadas pelo harness.
get_draw_base_address:
    mv a0, zero
    ret

draw_sprite_8bpp_fast:
    ret

draw_rect:
    ret

.include "src/powerups.s"
