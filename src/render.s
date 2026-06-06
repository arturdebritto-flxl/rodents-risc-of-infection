# ============================================================
# Rotinas de renderizacao simples
# ============================================================

.text

# ------------------------------------------------------------
# begin_frame
# Limpa o frame atual de desenho.
#
# Entrada: draw_frame
# Saida: frame atual limpo
# Modifica: t0, t1, a0, a1, a7
# ------------------------------------------------------------

begin_frame:
    la t0, draw_frame
    lw t1, 0(t0)

    li a0, 0x00
    mv a1, t1
    li a7, 148
    ecall

    ret

# ------------------------------------------------------------
# end_frame
# Mostra o frame recem desenhado e alterna draw_frame.
#
# Entrada: draw_frame
# Saida: frame exibido e draw_frame alternado
# Modifica: t0, t1
# ------------------------------------------------------------

end_frame:
    la t0, draw_frame
    lw t1, 0(t0)

    li t0, VGAFRAMESELECT
    sw t1, 0(t0)

    xori t1, t1, 1

    la t0, draw_frame
    sw t1, 0(t0)

    ret

# ------------------------------------------------------------
# get_draw_base_address
# Retorna em a0 o endereco base do frame atual de desenho.
#
# Entrada: draw_frame
# Saida: a0 = VGAADDRESSINI0 ou VGAADDRESSINI1
# Modifica: t0, t1
# ------------------------------------------------------------

get_draw_base_address:
    la t0, draw_frame
    lw t1, 0(t0)

    li a0, VGAADDRESSINI0
    beqz t1, end_get_draw_base_address

    li a0, VGAADDRESSINI1

end_get_draw_base_address:
    ret

# ------------------------------------------------------------
# draw_player_square
# Desenha o jogador como um quadrado 8x8.
#
# Entrada:
#   player_x
#   player_y
#   draw_frame
#
# Saida:
#   pixels escritos no frame atual de desenho
#
# Modifica:
#   t0-t6, a0-a4
# ------------------------------------------------------------

draw_player_square:
    addi sp, sp, -4
    sw ra, 0(sp)

    call get_draw_base_address
    mv t2, a0

    la t0, player_x
    lw t3, 0(t0)

    la t0, player_y
    lw t4, 0(t0)

    li t5, 0

player_row_loop:
    li t6, 0

    add a0, t4, t5

    slli a1, a0, 8
    slli a2, a0, 6
    add a1, a1, a2
    add a1, a1, t3

    add a1, a1, t2

player_col_loop:
    add a2, a1, t6

    li a3, 0xFF
    sb a3, 0(a2)

    addi t6, t6, 1
    li a4, 8
    blt t6, a4, player_col_loop

    addi t5, t5, 1
    li a4, 8
    blt t5, a4, player_row_loop

    lw ra, 0(sp)
    addi sp, sp, 4

    ret

# ------------------------------------------------------------
# draw_bullets
# Desenha todos os tiros ativos como quadrados 3x3.
#
# Entrada:
#   bullet_x
#   bullet_y
#   bullet_active
#   draw_frame
#
# Saida:
#   pixels dos tiros escritos no frame atual
#
# Modifica:
#   t0-t6, a0-a4
# ------------------------------------------------------------

draw_bullets:
    addi sp, sp, -4
    sw ra, 0(sp)

    # Pega endereco base do frame atual de desenho
    call get_draw_base_address
    mv t2, a0                  # t2 = base do framebuffer

    li t1, 0                   # indice do tiro atual

draw_bullets_loop:
    li t3, MAX_BULLETS
    beq t1, t3, end_draw_bullets

    # offset = indice * 4
    slli t4, t1, 2

    # Verifica bullet_active[indice]
    la t0, bullet_active
    add t5, t0, t4
    lw t6, 0(t5)

    # Se nao esta ativo, pula
    beqz t6, next_draw_bullet

    # Carrega bullet_x[indice] em a0
    la t0, bullet_x
    add t5, t0, t4
    lw a0, 0(t5)

    # Carrega bullet_y[indice] em a1
    la t0, bullet_y
    add t5, t0, t4
    lw a1, 0(t5)

    # Protecao: x precisa estar entre 0 e 317
    blt a0, zero, next_draw_bullet
    li t6, 317
    bgt a0, t6, next_draw_bullet

    # Protecao: y precisa estar entre 0 e 237
    blt a1, zero, next_draw_bullet
    li t6, 237
    bgt a1, t6, next_draw_bullet

    # Guarda x e y do tiro
    mv a2, a0                  # a2 = x
    mv a3, a1                  # a3 = y

    # Linha local do quadrado 3x3
    li a4, 0

bullet_row_loop:
    # Coluna local do quadrado 3x3
    li t5, 0

    # y_real = y + linha
    add t6, a3, a4

    # offset = y_real * 320 + x
    # 320 = 256 + 64
    slli a0, t6, 8             # y * 256
    slli a1, t6, 6             # y * 64
    add a0, a0, a1             # y * 320
    add a0, a0, a2             # + x
    add a0, a0, t2             # + base framebuffer

bullet_col_loop:
    # endereco do pixel atual
    add a1, a0, t5

    # cor do tiro: amarelo
    li t6, 0xE7
    sb t6, 0(a1)

    addi t5, t5, 1
    li t6, 3
    blt t5, t6, bullet_col_loop

    addi a4, a4, 1
    li t6, 3
    blt a4, t6, bullet_row_loop

next_draw_bullet:
    addi t1, t1, 1
    j draw_bullets_loop

end_draw_bullets:
    lw ra, 0(sp)
    addi sp, sp, 4

    ret

# ------------------------------------------------------------
# draw_enemies
# Desenha inimigos ativos como quadrados verdes 8x8.
# ------------------------------------------------------------

draw_enemies:
    addi sp, sp, -4
    sw ra, 0(sp)

    call get_draw_base_address
    mv t2, a0

    li t1, 0

draw_enemies_loop:
    li t3, MAX_ENEMIES
    beq t1, t3, end_draw_enemies

    slli t4, t1, 2

    la t0, enemy_active
    add t5, t0, t4
    lw t6, 0(t5)
    beqz t6, next_draw_enemy

    la t0, enemy_x
    add t5, t0, t4
    lw a0, 0(t5)

    la t0, enemy_y
    add t5, t0, t4
    lw a1, 0(t5)

    blt a0, zero, next_draw_enemy
    li t6, 312
    bgt a0, t6, next_draw_enemy

    blt a1, zero, next_draw_enemy
    li t6, 232
    bgt a1, t6, next_draw_enemy

    mv a2, a0
    mv a3, a1
    li a4, 0

enemy_row_loop:
    li t5, 0

    add t6, a3, a4

    slli a0, t6, 8
    slli a1, t6, 6
    add a0, a0, a1
    add a0, a0, a2
    add a0, a0, t2

enemy_col_loop:
    add a1, a0, t5

    li t6, 0x1C
    sb t6, 0(a1)

    addi t5, t5, 1
    li t6, 8
    blt t5, t6, enemy_col_loop

    addi a4, a4, 1
    li t6, 8
    blt a4, t6, enemy_row_loop

next_draw_enemy:
    addi t1, t1, 1
    j draw_enemies_loop

end_draw_enemies:
    lw ra, 0(sp)
    addi sp, sp, 4
    
    ret

# ------------------------------------------------------------
# draw_enemy_bullets
# Desenha projeteis inimigos ativos como quadrados 3x3.
#
# Entrada:
#   enemy_bullet_x
#   enemy_bullet_y
#   enemy_bullet_active
#
# Saida:
#   pixels escritos no frame atual
#
# Modifica: t0-t6, a0-a4
# ------------------------------------------------------------

draw_enemy_bullets:
    addi sp, sp, -4
    sw ra, 0(sp)

    call get_draw_base_address
    mv t2, a0

    li t1, 0

draw_enemy_bullets_loop:
    li t3, MAX_ENEMY_BULLETS
    beq t1, t3, end_draw_enemy_bullets

    slli t4, t1, 2

    # verifica se ativo
    la t0, enemy_bullet_active
    add t5, t0, t4
    lw t6, 0(t5)
    beqz t6, next_draw_enemy_bullet

    # a0 = x
    la t0, enemy_bullet_x
    add t5, t0, t4
    lw a0, 0(t5)

    # a1 = y
    la t0, enemy_bullet_y
    add t5, t0, t4
    lw a1, 0(t5)

    # segurança x
    blt a0, zero, next_draw_enemy_bullet
    li t6, 317
    bgt a0, t6, next_draw_enemy_bullet

    # segurança y
    blt a1, zero, next_draw_enemy_bullet
    li t6, 237
    bgt a1, t6, next_draw_enemy_bullet

    # guarda x/y
    mv a2, a0
    mv a3, a1

    li a4, 0

enemy_bullet_row_loop:
    li t5, 0

    # y real
    add t6, a3, a4

    # offset = y * 320 + x
    slli a0, t6, 8
    slli a1, t6, 6
    add a0, a0, a1
    add a0, a0, a2
    add a0, a0, t2

enemy_bullet_col_loop:
    add a1, a0, t5

    # cor do projetil inimigo
    li t6, 0xF0
    sb t6, 0(a1)

    addi t5, t5, 1
    li t6, 3
    blt t5, t6, enemy_bullet_col_loop

    addi a4, a4, 1
    li t6, 3
    blt a4, t6, enemy_bullet_row_loop

next_draw_enemy_bullet:
    addi t1, t1, 1
    j draw_enemy_bullets_loop

end_draw_enemy_bullets:
    lw ra, 0(sp)
    addi sp, sp, 4

    ret

# ------------------------------------------------------------
# draw_boss_square
# Desenha o boss ativo como quadrado 16x16.
#
# Entrada:
#   boss_active
#   boss_x
#   boss_y
#
# Saida:
#   pixels escritos no frame atual
#
# Modifica: t0-t6, a0-a4
# ------------------------------------------------------------

draw_boss_square:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, boss_active
    lw t1, 0(t0)
    beqz t1, end_draw_boss_square

    call get_draw_base_address
    mv t2, a0

    la t0, boss_x
    lw t3, 0(t0)

    la t0, boss_y
    lw t4, 0(t0)

    li t5, 0

boss_row_loop:
    li t6, 0

    add a0, t4, t5

    slli a1, a0, 8
    slli a2, a0, 6
    add a1, a1, a2
    add a1, a1, t3
    add a1, a1, t2

boss_col_loop:
    add a2, a1, t6

    # cor do boss
    li a3, 0xC4
    sb a3, 0(a2)

    addi t6, t6, 1
    li a4, BOSS_SIZE
    blt t6, a4, boss_col_loop

    addi t5, t5, 1
    li a4, BOSS_SIZE
    blt t5, a4, boss_row_loop

end_draw_boss_square:
    lw ra, 0(sp)
    addi sp, sp, 4

    ret

# ------------------------------------------------------------
# draw_menu_screen
# Desenha tela inicial simples.
# Mostra códigos numéricos provisórios:
#   2043 = ano/tema
#   1    = pressione start
# ------------------------------------------------------------


draw_menu_screen:
    la t0, draw_frame
    lw t1, 0(t0)

    li a0, 2043
    li a1, 120
    li a2, 80
    li a3, 0x000000FF
    mv a4, t1
    li a7, 101
    ecall

    li a0, 1
    li a1, 150
    li a2, 120
    li a3, 0x000000FF
    mv a4, t1
    li a7,101
    ecall

    ret

# ------------------------------------------------------------
# draw_game_over_screen
# Desenha tela de derrota simples.
# Mostra:
#   404 = game over provisório
#   score
# ------------------------------------------------------------

draw_game_over_screen:
    la t0, draw_frame
    lw t1, 0(t0)

    # 404 = derrota provisória
    li a0, 404
    li a1, 130
    li a2, 80
    li a3, 0x000000FF
    mv a4, t1
    li a7, 101
    ecall

    # score
    la t0, score
    lw a0, 0(t0)
    li a1, 130
    li a2, 120
    li a3, 0x000000FF
    mv a4, t1
    li a7, 101
    ecall

    ret

# ------------------------------------------------------------
# draw_victory_screen
# Desenha tela de vitória simples.
# Mostra:
#   200 = vitória provisória
#   score
# ------------------------------------------------------------

draw_victory_screen:
    la t0, draw_frame
    lw t1, 0(t0)

    # 200 = vitória provisória
    li a0, 200
    li a1, 130
    li a2, 80
    li a3, 0x000000FF
    mv a4, t1
    li a7, 101
    ecall

    # score
    la t0, score
    lw a0, 0(t0)
    li a1, 130
    li a2, 120
    li a3, 0x000000FF
    mv a4, t1
    li a7, 101
    ecall

    ret
    
