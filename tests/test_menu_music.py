import hashlib
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def table_values(source: str, start_label: str, end_label: str) -> tuple[int, ...]:
    section = source[source.index(start_label) : source.index(end_label)]
    values = []
    for line in section.splitlines():
        if ".byte" not in line:
            continue
        values.extend(int(value) for value in re.findall(r"\d+", line.split(".byte", 1)[1]))
    return tuple(values)


class MenuMusicTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.main = (ROOT / "main.s").read_text(encoding="utf-8")
        cls.constants = (ROOT / "src" / "constants.s").read_text(encoding="utf-8")
        cls.music = (ROOT / "src" / "music.s").read_text(encoding="utf-8")
        cls.music_data = (ROOT / "data" / "music_data.s").read_text(encoding="utf-8")
        cls.screens = (ROOT / "src" / "screens.s").read_text(encoding="utf-8")
        cls.state = (ROOT / "src" / "game_state.s").read_text(encoding="utf-8")

    def test_user_supplied_midi_is_archived_unchanged(self):
        midi = ROOT / "assets" / "source" / "audio" / "trilha_sonora_menu_tipo1.mid"
        self.assertTrue(midi.exists())
        self.assertEqual(
            hashlib.sha256(midi.read_bytes()).hexdigest(),
            "d441758d47834d6d461756164f4005b53a9074bac246c1476f0bbf426c492619",
        )

    def test_main_includes_music_data_and_runtime(self):
        self.assertIn('.include "data/music_data.s"', self.main)
        self.assertIn('.include "src/music.s"', self.main)
        self.assertLess(
            self.main.index('.include "data/music_data.s"'),
            self.main.index(".text"),
        )

    def test_note_tables_keep_the_supplied_96_step_song_and_four_step_drone(self):
        pitches = table_values(self.music_data, "menu_music_pitches:", "menu_music_frames:")
        frames = table_values(self.music_data, "menu_music_frames:", "menu_drone_pitches:")
        drone_pitches = table_values(
            self.music_data, "menu_drone_pitches:", "menu_drone_frames:"
        )
        drone_frames = table_values(
            self.music_data, "menu_drone_frames:", "menu_music_stop_pitches:"
        )
        self.assertEqual(len(pitches), 96)
        self.assertEqual(len(frames), 96)
        self.assertEqual(drone_pitches, (28, 27, 30, 31))
        self.assertEqual(drone_frames, (144, 144, 144, 168))
        self.assertIn(".eqv MENU_MUSIC_LENGTH          96", self.constants)

    def test_music_updates_only_inside_the_menu_keyboard_wait(self):
        wait = self.screens[
            self.screens.index("menu_wait_key:") : self.screens.index("play_music_note:")
        ]
        self.assertIn("call update_menu_music", wait)
        self.assertLess(wait.index("call update_menu_music"), wait.index("KDMMIO_Ctrl"))
        self.assertIn("sw ra, 0(sp)", wait)
        self.assertIn("lw ra, 0(sp)", wait)

        runtime_sources = self.main + "\n" + "\n".join(
            path.read_text(encoding="utf-8") for path in sorted((ROOT / "src").glob("*.s"))
        )
        self.assertEqual(runtime_sources.count("call update_menu_music"), 1)

        update = self.music[
            self.music.index("update_menu_music:") : self.music.index("play_next_menu_note:")
        ]
        self.assertIn("li t2, STATE_MENU", update)
        self.assertIn("bne t1, t2, end_update_menu_music", update)

    def test_player_music_option_controls_and_restarts_the_scheduler(self):
        update = self.music[
            self.music.index("update_menu_music:") : self.music.index("end_update_menu_music:")
        ]
        self.assertIn("la t0, music_enabled", update)
        self.assertIn("beqz t1, end_update_menu_music", update)

        toggle = self.screens[
            self.screens.index("options_toggle_music:") : self.screens.index(
                "options_toggle_sfx:"
            )
        ]
        self.assertIn("call stop_menu_music", toggle)
        self.assertIn("call reset_menu_music", toggle)

    def test_entering_resets_and_leaving_silences_every_menu_pitch(self):
        set_menu = self.state[self.state.index("set_state_menu:") :]
        self.assertIn("call reset_menu_music", set_menu)

        menu_exit = self.screens[
            self.screens.index("menu_start:") : self.screens.index("menu_return:")
        ]
        self.assertEqual(menu_exit.count("call stop_menu_music"), 2)

        stop = self.music[
            self.music.index("stop_menu_music:") : self.music.index("update_menu_music:")
        ]
        self.assertIn("li t1, MENU_MUSIC_STOP_PITCH_COUNT", stop)
        self.assertIn("li a3, 0", stop)
        self.assertIn("li a7, 31", stop)
        self.assertIn("j reset_menu_music", stop)

        stop_section = self.music_data[self.music_data.index("menu_music_stop_pitches:") :]
        stop_pitches = tuple(
            int(value)
            for line in stop_section.splitlines()
            if ".byte" in line
            for value in re.findall(r"\d+", line.split(".byte", 1)[1])
        )
        self.assertEqual(
            stop_pitches,
            (27, 28, 30, 31, 34, 38, 39, 41, 43, 45, 50, 53),
        )

    def test_scheduler_is_nonblocking(self):
        update = self.music[self.music.index("update_menu_music:") :]
        self.assertIn("li a7, 30", update)
        self.assertIn("li a7, 31", update)
        self.assertNotIn("li a7, 32", update)
        self.assertNotIn("li a7, 33", update)


if __name__ == "__main__":
    unittest.main()
