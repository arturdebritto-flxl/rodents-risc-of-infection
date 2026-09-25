import json
import re
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
BOSS_SYMBOLS = (
    "sprite_boss_down_0", "sprite_boss_down_1",
    "sprite_boss_up_0", "sprite_boss_up_1",
    "sprite_boss_right_0", "sprite_boss_right_1",
    "sprite_boss_left_0", "sprite_boss_left_1",
)


class BossScaleIntegrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.constants = (ROOT / "src" / "constants.s").read_text(encoding="utf-8")
        cls.boss = (ROOT / "src" / "boss.s").read_text(encoding="utf-8")
        cls.render = (ROOT / "src" / "render.s").read_text(encoding="utf-8")
        cls.collision = (ROOT / "src" / "collision.s").read_text(encoding="utf-8")
        cls.converter = (ROOT / "tools" / "convert_sprites.py").read_text(encoding="utf-8")
        cls.runtime_sprites = (
            ROOT / "assets" / "generated" / "runtime_sprites.s"
        ).read_text(encoding="ascii")
        cls.manifest = json.loads(
            (ROOT / "assets" / "generated" / "manifest.json").read_text(encoding="utf-8")
        )

    def constant(self, name):
        match = re.search(rf"^\.eqv\s+{name}\s+(\d+)\s*$", self.constants, re.MULTILINE)
        self.assertIsNotNone(match, name)
        return int(match.group(1))

    def test_boss_is_fifty_percent_larger_with_matching_center(self):
        self.assertEqual(self.constant("BOSS_SIZE"), 48)
        self.assertEqual(self.constant("BOSS_HALF_SIZE"), 24)
        self.assertEqual(self.constant("BOSS_START_X"), 144)
        self.assertEqual(self.constant("BOSS_START_Y"), 24)
        self.assertGreaterEqual(self.boss.count("BOSS_HALF_SIZE"), 4)

    def test_boss_bounds_keep_the_full_hitbox_inside_the_laboratory(self):
        self.assertLessEqual(self.constant("BOSS_MAX_X") + self.constant("BOSS_SIZE"), 310)
        self.assertLessEqual(self.constant("BOSS_MAX_Y") + self.constant("BOSS_SIZE"), 216)
        self.assertIn("li a4, BOSS_SIZE", self.boss)
        self.assertGreaterEqual(self.collision.count("li t6, BOSS_SIZE"), 2)

    def test_all_eight_runtime_boss_sprites_are_real_48px_payloads(self):
        records = {
            record["symbol"]: record for record in self.manifest["runtime_sprites"]
            if record["symbol"].startswith("sprite_boss_")
        }
        self.assertEqual(set(records), set(BOSS_SYMBOLS))
        for symbol in BOSS_SYMBOLS:
            self.assertEqual(records[symbol]["output_size"], [48, 48])
            self.assertIn(f'"{symbol}":', self.converter)
            self.assertIn(f'"{records[symbol]["source"]}", 48)', self.converter)
            tail = self.runtime_sprites.split(f"{symbol}:\n", 1)[1]
            next_label = re.search(r"^[a-z][a-z0-9_]*:$", tail, re.MULTILINE)
            block = tail[:next_label.start()] if next_label else tail
            self.assertEqual(len(re.findall(r"0x[0-9A-F]{2}", block)), 48 * 48)
        self.assertIn(self.runtime_sprites.rstrip(), self.render)

    def test_renderer_uses_the_same_size_for_sprite_and_fallback_hitbox(self):
        draw = self.render.split("draw_boss_square:", 1)[1].split(
            "end_draw_boss_square:", 1
        )[0]
        self.assertGreaterEqual(draw.count("BOSS_SIZE"), 4)
        self.assertIn("call draw_sprite_8bpp_fast", draw)


if __name__ == "__main__":
    unittest.main()
