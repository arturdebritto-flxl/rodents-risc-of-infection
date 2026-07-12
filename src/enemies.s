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

    la t0, enemy_direction
    add t4, t0, t3
    li t5, DIR_DOWN
    sw t5, 0(t4)

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

    li t2, STATE_LEVEL3
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
    beqz a0, end_spawn_wave_if_needed

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
    addi sp, sp, -16
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)

    call init_enemies

    la t0, remaining_enemies
    lw s1, 0(t0)                    # quantidade desejada

    li t2, MAX_ENEMIES
    ble s1, t2, spawn_count_ok
    li s1, MAX_ENEMIES

spawn_count_ok:
    li s0, 0                        # indice

spawn_enemy_loop:
    beq s0, s1, spawn_current_enemy_wave_succeeded

    slli s2, s0, 2                  # offset = indice * 4

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
    andi t6, s0, 3
    beqz t6, spawn_type_echo
    j spawn_type_common

spawn_type_sewer:
    # Sewer: mistura comum, Echo e Mutant
    andi t6, s0, 3
    beqz t6, spawn_type_mutant

    li t5, 1
    beq t6, t5, spawn_type_echo

    j spawn_type_common

spawn_type_laboratory:
    # Laboratory: mais inimigos resistentes/sensoriais
    andi t6, s0, 3

    beqz t6, spawn_type_mutant

    li t5, 1
    beq t6, t5, spawn_type_echo

    li t5, 2
    beq t6, t5, spawn_type_spitter

    j spawn_type_common

spawn_type_common:
    la t0, enemy_type
    add t4, t0, s2
    li t5, RAT_COMMON
    sw t5, 0(t4)

    la t0, enemy_hp
    add t4, t0, s2
    li t5, RAT_COMMON_HP
    sw t5, 0(t4)

    j end_spawn_type

spawn_type_echo:
    la t0, enemy_type
    add t4, t0, s2
    li t5, RAT_ECHO
    sw t5, 0(t4)

    la t0, enemy_hp
    add t4, t0, s2
    li t5, RAT_ECHO_HP
    sw t5, 0(t4)

    j end_spawn_type

spawn_type_mutant:
    la t0, enemy_type
    add t4, t0, s2
    li t5, RAT_MUTANT
    sw t5, 0(t4)

    la t0, enemy_hp
    add t4, t0, s2
    li t5, RAT_MUTANT_HP
    sw t5, 0(t4)

    j end_spawn_type

spawn_type_spitter:
    la t0, enemy_type
    add t4, t0, s2
    li t5, RAT_SPITTER
    sw t5, 0(t4)

    la t0, enemy_hp
    add t4, t0, s2
    li t5, RAT_SPITTER_HP
    sw t5, 0(t4)

    j end_spawn_type

end_spawn_type:
    la t0, enemy_attack_timer
    add t4, t0, s2
    sw zero, 0(t4)

    call select_enemy_spawn_position
    beqz a0, spawn_current_enemy_wave_failed

    la t0, enemy_x
    add t4, t0, s2
    sw a1, 0(t4)

    la t0, enemy_y
    add t4, t0, s2
    sw a2, 0(t4)

    # O slot so se torna ativo depois de uma posicao valida ser gravada.
    la t0, enemy_active
    add t4, t0, s2
    li t5, 1
    sw t5, 0(t4)

    addi s0, s0, 1
    j spawn_enemy_loop

spawn_current_enemy_wave_succeeded:
    li a0, 1
    j finish_spawn_current_enemy_wave

spawn_current_enemy_wave_failed:
    # Descarta qualquer criacao parcial; a wave sera tentada novamente.
    call init_enemies
    li a0, 0

finish_spawn_current_enemy_wave:
    lw s2, 12(sp)
    lw s1, 8(sp)
    lw s0, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 16

    ret

# ------------------------------------------------------------
# Validacao e escolha de pontos de spawn 16x16.
# ------------------------------------------------------------

# Entrada: a0=x, a1=y. Saida: a0=1 se fisicamente livre.
is_enemy_spawn_position_safe:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    mv s0, a0
    mv s1, a1

    blt s0, zero, enemy_spawn_position_unsafe
    li t0, PLAYER_MAX_X
    bgt s0, t0, enemy_spawn_position_unsafe
    li t0, PLAYER_MIN_Y
    blt s1, t0, enemy_spawn_position_unsafe
    li t0, ENEMY_SPAWN_MAX_Y
    bgt s1, t0, enemy_spawn_position_unsafe

    # Nunca permite sobreposicao com a hitbox completa do jogador.
    la t0, player_x
    lw t1, 0(t0)
    li t2, PLAYER_SIZE
    add t3, t1, t2
    ble t3, s0, enemy_spawn_check_obstacles
    li t2, ENEMY_SIZE
    add t3, s0, t2
    ble t3, t1, enemy_spawn_check_obstacles
    la t0, player_y
    lw t1, 0(t0)
    li t2, PLAYER_SIZE
    add t3, t1, t2
    ble t3, s1, enemy_spawn_check_obstacles
    li t2, ENEMY_SIZE
    add t3, s1, t2
    ble t3, t1, enemy_spawn_check_obstacles
    j enemy_spawn_position_unsafe

enemy_spawn_check_obstacles:
    mv a0, s0
    mv a1, s1
    call is_enemy_position_blocked
    bnez a0, enemy_spawn_position_unsafe

    li t0, 0
enemy_spawn_enemy_overlap_loop:
    li t1, MAX_ENEMIES
    beq t0, t1, enemy_spawn_check_boss
    slli t1, t0, 2
    la t2, enemy_active
    add t2, t2, t1
    lw t3, 0(t2)
    beqz t3, enemy_spawn_next_enemy_overlap
    la t2, enemy_x
    add t2, t2, t1
    lw t3, 0(t2)
    li t4, ENEMY_SIZE
    add t5, t3, t4
    ble t5, s0, enemy_spawn_next_enemy_overlap
    add t5, s0, t4
    ble t5, t3, enemy_spawn_next_enemy_overlap
    la t2, enemy_y
    add t2, t2, t1
    lw t3, 0(t2)
    add t5, t3, t4
    ble t5, s1, enemy_spawn_next_enemy_overlap
    add t5, s1, t4
    ble t5, t3, enemy_spawn_next_enemy_overlap
    j enemy_spawn_position_unsafe

enemy_spawn_next_enemy_overlap:
    addi t0, t0, 1
    j enemy_spawn_enemy_overlap_loop

enemy_spawn_check_boss:
    la t0, boss_active
    lw t1, 0(t0)
    beqz t1, enemy_spawn_check_powerups
    la t0, boss_x
    lw t1, 0(t0)
    li t2, BOSS_SIZE
    add t3, t1, t2
    ble t3, s0, enemy_spawn_check_powerups
    li t2, ENEMY_SIZE
    add t3, s0, t2
    ble t3, t1, enemy_spawn_check_powerups
    la t0, boss_y
    lw t1, 0(t0)
    li t2, BOSS_SIZE
    add t3, t1, t2
    ble t3, s1, enemy_spawn_check_powerups
    li t2, ENEMY_SIZE
    add t3, s1, t2
    ble t3, t1, enemy_spawn_check_powerups
    j enemy_spawn_position_unsafe

enemy_spawn_check_powerups:
    li t0, 0
enemy_spawn_powerup_overlap_loop:
    li t1, MAX_POWERUPS
    beq t0, t1, enemy_spawn_position_safe
    slli t1, t0, 2
    la t2, powerup_active
    add t2, t2, t1
    lw t3, 0(t2)
    beqz t3, enemy_spawn_next_powerup_overlap
    la t2, powerup_x
    add t2, t2, t1
    lw t3, 0(t2)
    li t4, POWERUP_SIZE
    add t5, t3, t4
    ble t5, s0, enemy_spawn_next_powerup_overlap
    li t4, ENEMY_SIZE
    add t5, s0, t4
    ble t5, t3, enemy_spawn_next_powerup_overlap
    la t2, powerup_y
    add t2, t2, t1
    lw t3, 0(t2)
    li t4, POWERUP_SIZE
    add t5, t3, t4
    ble t5, s1, enemy_spawn_next_powerup_overlap
    li t4, ENEMY_SIZE
    add t5, s1, t4
    ble t5, t3, enemy_spawn_next_powerup_overlap
    j enemy_spawn_position_unsafe

enemy_spawn_next_powerup_overlap:
    addi t0, t0, 1
    j enemy_spawn_powerup_overlap_loop

enemy_spawn_position_safe:
    li a0, 1
    j finish_enemy_spawn_position_safe

enemy_spawn_position_unsafe:
    li a0, 0

finish_enemy_spawn_position_safe:
    lw s1, 8(sp)
    lw s0, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 12
    ret

# Entrada: a0=x, a1=y. Alem de livre, exige distancia Manhattan >= 96.
is_enemy_spawn_position_valid:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw a0, 4(sp)
    sw a1, 8(sp)
    call is_enemy_spawn_position_safe
    beqz a0, finish_enemy_spawn_position_valid
    lw t0, 4(sp)
    la t1, player_x
    lw t1, 0(t1)
    sub t0, t0, t1
    bgez t0, enemy_spawn_valid_dx_ready
    sub t0, zero, t0
enemy_spawn_valid_dx_ready:
    lw t1, 8(sp)
    la t2, player_y
    lw t2, 0(t2)
    sub t1, t1, t2
    bgez t1, enemy_spawn_valid_dy_ready
    sub t1, zero, t1
enemy_spawn_valid_dy_ready:
    add t0, t0, t1
    li t1, SPAWN_MIN_PLAYER_DISTANCE
    slt a0, t0, t1
    xori a0, a0, 1
finish_enemy_spawn_position_valid:
    lw ra, 0(sp)
    addi sp, sp, 12
    ret

mix_enemy_spawn_seed:
    la t0, enemy_spawn_rng_state
    lw t1, 0(t0)
    la t2, frame_counter
    lw t2, 0(t2)
    xor t1, t1, t2
    la t2, current_wave
    lw t2, 0(t2)
    xor t1, t1, t2
    la t2, remaining_enemies
    lw t2, 0(t2)
    slli t2, t2, 8
    xor t1, t1, t2
    la t2, score
    lw t2, 0(t2)
    xor t1, t1, t2
    bnez t1, store_mixed_enemy_spawn_seed
    li t1, 0x6D2B79F5
store_mixed_enemy_spawn_seed:
    sw t1, 0(t0)
    ret

next_enemy_spawn_random:
    la t0, enemy_spawn_rng_state
    lw t1, 0(t0)
    slli t2, t1, 13
    xor t1, t1, t2
    srli t2, t1, 17
    xor t1, t1, t2
    slli t2, t1, 5
    xor t1, t1, t2
    bnez t1, store_enemy_spawn_random
    li t1, 0x6D2B79F5
store_enemy_spawn_random:
    sw t1, 0(t0)
    mv a0, t1
    ret

# Saida: a0=sucesso, a1=x, a2=y. Reservoir sampling entre pontos >=96;
# se nao houver, usa o ponto fisicamente valido mais distante.
select_enemy_spawn_position:
    addi sp, sp, -52
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    sw s4, 20(sp)
    sw s5, 24(sp)
    sw s6, 28(sp)
    sw s7, 32(sp)
    sw s8, 36(sp)
    sw s9, 40(sp)
    sw s10, 44(sp)
    sw s11, 48(sp)

    la t0, current_level
    lw t1, 0(t0)
    li t2, LEVEL_TOWN
    beq t1, t2, select_town_spawn_table
    li t2, LEVEL_SEWER
    beq t1, t2, select_sewer_spawn_table
    li t2, LEVEL_LABORATORY
    bne t1, t2, select_enemy_spawn_failed
    la s0, laboratory_enemy_spawn_points
    j enemy_spawn_table_ready
select_town_spawn_table:
    la s0, town_enemy_spawn_points
    j enemy_spawn_table_ready
select_sewer_spawn_table:
    la s0, sewer_enemy_spawn_points

enemy_spawn_table_ready:
    li s1, ENEMY_SPAWN_POINT_COUNT
    li s2, 0
    li s3, 0
    li s4, 0
    li s5, 0
    li s6, 0
    li s7, 0
    li s8, -1
    call mix_enemy_spawn_seed

select_enemy_spawn_loop:
    beq s2, s1, finish_select_enemy_spawn_candidates
    lw s9, 0(s0)
    lw s10, 4(s0)
    mv a0, s9
    mv a1, s10
    call is_enemy_spawn_position_safe
    beqz a0, select_enemy_spawn_next

    la t0, player_x
    lw t0, 0(t0)
    sub t0, s9, t0
    bgez t0, selected_spawn_dx_ready
    sub t0, zero, t0
selected_spawn_dx_ready:
    la t1, player_y
    lw t1, 0(t1)
    sub t1, s10, t1
    bgez t1, selected_spawn_dy_ready
    sub t1, zero, t1
selected_spawn_dy_ready:
    add t2, t0, t1
    bge s8, t2, selected_spawn_farthest_ready
    mv s8, t2
    mv s6, s9
    mv s7, s10
selected_spawn_farthest_ready:
    li t0, SPAWN_MIN_PLAYER_DISTANCE
    blt t2, t0, select_enemy_spawn_next
    addi s5, s5, 1
    call next_enemy_spawn_random
    remu t0, a0, s5
    bnez t0, select_enemy_spawn_next
    mv s3, s9
    mv s4, s10

select_enemy_spawn_next:
    addi s0, s0, 8
    addi s2, s2, 1
    j select_enemy_spawn_loop

finish_select_enemy_spawn_candidates:
    bnez s5, select_enemy_spawn_succeeded
    blt s8, zero, select_enemy_spawn_failed
    mv s3, s6
    mv s4, s7

select_enemy_spawn_succeeded:
    li a0, 1
    mv a1, s3
    mv a2, s4
    j finish_select_enemy_spawn_position

select_enemy_spawn_failed:
    li a0, 0
    li a1, 0
    li a2, 0

finish_select_enemy_spawn_position:
    lw s11, 48(sp)
    lw s10, 44(sp)
    lw s9, 40(sp)
    lw s8, 36(sp)
    lw s7, 32(sp)
    lw s6, 28(sp)
    lw s5, 24(sp)
    lw s4, 20(sp)
    lw s3, 16(sp)
    lw s2, 12(sp)
    lw s1, 8(sp)
    lw s0, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 52
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

    li t2, STATE_LEVEL3
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
    la t0, noise_timer
    lw t6, 0(t0)
    beqz t6, next_update_enemy

    li a5, RAT_ECHO_ALERT_SPEED
    j move_rat_towards_player

update_enemy_mutant:
    li a5, RAT_MUTANT_SPEED
    j move_rat_towards_player

update_enemy_spitter:
    la t0, enemy_x
    add t4, t0, t3
    lw a0, 0(t4)

    la t0, enemy_y
    add t4, t0, t3
    lw a1, 0(t4)

    la t0, player_x
    lw a2, 0(t0)

    la t0, player_y
    lw a3, 0(t0)

    sub t5, a2, a0
    bgez t5, spitter_dx_abs_ok
    sub t5, zero, t5

spitter_dx_abs_ok:
    sub t6, a3, a1
    bgez t6, spitter_dy_abs_ok
    sub t6, zero, t6

spitter_dy_abs_ok:
    add a4, t5, t6

    li t6, SPITTER_MAX_RANGE
    bgt a4, t6, spitter_approach

    li t6, SPITTER_MIN_RANGE
    blt a4, t6, spitter_retreat

    addi sp, sp, -8
    sw t1, 0(sp)
    sw a4, 4(sp)
    call spitter_strafe
    lw a4, 4(sp)
    lw t1, 0(sp)
    addi sp, sp, 8

    li t6, SPITTER_PROJECTILE_RANGE
    bgt a4, t6, next_update_enemy

    la t0, enemy_attack_timer
    add t4, t0, t3
    lw t5, 0(t4)
    addi t5, t5, 1
    li t6, SPITTER_SHOOT_DELAY
    blt t5, t6, spitter_store_timer
    sw zero, 0(t4)

    addi sp, sp, -8
    sw t1, 0(sp)
    sw t3, 4(sp)

    call spitter_fire_at_player

    lw t3, 4(sp)
    lw t1, 0(sp)
    addi sp, sp, 8
    j next_update_enemy

spitter_store_timer:
    sw t5, 0(t4)
    j next_update_enemy

spitter_approach:
    li a5, SPITTER_APPROACH_SPEED
    j move_rat_towards_player

spitter_retreat:
    la t0, enemy_x
    add t4, t0, t3
    lw t5, 0(t4)
    la t0, player_x
    lw t6, 0(t0)
    blt t5, t6, spitter_back_left

spitter_back_right:
    addi t5, t5, SPITTER_RETREAT_SPEED
    li a4, DIR_RIGHT
    jal ra, try_move_enemy_x
    j next_update_enemy

spitter_back_left:
    addi t5, t5, -2
    li a4, DIR_LEFT
    jal ra, try_move_enemy_x
    j next_update_enemy

spitter_strafe:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, frame_counter
    lw t5, 0(t0)
    andi t5, t5, 16
    beqz t5, spitter_strafe_down

spitter_strafe_up:
    la t0, enemy_y
    add t4, t0, t3
    lw t5, 0(t4)
    addi t5, t5, -1
    li t6, 10
    blt t5, t6, spitter_strafe_done
    li a4, DIR_UP
    jal ra, try_move_enemy_y
    j spitter_strafe_done

spitter_strafe_down:
    la t0, enemy_y
    add t4, t0, t3
    lw t5, 0(t4)
    addi t5, t5, SPITTER_STRAFE_SPEED
    li t6, 225
    bgt t5, t6, spitter_strafe_done
    li a4, DIR_DOWN
    jal ra, try_move_enemy_y

spitter_strafe_done:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

spitter_fire_at_player:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, enemy_x
    add t4, t0, t3
    lw a0, 0(t4)
    addi a0, a0, 4

    la t0, enemy_y
    add t4, t0, t3
    lw a1, 0(t4)
    addi a1, a1, 4

    la t0, player_x
    lw t5, 0(t0)
    sub t5, t5, a0
    mv t6, t5
    bgez t6, spitter_fire_dx_abs_ok
    sub t6, zero, t6

spitter_fire_dx_abs_ok:
    la t0, player_y
    lw a3, 0(t0)
    sub a3, a3, a1
    mv a4, a3
    bgez a4, spitter_fire_dy_abs_ok
    sub a4, zero, a4

spitter_fire_dy_abs_ok:
    bgt t6, a4, spitter_fire_horizontal

spitter_fire_vertical:
    li a2, 0
    li t6, ENEMY_BULLET_SPEED
    bgez a3, spitter_fire_down
    sub t6, zero, t6

spitter_fire_down:
    mv a3, t6
    li a4, ENEMY_PROJECTILE_SPITTER
    call spawn_enemy_bullet_typed
    j end_spitter_fire_at_player

spitter_fire_horizontal:
    li a3, 0
    li a2, ENEMY_BULLET_SPEED
    bgez t5, spitter_fire_right
    sub a2, zero, a2

spitter_fire_right:
    li a4, ENEMY_PROJECTILE_SPITTER
    call spawn_enemy_bullet_typed

end_spitter_fire_at_player:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

try_move_enemy_x:
    addi sp, sp, -24
    sw ra, 0(sp)
    sw t1, 4(sp)
    sw t3, 8(sp)
    sw t5, 12(sp)
    sw a4, 16(sp)
    sw a5, 20(sp)

    blt t5, zero, block_try_move_enemy_x
    li t0, 304
    bgt t5, t0, block_try_move_enemy_x

    mv a0, t5
    la t0, enemy_y
    add t4, t0, t3
    lw a1, 0(t4)
    call is_enemy_position_blocked
    bnez a0, end_try_move_enemy_x

    lw t3, 8(sp)
    lw t5, 12(sp)
    la t0, enemy_x
    add t4, t0, t3
    sw t5, 0(t4)

    lw a4, 16(sp)
    la t0, enemy_direction
    add t4, t0, t3
    sw a4, 0(t4)
    j end_try_move_enemy_x

block_try_move_enemy_x:
    li a0, 1

end_try_move_enemy_x:
    lw ra, 0(sp)
    lw t1, 4(sp)
    lw t3, 8(sp)
    lw t5, 12(sp)
    lw a4, 16(sp)
    lw a5, 20(sp)
    addi sp, sp, 24
    ret

try_move_enemy_y:
    addi sp, sp, -24
    sw ra, 0(sp)
    sw t1, 4(sp)
    sw t3, 8(sp)
    sw t5, 12(sp)
    sw a4, 16(sp)
    sw a5, 20(sp)

    blt t5, zero, block_try_move_enemy_y
    li t0, 224
    bgt t5, t0, block_try_move_enemy_y

    la t0, enemy_x
    add t4, t0, t3
    lw a0, 0(t4)
    mv a1, t5
    call is_enemy_position_blocked
    bnez a0, end_try_move_enemy_y

    lw t3, 8(sp)
    lw t5, 12(sp)
    la t0, enemy_y
    add t4, t0, t3
    sw t5, 0(t4)

    lw a4, 16(sp)
    la t0, enemy_direction
    add t4, t0, t3
    sw a4, 0(t4)
    j end_try_move_enemy_y

block_try_move_enemy_y:
    li a0, 1

end_try_move_enemy_y:
    lw ra, 0(sp)
    lw t1, 4(sp)
    lw t3, 8(sp)
    lw t5, 12(sp)
    lw a4, 16(sp)
    lw a5, 20(sp)
    addi sp, sp, 24
    ret

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
    li a4, DIR_RIGHT
    jal ra, try_move_enemy_x
    j rat_update_y

rat_move_left:
    sub t5, t5, a5
    li a4, DIR_LEFT
    jal ra, try_move_enemy_x

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
    li a4, DIR_DOWN
    jal ra, try_move_enemy_y
    j next_update_enemy

rat_move_up:
    sub t5, t5, a5
    li a4, DIR_UP
    jal ra, try_move_enemy_y

next_update_enemy:
    addi t1, t1, 1
    j update_enemies_loop

end_update_enemies:
    lw ra, 0(sp)
    addi sp, sp, 4

    ret
