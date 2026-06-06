# ============================================================
# Logica dos projeteis inimigos
# ============================================================

.text

# ------------------------------------------------------------
# init_enemy_bullets
# Desativa todos os projeteis inimigos.
#
# Entrada: nenhuma
# Saida: enemy_bullet_active zerado
# Modifica: t0-t4
# ------------------------------------------------------------

init_enemy_bullets:
    li t1, 0

init_enemy_bullets_loop:
    li t2, MAX_ENEMY_BULLETS
    beq t1, t2, end_init_enemy_bullets

    slli t3, t1, 2

    la t0, enemy_bullet_active
    add t4, t0, t3
    sw zero, 0(t4)

    addi t1, t1, 1
    j init_enemy_bullets_loop

end_init_enemy_bullets:
    ret

#------------------------------------------------------------
# spawn_enemy_bullet
# Cria um projetil inimigo no primeiro slot livre.
#
# Entrada:
#   a0 = x inicial
#   a1 = y inicial
#   a2 = dx
#   a3 = dy
#
# Saida:
#   enemy_bullet_* preenchido no primeiro slot livre
#
# Modifica: t0-t6
# ------------------------------------------------------------

spawn_enemy_bullet:
    li t1, 0

find_free_enemy_bullet_loop:
    li t2, MAX_ENEMY_BULLETS
    beq t1, t2, end_spawn_enemy_bullet

    slli t3, t1, 2

    la t0, enemy_bullet_active
    add t4, t0, t3
    lw t5, 0(t4)

    beqz t5, create_enemy_bullet_here

    addi t1, t1, 1
    j find_free_enemy_bullet_loop

create_enemy_bullet_here:
    # ativo = 1
    li t5, ENEMY_BULLET_ACTIVE
    sw t5, 0(t4)

    # x
    la t0, enemy_bullet_x
    add t6, t0, t3
    sw a0, 0(t6)

    # y
    la t0, enemy_bullet_y
    add t6, t0, t3
    sw a1, 0(t6)

    # dx
    la t0, enemy_bullet_dx
    add t6, t0, t3
    sw a2, 0(t6)

    # dy
    la t0, enemy_bullet_dy
    add t6, t0, t3
    sw a3, 0(t6)

end_spawn_enemy_bullet:
    ret

# ------------------------------------------------------------
# update_enemy_bullets
# Move projeteis inimigos ativos.
# Desativa se sair da tela.
#
# Entrada: arrays enemy_bullet_*
# Saida: posicoes atualizadas
# Modifica: t0-t6
# ------------------------------------------------------------

update_enemy_bullets:
    la t0, game_state
    lw t1, 0(t0)

    li t2, STATE_LEVEL1
    beq t1, t2, update_enemy_bullets_state_ok

    li t2, STATE_LEVEL2
    beq t1, t2, update_enemy_bullets_state_ok

    li t2, STATE_BOSS
    beq t1, t2, update_enemy_bullets_state_ok

    ret

update_enemy_bullets_state_ok:
    li t1, 0

update_enemy_bullets_loop:
    li t2, MAX_ENEMY_BULLETS
    beq t1, t2, end_update_enemy_bullets

    slli t3, t1, 2

    # Se inativo, pula
    la t0, enemy_bullet_active
    add t4, t0, t3
    lw t5, 0(t4)
    beqz t5, next_enemy_bullet_update

    # x = x + dx
    la t0, enemy_bullet_x
    add t4, t0, t3
    lw t5, 0(t4)

    la t0, enemy_bullet_dx
    add t6, t0, t3
    lw t6, 0(t6)

    add t5, t5, t6

    # se x < 0, desativa
    blt t5, zero, deactivate_enemy_bullet

    # se x > 317, desativa
    li t6, 317
    bgt t5, t6, deactivate_enemy_bullet

    # salva x
    sw t5, 0(t4)

    # y = y + dy
    la t0, enemy_bullet_y
    add t4, t0, t3
    lw t5, 0(t4)

    la t0, enemy_bullet_dy
    add t6, t0, t3
    lw t6, 0(t6)

    add t5, t5, t6

    # se y < 0, desativa
    blt t5, zero, deactivate_enemy_bullet

    # se y > 237, desativa
    li t6, 237
    bgt t5, t6, deactivate_enemy_bullet

    # salva y
    sw t5, 0(t4)

    j next_enemy_bullet_update

deactivate_enemy_bullet:
    la t0, enemy_bullet_active
    add t4, t0, t3
    sw zero, 0(t4)

next_enemy_bullet_update:
    addi t1, t1, 1
    j update_enemy_bullets_loop

end_update_enemy_bullets:
    ret
