"""Convert the supplied Game Over MIDI into deterministic RARS event data."""

from __future__ import annotations

import argparse
import hashlib
import struct
from collections import defaultdict, deque
from dataclasses import dataclass
from fractions import Fraction
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "source" / "audio" / "trilha_final_tipo1.mid"
OUTPUT = ROOT / "data" / "game_over_music_data.s"
SOURCE_SHA256 = "9ce020a175575c8f0d7783592a45c9088bcef8ba48e11da743d5f7dcc043ac47"


@dataclass(frozen=True)
class TickNote:
    start_tick: int
    end_tick: int
    pitch: int
    velocity: int
    program: int
    track: int
    order: int


@dataclass(frozen=True)
class NoteEvent:
    start_ms: int
    duration_ms: int
    pitch: int
    velocity: int


@dataclass(frozen=True)
class BuildResult:
    events: tuple[NoteEvent, ...]
    loop_ms: int
    instrument: int
    stop_pitches: tuple[int, ...]
    content: bytes


def read_vlq(data: bytes, offset: int) -> tuple[int, int]:
    value = 0
    for _ in range(4):
        if offset >= len(data):
            raise ValueError("truncated MIDI variable-length quantity")
        byte = data[offset]
        offset += 1
        value = (value << 7) | (byte & 0x7F)
        if not byte & 0x80:
            return value, offset
    raise ValueError("MIDI variable-length quantity exceeds four bytes")


def parse_midi(data: bytes) -> tuple[int, tuple[tuple[int, int], ...], tuple[TickNote, ...], int]:
    if data[:4] != b"MThd" or len(data) < 14:
        raise ValueError("invalid MIDI header")
    header_length = int.from_bytes(data[4:8], "big")
    if header_length != 6:
        raise ValueError(f"unsupported MIDI header length: {header_length}")
    midi_format, track_count, division = struct.unpack(">HHH", data[8:14])
    if midi_format not in (0, 1) or division & 0x8000:
        raise ValueError("only PPQN MIDI format 0/1 is supported")

    offset = 8 + header_length
    tempo_events: list[tuple[int, int]] = []
    notes: list[TickNote] = []
    loop_tick = 0
    note_order = 0

    for track_index in range(track_count):
        if data[offset : offset + 4] != b"MTrk":
            raise ValueError(f"track {track_index}: missing MTrk header")
        track_length = int.from_bytes(data[offset + 4 : offset + 8], "big")
        track = data[offset + 8 : offset + 8 + track_length]
        if len(track) != track_length:
            raise ValueError(f"track {track_index}: truncated data")
        offset += 8 + track_length

        cursor = 0
        absolute_tick = 0
        running_status: int | None = None
        programs = [0] * 16
        active: dict[tuple[int, int], deque[tuple[int, int, int, int]]] = defaultdict(deque)

        while cursor < len(track):
            delta, cursor = read_vlq(track, cursor)
            absolute_tick += delta
            status = track[cursor]
            if status & 0x80:
                cursor += 1
                if status < 0xF0:
                    running_status = status
                else:
                    running_status = None
            elif running_status is not None:
                status = running_status
            else:
                raise ValueError(f"track {track_index}: data byte without running status")

            if status == 0xFF:
                meta_type = track[cursor]
                cursor += 1
                length, cursor = read_vlq(track, cursor)
                payload = track[cursor : cursor + length]
                cursor += length
                if meta_type == 0x51:
                    if len(payload) != 3:
                        raise ValueError("invalid tempo meta event")
                    tempo_events.append((absolute_tick, int.from_bytes(payload, "big")))
                continue

            if status in (0xF0, 0xF7):
                length, cursor = read_vlq(track, cursor)
                cursor += length
                continue

            event_type = status & 0xF0
            channel = status & 0x0F
            if event_type in (0xC0, 0xD0):
                value = track[cursor]
                cursor += 1
                if event_type == 0xC0:
                    programs[channel] = value
                continue

            first = track[cursor]
            second = track[cursor + 1]
            cursor += 2
            key = (channel, first)
            if event_type == 0x90 and second > 0:
                active[key].append((absolute_tick, second, programs[channel], note_order))
                note_order += 1
            elif event_type == 0x80 or (event_type == 0x90 and second == 0):
                if not active[key]:
                    raise ValueError(
                        f"track {track_index}: note-off without note-on for pitch {first}"
                    )
                start_tick, velocity, program, order = active[key].popleft()
                notes.append(
                    TickNote(
                        start_tick=start_tick,
                        end_tick=absolute_tick,
                        pitch=first,
                        velocity=velocity,
                        program=program,
                        track=track_index,
                        order=order,
                    )
                )

        unfinished = [key for key, starts in active.items() if starts]
        if unfinished:
            raise ValueError(f"track {track_index}: unfinished notes: {unfinished}")
        loop_tick = max(loop_tick, absolute_tick)

    if offset != len(data):
        raise ValueError("unexpected bytes after final MIDI track")
    return division, tuple(sorted(tempo_events)), tuple(notes), loop_tick


def tick_microseconds(tick: int, division: int, tempo_events: tuple[tuple[int, int], ...]) -> Fraction:
    current_tick = 0
    current_tempo = 500_000
    total = Fraction(0)
    for event_tick, new_tempo in tempo_events:
        if event_tick > tick:
            break
        if event_tick < current_tick:
            continue
        total += Fraction((event_tick - current_tick) * current_tempo, division)
        current_tick = event_tick
        current_tempo = new_tempo
    total += Fraction((tick - current_tick) * current_tempo, division)
    return total


def exact_milliseconds(microseconds: Fraction) -> int:
    milliseconds = microseconds / 1000
    if milliseconds.denominator != 1:
        raise ValueError(f"event is not aligned to a whole millisecond: {milliseconds}")
    return milliseconds.numerator


def render(result: BuildResult) -> bytes:
    lines = [
        "# Generated by tools/build_game_over_music.py; do not edit.",
        "# RARS MIDI events: start_ms, duration_ms, pitch, velocity.",
        "",
        f".eqv GAME_OVER_MUSIC_EVENT_COUNT {len(result.events)}",
        f".eqv GAME_OVER_MUSIC_LOOP_MS {result.loop_ms}",
        f".eqv GAME_OVER_MUSIC_INSTRUMENT {result.instrument}",
        f".eqv GAME_OVER_MUSIC_STOP_PITCH_COUNT {len(result.stop_pitches)}",
        ".eqv GAME_OVER_MUSIC_ENABLED 1",
        "",
        ".data",
        ".align 2",
        "game_over_music_index:      .word 0",
        "game_over_music_loop_start: .word 0",
        "",
        "game_over_music_events:",
    ]
    for event in result.events:
        lines.append(
            f"    .word {event.start_ms}, {event.duration_ms}, "
            f"{event.pitch}, {event.velocity}"
        )
    lines.extend(
        (
            "",
            "game_over_music_stop_pitches:",
            "    .byte " + ", ".join(str(pitch) for pitch in result.stop_pitches),
        )
    )
    return ("\n".join(lines) + "\n").encode("ascii")


def build(source: Path = SOURCE) -> BuildResult:
    data = source.read_bytes()
    digest = hashlib.sha256(data).hexdigest()
    if digest != SOURCE_SHA256:
        raise ValueError(f"unexpected source MIDI hash: {digest}")

    division, tempo_events, tick_notes, loop_tick = parse_midi(data)
    programs = {note.program for note in tick_notes}
    if len(programs) != 1:
        raise ValueError(f"expected one MIDI program, got {sorted(programs)}")

    events = []
    for note in sorted(tick_notes, key=lambda item: (item.start_tick, item.track, item.order)):
        start_us = tick_microseconds(note.start_tick, division, tempo_events)
        end_us = tick_microseconds(note.end_tick, division, tempo_events)
        events.append(
            NoteEvent(
                start_ms=exact_milliseconds(start_us),
                duration_ms=exact_milliseconds(end_us - start_us),
                pitch=note.pitch,
                velocity=note.velocity,
            )
        )

    loop_ms = exact_milliseconds(tick_microseconds(loop_tick, division, tempo_events))
    stop_pitches = tuple(sorted({event.pitch for event in events}))
    provisional = BuildResult(
        events=tuple(events),
        loop_ms=loop_ms,
        instrument=next(iter(programs)),
        stop_pitches=stop_pitches,
        content=b"",
    )
    return BuildResult(
        events=provisional.events,
        loop_ms=provisional.loop_ms,
        instrument=provisional.instrument,
        stop_pitches=provisional.stop_pitches,
        content=render(provisional),
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    first = build()
    second = build()
    if first != second:
        raise AssertionError("Game Over MIDI conversion is not deterministic")

    if args.check:
        if not OUTPUT.exists() or OUTPUT.read_bytes() != first.content:
            print(f"missing or stale: {OUTPUT.relative_to(ROOT)}")
            return 1
        return 0

    OUTPUT.write_bytes(first.content)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
