# ============================================================
# Teste standalone: som de explosao
# Abra este arquivo no RARS e execute.
#
# Ideia: estalo inicial -> boom principal -> onda de choque -> detritos.
# ============================================================

.text
.globl main

main:
    # Estalo seco inicial.
    li a0, 84
    li a1, 120
    li a2, 127
    li a3, 118
    li a7, 31
    ecall

    li a0, 70
    li a1, 180
    li a2, 127
    li a3, 96
    li a7, 31
    ecall

    # Pequena distancia entre o flash e a onda de choque.
    li a0, 180
    li a7, 32
    ecall

    # Boom principal: forte, grave, mas sem embolar.
    li a0, 31
    li a1, 1400
    li a2, 118
    li a3, 127
    li a7, 31
    ecall

    li a0, 38
    li a1, 950
    li a2, 118
    li a3, 118
    li a7, 31
    ecall

    li a0, 43
    li a1, 700
    li a2, 55
    li a3, 98
    li a7, 31
    ecall

    # Onda de choque descendo.
    li a0, 260
    li a7, 32
    ecall

    li a0, 36
    li a1, 900
    li a2, 55
    li a3, 112
    li a7, 31
    ecall

    li a0, 220
    li a7, 32
    ecall

    li a0, 29
    li a1, 1300
    li a2, 55
    li a3, 106
    li a7, 31
    ecall

    li a0, 260
    li a7, 32
    ecall

    li a0, 24
    li a1, 1900
    li a2, 88
    li a3, 84
    li a7, 31
    ecall

    # Detritos e colapso depois do impacto.
    li a0, 420
    li a7, 32
    ecall

    li a0, 64
    li a1, 90
    li a2, 127
    li a3, 72
    li a7, 31
    ecall

    li a0, 170
    li a7, 32
    ecall

    li a0, 52
    li a1, 160
    li a2, 118
    li a3, 82
    li a7, 31
    ecall

    li a0, 240
    li a7, 32
    ecall

    li a0, 47
    li a1, 240
    li a2, 118
    li a3, 70
    li a7, 31
    ecall

    # Cauda grave final.
    li a0, 19
    li a1, 2600
    li a2, 88
    li a3, 68
    li a7, 31
    ecall

    li a0, 3000
    li a7, 32
    ecall

    li a7, 10
    ecall
