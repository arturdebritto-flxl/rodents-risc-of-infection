# ============================================================
# Logica do jogador
# ============================================================

.text

# ------------------------------------------------------------
# init_player
# Reinicializa posicao, direcao e vidas do jogador.
#
# Entrada: nenhuma
# Saida: dados do jogador restaurados
# Modifica: t0, t1
# ------------------------------------------------------------

init_player:
    la t0, player_x
    li t1, PLAYER_START_X
    sw t1, 0(t0)

    la t0, player_y
    li t1, PLAYER_START_Y
    sw t1, 0(t0)

    la t0, player_direction
    li t1, DIR_DOWN
    sw t1, 0(t0)

    la t0, player_lives
    li t1, 3 
    sw t1, 0(t0)

    la t0, player_moved
    sw zero, 0(t0)

    ret

# ------------------------------------------------------------
# update_player
# Atualiza a posicao do jogador com base em last_key.
#
# Teclas:
#   w = cima
#   s = baixo
#   a = esquerda
#   d = direita
#
# Entrada: last_key e key_pressed
# Saida: player_x/player_y/player_direction atualizados
# Modifica: t0, t1, t2, t3
# ------------------------------------------------------------

update_player:
    # Por padrao, assume que o jogador nao se moveu neste frame
    la t0, player_moved
    sw zero, 0(t0)

    la t0, key_pressed
    lw t1, 0(t0)
    beqz t1, end_update_player

    la t0, last_key
    lw t1, 0(t0)

    li t2, 'w'
    beq t1, t2, move_player_up

    li t2, 's'
    beq t1, t2, move_player_down

    li t2, 'a'
    beq t1, t2, move_player_left

    li t2, 'd'
    beq t1, t2, move_player_right

    j end_update_player

move_player_up:
    la t0, player_direction
    li t1, DIR_UP
    sw t1, 0(t0)

    la t0, player_y
    lw t1, 0(t0)
    li t2, PLAYER_SPEED
    sub t1, t1, t2

    li t3, PLAYER_MIN_Y
    blt t1, t3, clamp_player_y_min

    sw t1, 0(t0)

    j mark_player_moved

clamp_player_y_min:
    li t1, PLAYER_MIN_Y
    sw t1, 0(t0)
    j mark_player_moved

move_player_down:
    la t0, player_direction
    li t1, DIR_DOWN
    sw t1, 0(t0)

    la t0, player_y
    lw t1, 0(t0)
    li t2, PLAYER_SPEED
    add t1, t1, t2

    li t3, PLAYER_MAX_Y
    bgt t1, t3, clamp_player_y_max

    sw t1, 0(t0)
    j mark_player_moved

clamp_player_y_max:
    li t1, PLAYER_MAX_Y
    sw t1, 0(t0)
    j mark_player_moved

move_player_left:
    la t0, player_direction
    li t1, DIR_LEFT
    sw t1, 0(t0)

    la t0, player_x
    lw t1, 0(t0)
    li t2, PLAYER_SPEED
    sub t1, t1, t2

    li t3, PLAYER_MIN_X
    blt t1, t3, clamp_player_x_min

    sw t1, 0(t0)
    j mark_player_moved

clamp_player_x_min:
    li t1, PLAYER_MIN_X
    sw t1, 0(t0)
    j mark_player_moved

move_player_right:
    la t0, player_direction
    li t1, DIR_RIGHT
    sw t1, 0(t0)

    la t0, player_x
    lw t1, 0(t0)
    li t2, PLAYER_SPEED
    add t1, t1, t2

    li t3, PLAYER_MAX_X
    bgt t1, t3, clamp_player_x_max

    sw t1, 0(t0)
    j mark_player_moved

clamp_player_x_max:
    li t1, PLAYER_MAX_X
    sw t1, 0(t0)
    j mark_player_moved

mark_player_moved:
    la t0, player_moved
    li t1, 1
    sw t1, 0(t0)

end_update_player:
    ret
