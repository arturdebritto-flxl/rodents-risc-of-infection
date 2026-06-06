# ============================================================
# Inventario e uso de cura
# ============================================================

.text

init_inventory:
    la t0, weapon_type
    li t1, WEAPON_NORMAL
    sw t1, 0(t0)

    la t0, normal_ammo_count
    sw zero, 0(t0)

    la t0, boss_ammo_count
    sw zero, 0(t0)

    la t0, heal_count
    sw zero, 0(t0)

    ret

update_inventory:
    la t0, game_state
    lw t1, 0(t0)

    li t2, STATE_LEVEL1
    beq t1, t2, update_inventory_state_ok

    li t2, STATE_LEVEL2
    beq t1, t2, update_inventory_state_ok

    li t2, STATE_BOSS
    beq t1, t2, update_inventory_state_ok

    ret

update_inventory_state_ok:
    la t0, key_pressed
    lw t1, 0(t0)
    beqz t1, end_update_inventory

    la t0, last_key
    lw t1, 0(t0)

    li t2, 'h'
    beq t1, t2, try_use_heal

    li t2, 'H'
    bne t1, t2, end_update_inventory

try_use_heal:
    la t0, heal_count
    lw t1, 0(t0)
    blez t1, end_update_inventory

    la t2, player_lives
    lw t3, 0(t2)
    li t4, PLAYER_MAX_LIVES
    bge t3, t4, end_update_inventory

    addi t3, t3, 1
    sw t3, 0(t2)

    addi t1, t1, -1
    sw t1, 0(t0)

end_update_inventory:
    ret

draw_inventory:
    la t0, draw_frame
    lw t1, 0(t0)

    la t0, weapon_type
    lw a0, 0(t0)
    li a1, 8
    li a2, 224
    li a3, 0x000000FF
    mv a4, t1
    li a7, 101
    ecall

    la t0, normal_ammo_count
    lw a0, 0(t0)
    li a1, 56
    li a2, 224
    li a3, 0x000000FF
    mv a4, t1
    li a7, 101
    ecall

    la t0, boss_ammo_count
    lw a0, 0(t0)
    li a1, 104
    li a2, 224
    li a3, 0x000000FF
    mv a4, t1
    li a7, 101
    ecall

    la t0, heal_count
    lw a0, 0(t0)
    li a1, 152
    li a2, 224
    li a3, 0x000000FF
    mv a4, t1
    li a7, 101
    ecall

    ret
