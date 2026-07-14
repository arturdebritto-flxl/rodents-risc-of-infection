# ============================================================
# Gerenciamento de fases e hordas
# ============================================================

.text

# ------------------------------------------------------------
# init_level1
# Inicializa os dados específicos da primeira fase: Town.
#
# Entrada: nenhuma
# Saída: contadores da fase 1 configurados
# Modifica: t0, t1
# ------------------------------------------------------------

init_level1:
    la t0, current_wave
    li t1, 1
    sw t1, 0(t0)

    la t0, total_waves
    li t1, TOWN_TOTAL_WAVES
    sw t1, 0(t0)

    la t0, remaining_enemies
    li t1, TOWN_WAVE1_ENEMIES
    sw t1, 0(t0)

    la t0, wave_spawned
    sw zero, 0(t0)

    la t0, town_spawn_timer
    li t1, TOWN_FIRST_SPAWN_DELAY
    sw t1, 0(t0)

    la t0, town_exit_unlocked
    sw zero, 0(t0)
    la t0, town_exit_blink_timer
    sw zero, 0(t0)
    la t0, town_exit_blink_frame
    sw zero, 0(t0)
    la t0, town_exit_transitioned
    sw zero, 0(t0)

    ret

# Retorna a quantidade planejada da wave corrente para a fase ativa.
get_current_wave_enemy_count:
    la t0, game_state
    lw t1, 0(t0)
    li t2, STATE_BOSS
    beq t1, t2, get_boss_support_enemy_count
    la t0, current_level
    lw t1, 0(t0)
    li t2, LEVEL_TOWN
    beq t1, t2, select_town_wave_table
    li t2, LEVEL_SEWER
    beq t1, t2, select_sewer_wave_table
    li t2, LEVEL_LABORATORY
    beq t1, t2, select_lab_wave_table
    mv a0, zero
    ret
select_town_wave_table:
    la t0, town_wave_enemy_counts
    j load_current_wave_enemy_count
select_sewer_wave_table:
    la t0, sewer_wave_enemy_counts
    j load_current_wave_enemy_count
select_lab_wave_table:
    la t0, lab_wave_enemy_counts
load_current_wave_enemy_count:
    la t1, current_wave
    lw t1, 0(t1)
    addi t1, t1, -1
    slli t1, t1, 2
    add t0, t0, t1
    lw a0, 0(t0)
    ret
get_boss_support_enemy_count:
    li a0, BOSS_SUPPORT_ENEMIES
    ret

# ------------------------------------------------------------
# init_level2
# Inicializa os dados especificos da segunda fase: Sewer.
#
# Entrada: nenhuma
# Saida: contadores da fase 2 configurados
# Modifica: t0, t1
# ------------------------------------------------------------

init_level2:
    la t0, current_wave
    li t1, 1
    sw t1, 0(t0)

    la t0, total_waves
    li t1, SEWER_TOTAL_WAVES
    sw t1, 0(t0)

    la t0, remaining_enemies
    li t1, SEWER_WAVE1_ENEMIES
    sw t1, 0(t0)

    la t0, wave_spawned
    sw zero, 0(t0)

    la t0, level_spawn_timer
    li t1, LEVEL_FIRST_SPAWN_DELAY
    sw t1, 0(t0)
    la t0, level_exit_unlocked
    sw zero, 0(t0)
    la t0, level_exit_blink_timer
    sw zero, 0(t0)
    la t0, level_exit_blink_frame
    sw zero, 0(t0)
    la t0, level_exit_transitioned
    sw zero, 0(t0)
    la t0, boss_active
    sw zero, 0(t0)

    ret

# ------------------------------------------------------------
# init_level3
# Inicializa os dados da terceira fase: Laboratory.
# O boss aparecera somente depois da terceira wave.
#
# Entrada: nenhuma
# Saida: contadores iniciais do laboratorio configurados
# Modifica: t0, t1
# ------------------------------------------------------------

init_level3:
    la t0, current_wave
    li t1, 1
    sw t1, 0(t0)

    la t0, total_waves
    li t1, LABORATORY_TOTAL_WAVES
    sw t1, 0(t0)

    la t0, remaining_enemies
    li t1, LABORATORY_WAVE1_ENEMIES
    sw t1, 0(t0)

    la t0, wave_spawned
    sw zero, 0(t0)

    la t0, level_spawn_timer
    li t1, LEVEL_FIRST_SPAWN_DELAY
    sw t1, 0(t0)
    la t0, level_exit_unlocked
    sw zero, 0(t0)
    la t0, level_exit_blink_timer
    sw zero, 0(t0)
    la t0, level_exit_blink_frame
    sw zero, 0(t0)
    la t0, level_exit_transitioned
    sw zero, 0(t0)

    la t0, boss_active
    sw zero, 0(t0)

    ret

# ------------------------------------------------------------
# handle_next_level_cheat
# Preserva C/c como cheat de progressao em gameplay. Na saida liberada do
# Sewer, processa a interacao no mesmo ponto que reconheceu o evento.
# ------------------------------------------------------------
handle_next_level_cheat:
    addi sp, sp, -4
    sw ra, 0(sp)
    mv a0, zero

    la t0, game_state
    lw t1, 0(t0)
    li t2, STATE_LEVEL1
    beq t1, t2, check_next_level_cheat_key
    li t2, STATE_LEVEL2
    beq t1, t2, check_next_level_cheat_key
    li t2, STATE_LEVEL3
    beq t1, t2, check_next_level_cheat_key
    li t2, STATE_BOSS
    bne t1, t2, end_handle_next_level_cheat

check_next_level_cheat_key:
    la t0, key_pressed
    lw t1, 0(t0)
    beqz t1, end_handle_next_level_cheat
    la t0, last_key
    lw t1, 0(t0)
    li t2, 'c'
    beq t1, t2, check_normal_level_interaction
    li t2, 'C'
    bne t1, t2, end_handle_next_level_cheat

check_normal_level_interaction:
    la t0, current_level
    lw t1, 0(t0)
    li t2, LEVEL_SEWER
    beq t1, t2, handle_released_level_interaction
    li t2, LEVEL_LABORATORY
    bne t1, t2, try_next_level_cheat
handle_released_level_interaction:
    la t0, level_exit_unlocked
    lw t2, 0(t0)
    beqz t2, try_next_level_cheat
    call is_player_in_level_exit_range
    beqz a0, try_next_level_cheat

    # No Sewer, conclui a interacao antes que o evento atravesse o frame.
    la t0, current_level
    lw t1, 0(t0)
    li t2, LEVEL_SEWER
    bne t1, t2, defer_released_level_interaction
    call update_level_exit
    mv a0, zero
    la t0, game_state
    lw t1, 0(t0)
    li t2, STATE_CUTSCENE_LEVEL3
    bne t1, t2, end_handle_next_level_cheat
    li a0, 1
    j end_handle_next_level_cheat

defer_released_level_interaction:
    mv a0, zero
    j end_handle_next_level_cheat

try_next_level_cheat:
    la t0, current_level
    lw t1, 0(t0)
    li t2, LEVEL_TOWN
    beq t1, t2, cheat_to_level2
    li t2, LEVEL_SEWER
    beq t1, t2, cheat_to_level3
    li t2, LEVEL_LABORATORY
    bne t1, t2, end_handle_next_level_cheat
    call reset_transient_level_state
    call set_state_cutscene_detonator
    li a0, 1
    j end_handle_next_level_cheat
cheat_to_level2:
    call reset_transient_level_state
    call set_state_cutscene_level2
    li a0, 1
    j end_handle_next_level_cheat
cheat_to_level3:
    call reset_transient_level_state
    call set_state_cutscene_level3
    li a0, 1
end_handle_next_level_cheat:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# Retorna a0=1 quando o centro do jogador esta dentro do trigger logico
# acessivel de Sewer/Lab. INTERACTION nao participa da colisao fisica.
is_player_in_level_exit_range:
    la t0, current_level
    lw t1, 0(t0)
    la t0, player_x
    lw t2, 0(t0)
    addi t2, t2, 8
    la t0, player_y
    lw t3, 0(t0)
    addi t3, t3, 8
    li t4, LEVEL_SEWER
    beq t1, t4, measure_sewer_exit_range
    li t4, LEVEL_LABORATORY
    bne t1, t4, player_outside_level_exit_range
    addi t2, t2, -LAB_EXIT_CENTER_X
    addi t3, t3, -LAB_EXIT_CENTER_Y
    li t4, LAB_EXIT_RADIUS_SQUARED
    j test_player_level_exit_range
measure_sewer_exit_range:
    li t4, SEWER_EXIT_APPROACH_MIN_X
    blt t2, t4, measure_sewer_exit_circle
    li t4, SEWER_EXIT_APPROACH_MAX_X
    bgt t2, t4, measure_sewer_exit_circle
    li t4, SEWER_EXIT_APPROACH_MIN_Y
    blt t3, t4, measure_sewer_exit_circle
    li t4, SEWER_EXIT_APPROACH_MAX_Y
    ble t3, t4, player_inside_level_exit_range
measure_sewer_exit_circle:
    addi t2, t2, -SEWER_EXIT_CENTER_X
    addi t3, t3, -SEWER_EXIT_CENTER_Y
    li t4, SEWER_EXIT_RADIUS_SQUARED
test_player_level_exit_range:
    mul t2, t2, t2
    mul t3, t3, t3
    add t2, t2, t3
    bgt t2, t4, player_outside_level_exit_range
player_inside_level_exit_range:
    li a0, 1
    ret
player_outside_level_exit_range:
    mv a0, zero
    ret

# ------------------------------------------------------------
# reset_transient_level_state
# Limpa entidades e timers de fase sem apagar player/inventario.
# ------------------------------------------------------------

reset_transient_level_state:
    addi sp, sp, -4
    sw ra, 0(sp)

    call init_enemies
    call init_bullets
    call init_enemy_bullets
    call init_powerups
    call init_boss

    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# ------------------------------------------------------------
# advance_wave
# Avanca waves e muda de level quando a wave atual termina.
#
# Entrada: remaining_enemies deve estar em 0 para haver avanco
# Saida: atualiza wave, level ou ativa o boss
# Modifica: t0, t1, t2
# ------------------------------------------------------------

advance_wave:
    addi sp, sp, -8
    sw ra, 0(sp)
    la t0, boss_active
    lw t1, 0(t0)
    bnez t1, end_advance_level_wave
    la t0, remaining_enemies
    lw t1, 0(t0)
    bnez t1, end_advance_level_wave
    call get_current_wave_enemy_count
    sw a0, 4(sp)
    la t0, wave_spawned
    lw t1, 0(t0)
    lw t2, 4(sp)
    bne t1, t2, end_advance_level_wave
    call count_active_enemies
    bnez a0, end_advance_level_wave
    la t0, current_wave
    lw t1, 0(t0)
    la t2, total_waves
    lw t2, 0(t2)
    bge t1, t2, finish_current_level_waves
    addi t1, t1, 1
    sw t1, 0(t0)
    call get_current_wave_enemy_count
    la t0, remaining_enemies
    sw a0, 0(t0)
    la t0, wave_spawned
    sw zero, 0(t0)
    la t0, level_spawn_timer
    li t1, LEVEL_FIRST_SPAWN_DELAY
    sw t1, 0(t0)
    j end_advance_level_wave
finish_current_level_waves:
    call unlock_current_level_exit
end_advance_level_wave:
    lw ra, 0(sp)
    addi sp, sp, 8
    ret

unlock_current_level_exit:
    la t0, level_exit_unlocked
    lw t1, 0(t0)
    bnez t1, end_unlock_current_level_exit
    li t1, 1
    sw t1, 0(t0)
    la t0, level_exit_blink_timer
    sw zero, 0(t0)
    la t0, level_exit_blink_frame
    sw zero, 0(t0)
    la t0, level_exit_transitioned
    sw zero, 0(t0)
end_unlock_current_level_exit:
    ret

# Town preserva o contrato aprovado de proximidade automatica do bueiro.
update_town_exit:
    addi sp, sp, -4
    sw ra, 0(sp)
    la t0, level_exit_unlocked
    lw t1, 0(t0)
    beqz t1, end_update_town_exit
    la t0, level_exit_transitioned
    lw t1, 0(t0)
    bnez t1, end_update_town_exit
    call update_level_exit_blink

    la t0, player_x
    lw t1, 0(t0)
    addi t1, t1, 8
    addi t1, t1, -TOWN_EXIT_CENTER_X
    mul t1, t1, t1
    la t0, player_y
    lw t2, 0(t0)
    addi t2, t2, 8
    addi t2, t2, -TOWN_EXIT_CENTER_Y
    mul t2, t2, t2
    add t1, t1, t2
    li t2, TOWN_EXIT_RADIUS_SQUARED
    bgt t1, t2, end_update_town_exit

    la t0, level_exit_transitioned
    li t1, 1
    sw t1, 0(t0)
    call reset_transient_level_state
    call set_state_cutscene_level2
end_update_town_exit:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# Sewer e Lab exigem proximidade, C/c e uma unica transicao depois das waves.
# Town continua usando a interacao automatica ja aprovada.
update_level_exit:
    addi sp, sp, -8
    sw ra, 0(sp)
    la t0, current_level
    lw t1, 0(t0)
    sw t1, 4(sp)
    li t2, LEVEL_TOWN
    beq t1, t2, update_town_level_exit
    li t2, LEVEL_SEWER
    beq t1, t2, check_level_exit_unlocked
    li t2, LEVEL_LABORATORY
    bne t1, t2, finish_level_exit_transition

check_level_exit_unlocked:
    la t0, level_exit_unlocked
    lw t2, 0(t0)
    beqz t2, finish_level_exit_transition
    la t0, level_exit_transitioned
    lw t2, 0(t0)
    bnez t2, finish_level_exit_transition
    call update_level_exit_blink
    call is_player_in_level_exit_range
    beqz a0, finish_level_exit_transition

    la t0, key_pressed
    lw t2, 0(t0)
    beqz t2, finish_level_exit_transition
    la t0, last_key
    lw t2, 0(t0)
    li t3, 'c'
    beq t2, t3, activate_level_exit
    li t3, 'C'
    bne t2, t3, finish_level_exit_transition

activate_level_exit:
    la t0, level_exit_transitioned
    li t2, 1
    sw t2, 0(t0)
    call reset_transient_level_state
    lw t1, 4(sp)
    li t2, LEVEL_SEWER
    beq t1, t2, transition_sewer_to_lab
    call start_boss_fight
    j finish_level_exit_transition
transition_sewer_to_lab:
    call set_state_cutscene_level3
    j finish_level_exit_transition
update_town_level_exit:
    call update_town_exit

finish_level_exit_transition:
    lw ra, 0(sp)
    addi sp, sp, 8
    ret

update_level_exit_blink:
    la t0, level_exit_blink_timer
    lw t1, 0(t0)
    addi t1, t1, 1
    li t2, LEVEL_EXIT_BLINK_FRAMES
    blt t1, t2, store_level_exit_blink_timer
    sw zero, 0(t0)
    la t0, level_exit_blink_frame
    lw t1, 0(t0)
    xori t1, t1, 1
    sw t1, 0(t0)
    ret
store_level_exit_blink_timer:
    sw t1, 0(t0)
    ret

# Inicializa o boss uma unica vez, somente depois da interacao do painel.
start_boss_fight:
    addi sp, sp, -4
    sw ra, 0(sp)
    la t0, boss_active
    lw t1, 0(t0)
    bnez t1, end_start_boss_fight
    li t1, 1
    sw t1, 0(t0)
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
    la t0, boss_melee_timer
    sw zero, 0(t0)
    la t0, boss_heavy_timer
    sw zero, 0(t0)
    la t0, game_state
    li t1, STATE_BOSS
    sw t1, 0(t0)
    la t0, current_level
    li t1, LEVEL_LABORATORY
    sw t1, 0(t0)
    la t0, remaining_enemies
    li t1, BOSS_SUPPORT_ENEMIES
    sw t1, 0(t0)
    la t0, wave_spawned
    sw zero, 0(t0)
    la t0, level_spawn_timer
    li t1, LEVEL_FIRST_SPAWN_DELAY
    sw t1, 0(t0)
    la t0, level_exit_unlocked
    sw zero, 0(t0)
    la t0, level_exit_blink_frame
    sw zero, 0(t0)
    call clear_input_buffers
end_start_boss_fight:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret
