from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class GodModeCheatIntegrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.constants = (ROOT / "src" / "constants.s").read_text(encoding="utf-8")
        cls.data = (ROOT / "data" / "game_data.s").read_text(encoding="utf-8")
        cls.inventory = (ROOT / "src" / "inventory.s").read_text(encoding="utf-8")
        cls.bullets = (ROOT / "src" / "bullets.s").read_text(encoding="utf-8")
        cls.player = (ROOT / "src" / "player.s").read_text(encoding="utf-8")
        cls.collision = (ROOT / "src" / "collision.s").read_text(encoding="utf-8")
        cls.boss = (ROOT / "src" / "boss.s").read_text(encoding="utf-8")
        cls.game_state = (ROOT / "src" / "game_state.s").read_text(encoding="utf-8")
        cls.game_loop = (ROOT / "src" / "game_loop.s").read_text(encoding="utf-8")
        cls.render = (ROOT / "src" / "render.s").read_text(encoding="utf-8")

    def test_g_activates_in_every_gameplay_state(self):
        self.assertIn("li t2, 'g'", self.inventory)
        self.assertIn("li t2, 'G'", self.inventory)
        self.assertNotIn("'g'", self.bullets + self.player)
        self.assertNotIn("'G'", self.bullets + self.player)
        for state in ("STATE_LEVEL1", "STATE_LEVEL2", "STATE_LEVEL3", "STATE_BOSS"):
            self.assertIn(f"li t2, {state}", self.inventory)
        self.assertIn("activate_god_mode_cheat:", self.inventory)
        self.assertIn("god_mode_enabled:       .word 0", self.data)

    def test_activation_grants_all_weapons_and_infinite_resources(self):
        maintain = self.inventory.split("maintain_god_mode_cheat:", 1)[1].split(
            "end_handle_god_mode_cheat:", 1
        )[0]
        for symbol in (
            "player_lives", "shotgun_owned", "boss_weapon_owned",
            "normal_ammo_count", "shotgun_ammo_count", "boss_ammo_count",
            "rifle_mag_count", "shotgun_mag_count", "rifle_reload_timer",
            "shotgun_reload_timer",
        ):
            self.assertIn(f"la t0, {symbol}", maintain)
        self.assertIn(".eqv CHEAT_INFINITE_AMMO_COUNT 999", self.constants)
        self.assertIn("li t1, CHEAT_INFINITE_AMMO_COUNT", maintain)

    def test_cheat_runs_before_updates_and_is_reasserted_after_collisions(self):
        loop = self.game_loop.split("loop_playing_level:", 1)[1]
        self.assertLess(loop.index("call handle_god_mode_cheat"), loop.index("call update_player"))
        self.assertGreater(
            loop.index("call maintain_god_mode_cheat"),
            loop.index("call check_enemy_bullet_player_collisions"),
        )
        self.assertLess(loop.index("call maintain_god_mode_cheat"), loop.index("call advance_wave"))

    def test_ammo_is_not_decremented_while_enabled(self):
        uzi = self.bullets.split("spawn_uzi_bullet:", 1)[1].split("prepare_pistol_shot:", 1)[0]
        pistol = self.bullets.split("prepare_pistol_shot:", 1)[1].split("spawn_shotgun_blast:", 1)[0]
        shotgun = self.bullets.split("spawn_shotgun_blast:", 1)[1].split(
            "try_start_shotgun_reload_from_shot:", 1
        )[0]
        self.assertIn("bnez t2, arm_uzi_cooldown", uzi)
        self.assertIn("bnez t2, arm_pistol_cooldown", pistol)
        self.assertIn("bnez t2, arm_shotgun_cooldown", shotgun)

    def test_every_player_damage_path_respects_invincibility(self):
        self.assertGreaterEqual(self.collision.count("la t0, god_mode_enabled"), 2)
        self.assertIn("bnez t6, end_enemy_player_collisions", self.collision)
        self.assertIn("bnez t5, next_enemy_bullet_player", self.collision)
        self.assertIn("bnez t1, boss_melee_invincible", self.boss)
        self.assertIn("beqz t1, apply_game_over_state", self.game_state)

    def test_hud_shows_inf_and_new_run_resets_the_cheat(self):
        self.assertIn('label_ammo_infinite: .asciz "INF"', self.render)
        self.assertIn("bnez t1, draw_infinite_ammo_value", self.inventory)
        init_game = self.game_state.split("init_game:", 1)[1].split(
            "clear_input_buffers:", 1
        )[0]
        self.assertIn("la t0, god_mode_enabled", init_game)
        self.assertIn("sw zero, 0(t0)", init_game)


if __name__ == "__main__":
    unittest.main()
