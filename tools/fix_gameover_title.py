"""Repair the Game Over title while preserving the original BGR233 artwork.

The checked-in menu is stored as opaque horizontal runs.  This tool changes
only the small title rectangle, reusing glyphs from the original horror font,
and rewrites the run table deterministically.
"""

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ASSET_PATH = ROOT / "assets" / "generated" / "menus" / "gameover.data"
SCREEN_WIDTH = 320
SCREEN_HEIGHT = 240
PAYLOAD_SIZE = SCREEN_WIDTH * SCREEN_HEIGHT
TITLE_BOX = (108, 20, 212, 53)
TITLE_START_X = 110
TITLE_Y = 26
TEXT_COLORS = frozenset({0x02, 0x03, 0x04, 0x0B, 0x0C})

# Exact colored interiors of the original letters.  '.' is transparent;
# hexadecimal digits are native BGR233 values.  The one-pixel dark outline is
# rebuilt by stamp_glyph, so overlapping letters stay clean and deterministic.
GLYPHS = {
    "V": (
        "CCC.......CCCC",
        "CCCC.....CCCCC",
        "CCCC.....CCCCC",
        "CCCC.....CCCC2",
        "CCCC.....CCCC.",
        "CCCCC....CCCC.",
        "CCCCC...CCCCC.",
        ".CCCC...CCCCC.",
        ".CCCC...CCCC..",
        ".CCCC...CCCC..",
        ".CCCC...CCCC..",
        "..CCCC.CCCC...",
        "..CCCC.CCCC...",
        "..CCCC.CCCC...",
        "..2CCCCCCCC...",
        "..2C3CCCCC....",
        "...C33CCCC....",
        "...CC2332C....",
        "...CC2222C....",
        "....C2223C....",
        "....C2223.....",
        "....C.2.B.....",
        "......2.B.....",
        ".....22.......",
        ".....32.......",
        "..............",
    ),
    "O": (
        "....CCCCC.....",
        "..CCCCCCCCC...",
        ".CCCCCCCCCCC..",
        ".CCCCC.CCCCC..",
        ".CCCC...CCCCC.",
        ".CCC....CCCCC.",
        "CCCC.....CCCCC",
        "CCCC.....CCCCC",
        "CCCC.....CCCCC",
        "CCCC.....CCCCC",
        "CCCC.....CCCCC",
        "C2CC.....C3CCC",
        "C2CC.....33CCC",
        "C32C.....333CC",
        "C333.....C33CC",
        "C33C.....CCCCC",
        ".33C.....CCCC.",
        ".33CC...CCCCC.",
        ".433CC.CCCCC..",
        ".44334CCCCC...",
        "..444444CC....",
        "....44444C....",
        ".........B....",
        ".........B....",
        ".........B....",
        ".........B....",
    ),
    "C": (
        "..CCCCCCCCC..",
        ".CCCCCCCCCCC.",
        ".CCCC...CCCC.",
        ".CCC....CCCC.",
        "CCCC....CCCCC",
        "CCCC....CCCCC",
        "CCCC.........",
        "CCCC.........",
        "CCCC.........",
        "CCCC.........",
        "CCCC.........",
        "CCCC.........",
        "CCCC....CCCCC",
        "CCCC....CCCCC",
        ".CCC....CCCCC",
        ".CCC....CCCCC",
        ".3CCC..CCCCC.",
        "..CCCCCCCCC..",
        "...C333333...",
        "....33333....",
        ".......33....",
        ".......33....",
        "........3....",
        ".............",
        "........3....",
        ".............",
    ),
    "E": (
        "CCCCCCCCCC.",
        "CCCCCCCCCC.",
        "CCC........",
        "CCC........",
        "CCC........",
        "CCC........",
        "CCC........",
        "CCCCCCCCC..",
        "CCCCCCCCC..",
        "CCCCCCCCC..",
        "CCCCCCCCC..",
        "CCC........",
        "CCC........",
        "C2C........",
        "C2C........",
        "C22........",
        "C22222CCCCC",
        "C2222233CCC",
        "C222223CCC.",
        "32.....C...",
        ".2.....C...",
        ".......C...",
        ".......3...",
        "...........",
        "...........",
        "...........",
    ),
    "F": (
        "CCCCCCCCCC",
        "CCCCCCCCCC",
        "CCCCCCCCCC",
        "CCCCCCCCCC",
        "CCC.......",
        "CCC.......",
        "CCC.......",
        "CCC.......",
        "CCC.......",
        "CCCCCCCCC.",
        "CCCCCCCCC.",
        "C3CCCCCCC.",
        "C3C.......",
        "C3C.......",
        "C3C.......",
        "C22.......",
        "C2C.......",
        "C2C.......",
        "C2C.......",
        "C2C.......",
        "C2C.......",
        ".C........",
        ".C........",
        ".C........",
        ".C........",
        "..........",
    ),
    "I": (
        "CCCC",
        "CCCC",
        "CCCC",
        "CCCC",
        "CCCC",
        "CCCC",
        "CCCC",
        "CCCC",
        "CCCC",
        "CCCC",
        "CCCC",
        "CCCC",
        "CCCC",
        "CC3C",
        "C33C",
        "C33C",
        "CC32",
        "CC22",
        "C222",
        "C244",
        "CC2C",
        ".C..",
        ".C..",
        ".C..",
        ".4..",
        ".4..",
    ),
}

TITLE_LETTERS = (
    ("V", 0),
    ("O", 16),
    ("C", 32),
    ("E", 47),
    ("F", 67),
    ("O", 79),
    ("I", 95),
)


@dataclass(frozen=True)
class BuildResult:
    prefix: str
    original_payload: bytes
    payload: bytes
    content: bytes


def parse_asset(content: str) -> tuple[str, bytes]:
    try:
        header, body = content.split("game_over_runs:", 1)
    except ValueError as error:
        raise ValueError("game_over_runs label not found") from error

    values = [
        int(token, 0)
        for token in re.findall(
            r"(?<![A-Za-z_])-?(?:0x[0-9A-Fa-f]+|\d+)", body
        )
    ]
    if len(values) % 4:
        raise ValueError("run table does not contain groups of four values")

    pixels = bytearray(PAYLOAD_SIZE)
    coverage = bytearray(PAYLOAD_SIZE)
    found_sentinel = False
    for offset in range(0, len(values), 4):
        x, y, length, color = values[offset : offset + 4]
        if (x, y, length) == (-1, -1, -1):
            found_sentinel = True
            break
        if not (0 <= y < SCREEN_HEIGHT and 0 <= x < SCREEN_WIDTH):
            raise ValueError(f"run starts outside screen: {(x, y, length, color)}")
        if length <= 0 or x + length > SCREEN_WIDTH or not (0 <= color <= 0xFF):
            raise ValueError(f"invalid run: {(x, y, length, color)}")
        start = y * SCREEN_WIDTH + x
        end = start + length
        if any(coverage[start:end]):
            raise ValueError(f"overlapping run: {(x, y, length, color)}")
        pixels[start:end] = bytes([color]) * length
        coverage[start:end] = b"\x01" * length

    if not found_sentinel:
        raise ValueError("run table sentinel not found")
    if 0 in coverage:
        raise ValueError("run table does not cover the full 320x240 screen")

    return header + "game_over_runs:\n", bytes(pixels)


def glyph_points(glyph: tuple[str, ...]):
    for y, row in enumerate(glyph):
        for x, value in enumerate(row):
            if value != ".":
                color = int(value, 16)
                if color not in TEXT_COLORS:
                    raise ValueError(f"invalid title color: 0x{color:02X}")
                yield x, y, color


def stamp_glyph(pixels: bytearray, glyph: tuple[str, ...], x0: int, y0: int) -> None:
    points = tuple(glyph_points(glyph))
    for x, y, _ in points:
        for oy in (-1, 0, 1):
            for ox in (-1, 0, 1):
                target_x = x0 + x + ox
                target_y = y0 + y + oy
                index = target_y * SCREEN_WIDTH + target_x
                if pixels[index] == 0:
                    pixels[index] = 0x01
    for x, y, color in points:
        pixels[(y0 + y) * SCREEN_WIDTH + x0 + x] = color


def fix_title(payload: bytes) -> bytes:
    if len(payload) != PAYLOAD_SIZE:
        raise ValueError(f"expected {PAYLOAD_SIZE} pixels, got {len(payload)}")

    pixels = bytearray(payload)
    x0, y0, x1, y1 = TITLE_BOX
    for y in range(y0, y1):
        start = y * SCREEN_WIDTH + x0
        pixels[start : start + (x1 - x0)] = b"\x00" * (x1 - x0)

    for letter, offset in TITLE_LETTERS:
        stamp_glyph(pixels, GLYPHS[letter], TITLE_START_X + offset, TITLE_Y)

    # Circumflex on the E: the final title reads "VOCÊ FOI".
    accent_x = TITLE_START_X + 47
    accent = (
        (accent_x + 2, 24),
        (accent_x + 3, 23),
        (accent_x + 4, 22),
        (accent_x + 5, 22),
        (accent_x + 6, 23),
        (accent_x + 7, 24),
    )
    for x, y in accent:
        for oy in (-1, 0, 1):
            for ox in (-1, 0, 1):
                index = (y + oy) * SCREEN_WIDTH + x + ox
                if pixels[index] == 0:
                    pixels[index] = 0x01
        pixels[y * SCREEN_WIDTH + x] = 0x0C

    return bytes(pixels)


def encode_runs(payload: bytes) -> tuple[tuple[int, int, int, int], ...]:
    runs: list[tuple[int, int, int, int]] = []
    for y in range(SCREEN_HEIGHT):
        row_start = y * SCREEN_WIDTH
        x = 0
        while x < SCREEN_WIDTH:
            color = payload[row_start + x]
            end = x + 1
            while end < SCREEN_WIDTH and payload[row_start + end] == color:
                end += 1
            runs.append((x, y, end - x, color))
            x = end
    return tuple(runs)


def render_asset(prefix: str, payload: bytes) -> bytes:
    runs = encode_runs(payload)
    lines = [prefix.rstrip(), ""]
    for offset in range(0, len(runs), 5):
        chunk = runs[offset : offset + 5]
        values = []
        for x, y, length, color in chunk:
            values.extend((str(x), str(y), str(length), f"0x{color:02x}"))
        lines.append("    .word " + ", ".join(values))
    lines.append("    .word -1, -1, -1, 0")
    return ("\n".join(lines) + "\n").encode("ascii")


def build(path: Path = ASSET_PATH) -> BuildResult:
    prefix, original_payload = parse_asset(path.read_text(encoding="utf-8"))
    payload = fix_title(original_payload)
    return BuildResult(
        prefix=prefix,
        original_payload=original_payload,
        payload=payload,
        content=render_asset(prefix, payload),
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    result = build()
    if fix_title(result.payload) != result.payload:
        raise AssertionError("title repair is not idempotent")

    if args.check:
        if ASSET_PATH.read_bytes() != result.content:
            print(f"missing or stale: {ASSET_PATH.relative_to(ROOT)}")
            return 1
        return 0

    ASSET_PATH.write_bytes(result.content)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
