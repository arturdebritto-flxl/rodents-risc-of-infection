import unittest

from tools import fix_gameover_title


VALID_ADVANCE_KEYS = {10, 13, 32}


class CutsceneGateHarness:
    """Small model of the text-first phase-cutscene input flow."""

    def __init__(self):
        self.armed = False
        self.screen = "text"

    def frame(self, key=None):
        if not self.armed:
            if key is None:
                self.armed = True
            return self.screen
        if key in VALID_ADVANCE_KEYS:
            if self.screen == "text":
                self.screen = "image"
            elif self.screen == "image":
                self.screen = "level"
        return self.screen


class GameOverTitleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.result = fix_gameover_title.build()

    def test_checked_in_asset_is_current_and_idempotent(self):
        self.assertEqual(fix_gameover_title.ASSET_PATH.read_bytes(), self.result.content)
        self.assertEqual(
            fix_gameover_title.fix_title(self.result.payload),
            self.result.payload,
        )

    def test_run_table_round_trips_every_pixel(self):
        _, decoded = fix_gameover_title.parse_asset(self.result.content.decode("ascii"))
        self.assertEqual(len(decoded), 320 * 240)
        self.assertEqual(decoded, self.result.payload)

    def test_title_spells_voce_foi_with_the_original_colored_glyphs(self):
        self.assertEqual(
            tuple((letter, offset) for letter, offset in fix_gameover_title.TITLE_LETTERS),
            (("V", 0), ("O", 16), ("C", 32), ("E", 47), ("F", 67), ("O", 79), ("I", 95)),
        )
        for letter, offset in fix_gameover_title.TITLE_LETTERS:
            with self.subTest(letter=letter, offset=offset):
                for x, y, color in fix_gameover_title.glyph_points(
                    fix_gameover_title.GLYPHS[letter]
                ):
                    pixel_x = fix_gameover_title.TITLE_START_X + offset + x
                    pixel_y = fix_gameover_title.TITLE_Y + y
                    index = pixel_y * fix_gameover_title.SCREEN_WIDTH + pixel_x
                    self.assertEqual(self.result.payload[index], color)

        accent_x = fix_gameover_title.TITLE_START_X + 47
        for x, y in (
            (accent_x + 2, 24),
            (accent_x + 3, 23),
            (accent_x + 4, 22),
            (accent_x + 5, 22),
            (accent_x + 6, 23),
            (accent_x + 7, 24),
        ):
            self.assertEqual(
                self.result.payload[y * fix_gameover_title.SCREEN_WIDTH + x],
                0x0C,
            )

    def test_repair_never_changes_pixels_outside_the_title_box(self):
        damaged = bytearray(self.result.payload)
        x0, y0, x1, y1 = fix_gameover_title.TITLE_BOX
        for y in range(y0, y1):
            for x in range(x0, x1):
                damaged[y * fix_gameover_title.SCREEN_WIDTH + x] = 0xFF
        repaired = fix_gameover_title.fix_title(bytes(damaged))

        for y in range(fix_gameover_title.SCREEN_HEIGHT):
            for x in range(fix_gameover_title.SCREEN_WIDTH):
                if x0 <= x < x1 and y0 <= y < y1:
                    continue
                index = y * fix_gameover_title.SCREEN_WIDTH + x
                self.assertEqual(repaired[index], damaged[index])


class TextFirstCutsceneTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        root = fix_gameover_title.ROOT
        cls.data = (root / "data" / "game_data.s").read_text(encoding="utf-8")
        cls.state = (root / "src" / "game_state.s").read_text(encoding="utf-8")
        cls.screens = (root / "src" / "screens.s").read_text(encoding="utf-8")
        cls.loop = (root / "src" / "game_loop.s").read_text(encoding="utf-8")
        cls.render = (root / "src" / "render.s").read_text(encoding="utf-8")

    def test_residual_start_event_cannot_skip_the_text(self):
        cutscene = CutsceneGateHarness()
        self.assertEqual(cutscene.frame(13), "text")
        self.assertFalse(cutscene.armed)
        self.assertEqual(cutscene.frame(), "text")
        self.assertTrue(cutscene.armed)
        self.assertEqual(cutscene.frame(13), "image")
        self.assertEqual(cutscene.frame(13), "level")

    def test_gate_is_declared_and_reset_on_every_state_change(self):
        self.assertIn("cutscene_input_armed:   .word 0", self.data)
        clear_buffers = self.state[
            self.state.index("clear_input_buffers:") : self.state.index("set_state_level1:")
        ]
        self.assertIn("la t0, cutscene_input_armed", clear_buffers)
        self.assertIn("sw zero, 0(t0)", clear_buffers)

    def test_all_three_phase_cutscenes_are_initialized_with_text_visible(self):
        for label in (
            "set_state_cutscene_intro:",
            "set_state_cutscene_level2:",
            "set_state_cutscene_level3:",
        ):
            with self.subTest(label=label):
                start = self.state.index(label)
                end = self.state.index("\n\n", start)
                self.assertIn("j prepare_text_first_cutscene", self.state[start:end])

        prepare = self.state[
            self.state.index("prepare_text_first_cutscene:") : self.state.index(
                "set_state_cutscene_detonator:"
            )
        ]
        self.assertLess(
            prepare.index("call clear_input_buffers"),
            prepare.index("la t0, cutscene_text_visible"),
        )
        self.assertIn("li t1, 1", prepare)
        self.assertIn("sw t1, 0(t0)", prepare)

    def test_assembly_arms_only_after_a_frame_without_an_event(self):
        update = self.screens[
            self.screens.index("update_cutscene:") : self.screens.index("advance_cutscene:")
        ]
        expected_in_order = (
            "la t0, cutscene_input_armed",
            "bnez t1, check_cutscene_advance",
            "la t0, key_pressed",
            "bnez t1, end_update_cutscene",
            "li t1, 1",
            "check_cutscene_advance:",
            "call cutscene_advance_pressed",
            "j show_current_image_cutscene",
        )
        cursor = 0
        for instruction in expected_in_order:
            next_cursor = update.find(instruction, cursor)
            self.assertNotEqual(next_cursor, -1, instruction)
            cursor = next_cursor + len(instruction)

    def test_loop_draws_text_before_update_then_selects_the_image(self):
        loop = self.loop[
            self.loop.index("loop_cutscene:") : self.loop.index("loop_post_boss_detonator:")
        ]
        self.assertLess(loop.index("call draw_cutscene_screen"), loop.index("call update_cutscene"))

        draw = self.render[
            self.render.index("draw_cutscene_screen:") : self.render.index("draw_game_over_screen:")
        ]
        self.assertIn("beqz t3, select_image_cutscene", draw)
        self.assertIn("select_cutscene_intro:", draw)
        self.assertIn("la t0, cutscene_intro_pixels", draw)
        self.assertIn("select_text_cutscene_intro:", draw)
        self.assertIn("la t0, text_cutscene_0_pixels", draw)

        update = self.screens[
            self.screens.index("show_current_image_cutscene:") : self.screens.index(
                "advance_cutscene_to_level1:"
            )
        ]
        self.assertIn("call show_image_cutscene", update)
        self.assertIn("j advance_cutscene", update)


if __name__ == "__main__":
    unittest.main()
