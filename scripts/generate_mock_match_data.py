#!/usr/bin/env python3
"""Generate deterministic, plausible football tracking data for development.

The generated data is synthetic. Player names are only profile labels and do not
represent real match tracking for Son Heung-min, Lee Kang-in, or Kim Min-jae.
"""

from __future__ import annotations

import argparse
import json
import math
import random
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Iterable


FIELD_LENGTH_METERS = 105.0
FIELD_WIDTH_METERS = 68.0
DEFAULT_QUARTER_SECONDS = 15 * 60
DEFAULT_SECONDS_PER_POINT = 5


@dataclass(frozen=True)
class PlayerProfile:
    key: str
    display_name: str
    role: str
    # x/y are metres from the player's own goal, with y=0 at the top touchline.
    anchors: tuple[tuple[float, float, float], ...]
    movement_sigma: float
    cruising_speed_mps: float
    max_speed_mps: float
    resting_heart_rate: float
    peak_heart_rate: float
    goals_per_quarter: int
    assists_per_quarter: int


PROFILES: tuple[PlayerProfile, ...] = (
    PlayerProfile(
        key="son-heung-min",
        display_name="손흥민 (공격수 스타일 목업)",
        role="forward_winger",
        anchors=((78.0, 20.0, 0.28), (88.0, 34.0, 0.42), (76.0, 50.0, 0.20), (62.0, 28.0, 0.10)),
        movement_sigma=3.0,
        cruising_speed_mps=1.85,
        max_speed_mps=8.8,
        resting_heart_rate=118.0,
        peak_heart_rate=184.0,
        goals_per_quarter=3,
        assists_per_quarter=1,
    ),
    PlayerProfile(
        key="lee-kang-in",
        display_name="이강인 (플레이메이커 스타일 목업)",
        role="attacking_midfielder",
        anchors=((55.0, 22.0, 0.24), (68.0, 34.0, 0.34), (76.0, 48.0, 0.24), (48.0, 47.0, 0.18)),
        movement_sigma=2.5,
        cruising_speed_mps=1.70,
        max_speed_mps=8.0,
        resting_heart_rate=114.0,
        peak_heart_rate=180.0,
        goals_per_quarter=1,
        assists_per_quarter=3,
    ),
    PlayerProfile(
        key="kim-min-jae",
        display_name="김민재 (센터백 스타일 목업)",
        role="center_back",
        anchors=((22.0, 26.0, 0.30), (30.0, 38.0, 0.40), (23.0, 49.0, 0.20), (42.0, 34.0, 0.10)),
        movement_sigma=1.8,
        cruising_speed_mps=1.45,
        max_speed_mps=7.5,
        resting_heart_rate=108.0,
        peak_heart_rate=172.0,
        goals_per_quarter=0,
        assists_per_quarter=1,
    ),
)


class DeterministicRNG:
    """Small wrapper so the generator has one obvious reproducibility point."""

    def __init__(self, seed: int) -> None:
        self._random = random.Random(seed)

    def uniform(self, low: float, high: float) -> float:
        return self._random.uniform(low, high)

    def normal(self, mean: float, sigma: float) -> float:
        return self._random.gauss(mean, sigma)

    def random(self) -> float:
        return self._random.random()

    def choice(self, values: list[tuple[float, float, float]]) -> tuple[float, float, float]:
        return self._random.choice(values)

    def sample(self, values: range, count: int) -> list[int]:
        return self._random.sample(values, count)


def clamp(value: float, low: float, high: float) -> float:
    return max(low, min(high, value))


def iso8601(value: datetime) -> str:
    return value.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


def generate_points(
    profile: PlayerProfile,
    quarter_number: int,
    quarter_seconds: int,
    seconds_per_point: int,
    start: datetime,
    rng: DeterministicRNG,
) -> list[dict[str, float | int | str]]:
    """Generate a smooth path with role-specific spatial bias and fatigue."""

    anchor = rng.choice(list(profile.anchors))
    x = anchor[0] + rng.normal(0, 1.0)
    y = anchor[1] + rng.normal(0, 1.0)
    previous_x, previous_y = x, y
    points: list[dict[str, float | int | str]] = []

    for elapsed in range(0, quarter_seconds + 1, seconds_per_point):
        if rng.random() < 0.12:
            anchor = rng.choice(list(profile.anchors))

        # A small attraction to the role's active zones prevents a random walk
        # from drifting to unrealistic corners of the pitch.
        target_x, target_y, _ = anchor
        progress = elapsed / max(quarter_seconds, 1)
        fatigue = 1.0 - 0.12 * progress
        target_angle = math.atan2(target_y - y, target_x - x)
        direction_angle = target_angle + rng.normal(0, 0.68)
        desired_speed = profile.cruising_speed_mps * (0.88 + 0.18 * fatigue)
        desired_speed += rng.normal(0, profile.movement_sigma * 0.08)
        x += math.cos(direction_angle) * desired_speed * seconds_per_point
        y += math.sin(direction_angle) * desired_speed * seconds_per_point

        # Add a little positional noise after the main movement so the path is
        # not a sequence of perfectly straight vectors.
        x += rng.normal(0, profile.movement_sigma * 0.08)
        y += rng.normal(0, profile.movement_sigma * 0.08)

        x = clamp(x, 2.0, FIELD_LENGTH_METERS - 2.0)
        y = clamp(y, 2.0, FIELD_WIDTH_METERS - 2.0)
        distance = math.hypot(x - previous_x, y - previous_y)
        speed = min(profile.max_speed_mps, distance / max(seconds_per_point, 1))

        # Occasional bursts model a sprint without producing impossible jumps.
        if rng.random() < 0.06:
            speed = min(profile.max_speed_mps, speed + rng.uniform(1.5, 3.2))

        intensity = clamp(speed / profile.max_speed_mps, 0.0, 1.0)
        bpm = profile.resting_heart_rate + (profile.peak_heart_rate - profile.resting_heart_rate) * (
            0.18 + 0.72 * intensity + 0.10 * progress
        )
        bpm += rng.normal(0, 2.2)

        timestamp = start + timedelta(seconds=elapsed)
        points.append(
            {
                "timestamp": iso8601(timestamp),
                "xMeters": round(x, 3),
                "yMeters": round(y, 3),
                "x": round(x / FIELD_LENGTH_METERS, 5),
                "y": round(y / FIELD_WIDTH_METERS, 5),
                "speedMps": round(speed, 3),
                "heartRateBpm": round(clamp(bpm, profile.resting_heart_rate, profile.peak_heart_rate), 1),
                "quarter": quarter_number,
            }
        )
        previous_x, previous_y = x, y

    return points


def generate_player(
    profile: PlayerProfile,
    quarters: int,
    quarter_seconds: int,
    seconds_per_point: int,
    start: datetime,
    seed: int,
) -> dict[str, object]:
    quarter_data = []
    for quarter_number in range(1, quarters + 1):
        quarter_start = start + timedelta(seconds=(quarter_number - 1) * quarter_seconds)
        random = DeterministicRNG(seed + quarter_number * 10_007)
        points = generate_points(
            profile=profile,
            quarter_number=quarter_number,
            quarter_seconds=quarter_seconds,
            seconds_per_point=seconds_per_point,
            start=quarter_start,
            rng=random,
        )
        events = generate_events(profile, quarter_number, points, random)
        quarter_data.append(
            {
                "number": quarter_number,
                "durationSeconds": quarter_seconds,
                "points": points,
                "events": events,
            }
        )

    return {
        "id": profile.key,
        "displayName": profile.display_name,
        "role": profile.role,
        "quarters": quarter_data,
    }


def generate_events(
    profile: PlayerProfile,
    quarter_number: int,
    points: list[dict[str, float | int | str]],
    rng: DeterministicRNG,
) -> list[dict[str, float | int | str]]:
    goals = varied_count(profile.goals_per_quarter, rng)
    assists = varied_count(profile.assists_per_quarter, rng)
    event_count = goals + assists
    if not points or event_count == 0:
        return []

    lower = min(2, max(0, len(points) - 1))
    upper = max(lower, len(points) - 3)
    count = min(event_count, upper - lower + 1)
    indexes = sorted(rng.sample(range(lower, upper + 1), count))
    event_types = ["goal"] * goals + ["assist"] * assists
    return [
        {
            "id": f"{profile.key}-q{quarter_number}-event{index}",
            "type": event_types[index],
            "pointIndex": point_index,
            "timestamp": points[point_index]["timestamp"],
            "x": points[point_index]["x"],
            "y": points[point_index]["y"],
        }
        for index, point_index in enumerate(indexes)
    ]


def varied_count(target: int, rng: DeterministicRNG) -> int:
    """Use profile counts as averages while varying each quarter by one."""

    if target <= 0:
        return 0
    roll = rng.random()
    if roll < 0.30:
        return max(0, target - 1)
    if roll > 0.70:
        return target + 1
    return target


def selected_profiles(player_keys: Iterable[str]) -> list[PlayerProfile]:
    requested = set(player_keys)
    if "all" in requested:
        return list(PROFILES)
    unknown = requested - {profile.key for profile in PROFILES}
    if unknown:
        raise ValueError(f"unknown player profile(s): {', '.join(sorted(unknown))}")
    return [profile for profile in PROFILES if profile.key in requested]


def build_payload(args: argparse.Namespace) -> dict[str, object]:
    start = datetime.fromisoformat(args.start.replace("Z", "+00:00"))
    profiles = selected_profiles(args.players)
    return {
        "schemaVersion": 1,
        "source": "synthetic",
        "disclaimer": "실제 선수의 경기 기록이 아닌, 포지션별 활동 영역을 참고한 개발용 목업 데이터입니다.",
        "seed": args.seed,
        "match": {
            "id": f"mock-match-{args.seed}",
            "startedAt": iso8601(start),
            "quarters": args.quarters,
            "quarterDurationSeconds": args.quarter_seconds,
            "secondsPerPoint": args.seconds_per_point,
        },
        "pitch": {
            "lengthMeters": FIELD_LENGTH_METERS,
            "widthMeters": FIELD_WIDTH_METERS,
            "coordinateSystem": "x=own-goal-to-opponent-goal, y=top-touchline-to-bottom-touchline",
            "normalizedRange": {"x": [0, 1], "y": [0, 1]},
        },
        "players": [
            generate_player(
                profile,
                quarters=args.quarters,
                quarter_seconds=args.quarter_seconds,
                seconds_per_point=args.seconds_per_point,
                start=start,
                seed=args.seed + index * 100_003,
            )
            for index, profile in enumerate(profiles)
        ],
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--players",
        nargs="+",
        default=["all"],
        choices=["all", *(profile.key for profile in PROFILES)],
        help="player profiles to generate (default: all)",
    )
    parser.add_argument("--quarters", type=int, default=4, choices=range(1, 5))
    parser.add_argument("--quarter-seconds", type=int, default=DEFAULT_QUARTER_SECONDS)
    parser.add_argument("--seconds-per-point", type=int, default=DEFAULT_SECONDS_PER_POINT)
    parser.add_argument("--seed", type=int, default=102)
    parser.add_argument("--start", default="2026-11-16T10:00:00Z")
    parser.add_argument("--output", type=Path)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if args.quarters < 1 or args.quarter_seconds < 1 or args.seconds_per_point < 1:
        raise SystemExit("quarters, quarter-seconds, and seconds-per-point must be positive")

    payload = build_payload(args)
    encoded = json.dumps(payload, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(encoded, encoding="utf-8")
    else:
        print(encoded, end="")


if __name__ == "__main__":
    main()
