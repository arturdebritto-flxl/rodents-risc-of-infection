import hashlib
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class FinalExplosionSfxTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.screens = (ROOT / "src" / "screens.s").read_text(encoding="utf-8")

    def test_supplied_explosion_source_is_archived_unchanged(self):
        source = ROOT / "assets" / "source" / "audio" / "test_som_explosao.s"
        self.assertEqual(
            hashlib.sha256(source.read_bytes()).hexdigest(),
            "b6f1d83050a3030a786e02514c974e301dd3f1c128b0bd0ef144c73b2326e519",
        )

    def test_effect_starts_after_explosion_image_and_before_victory_wait(self):
        explosion = self.screens[
            self.screens.index("update_post_boss_explosion:") : self.screens.index(
                "end_update_post_boss_explosion:"
            )
        ]
        self.assertEqual(explosion.count("call play_final_explosion_sfx"), 1)
        self.assertLess(
            explosion.index("call draw_cutscene_screen"),
            explosion.index("call play_final_explosion_sfx"),
        )
        self.assertLess(
            explosion.index("call play_final_explosion_sfx"),
            explosion.index("call wait_post_boss_explosion_key"),
        )

    def test_effect_keeps_the_supplied_note_sequence_and_respects_sfx_option(self):
        effect = self.screens[
            self.screens.index("play_final_explosion_sfx:") : self.screens.index(
                "end_play_final_explosion_sfx:"
            )
        ]
        self.assertIn("la t0, sfx_enabled", effect)
        self.assertIn("beqz t1, end_play_final_explosion_sfx", effect)
        self.assertEqual(effect.count("li a7, 31"), 12)
        self.assertEqual(effect.count("li a7, 32"), 7)
        for pitch in (84, 70, 31, 38, 43, 36, 29, 24, 64, 52, 47, 19):
            self.assertIn(f"li a0, {pitch}", effect)

    def test_countdown_keeps_the_button_on_screen_before_the_explosion(self):
        detonator = self.screens[
            self.screens.index("check_post_boss_detonator_advance:") : self.screens.index(
                "end_update_post_boss_detonator:"
            )
        ]
        self.assertLess(
            detonator.index("call show_image_cutscene"),
            detonator.index("call play_final_countdown_sfx"),
        )
        self.assertLess(
            detonator.index("call play_final_countdown_sfx"),
            detonator.index("j advance_to_post_boss_explosion"),
        )

        countdown = self.screens[
            self.screens.index("play_final_countdown_sfx:") : self.screens.index(
                "play_final_explosion_sfx:"
            )
        ]
        self.assertIn("la t0, sfx_enabled", countdown)
        self.assertIn("sw ra, 0(sp)", countdown)
        self.assertIn("lw ra, 0(sp)", countdown)
        for value in (3, 2, 1, 0):
            self.assertIn(
                f"li a0, {value}\n    call draw_detonator_countdown_frame", countdown
            )
        self.assertEqual(countdown.count("li a7, 31"), 4)
        self.assertEqual(countdown.count("li a7, 32"), 4)
        for pitch in (72, 76, 80, 84):
            self.assertIn(f"li a0, {pitch}", countdown)

    def test_countdown_overlay_changes_only_the_timer_display_area(self):
        overlay = self.screens[
            self.screens.index("draw_detonator_countdown:") : self.screens.index(
                "draw_detonator_timer_digit:"
            )
        ]
        self.assertIn("li a0, 36", overlay)
        self.assertIn("li a1, 40", overlay)
        self.assertIn("li a2, 68", overlay)
        self.assertIn("li a3, 17", overlay)
        self.assertIn("COLOR_BLACK", overlay)
        self.assertEqual(overlay.count("call draw_detonator_timer_digit"), 4)


if __name__ == "__main__":
    unittest.main()
