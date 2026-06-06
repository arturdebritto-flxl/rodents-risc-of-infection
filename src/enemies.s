# ============================================================
# Logica dos inimigos/ratos
# ============================================================

.text

# ------------------------------------------------------------
# init_enemies
# Desativa todos os inimigos.
# ------------------------------------------------------------

init_enemies:
    li t1, 0

init_enemies_loop:
    li t2, MAX_ENEMIES
    beq t1, t2, end_init_enemies

    slli t3, t1, 2

    la t0, enemy_active
    add t4, t0, t3
    sw zero, 0(t4)

    la t0, enemy_hp
    add t4, t0, t3
    sw zero, 0(t4)

    la t0, enemy_attack_timer
    add t4, t0, t3
    sw zero, 0(t4)

    addi t1, t1, 1
    j init_enemies_loop

end_init_enemies:
    ret


# ------------------------------------------------------------
# spawn_wave_if_needed
# Cria os inimigos da wave atual se ainda nao foram criados.
# ------------------------------------------------------------

spawn_wave_if_needed:
    addi sp, sp, -4
    sw ra, 0(sp)

    # So cria inimigos durante gameplay
    la t0, game_state
    lw t1, 0(t0)

    li t2, STATE_LEVEL1
    beq t1, t2, spawn_wave_state_ok

    li t2, STATE_LEVEL2
    beq t1, t2, spawn_wave_state_ok

    li t2, STATE_BOSS
    beq t1, t2, spawn_wave_state_ok

    j end_spawn_wave_if_needed

spawn_wave_state_ok:
    la t0, wave_spawned
    lw t1, 0(t0)
    bnez t1, end_spawn_wave_if_needed

    la t0, remaining_enemies
    lw t1, 0(t0)
    beqz t1, end_spawn_wave_if_needed

    call spawn_current_enemy_wave

    la t0, wave_spawned
    li t1, 1
    sw t1, 0(t0)

end_spawn_wave_if_needed:
    lw ra, 0(sp)
    addi sp, sp, 4

    ret


# ------------------------------------------------------------
# spawn_current_enemy_wave
# Ativa N inimigos conforme remaining_enemies.
# Nao passa de MAX_ENEMIES.
# ------------------------------------------------------------

spawn_current_enemy_wave:
    addi sp, sp, -4
    sw ra, 0(sp)

    call init_enemies

    la t0, remaining_enemies
    lw a6, 0(t0)                    # a6 = quantidade desejada

    li t2, MAX_ENEMIES
    ble a6, t2, spawn_count_ok
    li a6, MAX_ENEMIES

spawn_count_ok:
    li t2, 0                        # indice

spawn_enemy_loop:
    beq t2, a6, end_spawn_current_enemy_wave

    slli t3, t2, 2                  # offset = indice * 4

    # active = 1
    la t0, enemy_active
    add t4, t0, t3
    li t5, 1
    sw t5, 0(t4)

    # --------------------------------------------------------
    # Define tipo e HP conforme fase/indice.
    # --------------------------------------------------------

    la t0, current_level
    lw t5, 0(t0)

    li t6, LEVEL_TOWN
    beq t5, t6, spawn_type_town

    li t6, LEVEL_SEWER
    beq t5, t6, spawn_type_sewer

    li t6, LEVEL_LABORATORY
    beq t5, t6, spawn_type_laboratory

    j spawn_type_common

spawn_type_town:
    # Town: a cada 4 inimigos, um RAT_ECHO; resto comum
    andi t6, t2, 3
    beqz t6, spawn_type_echo
    j spawn_type_common

spawn_type_sewer:
    # Sewer: mistura comum, Echo e Mutant
    andi t6, t2, 3
    beqz t6, spawn_type_mutant

    li t5, 1
    beq t6, t5, spawn_type_echo

    j spawn_type_common

spawn_type_laboratory:
    # Laboratory: mais inimigos resistentes/sensoriais
    andi t6, t2, 3

    beqz t6, spawn_type_mutant

    li t5, 1
    beq t6, t5, spawn_type_echo

    li t5, 2
    beq t6, t5, spawn_type_spitter

    j spawn_type_common

spawn_type_common:
    la t0, enemy_type
    add t4, t0, t3
    li t5, RAT_COMMON
    sw t5, 0(t4)

    la t0, enemy_hp
    add t4, t0, t3
    li t5, RAT_COMMON_HP
    sw t5, 0(t4)

    j end_spawn_type

spawn_type_echo:
    la t0, enemy_type
    add t4, t0, t3
    li t5, RAT_ECHO
    sw t5, 0(t4)

    la t0, enemy_hp
    add t4, t0, t3
    li t5, RAT_ECHO_HP
    sw t5, 0(t4)

    j end_spawn_type

spawn_type_mutant:
    la t0, enemy_type
    add t4, t0, t3
    li t5, RAT_MUTANT
    sw t5, 0(t4)

    la t0, enemy_hp
    add t4, t0, t3
    li t5, RAT_MUTANT_HP
    sw t5, 0(t4)

    j end_spawn_type

spawn_type_spitter:
    la t0, enemy_type
    add t4, t0, t3
    li t5, RAT_SPITTER
    sw t5, 0(t4)

    la t0, enemy_hp
    add t4, t0, t3
    li t5, RAT_SPITTER_HP
    sw t5, 0(t4)

    j end_spawn_type

end_spawn_type:
    la t0, enemy_attack_timer
    add t4, t0, t3
    sw zero, 0(t4)

    # --------------------------------------------------------
    # Posicao inicial espalhada nas bordas
    # indice % 4:
    #   0 -> topo
    #   1 -> baixo
    #   2 -> esquerda
    #   3 -> direita
    # --------------------------------------------------------

    andi t6, t2, 3

    beqz t6, spawn_enemy_top

    li t5, 1
    beq t6, t5, spawn_enemy_bottom

    li t5, 2
    beq t6, t5, spawn_enemy_left

    j spawn_enemy_right

spawn_enemy_top:
    li t5, 18
    mul t5, t2, t5
    addi t5, t5, 20

    li t6, 300
    ble t5, t6, spawn_top_x_ok
    li t5, 300

spawn_top_x_ok:
    la t0, enemy_x
    add t4, t0, t3
    sw t5, 0(t4)

    la t0, enemy_y
    add t4, t0, t3
    li t5, 10
    sw t5, 0(t4)

    j end_spawn_enemy_position

spawn_enemy_bottom:
    li t5, 18
    mul t5, t2, t5

    li t6, 300
    sub t5, t6, t5

    li t6, 20
    bge t5, t6, spawn_bottom_x_ok
    li t5, 20

spawn_bottom_x_ok:
    la t0, enemy_x
    add t4, t0, t3
    sw t5, 0(t4)

    la t0, enemy_y
    add t4, t0, t3
    li t5, 220
    sw t5, 0(t4)

    j end_spawn_enemy_position

spawn_enemy_left:
    la t0, enemy_x
    add t4, t0, t3
    li t5, 10
    sw t5, 0(t4)

    li t5, 12
    mul t5, t2, t5
    addi t5, t5, 20

    li t6, 220
    ble t5, t6, spawn_left_y_ok
    li t5, 220

spawn_left_y_ok:
    la t0, enemy_y
    add t4, t0, t3
    sw t5, 0(t4)

    j end_spawn_enemy_position

spawn_enemy_right:
    la t0, enemy_x
    add t4, t0, t3
    li t5, 300
    sw t5, 0(t4)

    li t5, 12
    mul t5, t2, t5

    li t6, 220
    sub t5, t6, t5

    li t6, 20
    bge t5, t6, spawn_right_y_ok
    li t5, 20

spawn_right_y_ok:
    la t0, enemy_y
    add t4, t0, t3
    sw t5, 0(t4)

end_spawn_enemy_position:
    addi t2, t2, 1
    j spawn_enemy_loop

end_spawn_current_enemy_wave:
    lw ra, 0(sp)
    addi sp, sp, 4

    ret


# ------------------------------------------------------------
# update_enemies
# Move inimigos ativos conforme tipo.
# ------------------------------------------------------------

update_enemies:
    addi sp, sp, -4
    sw ra, 0(sp)

    # So atualiza inimigos durante gameplay
    la t0, game_state
    lw t1, 0(t0)

    li t2, STATE_LEVEL1
    beq t1, t2, update_enemies_state_ok

    li t2, STATE_LEVEL2
    beq t1, t2, update_enemies_state_ok

    li t2, STATE_BOSS
    beq t1, t2, update_enemies_state_ok

    j end_update_enemies

update_enemies_state_ok:
    li t1, 0

update_enemies_loop:
    li t2, MAX_ENEMIES
    beq t1, t2, end_update_enemies

    slli t3, t1, 2                # offset = indice * 4

    # Se inativo, pula
    la t0, enemy_active
    add t4, t0, t3
    lw t5, 0(t4)
    beqz t5, next_update_enemy

    # Le tipo do inimigo
    la t0, enemy_type
    add t4, t0, t3
    lw t5, 0(t4)

    li t6, RAT_ECHO
    beq t5, t6, update_enemy_echo

    li t6, RAT_MUTANT
    beq t5, t6, update_enemy_mutant

    li t6, RAT_SPITTER
    beq t5, t6, update_enemy_spitter

    j update_enemy_common

update_enemy_common:
    li a5, RAT_COMMON_SPEED
    j move_rat_towards_player

update_enemy_echo:
    # RAT_ECHO so anda se o jogador se moveu neste frame
    la t0, player_moved
    lw t6, 0(t0)
    beqz t6, next_update_enemy

    li a5, RAT_ECHO_SPEED
    j move_rat_towards_player

update_enemy_mutant:
    li a5, RAT_MUTANT_SPEED
    j move_rat_towards_player

update_enemy_spitter:
    # Incrementa enemy_attack_timer[indice]
    la t0, enemy_attack_timer
    add t4, t0, t3
    lw t5, 0(t4)

    addi t5, t5, 1

    li t6, SPITTER_SHOOT_DELAY
    blt t5, t6, store_spitter_timer

    sw zero, 0(t4)

    # Salva indice e offset antes de chamar spawn_enemy_bullet
    addi sp, sp, -8
    sw t1, 0(sp)
    sw t3, 4(sp)

    # a0 = enemy_x + 4
    la t0, enemy_x
    add t4, t0, t3
    lw a0, 0(t4)
    addi a0, a0, 4

    # a1 = enemy_y + 4
    la t0, enemy_y
    add t4, t0, t3
    lw a1, 0(t4)
    addi a1, a1, 4

    # Decide direcao simples do tiro comparando posicao do player e do inimigo
    la t0, player_x
    lw t5, 0(t0)

    la t0, enemy_x
    add t4, t0, t3
    lw t6, 0(t4)

    blt t5, t6, spitter_shoot_left

spitter_shoot_right:
    li a2, ENEMY_BULLET_SPEED
    li a3, 0
    call spawn_enemy_bullet
    j end_spitter_shoot_call

spitter_shoot_left:
    li a2, -3
    li a3, 0
    call spawn_enemy_bullet

end_spitter_shoot_call:
    lw t3, 4(sp)
    lw t1, 0(sp)
    addi sp, sp, 8

    j next_update_enemy


store_spitter_timer:
    sw t5, 0(t4)

    la t0, enemy_x
    add t4, t0, t3
    lw t5, 0(t4)

    la t0, player_x
    lw t6, 0(t0)

    sub a0, t5, t6
    li a1, 24
    bgt a0, a1, next_update_enemy

    li a1, -24
    blt a0, a1, next_update_enemy

    blt t5, t6, spitter_back_left

spitter_back_right:
    addi t5, t5, RAT_SPITTER_SPEED
    sw t5, 0(t4)
    j next_update_enemy

spitter_back_left:
    addi t5, t5, -1
    sw t5, 0(t4)
    j next_update_enemy

move_rat_towards_player:
    # mover x em direcao ao player_x
    la t0, enemy_x
    add t4, t0, t3
    lw t5, 0(t4)

    la t0, player_x
    lw t6, 0(t0)

    blt t5, t6, rat_move_right
    bgt t5, t6, rat_move_left
    j rat_update_y

rat_move_right:
    add t5, t5, a5
    sw t5, 0(t4)
    j rat_update_y

rat_move_left:
    sub t5, t5, a5
    sw t5, 0(t4)

rat_update_y:
    la t0, enemy_y
    add t4, t0, t3
    lw t5, 0(t4)

    la t0, player_y
    lw t6, 0(t0)

    blt t5, t6, rat_move_down
    bgt t5, t6, rat_move_up
    j next_update_enemy

rat_move_down:
    add t5, t5, a5
    sw t5, 0(t4)
    j next_update_enemy

rat_move_up:
    sub t5, t5, a5
    sw t5, 0(t4)

next_update_enemy:
    addi t1, t1, 1
    j update_enemies_loop

end_update_enemies:
    lw ra, 0(sp)
    addi sp, sp, 4

    ret
