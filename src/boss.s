# ============================================================
# Lógica do boss final
# ============================================================

.text

# ------------------------------------------------------------
# init_boss
# Reinicializa dados do boss.
#
# Entrada: nenhuma
# Saida: boss restaurado e inativo
# Modifica: t0, t1
# ------------------------------------------------------------

init_boss:
    la t0, boss_x
    li t1, BOSS_START_X
    sw t1, 0(t0)

    la t0, boss_y
    li t1, BOSS_START_Y
    sw t1, 0(t0)

    la t0, boss_hp
    li t1, BOSS_HP_START
    sw t1, 0(t0)

    la t0, boss_direction
    li t1, DIR_RIGHT
    sw t1, 0(t0)

    la t0, boss_attack_timer
    sw zero, 0(t0)

    la t0, boss_active
    sw zero, 0(t0)

    ret

# ------------------------------------------------------------
# update_boss
# Atualiza movimento e disparo do boss se boss_active = 1.
#
# Entrada: boss_active, boss_x, boss_direction, player_x
# Saida: boss movido e possivelmente cria projetil inimigo
# Modifica: t0-t6, a0-a3
# ------------------------------------------------------------

update_boss:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, boss_active
    lw t1, 0(t0)
    beqz t1, end_update_boss

    la t0, game_state
    lw t1, 0(t0)
    li t2, STATE_BOSS
    bne t1, t2, end_update_boss

    call move_boss
    call update_boss_attack

end_update_boss:
    lw ra, 0(sp)
    addi sp, sp, 4

    ret

# -------------------------------------------------------------
# move_boss
# -------------------------------------------------------------

move_boss:
    la t0, boss_direction
    lw t1, 0(t0)

    li t2, DIR_RIGHT
    beq t1, t2, move_boss_right

    li t2, DIR_LEFT
    beq t1, t2, move_boss_left

    # Direção inválida: corrige para direita
    li t1, DIR_RIGHT
    sw t1, 0(t0)
    j move_boss_right

move_boss_right:
    la t0, boss_x
    lw t1, 0(t0)

    li t2, BOSS_SPEED
    add t1, t1, t2

    li t3, BOSS_MAX_X
    bgt t1, t3, clamp_boss_right

    sw t1, 0(t0)
    ret

clamp_boss_right:
    li t1, BOSS_MAX_X
    sw t1, 0(t0)

    la t0, boss_direction
    li t1, DIR_LEFT
    sw t1, 0(t0)

    ret

move_boss_left:
    la t0, boss_x
    lw t1, 0(t0)

    li t2, BOSS_SPEED
    sub t1, t1, t2

    li t3, BOSS_MIN_X
    blt t1, t3, clamp_boss_left

    sw t1, 0(t0)
    ret

clamp_boss_left:
    li t1, BOSS_MIN_X
    sw t1, 0(t0)

    la t0, boss_direction
    li t1, DIR_RIGHT
    sw t1, 0(t0)

    ret

# ------------------------------------------------------------
# update_boss_attack
# Boss dispara projeteis em intervalo fixo.
# Direcao simples:
#   se player_x muito a esquerda -> atira esquerda
#   se player_x muito a direita  -> atira direita
#   senao                        -> atira para baixo
# ------------------------------------------------------------

update_boss_attack:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, boss_attack_timer
    lw t1, 0(t0)

    addi t1, t1, 1

    li t2, BOSS_SHOOT_DELAY
    blt t1, t2, store_boss_attack_timer

    # Timer atingiu o limite: reseta e atira
    sw zero, 0(t0)

    # a0 = boss_x + 8
    la t0, boss_x
    lw t0, 0(t0)
    addi a0, t0, 8

    # a1 = boss_y + 16
    la t0, boss_y
    lw a1, 0(t0)
    addi a1, a1, 16

    # Decide direcao aproximada usando player_x
    la t0, player_x
    lw t1, 0(t0)

    la t0, boss_x
    lw t2, 0(t0)

    # se player_x < boss_x - 8, atira para esquerda
    addi t3, t2, -8
    blt t1, t3, boss_shoot_left

    # se player_x > boss_x + 16, atira para direita
    addi t3, t2, 16
    bgt t1, t3, boss_shoot_right

    # senao, atira para baixo
    j boss_shoot_down

boss_shoot_down:
    li a2, 0
    li a3, ENEMY_BULLET_SPEED
    call spawn_enemy_bullet
    j end_update_boss_attack

boss_shoot_right:
    li a2, ENEMY_BULLET_SPEED
    li a3, 0
    call spawn_enemy_bullet
    j end_update_boss_attack

boss_shoot_left:
    li a2, -3
    li a3, 0
    call spawn_enemy_bullet
    j end_update_boss_attack

store_boss_attack_timer:
    sw t1, 0(t0)

end_update_boss_attack:
    lw ra, 0(sp)
    addi sp, sp, 4

    ret
