# ============================================================
# Teste standalone: contagem regressiva do detonador
# Abra este arquivo no RARS e execute.
#
# Ideia: tres bipes crescentes e um sinal final antes da explosao.
# ============================================================

.text
.globl main

main:
    # 3, 2, 1
    li a0, 72
    li a1, 90
    li a2, 80
    li a3, 96
    li a7, 31
    ecall

    li a0, 600
    li a7, 32
    ecall

    li a0, 76
    li a1, 90
    li a2, 80
    li a3, 96
    li a7, 31
    ecall

    li a0, 600
    li a7, 32
    ecall

    li a0, 80
    li a1, 90
    li a2, 80
    li a3, 96
    li a7, 31
    ecall

    li a0, 600
    li a7, 32
    ecall

    # Sinal final: explosao imediata depois deste beep longo.
    li a0, 84
    li a1, 320
    li a2, 80
    li a3, 112
    li a7, 31
    ecall

    li a0, 420
    li a7, 32
    ecall

    li a7, 10
    ecall
