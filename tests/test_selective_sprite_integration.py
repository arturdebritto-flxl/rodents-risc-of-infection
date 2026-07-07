import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def eqv(source: str, name: str) -> int:
    match = re.search(rf"^\.eqv\s+{name}\s+(-?\d+)\s*$", source, re.MULTILINE)
    if not match:
        raise AssertionError(f"missing constant {name}")
    return int(match.group(1))


def routine(source: str, start: str, end: str) -> str:
    return source.split(f"{start}:\n", 1)[1].split(f"\n{end}:", 1)[0]


class SelectiveSpriteIntegrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.constants = (ROOT / "src/constants.s").read_text(encoding="utf-8")
        cls.render = (ROOT / "src/render.s").read_text(encoding="utf-8")
        cls.powerups = (ROOT / "src/powerups.s").read_text(encoding="utf-8")
        cls.bullets = (ROOT / "src/bullets.s").read_text(encoding="utf-8")
        cls.collision = (ROOT / "src/collision.s").read_text(encoding="utf-8")
        cls.inventory = (ROOT / "src/inventory.s").read_text(encoding="utf-8")
        manifest = json.loads(
            (ROOT / "assets/generated/manifest.json").read_text(encoding="utf-8")
        )
        cls.runtime = {
            record["symbol"]: record for record in manifest["runtime_sprites"]
        }

    def test_unapproved_entities_use_baseline_sources_and_sizes(self) -> None:
        expected = {
            "sprite_player_down_0": ("sprite_00.png", [16, 16]),
            "sprite_enemy_common_0": ("sprites/image-1.png.png", [16, 16]),
            "sprite_enemy_echo_0": ("sprites/image-12.png.png", [16, 16]),
            "sprite_enemy_mutant_0": ("sprites/image-10.png.png", [16, 16]),
            "sprite_boss_0": ("sprites/New Piskel-1.png.png", [32, 32]),
            "sprite_powerup_boss_weapon": ("sprite_0.png", [16, 16]),
            "sprite_weapon_normal_icon": ("sprite_0.png", [16, 16]),
            "sprite_weapon_shotgun_icon": ("sprite_4.png", [16, 16]),
            "sprite_weapon_boss_icon": ("sprite_2.png", [16, 16]),
        }
        for symbol, (source, size) in expected.items():
            with self.subTest(symbol=symbol):
                self.assertEqual(source, self.runtime[symbol]["source"])
                self.assertEqual(size, self.runtime[symbol]["output_size"])

    def test_only_approved_final_asset_categories_are_runtime_mapped(self) -> None:
        final_sources = {
            record["source"]
            for record in self.runtime.values()
            if record["group"] == "_final_sprites"
        }
        self.assertTrue(final_sources)
        self.assertTrue(all(
            source.startswith("05_MUNICAO_E_MEDKIT_8x8/")
            or source.startswith("06_PROJETEIS/")
            for source in final_sources
        ))

    def test_spitter_uses_original_two_frame_contract(self) -> None:
        self.assertEqual(
            "sprites/image-18.png.png", self.runtime["sprite_enemy_spitter_0"]["source"]
        )
        self.assertEqual(
            "sprites/image-19.png.png", self.runtime["sprite_enemy_spitter_1"]["source"]
        )
        enemies = routine(self.render, "draw_enemies", "draw_enemy_bullets")
        self.assertIn("sprite_enemy_spitter_0", enemies)
        self.assertIn("sprite_enemy_spitter_1", enemies)
        self.assertNotIn("sprite_enemy_spitter_walk_1_table", enemies)

    def test_rendering_has_baseline_sizes_and_no_generic_scaler(self) -> None:
        for name, value in {
            "PLAYER_SIZE": 16,
            "ENEMY_SIZE": 16,
            "BOSS_SIZE": 32,
            "POWERUP_SIZE": 16,
            "BULLET_SIZE": 3,
        }.items():
            self.assertEqual(value, eqv(self.constants, name))
        self.assertNotIn("VISUAL_SCALE", self.constants)
        self.assertNotIn("draw_sprite_8bpp_scaled:", self.render)
        player = routine(self.render, "draw_player_square", "draw_bullets")
        boss = routine(self.render, "draw_boss_square", "draw_menu_screen")
        self.assertIn("sprite_player_down_0", player)
        self.assertIn("call draw_sprite_8bpp_fast", player)
        self.assertIn("sprite_boss_0", boss)
        self.assertIn("call draw_sprite_8bpp_fast", boss)

    def test_new_pickups_are_centered_without_changing_hitbox(self) -> None:
        draw = routine(self.powerups, "draw_powerups", "end_draw_powerups")
        for symbol in (
            "sprite_ammo_pistol_pickup",
            "sprite_ammo_shotgun_pickup",
            "sprite_ammo_uzi_pickup",
            "sprite_medkit_pickup",
        ):
            self.assertIn(symbol, self.render)
        self.assertIn("addi a0, a0, 4", draw)
        self.assertIn("addi a1, a1, 4", draw)
        self.assertIn("li a3, 8", draw)
        self.assertEqual(16, eqv(self.constants, "POWERUP_SIZE"))

    def test_drop_cycle_preserves_seven_of_fifteen_and_allows_none(self) -> None:
        cycle = eqv(self.constants, "DROP_CYCLE_LENGTH")
        heal = eqv(self.constants, "DROP_HEAL_INTERVAL")
        ammo = eqv(self.constants, "DROP_AMMO_INTERVAL")
        results = [
            "heal" if roll % heal == 0 else "ammo" if roll % ammo == 0 else "none"
            for roll in range(1, cycle + 1)
        ]
        self.assertEqual((7, 8, 3, 4), (
            sum(result != "none" for result in results),
            results.count("none"),
            results.count("heal"),
            results.count("ammo"),
        ))
        flow = routine(
            self.powerups,
            "spawn_powerup_from_enemy_death",
            "select_ammo_powerup_for_level",
        )
        self.assertIn("bnez t3, end_spawn_powerup_from_enemy_death", flow)
        self.assertIn("call select_ammo_powerup_for_level", flow)

    def test_ammo_weights_are_phase_limited(self) -> None:
        expected = {
            "AMMO_WEIGHT_PISTOL_PHASE1": 100,
            "AMMO_WEIGHT_PISTOL_PHASE2": 75,
            "AMMO_WEIGHT_SHOTGUN_PHASE2": 25,
            "AMMO_WEIGHT_PISTOL_PHASE3": 25,
            "AMMO_WEIGHT_SHOTGUN_PHASE3": 25,
            "AMMO_WEIGHT_UZI_PHASE3": 50,
        }
        for name, value in expected.items():
            self.assertEqual(value, eqv(self.constants, name))
        selector = routine(
            self.powerups, "select_ammo_powerup_for_level", "spawn_boss_powerups"
        )
        self.assertIn("LEVEL_SEWER", selector)
        self.assertIn("LEVEL_LABORATORY", selector)
        self.assertIn("POWERUP_SHOTGUN_AMMO", selector)
        self.assertIn("POWERUP_BOSS_AMMO", selector)

    def test_only_phase2_wave_counts_changed(self) -> None:
        actual = [eqv(self.constants, f"SEWER_WAVE{i}_ENEMIES") for i in range(1, 6)]
        self.assertEqual([6, 7, 7, 8, 9], actual)
        self.assertEqual(sorted(actual), actual)
        self.assertEqual(26.0, (50 - sum(actual)) * 100 / 50)
        self.assertEqual([4, 5, 6, 7], [eqv(self.constants, f"TOWN_WAVE{i}_ENEMIES") for i in range(1, 5)])
        self.assertEqual([13, 14, 15], [eqv(self.constants, f"LABORATORY_WAVE{i}_ENEMIES") for i in range(1, 4)])

    def test_projectile_signs_and_front_edge_spawns_remain_correct(self) -> None:
        cardinal = routine(self.bullets, "set_cardinal_delta", "set_spread_delta_left")
        for instruction in (
            "sub a3, zero, t5",
            "mv a3, t5",
            "sub a2, zero, t5",
            "mv a2, t5",
        ):
            self.assertIn(instruction, cardinal)
        spawn = routine(self.bullets, "create_bullet_here", "play_bullet_sfx")
        self.assertIn("addi t5, t5, -3", spawn)
        self.assertIn("addi t5, t5, PLAYER_SIZE", spawn)

    def test_bullet_loop_rejects_indices_at_or_above_capacity(self) -> None:
        movement = routine(self.bullets, "move_bullets", "end_move_bullets")
        self.assertIn("bge t1, t2, end_move_bullets", movement)
        self.assertNotIn("beq t1, t2, end_move_bullets", movement)

    def test_weapons_equip_only_after_their_ground_drop_is_collected(self) -> None:
        self.assertEqual(6, eqv(self.constants, "POWERUP_SHOTGUN_WEAPON"))
        death = routine(
            self.collision, "apply_rat_score", "next_collision_enemy"
        )
        self.assertNotIn("call unlock_shotgun", death)
        spawn = routine(
            self.powerups, "maybe_spawn_shotgun_weapon_drop", "spawn_boss_powerups"
        )
        self.assertIn("POWERUP_SHOTGUN_WEAPON", spawn)
        collect = routine(
            self.powerups, "powerup_collision_loop", "end_player_powerup_collisions"
        )
        self.assertRegex(
            collect, r"POWERUP_SHOTGUN_WEAPON[\s\S]*?collect_shotgun_weapon"
        )
        self.assertRegex(collect, r"collect_shotgun_weapon:[\s\S]*?call unlock_shotgun")
        self.assertRegex(
            collect,
            r"collect_shotgun_weapon:[\s\S]*?sw t1, 4\(sp\)[\s\S]*?"
            r"call unlock_shotgun[\s\S]*?lw t1, 4\(sp\)",
        )
        self.assertRegex(
            collect, r"POWERUP_BOSS_WEAPON[\s\S]*?collect_boss_weapon"
        )
        init = routine(self.inventory, "init_inventory", "update_inventory")
        self.assertRegex(init, r"weapon_type[\s\S]*?WEAPON_NORMAL")

    def test_ground_weapon_sprites_and_invalid_type_guard_are_explicit(self) -> None:
        draw = routine(self.powerups, "draw_powerups", "end_draw_powerups")
        self.assertIn("sprite_weapon_shotgun_icon", draw)
        self.assertIn("sprite_weapon_boss_icon", draw)
        self.assertIn("blt t6, t5, next_draw_powerup", draw)


if __name__ == "__main__":
    unittest.main()
