import hashlib
import unittest

from tools import build_sewer_bgr233


class SewerBgr233BuildTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.result = build_sewer_bgr233.build(write=False)

    def test_sources_and_exact_exit_mask(self):
        self.assertEqual(self.result.source_size, (320, 240))
        self.assertTrue(self.result.sources_opaque)
        self.assertEqual(len(self.result.original_difference_offsets), 42)
        self.assertEqual(self.result.metrics["overlay_bbox"], (20, 0, 54, 11))

    def test_deterministic_bgr233_conversion(self):
        source, _, _ = build_sewer_bgr233.load_sources()
        expected = bytes(
            build_sewer_bgr233.encode_sewer_pixel(red, green, blue, offset % 320, offset // 320)
            for offset, (red, green, blue, _) in enumerate(source.get_flattened_data())
        )
        self.assertEqual(self.result.base, expected)
        self.assertEqual(len(self.result.base), 76_800)
        self.assertEqual(self.result.preview_base_rgb,
                         tuple(build_sewer_bgr233.decode_bgr233(value) for value in expected))

    def test_dominant_floor_average_is_closer_to_the_png(self):
        source, _, _ = build_sewer_bgr233.load_sources()
        offsets = tuple(
            offset for offset, rgba in enumerate(source.get_flattened_data())
            if rgba[:3] == build_sewer_bgr233.DOMINANT_FLOOR_RGB
        )
        converted = [build_sewer_bgr233.decode_bgr233(self.result.base[offset]) for offset in offsets]
        average = tuple(sum(pixel[channel] for pixel in converted) / len(converted) for channel in range(3))
        target = build_sewer_bgr233.DOMINANT_FLOOR_RGB
        nearest = build_sewer_bgr233.decode_bgr233(build_sewer_bgr233.encode_bgr233(*target))
        average_error = sum((average[i] - target[i]) ** 2 for i in range(3))
        nearest_error = sum((nearest[i] - target[i]) ** 2 for i in range(3))
        self.assertLess(average_error, nearest_error)

    def test_overlay_changes_only_the_supplied_42_pixels(self):
        converted = tuple(
            offset for offset, pair in enumerate(zip(self.result.base, self.result.highlight))
            if pair[0] != pair[1]
        )
        self.assertEqual(converted, self.result.original_difference_offsets)
        self.assertEqual(converted, tuple(offset for offset, _ in self.result.overlay))

    def test_generation_is_deterministic(self):
        repeated = build_sewer_bgr233.build(write=False)
        self.assertEqual(self.result.files, repeated.files)
        self.assertEqual(hashlib.sha256(self.result.base).digest(),
                         hashlib.sha256(repeated.base).digest())


class SewerBgr233IntegrationTests(unittest.TestCase):
    def test_renderer_uses_full_map_and_42_pixel_overlay(self):
        root = build_sewer_bgr233.ROOT
        render = (root / "src" / "render.s").read_text(encoding="utf-8")
        self.assertIn('.include "../assets/generated/sewer_bgr233.s"', render)
        self.assertIn("la a0, sewer_bgr233_base_pixels", render)
        self.assertIn("la t0, sewer_bgr233_exit_overlay_pixels", render)
        self.assertIn("call copy_full_screen_words", render)
        self.assertIn("li t2, 42", render)

    def test_sewer_is_selected_before_draw_rect_clobbers_current_level(self):
        root = build_sewer_bgr233.ROOT
        render = (root / "src" / "render.s").read_text(encoding="utf-8")
        background = render[render.index("draw_background:"):render.index("draw_town_background:")]
        sewer_branch = background.index("beq t1, t2, draw_sewer_background")
        first_draw_rect = background.index("call draw_rect")
        self.assertLess(sewer_branch, first_draw_rect)

    def test_exit_unlocks_after_wave_five_and_blinks_near_exit(self):
        root = build_sewer_bgr233.ROOT
        manager = (root / "src" / "level_manager.s").read_text(encoding="utf-8")
        loop = (root / "src" / "game_loop.s").read_text(encoding="utf-8")
        self.assertIn("finish_sewer:", manager)
        self.assertIn("la t0, sewer_exit_unlocked", manager)
        self.assertIn("update_sewer_exit:", manager)
        self.assertIn("xori t1, t1, 1", manager)
        self.assertIn("call set_state_cutscene_level3", manager)
        self.assertIn("call update_sewer_exit", loop)

    def test_collision_table_matches_the_four_striped_barriers(self):
        root = build_sewer_bgr233.ROOT
        data = (root / "data" / "game_data.s").read_text(encoding="utf-8")
        player = (root / "src" / "player.s").read_text(encoding="utf-8")
        for rectangle in ("79,36,91,70", "157,38,295,53", "53,155,67,202", "205,172,301,187"):
            self.assertIn(rectangle, data)
        self.assertIn("la t6, sewer_collision_aabbs", player)


if __name__ == "__main__":
    unittest.main()
