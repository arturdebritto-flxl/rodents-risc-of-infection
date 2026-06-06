# ============================================================
# Entrada de teclado
# ============================================================

.text

# ------------------------------------------------------------
# read_input
# Le o teclado de forma nao bloqueante.
#
# Entrada: nenhuma
# Saida:
#   key_pressed = 1 se tecla foi lida
#   key_pressed = 0 se nenhuma tecla foi lida
#   last_key = ASCII da tecla, se houver
# Modifica: t0, t1, t2
# ------------------------------------------------------------

read_input:
    la t0, key_pressed
    sw zero, 0(t0)

    li t0, KDMMIO_Ctrl
    lw t1, 0(t0)

    andi t1, t1, 1
    beqz t1, end_read_input

    li t0, KDMMIO_Data
    lw t2, 0(t0)

    la t0, last_key
    sw t2, 0(t0)

    la t0, key_pressed
    li t1, 1
    sw t1, 0(t0)

end_read_input:
    ret

# ------------------------------------------------------------
# clear_input_frame
# Limpa a tecla lida no frame atual.
#
# Entrada: nenhuma
# Saida:
#   key_pressed = 0
#   last_key = 0
# Modifica: t0
# ------------------------------------------------------------

clear_input_frame:
    la t0, key_pressed
    sw zero, 0(t0)

    la t0, last_key
    sw zero, 0(t0)

    ret
