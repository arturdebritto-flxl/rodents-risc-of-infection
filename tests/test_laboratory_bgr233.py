import hashlib
import re
import unittest

from tools import build_laboratory_bgr233


class LaboratoryBgr233BuildTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.result = build_laboratory_bgr233.build(write=False)

    def test_sources_and_exact_exit_mask(self):
        self.assertEqual(self.result.source_size, (320, 240))
        self.assertTrue(self.result.sources_opaque)
        self.assertEqual(len(self.result.original_difference_offsets), 114)
        self.assertEqual(self.result.metrics["overlay_bbox"], (299, 10, 310, 58))

    def test_deterministic_bgr233_conversion(self):
        source, _, _ = build_laboratory_bgr233.load_sources()
        expected = bytes(
            build_laboratory_bgr233.encode_laboratory_pixel(
                red, green, blue, offset % 320, offset // 320
            )
            for offset, (red, green, blue, _) in enumerate(source.get_flattened_data())
        )
        self.assertEqual(self.result.base, expected)
        self.assertEqual(len(self.result.base), 76_800)

    def test_dominant_floor_average_is_closer_than_one_solid_bgr233_color(self):
        source, _, _ = build_laboratory_bgr233.load_sources()
        offsets = tuple(
            offset for offset, rgba in enumerate(source.get_flattened_data())
            if rgba[:3] == build_laboratory_bgr233.DOMINANT_FLOOR_RGB
        )
        converted = [build_laboratory_bgr233.decode_bgr233(self.result.base[offset])
                     for offset in offsets]
        average = tuple(sum(pixel[channel] for pixel in converted) / len(converted)
                        for channel in range(3))
        target = build_laboratory_bgr233.DOMINANT_FLOOR_RGB
        nearest = build_laboratory_bgr233.decode_bgr233(
            build_laboratory_bgr233.encode_bgr233(*target)
        )
        average_error = sum((average[i] - target[i]) ** 2 for i in range(3))
        nearest_error = sum((nearest[i] - target[i]) ** 2 for i in range(3))
        self.assertLess(average_error, nearest_error)

    def test_overlay_changes_only_the_supplied_114_pixels(self):
        converted = tuple(
            offset for offset, pair in enumerate(zip(self.result.base, self.result.highlight))
            if pair[0] != pair[1]
        )
        self.assertEqual(converted, self.result.original_difference_offsets)
        self.assertEqual(converted, tuple(offset for offset, _ in self.result.overlay))

    def test_generation_is_deterministic(self):
        repeated = build_laboratory_bgr233.build(write=False)
        self.assertEqual(self.result.files, repeated.files)
        self.assertEqual(hashlib.sha256(self.result.base).digest(),
                         hashlib.sha256(repeated.base).digest())


class LaboratoryIntegrationTests(unittest.TestCase):
    def test_renderer_uses_full_map_and_exit_overlay(self):
        root = build_laboratory_bgr233.ROOT
        render = (root / "src" / "render.s").read_text(encoding="utf-8")
        self.assertIn('.include "../assets/generated/laboratory_bgr233.s"', render)
        self.assertIn("la a0, laboratory_bgr233_base_pixels", render)
        self.assertIn("la t0, laboratory_bgr233_exit_overlay_pixels", render)
        self.assertIn("li t2, 114", render)
        background = render[render.index("draw_background:"):render.index("draw_town_background:")]
        self.assertLess(background.index("beq t1, t2, draw_laboratory_background"),
                        background.index("call draw_rect"))

    def test_exit_unlocks_after_wave_three_and_starts_boss(self):
        root = build_laboratory_bgr233.ROOT
        manager = (root / "src" / "level_manager.s").read_text(encoding="utf-8")
        loop = (root / "src" / "game_loop.s").read_text(encoding="utf-8")
        self.assertIn("finish_laboratory:", manager)
        self.assertIn("update_laboratory_exit:", manager)
        self.assertIn("call start_boss_fight", manager)
        self.assertIn("call update_laboratory_exit", loop)

    def test_collision_table_matches_five_solid_lab_objects(self):
        root = build_laboratory_bgr233.ROOT
        data = (root / "data" / "game_data.s").read_text(encoding="utf-8")
        player = (root / "src" / "player.s").read_text(encoding="utf-8")
        for rectangle in (
            "253,29,278,66", "38,72,90,85", "20,105,53,139",
            "43,156,155,201", "235,172,286,209",
        ):
            self.assertIn(rectangle, data)
        self.assertIn("la t6, laboratory_collision_aabbs", player)

    def test_all_twenty_spawn_points_are_inside_the_map_and_clear(self):
        root = build_laboratory_bgr233.ROOT
        data = (root / "data" / "enemy_data.s").read_text(encoding="utf-8")
        section = data.split("laboratory_enemy_spawn_points:", 1)[1]
        values = tuple(map(int, re.findall(r"\d+", section)))
        points = tuple(zip(values[::2], values[1::2]))
        obstacles = (
            (253, 29, 278, 66), (38, 72, 90, 85), (20, 105, 53, 139),
            (43, 156, 155, 201), (235, 172, 286, 209),
        )
        self.assertEqual(len(points), 20)
        for x, y in points:
            self.assertGreaterEqual(x, 10)
            self.assertGreaterEqual(y, 20)
            self.assertLessEqual(x + 16, 310)
            self.assertLessEqual(y + 16, 216)
            for x0, y0, x1, y1 in obstacles:
                overlaps = x < x1 and x + 16 > x0 and y < y1 and y + 16 > y0
                self.assertFalse(overlaps, (x, y, x0, y0, x1, y1))

    def test_laboratory_waves_are_staged_to_protect_frame_rate(self):
        root = build_laboratory_bgr233.ROOT
        constants = (root / "src" / "constants.s").read_text(encoding="utf-8")
        enemies = (root / "src" / "enemies.s").read_text(encoding="utf-8")
        manager = (root / "src" / "level_manager.s").read_text(encoding="utf-8")
        self.assertIn(".eqv LABORATORY_MAX_ACTIVE_ENEMIES 6", constants)
        self.assertIn("spawn_laboratory_enemy_if_needed:", enemies)
        self.assertIn("call spawn_one_laboratory_enemy", enemies)
        self.assertIn("li t0, LABORATORY_MAX_ACTIVE_ENEMIES", enemies)
        self.assertIn("get_laboratory_wave_enemy_count:", manager)
        self.assertGreaterEqual(manager.count("li t1, LABORATORY_FIRST_SPAWN_DELAY"), 3)


if __name__ == "__main__":
    unittest.main()
