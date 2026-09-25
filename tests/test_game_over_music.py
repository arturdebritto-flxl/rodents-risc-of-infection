import unittest

from tools import build_game_over_music


EXPECTED_EVENTS = (
    build_game_over_music.NoteEvent(0, 34560, 24, 70),
    build_game_over_music.NoteEvent(1632, 5888, 46, 46),
    build_game_over_music.NoteEvent(7296, 34560, 23, 70),
    build_game_over_music.NoteEvent(8704, 6624, 43, 46),
    build_game_over_music.NoteEvent(14416, 5888, 50, 46),
    build_game_over_music.NoteEvent(14592, 34560, 26, 70),
    build_game_over_music.NoteEvent(21488, 6624, 41, 46),
    build_game_over_music.NoteEvent(21888, 40320, 27, 70),
    build_game_over_music.NoteEvent(28832, 5888, 45, 46),
    build_game_over_music.NoteEvent(30400, 34560, 24, 70),
    build_game_over_music.NoteEvent(34272, 6624, 38, 46),
    build_game_over_music.NoteEvent(37696, 34560, 23, 70),
)


class GameOverMusicBuildTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.result = build_game_over_music.build()

    def test_supplied_midi_is_converted_exactly(self):
        self.assertEqual(self.result.events, EXPECTED_EVENTS)
        self.assertEqual(self.result.loop_ms, 72256)
        self.assertEqual(self.result.instrument, 88)
        self.assertEqual(
            self.result.stop_pitches,
            (23, 24, 26, 27, 38, 41, 43, 45, 46, 50),
        )

    def test_two_overlapping_layers_and_long_notes_are_preserved(self):
        low_layer = tuple(event for event in self.result.events if event.velocity == 70)
        melody = tuple(event for event in self.result.events if event.velocity == 46)
        self.assertEqual(len(low_layer), 6)
        self.assertEqual(len(melody), 6)
        self.assertGreater(max(event.duration_ms for event in low_layer), 40_000)
        self.assertLess(max(event.duration_ms for event in melody), 7_000)

    def test_generation_is_deterministic_and_checked_in_output_is_current(self):
        self.assertEqual(self.result, build_game_over_music.build())
        self.assertTrue(build_game_over_music.OUTPUT.exists())
        self.assertEqual(build_game_over_music.OUTPUT.read_bytes(), self.result.content)


class GameOverMusicIntegrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        root = build_game_over_music.ROOT
        cls.main = (root / "main.s").read_text(encoding="utf-8")
        cls.music = (root / "src" / "music.s").read_text(encoding="utf-8")
        cls.screens = (root / "src" / "screens.s").read_text(encoding="utf-8")
        cls.state = (root / "src" / "game_state.s").read_text(encoding="utf-8")

    def test_runtime_data_is_included_before_text(self):
        include = '.include "data/game_over_music_data.s"'
        self.assertIn(include, self.main)
        self.assertLess(self.main.index(include), self.main.index(".text"))

    def test_shared_keyboard_wait_updates_both_tracks_but_each_checks_its_state(self):
        wait = self.screens[
            self.screens.index("menu_wait_key:") : self.screens.index("play_music_note:")
        ]
        self.assertIn("call update_menu_music", wait)
        self.assertIn("call update_game_over_music", wait)
        self.assertLess(wait.index("call update_game_over_music"), wait.index("KDMMIO_Ctrl"))

        menu_update = self.music[
            self.music.index("update_menu_music:") : self.music.index("play_next_menu_note:")
        ]
        self.assertIn("STATE_MENU", menu_update)

        game_over_update = self.music[
            self.music.index("update_game_over_music:") : self.music.index(
                "end_update_game_over_music:"
            )
        ]
        self.assertIn("STATE_GAME_OVER", game_over_update)
        self.assertIn("la t0, music_enabled", game_over_update)

    def test_entering_game_over_resets_the_track(self):
        setter = self.state[
            self.state.index("set_state_game_over:") : self.state.index("set_state_menu:")
        ]
        self.assertIn("call reset_game_over_music", setter)
        self.assertLess(
            setter.index("li t1, STATE_GAME_OVER"),
            setter.index("call reset_game_over_music"),
        )

    def test_retry_and_leave_both_stop_all_long_notes(self):
        screen = self.screens[
            self.screens.index("game_over_screen:") : self.screens.index("victory_screen:")
        ]
        self.assertEqual(screen.count("call stop_game_over_music"), 2)
        self.assertLess(
            screen.index("call stop_game_over_music", screen.index("game_over_confirm:")),
            screen.index("li a0, 1", screen.index("game_over_confirm:")),
        )
        self.assertLess(
            screen.index("call stop_game_over_music", screen.index("game_over_leave:")),
            screen.index("li a0, 0", screen.index("game_over_leave:")),
        )

        stop = self.music[
            self.music.index("stop_game_over_music:") : self.music.index(
                "update_game_over_music:"
            )
        ]
        self.assertIn("GAME_OVER_MUSIC_STOP_PITCH_COUNT", stop)
        self.assertIn("li a3, 0", stop)
        self.assertIn("li a7, 31", stop)
        self.assertIn("j reset_game_over_music", stop)

    def test_scheduler_uses_nonblocking_time_and_midi_syscalls(self):
        update = self.music[
            self.music.index("update_game_over_music:") : self.music.index(
                "end_update_game_over_music:"
            )
        ]
        self.assertIn("li a7, 30", update)
        self.assertIn("li a7, 31", update)
        self.assertIn("GAME_OVER_MUSIC_LOOP_MS", update)
        self.assertIn("slli t3, t1, 4", update)
        self.assertNotIn("li a7, 32", update)
        self.assertNotIn("li a7, 33", update)


if __name__ == "__main__":
    unittest.main()
