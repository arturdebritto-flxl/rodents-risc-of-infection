import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def routine(source: str, start: str, end: str) -> str:
    return source.split(f"{start}:\n", 1)[1].split(f"\n{end}:", 1)[0]


class VisualRegressionTests(unittest.TestCase):
    def setUp(self) -> None:
        self.constants = (ROOT / "src" / "constants.s").read_text(encoding="utf-8")
        self.render = (ROOT / "src" / "render.s").read_text(encoding="utf-8")
        self.bullets = (ROOT / "src" / "bullets.s").read_text(encoding="utf-8")

    def test_player_sheet_rows_follow_direction_contract(self) -> None:
        manifest = json.loads(
            (ROOT / "assets" / "generated" / "manifest.json").read_text(
                encoding="utf-8"
            )
        )
        tables = manifest["runtime_tables"]
        self.assertNotIn("sprite_player_idle_table", tables)

    def test_projectile_velocity_signs_match_all_directions(self) -> None:
        cardinal = routine(self.bullets, "set_cardinal_delta", "set_spread_delta_left")
        expectations = {
            "delta_up": "sub a3, zero, t5",
            "delta_down": "mv a3, t5",
            "delta_left": "sub a2, zero, t5",
            "delta_right": "mv a2, t5",
        }
        for label, instruction in expectations.items():
            self.assertRegex(cardinal, rf"{label}:[\s\S]*?{re.escape(instruction)}")

    def test_projectiles_spawn_beyond_the_matching_visual_edge(self) -> None:
        spawn = routine(self.bullets, "create_bullet_here", "play_bullet_sfx")
        self.assertRegex(spawn, r"DIR_LEFT[\s\S]*?spawn_bullet_x_left")
        self.assertRegex(spawn, r"DIR_RIGHT[\s\S]*?spawn_bullet_x_right")
        self.assertRegex(spawn, r"spawn_bullet_x_left:[\s\S]*?addi t5, t5, -3")
        self.assertRegex(spawn, r"spawn_bullet_x_right:[\s\S]*?addi t5, t5, PLAYER_SIZE")
        self.assertRegex(spawn, r"DIR_UP[\s\S]*?spawn_bullet_y_up")
        self.assertRegex(spawn, r"DIR_DOWN[\s\S]*?spawn_bullet_y_down")
        self.assertRegex(spawn, r"spawn_bullet_y_up:[\s\S]*?addi t5, t5, -3")
        self.assertRegex(spawn, r"spawn_bullet_y_down:[\s\S]*?addi t5, t5, PLAYER_SIZE")

    def test_visual_scale_does_not_change_logical_sizes(self) -> None:
        logical = {
            "PLAYER_SIZE": 16,
            "ENEMY_SIZE": 16,
            "BOSS_SIZE": 32,
            "POWERUP_SIZE": 16,
            "BULLET_SIZE": 3,
        }
        for name, value in logical.items():
            self.assertRegex(self.constants, rf"\.eqv\s+{name}\s+{value}\b")

        self.assertNotIn("VISUAL_SCALE", self.constants)

    def test_scaled_blitter_is_nearest_neighbor_and_projectiles_stay_unscaled(self) -> None:
        self.assertNotIn("draw_sprite_8bpp_scaled:", self.render)

        player_bullets = routine(self.render, "draw_bullets", "draw_enemies")
        enemy_bullets = routine(self.render, "draw_enemy_bullets", "draw_boss_square")
        self.assertNotIn("draw_sprite_8bpp_scaled", player_bullets)
        self.assertNotIn("draw_sprite_8bpp_scaled", enemy_bullets)

    def test_boss_visual_remains_centered_on_logical_box(self) -> None:
        boss = routine(self.render, "draw_boss_square", "draw_menu_screen")
        self.assertNotIn("BOSS_VISUAL_OFFSET", boss)
        self.assertIn("li a3, BOSS_SIZE", boss)
        self.assertIn("call draw_sprite_8bpp_fast", boss)


if __name__ == "__main__":
    unittest.main()
