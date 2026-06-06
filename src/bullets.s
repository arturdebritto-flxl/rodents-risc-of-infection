# ============================================================
# Logica dos tiros
# ============================================================

.text

# ------------------------------------------------------------
# init_bullets
# Desativa todos os tiros.
#
# Entrada: nenhuma
# Saida: bullet_active zerado
# Modifica: t0, t1, t2, t3
# ------------------------------------------------------------

init_bullets:
    li t1, 0

init_bullets_loop:
    li t2, MAX_BULLETS
    beq t1, t2, end_init_bullets

    slli t3, t1, 2

    la t0, bullet_active
    add t4, t0, t3
    sw zero, 0(t4)

    la t0, bullet_damage
    add t4, t0, t3
    sw zero, 0(t4)

    addi t1, t1, 1
    j init_bullets_loop

end_init_bullets:
    ret

# ------------------------------------------------------------
# update_bullets
# Cria tiro se tecla de ataque foi pressionada e move tiros ativos.
#
# Teclas:
#   i = cima
#   k = baixo
#   j = esquerda
#   l = direita
#
# Entrada: last_key, key_pressed, player_x, player_y
# Saida: tiros criados/movidos
# Modifica: t0-t6, a0
# ------------------------------------------------------------

update_bullets:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, game_state
    lw t1, 0(t0)

    li t2, STATE_LEVEL1
    beq t1, t2, update_bullets_state_ok

    li t2, STATE_LEVEL2
    beq t1, t2, update_bullets_state_ok

    li t2, STATE_BOSS
    beq t1, t2, update_bullets_state_ok

    j end_update_bullets

update_bullets_state_ok:
    call check_shoot_input
    call move_bullets

end_update_bullets:
    lw ra, 0(sp)
    addi sp, sp, 4

    ret


# ------------------------------------------------------------
# check_shoot_input
# Verifica se a tecla pressionada e uma tecla de tiro.
#
# Entrada: key_pressed, last_key
# Saida: pode chamar spawn_bullet
# Modifica: t0, t1, t2, a0
# ------------------------------------------------------------

check_shoot_input:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, key_pressed
    lw t1, 0(t0)
    beqz t1, end_check_shoot_input

    la t0, last_key
    lw t1, 0(t0)

    li t2, 'i'
    beq t1, t2, shoot_up

    li t2, 'k'
    beq t1, t2, shoot_down

    li t2, 'j'
    beq t1, t2, shoot_left

    li t2, 'l'
    beq t1, t2, shoot_right

    j end_check_shoot_input


shoot_up:
    li a0, DIR_UP
    call spawn_bullet
    j end_check_shoot_input


shoot_down:
    li a0, DIR_DOWN
    call spawn_bullet
    j end_check_shoot_input


shoot_left:
    li a0, DIR_LEFT
    call spawn_bullet
    j end_check_shoot_input


shoot_right:
    li a0, DIR_RIGHT
    call spawn_bullet
    j end_check_shoot_input


end_check_shoot_input:
    lw ra, 0(sp)
    addi sp, sp, 4

    ret

# ------------------------------------------------------------
# spawn_bullet
# Cria um tiro no primeiro slot livre.
#
# Entrada:
#   a0 = direcao do tiro
#
# Saida:
#   primeiro bullet_active = 0 vira ativo
#
# Modifica: t0-t6
# ------------------------------------------------------------

spawn_bullet:
    la t0, bullet_active
    li t1, 0

find_free_bullet_loop:
    li t2, MAX_BULLETS
    beq t1, t2, end_spawn_bullet

    slli t3, t1, 2
    add t4, t0, t3
    lw t5, 0(t4)

    beqz t5, create_bullet_here

    addi t1, t1, 1
    j find_free_bullet_loop


create_bullet_here:
    # Marca como ativo
    li t5, BULLET_ACTIVE
    sw t5, 0(t4)

    # bullet_x = player_x + 4
    la t0, player_x
    lw t5, 0(t0)
    addi t5, t5, 4

    la t0, bullet_x
    add t6, t0, t3
    sw t5, 0(t6)

    # bullet_y = player_y + 4
    la t0, player_y
    lw t5, 0(t0)
    addi t5, t5, 4

    la t0, bullet_y
    add t6, t0, t3
    sw t5, 0(t6)

    # bullet_direction = a0
    la t0, bullet_direction
    add t6, t0, t3
    sw a0, 0(t6)

    li t5, WEAPON_NORMAL_DAMAGE

    la t0, weapon_type
    lw t6, 0(t0)
    li t0, WEAPON_BOSS
    bne t6, t0, normal_weapon_fire

    la t0, boss_ammo_count
    lw t6, 0(t0)
    blez t6, normal_weapon_fire
    addi t6, t6, -1
    sw t6, 0(t0)
    li t5, WEAPON_BOSS_DAMAGE
    j store_bullet_damage

normal_weapon_fire:
    la t0, normal_ammo_count
    lw t6, 0(t0)
    blez t6, store_bullet_damage
    addi t6, t6, -1
    sw t6, 0(t0)

store_bullet_damage:
    la t0, bullet_damage
    add t6, t0, t3
    sw t5, 0(t6)

end_spawn_bullet:
    ret


# ------------------------------------------------------------
# move_bullets
# Move todos os tiros ativos.
# Remove tiro se sair da tela.
# ------------------------------------------------------------

move_bullets:
    li t1, 0

move_bullets_loop:
    li t2, MAX_BULLETS
    beq t1, t2, end_move_bullets

    slli t3, t1, 2

    # Verifica se ativo
    la t0, bullet_active
    add t4, t0, t3
    lw t5, 0(t4)
    beqz t5, next_bullet

    # Le direcao
    la t0, bullet_direction
    add t4, t0, t3
    lw t5, 0(t4)

    li t6, DIR_UP
    beq t5, t6, move_bullet_up

    li t6, DIR_DOWN
    beq t5, t6, move_bullet_down

    li t6, DIR_LEFT
    beq t5, t6, move_bullet_left

    li t6, DIR_RIGHT
    beq t5, t6, move_bullet_right

    j next_bullet


move_bullet_up:
    la t0, bullet_y
    add t4, t0, t3
    lw t5, 0(t4)

    li t6, BULLET_SPEED
    sub t5, t5, t6

    blt t5, zero, deactivate_current_bullet

    sw t5, 0(t4)
    j next_bullet


move_bullet_down:
    la t0, bullet_y
    add t4, t0, t3
    lw t5, 0(t4)

    li t6, BULLET_SPEED
    add t5, t5, t6

    li t6, SCREEN_HEIGHT
    bge t5, t6, deactivate_current_bullet

    sw t5, 0(t4)
    j next_bullet


move_bullet_left:
    la t0, bullet_x
    add t4, t0, t3
    lw t5, 0(t4)

    li t6, BULLET_SPEED
    sub t5, t5, t6

    blt t5, zero, deactivate_current_bullet

    sw t5, 0(t4)
    j next_bullet


move_bullet_right:
    la t0, bullet_x
    add t4, t0, t3
    lw t5, 0(t4)

    li t6, BULLET_SPEED
    add t5, t5, t6

    li t6, SCREEN_WIDTH
    bge t5, t6, deactivate_current_bullet

    sw t5, 0(t4)
    j next_bullet


deactivate_current_bullet:
    la t0, bullet_active
    add t4, t0, t3
    sw zero, 0(t4)

next_bullet:
    addi t1, t1, 1
    j move_bullets_loop

end_move_bullets:
    ret
