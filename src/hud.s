# ============================================================
# HUD do jogo
# ============================================================

.text

# ------------------------------------------------------------
# draw_hud
# Desenha informações principais do jogo.
#
# Layout numerico:
#   x=8    score
#   x=80   vidas
#   x=120  level
#   x=160  wave
#   x=200  inimigos restantes
#   x=260  boss_hp, se boss ativo
#
# Entrada: variaveis globais
# Saida: HUD desenhado no frame atual
# Modifica: t0, t1, a0-a4, a7
# ------------------------------------------------------------

draw_hud:
    la t0, draw_frame
    lw t1, 0(t0)

    la t0, score
    lw a0, 0(t0)
    li a1, 8
    li a2, 8
    li a3, 0x000000FF
    mv a4, t1
    li a7, 101
    ecall

    la t0, player_lives
    lw a0, 0(t0)
    li a1, 80
    li a2, 8
    li a3, 0x000000FF
    mv a4, t1
    li a7, 101
    ecall

    la t0, current_level
    lw a0, 0(t0)
    li a1, 120
    li a2, 8
    li a3, 0x000000FF
    mv a4, t1
    li a7, 101
    ecall

    la t0, current_wave
    lw a0, 0(t0)
    li a1, 160
    li a2, 8
    li a3, 0x000000FF
    mv a4, t1
    li a7, 101
    ecall

    la t0, remaining_enemies
    lw a0, 0(t0)
    li a1, 200
    li a2, 8
    li a3, 0x000000FF
    mv a4, t1
    li a7, 101
    ecall

    la t0, boss_active
    lw t2, 0(t0)
    beqz t2, end_draw_hud

    la t0, boss_hp
    lw a0, 0(t0)
    li a1, 260
    li a2, 8
    li a3, 0x000000FF
    mv a4, t1
    li a7, 101
    ecall

end_draw_hud:
    ret
