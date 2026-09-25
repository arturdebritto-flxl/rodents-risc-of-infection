# =====================================================
# Telas de menus, game over e vitoria
# =====================================================

.text

# Contrato: a0=1 para START; a0=0 para LEAVE.
menu_game_screen:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, selected
    sw zero, 0(t0)

menu_prepare_frames:
    # O RLE grande e desenhado uma unica vez. O segundo framebuffer recebe
    # uma copia por palavras e, durante a navegacao, so o overlay muda.
    call draw_menu_screen
    call end_frame
    call mirror_visible_frame_to_draw_frame

menu_wait_input:
    call menu_wait_key

    li t0, 'q'
    beq a0, t0, menu_leave
    li t0, 'Q'
    beq a0, t0, menu_leave

    li t0, 'w'
    beq a0, t0, menu_move_up
    li t0, 'W'
    beq a0, t0, menu_move_up
    li t0, 'k'
    beq a0, t0, menu_move_up
    li t0, 'K'
    beq a0, t0, menu_move_up

    li t0, 's'
    beq a0, t0, menu_move_down
    li t0, 'S'
    beq a0, t0, menu_move_down
    li t0, 'j'
    beq a0, t0, menu_move_down
    li t0, 'J'
    beq a0, t0, menu_move_down

    li t0, 32
    beq a0, t0, menu_confirm
    li t0, 10
    beq a0, t0, menu_confirm
    li t0, 13
    beq a0, t0, menu_confirm
    j menu_wait_input

menu_move_up:
    la t0, selected
    lw t1, 0(t0)
    addi t1, t1, -1
    bgez t1, menu_store_selection
    li t1, 2
    j menu_store_selection

menu_move_down:
    la t0, selected
    lw t1, 0(t0)
    addi t1, t1, 1
    li t2, 3
    blt t1, t2, menu_store_selection
    li t1, 0

menu_store_selection:
    sw t1, 0(t0)
    call draw_menu_selection_overlay
    call end_frame
    j menu_wait_input

menu_confirm:
    la t0, selected
    lw t1, 0(t0)
    beqz t1, menu_start
    li t2, 1
    beq t1, t2, options_prepare_frames
    j menu_leave

options_prepare_frames:
    call draw_options_screen
    call end_frame
    call mirror_visible_frame_to_draw_frame

options_wait_input:
    call menu_wait_key

    li t0, 'q'
    beq a0, t0, menu_leave
    li t0, 'Q'
    beq a0, t0, menu_leave

    li t0, 'w'
    beq a0, t0, options_move_up
    li t0, 'W'
    beq a0, t0, options_move_up
    li t0, 'k'
    beq a0, t0, options_move_up
    li t0, 'K'
    beq a0, t0, options_move_up

    li t0, 's'
    beq a0, t0, options_move_down
    li t0, 'S'
    beq a0, t0, options_move_down
    li t0, 'j'
    beq a0, t0, options_move_down
    li t0, 'J'
    beq a0, t0, options_move_down

    li t0, 32
    beq a0, t0, options_confirm
    li t0, 10
    beq a0, t0, options_confirm
    li t0, 13
    beq a0, t0, options_confirm
    j options_wait_input

options_move_up:
    la t0, option_selected
    lw t1, 0(t0)
    addi t1, t1, -1
    bgez t1, options_store_selection
    li t1, 2
    j options_store_selection

options_move_down:
    la t0, option_selected
    lw t1, 0(t0)
    addi t1, t1, 1
    li t2, 3
    blt t1, t2, options_store_selection
    li t1, 0

options_store_selection:
    sw t1, 0(t0)
    call draw_options_content_only
    call end_frame
    j options_wait_input

options_confirm:
    la t0, option_selected
    lw t1, 0(t0)
    beqz t1, options_toggle_music
    li t2, 1
    beq t1, t2, options_toggle_sfx
    j menu_prepare_frames

options_toggle_music:
    la t0, music_enabled
    lw t1, 0(t0)
    xori t1, t1, 1
    sw t1, 0(t0)
    bnez t1, options_restart_music
    call stop_menu_music
    j options_redraw_after_music_toggle

options_restart_music:
    call reset_menu_music

options_redraw_after_music_toggle:
    call draw_options_content_only
    call end_frame
    j options_wait_input

options_toggle_sfx:
    la t0, sfx_enabled
    lw t1, 0(t0)
    xori t1, t1, 1
    sw t1, 0(t0)
    call draw_options_content_only
    call end_frame
    j options_wait_input

menu_start:
    call stop_menu_music
    li a0, 1
    j menu_return

menu_leave:
    call stop_menu_music
    li a0, 0

menu_return:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# A leitura do registrador de dados consome exatamente um evento MMIO.
menu_wait_key:
    addi sp, sp, -4
    sw ra, 0(sp)

menu_wait_key_loop:
    call update_menu_music
    call update_game_over_music

    li t0, KDMMIO_Ctrl
    lw t1, 0(t0)
    andi t1, t1, 1
    beqz t1, menu_wait_key_loop
    li t0, KDMMIO_Data
    lw a0, 0(t0)

    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# Estados globais de audio consultados pelas chamadas MIDI reais.
play_music_note:
    la t0, music_enabled
    lw t1, 0(t0)
    beqz t1, end_play_music_note
    li a7, 31
    ecall

end_play_music_note:
    ret

# Caminho unico de inicializacao usado por START e RETRY.
start_new_game_from_menu:
    addi sp, sp, -4
    sw ra, 0(sp)

    call clear_input_frame

    li a0, 72
    li a1, 120
    li a2, 9
    li a3, 80
    call play_music_note

    call reset_game_run
    call set_state_cutscene_intro

    call clear_input_frame

    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# ------------------------------------------------------------
# update_cutscene. O texto vem primeiro; SPACE ou ENTER mostra a imagem.
# Um segundo evento novo avanca para a fase associada.
# Outras teclas, inclusive C/c, nao alteram o estado.
# ------------------------------------------------------------

# Retorna a0=1 quando o evento do frame e SPACE ou ENTER.
cutscene_advance_pressed:
    li a0, 0

    la t0, key_pressed
    lw t1, 0(t0)
    beqz t1, end_cutscene_advance_pressed

    la t0, last_key
    lw t1, 0(t0)
    li t2, 32
    beq t1, t2, cutscene_accept_key
    li t2, 10
    beq t1, t2, cutscene_accept_key
    li t2, 13
    bne t1, t2, end_cutscene_advance_pressed

cutscene_accept_key:
    li a0, 1

end_cutscene_advance_pressed:
    ret

# Descarta eventos pendentes, seleciona o painel pedido em a0 e espera um novo
# evento valido. a0=0 exibe imagem; a0=1 exibe texto.
# O READY e baseado em eventos: ler KDMMIO_Data consome exatamente um evento.
show_text_cutscene:
    li a0, 1
    j show_cutscene_panel

show_image_cutscene:
    li a0, 0

show_cutscene_panel:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw a0, 4(sp)

    call discard_pending_keyboard_events

    la t0, cutscene_text_visible
    lw t1, 4(sp)
    sw t1, 0(t0)

    call clear_input_frame
    call begin_frame
    call draw_cutscene_screen
    call end_frame

cutscene_wait_new_event:
    li t0, KDMMIO_Ctrl
    lw t1, 0(t0)
    andi t1, t1, 1
    beqz t1, cutscene_wait_new_event

    li t0, KDMMIO_Data
    lw a0, 0(t0)
    li t2, 32
    beq a0, t2, end_show_text_cutscene
    li t2, 10
    beq a0, t2, end_show_text_cutscene
    li t2, 13
    bne a0, t2, cutscene_wait_new_event

end_show_text_cutscene:
    lw ra, 0(sp)
    addi sp, sp, 8
    ret

show_text_cutscene_3:
    j show_text_cutscene

discard_pending_keyboard_events:
    li t0, KDMMIO_Ctrl

cutscene_discard_pending_loop:
    lw t1, 0(t0)
    andi t1, t1, 1
    beqz t1, end_discard_pending_keyboard_events
    li t2, KDMMIO_Data
    lw t3, 0(t2)
    j cutscene_discard_pending_loop

end_discard_pending_keyboard_events:
    ret

update_cutscene:
    addi sp, sp, -4
    sw ra, 0(sp)

    # Nao aceite o evento que iniciou/encerrou a tela anterior. A entrada so
    # fica armada depois de um frame limpo, garantindo texto antes da imagem.
    la t0, cutscene_input_armed
    lw t1, 0(t0)
    bnez t1, check_cutscene_advance

    la t0, key_pressed
    lw t1, 0(t0)
    bnez t1, end_update_cutscene

    la t0, cutscene_input_armed
    li t1, 1
    sw t1, 0(t0)
    j end_update_cutscene

check_cutscene_advance:
    call cutscene_advance_pressed
    beqz a0, end_update_cutscene
    j show_current_image_cutscene

advance_cutscene:
    call clear_input_frame

    la t0, game_state
    lw t1, 0(t0)
    li t2, STATE_CUTSCENE_INTRO
    beq t1, t2, advance_cutscene_to_level1
    li t2, STATE_CUTSCENE_LEVEL2
    beq t1, t2, advance_cutscene_to_level2
    li t2, STATE_CUTSCENE_LEVEL3
    beq t1, t2, advance_cutscene_to_level3
    j end_update_cutscene

show_current_image_cutscene:
    call show_image_cutscene
    j advance_cutscene

advance_cutscene_to_level1:
    call set_state_level1
    j finish_advance_cutscene

advance_cutscene_to_level2:
    call set_state_level2
    j finish_advance_cutscene

advance_cutscene_to_level3:
    call set_state_level3

finish_advance_cutscene:
    call clear_input_frame

end_update_cutscene:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

update_post_boss_detonator:
    addi sp, sp, -4
    sw ra, 0(sp)

    # O estado comeca no texto final. Protege contra o evento residual que
    # derrotou/pulou o boss antes de aceitar a troca para a imagem do botao.
    la t0, cutscene_input_armed
    lw t1, 0(t0)
    bnez t1, check_post_boss_detonator_advance

    la t0, key_pressed
    lw t1, 0(t0)
    bnez t1, end_update_post_boss_detonator

    la t0, cutscene_input_armed
    li t1, 1
    sw t1, 0(t0)
    j end_update_post_boss_detonator

check_post_boss_detonator_advance:
    call cutscene_advance_pressed
    beqz a0, end_update_post_boss_detonator
    call show_image_cutscene
    call play_final_countdown_sfx
    j advance_to_post_boss_explosion

advance_to_post_boss_explosion:
    call clear_input_frame
    call set_state_cutscene_explosion
    call clear_input_frame
    j end_update_post_boss_detonator

end_update_post_boss_detonator:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

update_post_boss_explosion:
    addi sp, sp, -4
    sw ra, 0(sp)

    call discard_pending_keyboard_events
    call begin_frame
    call draw_cutscene_screen
    call end_frame
    call play_final_explosion_sfx
    call wait_post_boss_explosion_key
    call set_state_victory

end_update_post_boss_explosion:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

wait_post_boss_explosion_key:
    li t0, KDMMIO_Ctrl
    lw t1, 0(t0)
    andi t1, t1, 1
    beqz t1, wait_post_boss_explosion_key

    li t0, KDMMIO_Data
    lw a0, 0(t0)
    li t2, 32
    beq a0, t2, end_wait_post_boss_explosion_key
    li t2, 10
    beq a0, t2, end_wait_post_boss_explosion_key
    li t2, 13
    bne a0, t2, wait_post_boss_explosion_key

end_wait_post_boss_explosion_key:
    ret

# Renderiza um frame do visor da bomba sem modificar a pixel art original.
# Entrada a0: segundos restantes (0 a 3).
draw_detonator_countdown_frame:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw a0, 4(sp)

    call begin_frame
    call draw_cutscene_screen
    lw a0, 4(sp)
    call draw_detonator_countdown
    call end_frame

    lw ra, 0(sp)
    addi sp, sp, 8
    ret

# Sobrepoe somente os numeros do visor, na faixa x=39..101 e y=41..55.
# Entrada a0: ultimo digito de 00:0x.
draw_detonator_countdown:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw a0, 4(sp)

    call get_draw_base_address
    sw a0, 8(sp)

    # Apaga os digitos antigos, sem tocar na moldura ou no restante do painel.
    li a0, 36
    li a1, 40
    li a2, 68
    li a3, 17
    li a4, COLOR_BLACK
    lw a5, 8(sp)
    call draw_rect

    # Formato fixo: 00:03, 00:02, 00:01 e 00:00.
    li a0, 0
    li a1, 39
    li a2, 41
    lw a5, 8(sp)
    call draw_detonator_timer_digit

    li a0, 0
    li a1, 54
    li a2, 41
    lw a5, 8(sp)
    call draw_detonator_timer_digit

    li a0, 68
    li a1, 44
    li a2, 4
    li a3, 3
    li a4, COLOR_DETONATOR_TIMER
    lw a5, 8(sp)
    call draw_rect

    li a0, 68
    li a1, 51
    li a2, 4
    li a3, 3
    li a4, COLOR_DETONATOR_TIMER
    lw a5, 8(sp)
    call draw_rect

    li a0, 0
    li a1, 75
    li a2, 41
    lw a5, 8(sp)
    call draw_detonator_timer_digit

    lw a0, 4(sp)
    li a1, 90
    li a2, 41
    lw a5, 8(sp)
    call draw_detonator_timer_digit

    lw ra, 0(sp)
    addi sp, sp, 12
    ret

# Digito de sete segmentos 12x16. Entrada: a0=0..3, a1=x, a2=y, a5=frame.
draw_detonator_timer_digit:
    addi sp, sp, -24
    sw ra, 0(sp)
    sw a0, 4(sp)
    sw a1, 8(sp)
    sw a2, 12(sp)
    sw a5, 16(sp)

    li t0, 0x3F                 # 0: abcdef
    lw t1, 4(sp)
    li t2, 1
    beq t1, t2, detonator_timer_digit_one
    li t2, 2
    beq t1, t2, detonator_timer_digit_two
    li t2, 3
    beq t1, t2, detonator_timer_digit_three
    j detonator_timer_mask_ready

detonator_timer_digit_one:
    li t0, 0x06                 # 1: bc
    j detonator_timer_mask_ready

detonator_timer_digit_two:
    li t0, 0x5B                 # 2: abdeg
    j detonator_timer_mask_ready

detonator_timer_digit_three:
    li t0, 0x4F                 # 3: abcdg

detonator_timer_mask_ready:
    sw t0, 20(sp)

    # a: barra superior.
    lw t0, 20(sp)
    andi t0, t0, 0x01
    beqz t0, skip_detonator_segment_a
    lw a0, 8(sp)
    lw a1, 12(sp)
    li a2, 12
    li a3, 2
    li a4, COLOR_DETONATOR_TIMER
    lw a5, 16(sp)
    call draw_rect
skip_detonator_segment_a:

    # b: direita superior.
    lw t0, 20(sp)
    andi t0, t0, 0x02
    beqz t0, skip_detonator_segment_b
    lw a0, 8(sp)
    addi a0, a0, 10
    lw a1, 12(sp)
    addi a1, a1, 2
    li a2, 2
    li a3, 5
    li a4, COLOR_DETONATOR_TIMER
    lw a5, 16(sp)
    call draw_rect
skip_detonator_segment_b:

    # c: direita inferior.
    lw t0, 20(sp)
    andi t0, t0, 0x04
    beqz t0, skip_detonator_segment_c
    lw a0, 8(sp)
    addi a0, a0, 10
    lw a1, 12(sp)
    addi a1, a1, 9
    li a2, 2
    li a3, 5
    li a4, COLOR_DETONATOR_TIMER
    lw a5, 16(sp)
    call draw_rect
skip_detonator_segment_c:

    # d: barra inferior.
    lw t0, 20(sp)
    andi t0, t0, 0x08
    beqz t0, skip_detonator_segment_d
    lw a0, 8(sp)
    lw a1, 12(sp)
    addi a1, a1, 14
    li a2, 12
    li a3, 2
    li a4, COLOR_DETONATOR_TIMER
    lw a5, 16(sp)
    call draw_rect
skip_detonator_segment_d:

    # e: esquerda inferior.
    lw t0, 20(sp)
    andi t0, t0, 0x10
    beqz t0, skip_detonator_segment_e
    lw a0, 8(sp)
    lw a1, 12(sp)
    addi a1, a1, 9
    li a2, 2
    li a3, 5
    li a4, COLOR_DETONATOR_TIMER
    lw a5, 16(sp)
    call draw_rect
skip_detonator_segment_e:

    # f: esquerda superior.
    lw t0, 20(sp)
    andi t0, t0, 0x20
    beqz t0, skip_detonator_segment_f
    lw a0, 8(sp)
    lw a1, 12(sp)
    addi a1, a1, 2
    li a2, 2
    li a3, 5
    li a4, COLOR_DETONATOR_TIMER
    lw a5, 16(sp)
    call draw_rect
skip_detonator_segment_f:

    # g: barra central.
    lw t0, 20(sp)
    andi t0, t0, 0x40
    beqz t0, skip_detonator_segment_g
    lw a0, 8(sp)
    lw a1, 12(sp)
    addi a1, a1, 7
    li a2, 12
    li a3, 2
    li a4, COLOR_DETONATOR_TIMER
    lw a5, 16(sp)
    call draw_rect
skip_detonator_segment_g:

    lw ra, 0(sp)
    addi sp, sp, 24
    ret

# Contagem regressiva do detonador fornecida em
# assets/source/audio/test_som_contagem.s. A imagem do botao ja esta visivel
# e show_image_cutscene so retorna quando o jogador confirma o acionamento.
play_final_countdown_sfx:
    # Esta rotina desenha quatro frames, portanto preserva o retorno para
    # que a contagem siga para a explosao em vez de repetir o ultimo bip.
    addi sp, sp, -4
    sw ra, 0(sp)

    # 3, 2, 1
    li a0, 3
    call draw_detonator_countdown_frame
    la t0, sfx_enabled
    lw t1, 0(t0)
    beqz t1, skip_final_countdown_beep_three
    li a0, 72
    li a1, 90
    li a2, 80
    li a3, 96
    li a7, 31
    ecall
skip_final_countdown_beep_three:

    li a0, 600
    li a7, 32
    ecall

    li a0, 2
    call draw_detonator_countdown_frame
    la t0, sfx_enabled
    lw t1, 0(t0)
    beqz t1, skip_final_countdown_beep_two
    li a0, 76
    li a1, 90
    li a2, 80
    li a3, 96
    li a7, 31
    ecall
skip_final_countdown_beep_two:

    li a0, 600
    li a7, 32
    ecall

    li a0, 1
    call draw_detonator_countdown_frame
    la t0, sfx_enabled
    lw t1, 0(t0)
    beqz t1, skip_final_countdown_beep_one
    li a0, 80
    li a1, 90
    li a2, 80
    li a3, 96
    li a7, 31
    ecall
skip_final_countdown_beep_one:

    li a0, 600
    li a7, 32
    ecall

    # Sinal final: a explosao vem logo depois deste beep longo.
    li a0, 0
    call draw_detonator_countdown_frame
    la t0, sfx_enabled
    lw t1, 0(t0)
    beqz t1, skip_final_countdown_beep_zero
    li a0, 84
    li a1, 320
    li a2, 80
    li a3, 112
    li a7, 31
    ecall
skip_final_countdown_beep_zero:

    li a0, 420
    li a7, 32
    ecall

end_play_final_countdown_sfx:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# Efeito final fornecido: flash, impacto, onda de choque e detritos.
# Esta tela e estatica e ja aguarda uma nova tecla; assim a sequencia mantem
# os intervalos originais sem travar gameplay ou o agendador das musicas.
play_final_explosion_sfx:
    la t0, sfx_enabled
    lw t1, 0(t0)
    beqz t1, end_play_final_explosion_sfx

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

    li a0, 180
    li a7, 32
    ecall

    # Boom principal.
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

    li a0, 260
    li a7, 32
    ecall

    # Onda de choque descendo.
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

    # Detritos e cauda grave final.
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

    li a0, 19
    li a1, 2600
    li a2, 88
    li a3, 68
    li a7, 31
    ecall

end_play_final_explosion_sfx:
    ret

# Entrada a0=score; retorno a0=1 RETRY, a0=0 LEAVE.
game_over_screen:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, game_over_score
    sw a0, 0(t0)
    la t0, game_over_selected
    sw zero, 0(t0)

game_over_redraw:
    call begin_frame
    call draw_game_over_screen
    call end_frame
    call menu_wait_key

    li t0, 'q'
    beq a0, t0, game_over_leave
    li t0, 'Q'
    beq a0, t0, game_over_leave

    li t0, 'w'
    beq a0, t0, game_over_toggle
    li t0, 'W'
    beq a0, t0, game_over_toggle
    li t0, 'k'
    beq a0, t0, game_over_toggle
    li t0, 'K'
    beq a0, t0, game_over_toggle
    li t0, 's'
    beq a0, t0, game_over_toggle
    li t0, 'S'
    beq a0, t0, game_over_toggle
    li t0, 'j'
    beq a0, t0, game_over_toggle
    li t0, 'J'
    beq a0, t0, game_over_toggle

    li t0, 32
    beq a0, t0, game_over_confirm
    li t0, 10
    beq a0, t0, game_over_confirm
    li t0, 13
    beq a0, t0, game_over_confirm
    j game_over_redraw

game_over_toggle:
    la t0, game_over_selected
    lw t1, 0(t0)
    xori t1, t1, 1
    sw t1, 0(t0)
    j game_over_redraw

game_over_confirm:
    la t0, game_over_selected
    lw t1, 0(t0)
    bnez t1, game_over_leave
    call stop_game_over_music
    li a0, 1
    j game_over_return

game_over_leave:
    call stop_game_over_music
    li a0, 0

game_over_return:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# Entrada a0=score; retorno a0=1 MENU, a0=0 LEAVE.
victory_screen:
    addi sp, sp, -4
    sw ra, 0(sp)

    call discard_pending_keyboard_events

    la t0, victory_score
    sw a0, 0(t0)
    la t0, victory_selected
    sw zero, 0(t0)

victory_redraw:
    call begin_frame
    call draw_victory_screen
    call end_frame
    call menu_wait_key

    li t0, 'q'
    beq a0, t0, victory_leave
    li t0, 'Q'
    beq a0, t0, victory_leave

    li t0, 'w'
    beq a0, t0, victory_toggle
    li t0, 'W'
    beq a0, t0, victory_toggle
    li t0, 'k'
    beq a0, t0, victory_toggle
    li t0, 'K'
    beq a0, t0, victory_toggle
    li t0, 's'
    beq a0, t0, victory_toggle
    li t0, 'S'
    beq a0, t0, victory_toggle
    li t0, 'j'
    beq a0, t0, victory_toggle
    li t0, 'J'
    beq a0, t0, victory_toggle

    li t0, 32
    beq a0, t0, victory_confirm
    li t0, 10
    beq a0, t0, victory_confirm
    li t0, 13
    beq a0, t0, victory_confirm
    j victory_redraw

victory_toggle:
    la t0, victory_selected
    lw t1, 0(t0)
    xori t1, t1, 1
    sw t1, 0(t0)
    j victory_redraw

victory_confirm:
    la t0, victory_selected
    lw t1, 0(t0)
    bnez t1, victory_leave
    li a0, 1
    j victory_return

victory_leave:
    li a0, 0

victory_return:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# ------------------------------------------------------------
# reset_game_run
# Reinicializa todos os dados mutaveis da partida.
#
# Nao escolhe o estado final.
# Quem chama decide se vai para menu ou level1.
# ------------------------------------------------------------

reset_game_run:
    addi sp, sp, -4
    sw ra, 0(sp)

    call init_game
    call init_player
    call init_bullets
    call init_enemy_bullets
    call init_enemies
    call init_boss
    call init_inventory
    call init_powerups

    lw ra, 0(sp)
    addi sp, sp, 4

    ret
