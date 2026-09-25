import hashlib
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE_SHA256 = "4343336a174bf3ad6d2a822a2e4fab218adac8abeeae1f5be95b1dc6cafce1a0"


def table_values(source: str, label: str) -> tuple[int, ...]:
    section = source[source.index(label) :]
    values = []
    for line in section.splitlines()[1:]:
        if ".byte" in line:
            values.extend(int(value) for value in re.findall(r"\d+", line.split(".byte", 1)[1]))
        elif values:
            break
    return tuple(values)


class GameplayMusicTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.main = (ROOT / "main.s").read_text(encoding="utf-8")
        cls.constants = (ROOT / "src" / "constants.s").read_text(encoding="utf-8")
        cls.data = (ROOT / "data" / "gameplay_music_data.s").read_text(encoding="utf-8")
        cls.source = (ROOT / "assets" / "source" / "audio" / "test_trilha_gameplay.s").read_text(
            encoding="utf-8"
        )
        cls.music = (ROOT / "src" / "music.s").read_text(encoding="utf-8")
        cls.state = (ROOT / "src" / "game_state.s").read_text(encoding="utf-8")
        cls.loop = (ROOT / "src" / "game_loop.s").read_text(encoding="utf-8")

    def test_user_supplied_source_is_archived_unchanged(self):
        source = ROOT / "assets" / "source" / "audio" / "test_trilha_gameplay.s"
        self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(), SOURCE_SHA256)

    def test_runtime_tables_match_the_supplied_two_layer_song(self):
        labels = (
            "game_bass_pitches:",
            "game_bass_frames:",
            "game_stab_pitches:",
            "game_stab_frames:",
        )
        for label in labels:
            with self.subTest(table=label):
                self.assertEqual(
                    table_values(self.data, label),
                    table_values(self.source, label),
                )

        self.assertEqual(
            table_values(self.data, "game_music_stop_pitches:"),
            (31, 35, 36, 38, 40, 52, 55, 58, 60, 62, 63, 64, 67),
        )
        self.assertIn(".eqv GAME_BASS_LENGTH         12", self.constants)
        self.assertIn(".eqv GAME_STAB_LENGTH         24", self.constants)

    def test_runtime_data_is_loaded_before_text(self):
        include = '.include "data/gameplay_music_data.s"'
        self.assertIn(include, self.main)
        self.assertLess(self.main.index(include), self.main.index(".text"))

    def test_gameplay_loop_is_the_only_runtime_updater(self):
        loop = self.loop[
            self.loop.index("loop_playing_level:") : self.loop.index("finish_playing_frame:")
        ]
        self.assertIn("call update_gameplay_music", loop)
        self.assertLess(
            loop.index("call update_gameplay_music"), loop.index("call handle_god_mode_cheat")
        )

        runtime_sources = self.main + "\n" + "\n".join(
            path.read_text(encoding="utf-8") for path in sorted((ROOT / "src").glob("*.s"))
        )
        self.assertEqual(runtime_sources.count("call update_gameplay_music"), 1)

    def test_state_guard_allows_every_phase_and_the_boss_only(self):
        update = self.music[
            self.music.index("update_gameplay_music:") : self.music.index(
                "end_update_gameplay_music:"
            )
        ]
        for state in ("STATE_LEVEL1", "STATE_LEVEL2", "STATE_LEVEL3", "STATE_BOSS"):
            self.assertIn(state, update)
        self.assertIn("la t0, music_enabled", update)
        self.assertNotIn("STATE_MENU", update)
        self.assertNotIn("STATE_GAME_OVER", update)

        dispatch = self.loop[self.loop.index("loop_frame:") : self.loop.index("loop_menu:")]
        self.assertIn("STATE_BOSS", dispatch)
        self.assertIn("loop_playing_level", dispatch)

    def test_every_phase_restarts_the_track_after_its_cutscene(self):
        for label, next_label in (
            ("set_state_level1:", "set_state_level2:"),
            ("set_state_level2:", "set_state_level3:"),
            ("set_state_level3:", "set_state_cutscene_intro:"),
        ):
            with self.subTest(label=label):
                section = self.state[self.state.index(label) : self.state.index(next_label)]
                self.assertIn("call clear_input_buffers", section)
                self.assertIn("call reset_gameplay_music", section)
                self.assertLess(
                    section.index("call clear_input_buffers"),
                    section.index("call reset_gameplay_music"),
                )

    def test_state_changes_silence_long_notes_before_non_gameplay_screens(self):
        clear = self.state[
            self.state.index("clear_input_buffers:") : self.state.index("set_state_level1:")
        ]
        self.assertIn("call stop_gameplay_music", clear)
        self.assertIn("sw ra, 0(sp)", clear)
        self.assertIn("lw ra, 0(sp)", clear)
        self.assertIn("addi sp, sp, -4", clear)
        self.assertIn("addi sp, sp, 4", clear)

        stop = self.music[
            self.music.index("stop_gameplay_music:") : self.music.index(
                "update_gameplay_music:"
            )
        ]
        self.assertIn("GAME_MUSIC_STOP_PITCH_COUNT", stop)
        self.assertIn("li a3, 0", stop)
        self.assertIn("li a7, 31", stop)
        self.assertIn("j reset_gameplay_music", stop)

    def test_scheduler_is_nonblocking_and_keeps_bass_and_stab_layers(self):
        update = self.music[
            self.music.index("update_gameplay_music:") : self.music.index(
                "end_update_gameplay_music:"
            )
        ]
        self.assertIn("play_next_game_bass:", update)
        self.assertIn("update_game_stab:", update)
        self.assertIn("play_next_game_stab:", update)
        self.assertIn("li a7, 30", update)
        self.assertIn("li a7, 31", update)
        self.assertNotIn("li a7, 32", update)
        self.assertNotIn("li a7, 33", update)


if __name__ == "__main__":
    unittest.main()
