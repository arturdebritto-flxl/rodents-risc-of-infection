import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class BossVolleyTests(unittest.TestCase):
    def test_boss_fires_three_projectile_volley_more_frequently(self):
        constants = (ROOT / "src" / "constants.s").read_text(encoding="utf-8")
        boss = (ROOT / "src" / "boss.s").read_text(encoding="utf-8")
        attack = boss[boss.index("update_boss_heavy_attack:") : boss.index("end_update_boss_heavy_attack:")]

        self.assertIn(".eqv BOSS_HEAVY_SHOOT_DELAY    28", constants)
        self.assertEqual(attack.count("call spawn_enemy_bullet_typed"), 3)
        self.assertIn("# Tiro central.", attack)
        self.assertIn("# Segundo tiro:", attack)
        self.assertIn("# Terceiro tiro:", attack)
        self.assertIn("sw a2, 12(sp)", attack)
        self.assertIn("sw a3, 16(sp)", attack)


if __name__ == "__main__":
    unittest.main()
