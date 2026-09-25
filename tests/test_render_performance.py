import hashlib
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class RenderPerformanceTests(unittest.TestCase):
    def test_supplied_menu_data_is_used_byte_for_byte(self):
        source = ROOT / "assets" / "source" / "menus" / "menu_game.data"
        runtime = ROOT / "assets" / "generated" / "menus" / "menu_game.data"
        current_menu_hash = "1a83ca90e57d11f8a33aadb2e21e5ddb368f54a5675ac81c0e52ac8df0531e57"
        self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(), current_menu_hash)
        self.assertEqual(hashlib.sha256(runtime.read_bytes()).hexdigest(), current_menu_hash)

    def test_menu_navigation_only_redraws_overlay(self):
        screens = (ROOT / "src" / "screens.s").read_text(encoding="utf-8")
        render = (ROOT / "src" / "render.s").read_text(encoding="utf-8")
        self.assertIn("call draw_menu_selection_overlay", screens)
        self.assertIn("call mirror_visible_frame_to_draw_frame", screens)
        self.assertIn("draw_menu_selection_overlay:", render)

    def test_full_maps_skip_redundant_clear_and_use_unrolled_copy(self):
        render = (ROOT / "src" / "render.s").read_text(encoding="utf-8")
        begin = render[render.index("begin_frame:"):render.index("clear_draw_frame:")]
        self.assertIn("LEVEL_TOWN", begin)
        self.assertIn("LEVEL_SEWER", begin)
        self.assertNotIn("bne t1, t2, clear_draw_frame", begin)
        copy = render[render.index("copy_full_screen_words:"):
                      render.index("mirror_visible_frame_to_draw_frame:")]
        self.assertIn("li t2, 2400", copy)
        self.assertIn("lw t3, 28(a0)", copy)
        self.assertIn("sw t3, 28(a1)", copy)

    def test_frame_delay_subtracts_work_already_spent(self):
        loop = (ROOT / "src" / "game_loop.s").read_text(encoding="utf-8")
        delay = loop[loop.index("frame_delay:"):loop.index("debug_stop_after_frames:")]
        self.assertIn("frame_start_time", delay)
        self.assertIn("sub t2, a0, t1", delay)
        self.assertIn("sub a0, t3, t2", delay)
        self.assertIn("TARGET_FRAME_TIME_MS", delay)


if __name__ == "__main__":
    unittest.main()
