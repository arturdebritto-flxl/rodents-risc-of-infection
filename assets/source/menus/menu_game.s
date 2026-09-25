# menu_game.s
# Rotinas do menu. Os dados visuais ficam em menu_game.data.

.include "menu_game.data"
.text
.globl main
main:
redraw:
    # Desenha tela base pre-renderizada.
    la s2, base_runs
    j draw_runs

after_base:
    jal ra, draw_title_game
    la t0, selected
    lw t1, 0(t0)
    beqz t1, use_overlay_0
    li t2, 1
    beq t1, t2, use_overlay_1
    la s2, overlay_2_runs
    j draw_overlay
use_overlay_0:
    la s2, overlay_0_runs
    j draw_overlay
use_overlay_1:
    la s2, overlay_1_runs
    j draw_overlay

draw_overlay:
    li s5, 1
    j draw_runs_loop_entry

draw_runs:
    li s5, 0

draw_runs_loop_entry:
    lw t0, 0(s2)
    bltz t0, draw_runs_done
    lw t1, 4(s2)
    lw t2, 8(s2)
    lw t3, 12(s2)
    slli t5, t1, 8
    slli t4, t1, 6
    add t5, t5, t4
    add t5, t5, t0
    li t6, VGA_BASE
    add t6, t6, t5
draw_run_pixels:
    beqz t2, draw_run_next
    sb t3, 0(t6)
    addi t6, t6, 1
    addi t2, t2, -1
    j draw_run_pixels
draw_run_next:
    addi s2, s2, 16
    j draw_runs_loop_entry
draw_runs_done:
    beqz s5, after_base
    li t0, 2
    beq s5, t0, after_options_base
    j wait_key

after_options_base:
    jal ra, draw_options_content
    j wait_options_key

draw_title_game:
    mv s9, ra
    la s3, title_game_runs
    li s6, 65
    li s7, 10
    jal ra, draw_sprite_rle_transparent
    jr s9

draw_sprite_rle_transparent:
    lw t0, 0(s3)
    bltz t0, draw_sprite_transparent_done
    lw t1, 4(s3)
    lw t2, 8(s3)
    lw t3, 12(s3)
    add t0, t0, s6
    add t1, t1, s7
    slli t5, t1, 8
    slli t4, t1, 6
    add t5, t5, t4
    add t5, t5, t0
    li t6, VGA_BASE
    add t6, t6, t5
draw_sprite_transparent_pixels:
    beqz t2, draw_sprite_transparent_next
    beqz t3, draw_sprite_transparent_skip
    sb t3, 0(t6)
draw_sprite_transparent_skip:
    addi t6, t6, 1
    addi t2, t2, -1
    j draw_sprite_transparent_pixels
draw_sprite_transparent_next:
    addi s3, s3, 16
    j draw_sprite_rle_transparent
draw_sprite_transparent_done:
    jr ra

wait_key:
    # Espera tecla no menu estatico.
    lui t0, 0xff200
    lw t1, 0(t0)
    andi t1, t1, 1
    bnez t1, read_key
    j wait_key

read_key:
    lw a0, 4(t0)

    li t0, 'q'
    beq a0, t0, exit_program
    li t0, 'Q'
    beq a0, t0, exit_program

    li t0, 'w'
    beq a0, t0, move_up
    li t0, 'W'
    beq a0, t0, move_up
    li t0, 'k'
    beq a0, t0, move_up
    li t0, 'K'
    beq a0, t0, move_up

    li t0, 's'
    beq a0, t0, move_down
    li t0, 'S'
    beq a0, t0, move_down
    li t0, 'j'
    beq a0, t0, move_down
    li t0, 'J'
    beq a0, t0, move_down

    li t0, ' '
    beq a0, t0, confirm_option
    li t0, 10
    beq a0, t0, confirm_option
    li t0, 13
    beq a0, t0, confirm_option
    j wait_key

move_up:
    la t0, selected
    lw t1, 0(t0)
    addi t1, t1, -1
    bgez t1, store_selection
    li t1, 2
    j store_selection

move_down:
    la t0, selected
    lw t1, 0(t0)
    addi t1, t1, 1
    li t2, 3
    blt t1, t2, store_selection
    li t1, 0

store_selection:
    sw t1, 0(t0)
    j redraw_menu_only

redraw_menu_only:
    la t0, selected
    lw t1, 0(t0)
    beqz t1, redraw_menu_0
    li t2, 1
    beq t1, t2, redraw_menu_1
    la s2, overlay_2_runs
    j draw_overlay
redraw_menu_0:
    la s2, overlay_0_runs
    j draw_overlay
redraw_menu_1:
    la s2, overlay_1_runs
    j draw_overlay

confirm_option:
    la t0, selected
    lw t1, 0(t0)
    beqz t1, start_screen
    li t2, 1
    beq t1, t2, options_screen
    j exit_program

start_screen:
    li t2, C_GREEN
    j fill_feedback
options_screen:
    la s2, base_runs
    li s5, 2
    j draw_runs_loop_entry

redraw_options_only:
    jal ra, draw_options_content
    j wait_options_key

draw_options_content:
    mv s10, ra
    li a0, 47
    li a1, 84
    li a2, 226
    li a3, 112
    li a4, C_PANEL
    jal ra, fill_rect

    la s3, options_title_runs
    li s6, 50
    li s7, 28
    jal ra, draw_sprite_rle_transparent

    la t0, option_selected
    lw t1, 0(t0)
    li a0, 65
    li a2, 190
    li a3, 24
    li a4, C_HILITE
    beqz t1, option_hilite_music
    li t2, 1
    beq t1, t2, option_hilite_sfx
    li a1, 161
    j option_draw_hilite
option_hilite_music:
    li a1, 109
    j option_draw_hilite
option_hilite_sfx:
    li a1, 135
option_draw_hilite:
    jal ra, fill_rect

    la s3, music_label_runs
    li s6, 80
    li s7, 113
    jal ra, draw_sprite_rle_transparent
    la s3, sfx_label_runs
    li s6, 80
    li s7, 139
    jal ra, draw_sprite_rle_transparent
    la s3, back_label_runs
    li s6, 80
    li s7, 165
    jal ra, draw_sprite_rle_transparent

    la t0, music_enabled
    lw t1, 0(t0)
    beqz t1, draw_music_off
    la s3, on_label_runs
    j draw_music_state
draw_music_off:
    la s3, off_label_runs
draw_music_state:
    li s6, 210
    li s7, 113
    jal ra, draw_sprite_rle_transparent

    la t0, sfx_enabled
    lw t1, 0(t0)
    beqz t1, draw_sfx_off
    la s3, on_label_runs
    j draw_sfx_state
draw_sfx_off:
    la s3, off_label_runs
draw_sfx_state:
    li s6, 210
    li s7, 139
    jal ra, draw_sprite_rle_transparent
    jr s10

fill_rect:
    li t0, VGA_BASE
    li t1, 0
fill_rect_row_loop:
    bge t1, a3, fill_rect_done
    add t2, a1, t1
    slli t3, t2, 8
    slli t4, t2, 6
    add t3, t3, t4
    add t3, t3, a0
    add t5, t0, t3
    mv t6, a2
fill_rect_pixel_loop:
    beqz t6, fill_rect_next_row
    sb a4, 0(t5)
    addi t5, t5, 1
    addi t6, t6, -1
    j fill_rect_pixel_loop
fill_rect_next_row:
    addi t1, t1, 1
    j fill_rect_row_loop
fill_rect_done:
    jr ra

wait_options_key:
    lui t0, 0xff200
    lw t1, 0(t0)
    andi t1, t1, 1
    bnez t1, read_options_key
    j wait_options_key

read_options_key:
    lw a0, 4(t0)
    li t0, 'q'
    beq a0, t0, exit_program
    li t0, 'Q'
    beq a0, t0, exit_program
    li t0, 'w'
    beq a0, t0, option_move_up
    li t0, 'W'
    beq a0, t0, option_move_up
    li t0, 'k'
    beq a0, t0, option_move_up
    li t0, 'K'
    beq a0, t0, option_move_up
    li t0, 's'
    beq a0, t0, option_move_down
    li t0, 'S'
    beq a0, t0, option_move_down
    li t0, 'j'
    beq a0, t0, option_move_down
    li t0, 'J'
    beq a0, t0, option_move_down
    li t0, ' '
    beq a0, t0, option_confirm
    li t0, 10
    beq a0, t0, option_confirm
    li t0, 13
    beq a0, t0, option_confirm
    j wait_options_key

option_move_up:
    la t0, option_selected
    lw t1, 0(t0)
    addi t1, t1, -1
    bgez t1, option_store_selection
    li t1, 2
    j option_store_selection

option_move_down:
    la t0, option_selected
    lw t1, 0(t0)
    addi t1, t1, 1
    li t2, 3
    blt t1, t2, option_store_selection
    li t1, 0

option_store_selection:
    sw t1, 0(t0)
    j redraw_options_only

option_confirm:
    la t0, option_selected
    lw t1, 0(t0)
    beqz t1, toggle_music
    li t2, 1
    beq t1, t2, toggle_sfx
    j redraw

toggle_music:
    la t0, music_enabled
    lw t1, 0(t0)
    xori t1, t1, 1
    sw t1, 0(t0)
    j redraw_options_only

toggle_sfx:
    la t0, sfx_enabled
    lw t1, 0(t0)
    xori t1, t1, 1
    sw t1, 0(t0)
    j redraw_options_only

fill_feedback:
    li t0, VGA_BASE
    li t1, SCREEN_PIXELS
fill_feedback_loop:
    sb t2, 0(t0)
    addi t0, t0, 1
    addi t1, t1, -1
    bnez t1, fill_feedback_loop
feedback_wait:
    lui t0, 0xff200
    lw t1, 0(t0)
    andi t1, t1, 1
    beqz t1, feedback_wait
    lw a0, 4(t0)
    li t0, 'q'
    beq a0, t0, exit_program
    li t0, 'Q'
    beq a0, t0, exit_program
    j redraw

exit_program:
    li a7, 10
    ecall

