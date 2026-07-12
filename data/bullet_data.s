# ============================================================
# Dados dos tiros
# ============================================================

.data

bullet_x:               .space 96
bullet_y:               .space 96
bullet_dx:              .space 96
bullet_dy:              .space 96
bullet_direction:       .space 96
bullet_active:          .space 96
bullet_damage:          .space 96
shoot_direction:        .word DIR_UP
shoot_hold_timer:       .word 0
player_burst_weapon:    .word 0
player_burst_direction: .word DIR_UP
player_burst_remaining: .word 0
player_burst_interval_timer: .word 0
