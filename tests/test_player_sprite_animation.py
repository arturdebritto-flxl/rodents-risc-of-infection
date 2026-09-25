import hashlib
import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class PlayerSpriteAnimationTests(unittest.TestCase):
    def test_supplied_protagonist_archive_is_the_runtime_source(self):
        archive = ROOT / "assets" / "source" / "Protagonista .zip"
        expected_hash = "8779963a87459d81d3c0ba2ae16249574282a3bc2945a4ee882931f2a0025f2a"
        self.assertEqual(hashlib.sha256(archive.read_bytes()).hexdigest(), expected_hash)

    def test_runtime_maps_weapons_and_lateral_walk_frames(self):
        manifest = json.loads((ROOT / "assets" / "generated" / "manifest.json").read_text())
        runtime = {entry["symbol"]: entry for entry in manifest["runtime_sprites"]}
        expected = {
            "sprite_player_down_pistol": "sprite_01.png",
            "sprite_player_down_shotgun": "sprite_02.png",
            "sprite_player_down_uzi": "sprite_03.png",
            "sprite_player_up_pistol": "sprite_05.png",
            "sprite_player_up_shotgun": "sprite_06.png",
            "sprite_player_up_uzi": "sprite_07.png",
            "sprite_player_right_pistol_idle": "sprite_09.png",
            "sprite_player_right_pistol_walk": "sprite_13.png",
            "sprite_player_left_pistol_idle": "sprite_17.png",
            "sprite_player_left_pistol_walk": "sprite_21.png",
        }
        for symbol, source in expected.items():
            self.assertEqual(runtime[symbol]["source"], source)
            self.assertEqual(runtime[symbol]["source_size"], [160, 160])
            self.assertEqual(runtime[symbol]["crop"], [0, 0, 160, 160])
            self.assertEqual(runtime[symbol]["offset"], [0, 0])
            self.assertEqual(runtime[symbol]["resampling"], "nearest-full-canvas")

    def test_player_walk_cycle_is_independent_and_only_runs_while_moving(self):
        player = (ROOT / "src" / "player.s").read_text(encoding="utf-8")
        animation = player[player.index("update_player_walk_animation:"):player.index("update_player_facing_direction:")]
        self.assertIn("player_moved", animation)
        self.assertIn("PLAYER_WALK_FRAME_DELAY", animation)
        self.assertIn("xori t1, t1, 1", animation)
        self.assertIn("player_walk_frame", animation)
        self.assertIn("sw zero, 0(t0)", animation)

        render = (ROOT / "src" / "render.s").read_text(encoding="utf-8")
        player_draw = render[render.index("draw_player_square:"):render.index("draw_player_fallback_rect:")]
        self.assertIn("player_walk_frame", player_draw)
        self.assertIn("sprite_player_right_pistol_walk", player_draw)
        self.assertIn("sprite_player_left_pistol_walk", player_draw)
        self.assertNotIn("la t0, animation_frame", player_draw)


if __name__ == "__main__":
    unittest.main()
