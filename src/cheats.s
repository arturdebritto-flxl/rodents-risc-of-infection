# ============================================================
# Cheats de apresentacao (somente em debug)
# ============================================================

.text

update_debug_cheats:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, debug_mode
    lw t0, 0(t0)
    beqz t0, end_update_debug_cheats
    la t0, key_pressed
    lw t0, 0(t0)
    beqz t0, end_update_debug_cheats
    la t0, last_key
    lw t1, 0(t0)

    li t2, '7'
    beq t1, t2, cheat_town
    li t2, '8'
    beq t1, t2, cheat_sewer
    li t2, '9'
    beq t1, t2, cheat_laboratory
    li t2, '0'
    beq t1, t2, cheat_boss
    li t2, 'V'
    beq t1, t2, cheat_lives
    li t2, 'v'
    beq t1, t2, cheat_lives
    li t2, 'M'
    beq t1, t2, cheat_ammo
    li t2, 'm'
    beq t1, t2, cheat_ammo
    j end_update_debug_cheats

cheat_town:
    call set_state_level1
    j consume_debug_cheat
cheat_sewer:
    call set_state_level2
    j consume_debug_cheat
cheat_laboratory:
    call set_state_level3
    j consume_debug_cheat
cheat_boss:
    call start_boss_fight
    j consume_debug_cheat
cheat_lives:
    la t0, player_lives
    li t1, PLAYER_MAX_LIVES
    sw t1, 0(t0)
    j consume_debug_cheat
cheat_ammo:
    la t0, normal_ammo_count
    lw t1, 0(t0)
    addi t1, t1, 30
    sw t1, 0(t0)
    la t0, shotgun_ammo_count
    lw t1, 0(t0)
    addi t1, t1, 12
    sw t1, 0(t0)
    la t0, boss_ammo_count
    lw t1, 0(t0)
    addi t1, t1, 10
    sw t1, 0(t0)

consume_debug_cheat:
    call clear_input_frame
end_update_debug_cheats:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret
