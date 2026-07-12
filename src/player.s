# ============================================================
# Logica do jogador
# ============================================================

.text

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

    la t0, player_move_facing_direction
    sw t1, 0(t0)

    la t0, player_lives
    li t1, PLAYER_MAX_LIVES
    sw t1, 0(t0)

    la t0, player_moved
    sw zero, 0(t0)

    la t0, move_x_direction
    sw zero, 0(t0)

    la t0, move_x_timer
    sw zero, 0(t0)

    la t0, move_y_direction
    sw zero, 0(t0)

    la t0, move_y_timer
    sw zero, 0(t0)

    ret

update_player:
    addi sp, sp, -16
    sw ra, 0(sp)

    la t0, player_moved
    sw zero, 0(t0)

    la t0, key_pressed
    lw t1, 0(t0)
    beqz t1, apply_axis_buffers

    la t0, last_key
    lw t1, 0(t0)
    li t2, 'w'
    beq t1, t2, buffer_move_up
    li t2, 's'
    beq t1, t2, buffer_move_down
    li t2, 'a'
    beq t1, t2, buffer_move_left
    li t2, 'd'
    beq t1, t2, buffer_move_right
    j apply_axis_buffers

buffer_move_up:
    la t0, move_y_direction
    li t1, -1
    sw t1, 0(t0)
    la t0, move_y_timer
    li t1, MOVE_AXIS_BUFFER_FRAMES
    sw t1, 0(t0)
    li t1, DIR_UP
    j store_move_facing

buffer_move_down:
    la t0, move_y_direction
    li t1, 1
    sw t1, 0(t0)
    la t0, move_y_timer
    li t1, MOVE_AXIS_BUFFER_FRAMES
    sw t1, 0(t0)
    li t1, DIR_DOWN
    j store_move_facing

buffer_move_left:
    la t0, move_x_direction
    li t1, -1
    sw t1, 0(t0)
    la t0, move_x_timer
    li t1, MOVE_AXIS_BUFFER_FRAMES
    sw t1, 0(t0)
    li t1, DIR_LEFT
    j store_move_facing

buffer_move_right:
    la t0, move_x_direction
    li t1, 1
    sw t1, 0(t0)
    la t0, move_x_timer
    li t1, MOVE_AXIS_BUFFER_FRAMES
    sw t1, 0(t0)
    li t1, DIR_RIGHT

store_move_facing:
    la t0, player_move_facing_direction
    sw t1, 0(t0)
    la t0, player_direction
    sw t1, 0(t0)

apply_axis_buffers:
    # Movimento cardinal usa 2 px; diagonal usa 1 px por eixo.
    li t3, PLAYER_SMOOTH_SPEED
    la t0, move_x_timer
    lw t1, 0(t0)
    la t0, move_y_timer
    lw t2, 0(t0)
    blez t1, store_axis_step
    blez t2, store_axis_step
    li t3, 1

store_axis_step:
    sw t3, 4(sp)

    # X e validado primeiro; bloqueio nao impede a tentativa em Y.
    la t0, move_x_timer
    lw t1, 0(t0)
    blez t1, try_move_y_axis
    addi t1, t1, -1
    sw t1, 0(t0)
    la t0, move_x_direction
    lw t2, 0(t0)
    beqz t2, try_move_y_axis
    la t0, player_x
    lw t1, 0(t0)
    lw t3, 4(sp)
    bltz t2, apply_x_left
    add t1, t1, t3
    j clamp_x_candidate

apply_x_left:
    sub t1, t1, t3

clamp_x_candidate:
    li t3, PLAYER_MIN_X
    bge t1, t3, check_x_max
    mv t1, t3
check_x_max:
    li t3, PLAYER_MAX_X
    ble t1, t3, test_x_collision
    mv t1, t3
test_x_collision:
    sw t1, 8(sp)
    mv a0, t1
    la t0, player_y
    lw a1, 0(t0)
    call is_player_position_blocked
    bnez a0, try_move_y_axis
    lw t1, 8(sp)
    la t0, player_x
    sw t1, 0(t0)
    la t0, player_moved
    li t1, 1
    sw t1, 0(t0)

try_move_y_axis:
    la t0, move_y_timer
    lw t1, 0(t0)
    blez t1, finish_player_movement
    addi t1, t1, -1
    sw t1, 0(t0)
    la t0, move_y_direction
    lw t2, 0(t0)
    beqz t2, finish_player_movement
    la t0, player_y
    lw t1, 0(t0)
    lw t3, 4(sp)
    bltz t2, apply_y_up
    add t1, t1, t3
    j clamp_y_candidate

apply_y_up:
    sub t1, t1, t3

clamp_y_candidate:
    li t3, PLAYER_MIN_Y
    bge t1, t3, check_y_max
    mv t1, t3
check_y_max:
    li t3, PLAYER_MAX_Y
    ble t1, t3, test_y_collision
    mv t1, t3
test_y_collision:
    sw t1, 12(sp)
    la t0, player_x
    lw a0, 0(t0)
    mv a1, t1
    call is_player_position_blocked
    bnez a0, finish_player_movement
    lw t1, 12(sp)
    la t0, player_y
    sw t1, 0(t0)
    la t0, player_moved
    li t1, 1
    sw t1, 0(t0)

finish_player_movement:
    la t0, player_moved
    lw t1, 0(t0)
    beqz t1, end_update_player
    la t0, noise_timer
    lw t1, 0(t0)
    li t2, NOISE_MOVE_FRAMES
    bge t1, t2, end_update_player
    sw t2, 0(t0)

end_update_player:
    lw ra, 0(sp)
    addi sp, sp, 16
    ret

# ------------------------------------------------------------
# update_player_facing_direction
# Prioridade visual: tiro ativo, movimento no frame, ultima direcao.
# Deve ser chamada depois de update_player e antes de consumir o
# shoot_hold_timer do frame atual.
# ------------------------------------------------------------

update_player_facing_direction:
    la t0, player_burst_remaining
    lw t1, 0(t0)
    bgtz t1, face_burst_direction

    la t0, shoot_request_pending
    lw t1, 0(t0)
    bgtz t1, face_shoot_direction

    la t0, player_moved
    lw t1, 0(t0)
    beqz t1, end_update_player_facing_direction
    la t0, player_move_facing_direction
    lw t1, 0(t0)
    j store_player_facing_direction

face_burst_direction:
    la t0, player_burst_direction
    lw t1, 0(t0)
    j store_player_facing_direction

face_shoot_direction:
    la t0, shoot_direction
    lw t1, 0(t0)

store_player_facing_direction:
    la t0, player_direction
    sw t1, 0(t0)

end_update_player_facing_direction:
    ret

is_player_position_blocked:
    li a4, PLAYER_SIZE
    j is_position_blocked

is_enemy_position_blocked:
    li a4, ENEMY_SIZE

is_position_blocked:
    la t0, current_level
    lw t1, 0(t0)

    li t2, LEVEL_TOWN
    beq t1, t2, check_town_player_obstacles

    li t2, LEVEL_SEWER
    beq t1, t2, check_sewer_player_obstacles

    li t2, LEVEL_LABORATORY
    beq t1, t2, check_laboratory_player_obstacles

    mv a0, zero
    ret

check_town_player_obstacles:
    li t0, 72
    li t1, 68
    li t2, 64
    li t3, 10
    jal zero, check_obstacle_rect

check_town_obstacle_2:
    li t0, 184
    li t1, 152
    li t2, 64
    li t3, 10
    jal zero, check_obstacle_rect

check_town_obstacles_done:
    mv a0, zero
    ret

check_sewer_player_obstacles:
    li t0, 96
    li t1, 44
    li t2, 12
    li t3, 76
    jal zero, check_obstacle_rect

check_sewer_obstacle_2:
    li t0, 212
    li t1, 118
    li t2, 12
    li t3, 76
    jal zero, check_obstacle_rect

check_sewer_obstacles_done:
    mv a0, zero
    ret

check_laboratory_player_obstacles:
    li t0, 144
    li t1, 88
    li t2, 40
    li t3, 36
    jal zero, check_obstacle_rect

check_laboratory_obstacle_2:
    li t0, 40
    li t1, 58
    li t2, 72
    li t3, 10
    jal zero, check_obstacle_rect

check_laboratory_obstacle_3:
    li t0, 208
    li t1, 172
    li t2, 72
    li t3, 10
    jal zero, check_obstacle_rect

check_laboratory_obstacles_done:
    mv a0, zero
    ret

check_obstacle_rect:
    add t5, a0, a4
    ble t5, t0, next_obstacle_rect

    add t5, t0, t2
    bge a0, t5, next_obstacle_rect

    add t5, a1, a4
    ble t5, t1, next_obstacle_rect

    add t5, t1, t3
    bge a1, t5, next_obstacle_rect

    li a0, 1
    ret

next_obstacle_rect:
    la t4, current_level
    lw t5, 0(t4)

    li t4, LEVEL_TOWN
    beq t5, t4, route_next_town_obstacle

    li t4, LEVEL_SEWER
    beq t5, t4, route_next_sewer_obstacle

    li t4, LEVEL_LABORATORY
    beq t5, t4, route_next_laboratory_obstacle

    mv a0, zero
    ret

route_next_town_obstacle:
    li t4, 72
    beq t0, t4, check_town_obstacle_2
    j check_town_obstacles_done

route_next_sewer_obstacle:
    li t4, 96
    beq t0, t4, check_sewer_obstacle_2
    j check_sewer_obstacles_done

route_next_laboratory_obstacle:
    li t4, 144
    beq t0, t4, check_laboratory_obstacle_2
    li t4, 40
    beq t0, t4, check_laboratory_obstacle_3
    j check_laboratory_obstacles_done
