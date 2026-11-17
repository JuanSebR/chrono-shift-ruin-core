"""Build the original-source global loop. Requires local FFmpeg and NumPy; installs nothing."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import subprocess

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/Sonidos/Cancion/videoplayback.m4a"
OUTPUT = ROOT / "assets/Sonidos/Cancion/derived/global_background_loop.ogg"
RATE = 44100
START = 60
LENGTH = 188
FADE = 8


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    ffmpeg = shutil.which("ffmpeg")
    if ffmpeg is None or not SOURCE.is_file():
        raise SystemExit("C.O.R.E.-9: Falta FFmpeg o la cancion original. Sin materiales no hay milagros.")
    pcm = subprocess.run(
        [ffmpeg, "-v", "error", "-ss", str(START), "-t", str(LENGTH), "-i", str(SOURCE),
         "-vn", "-ar", str(RATE), "-ac", "2", "-f", "f32le", "pipe:1"],
        check=True, capture_output=True,
    ).stdout
    source = np.frombuffer(pcm, dtype="<f4").reshape(-1, 2)
    assert len(source) == LENGTH * RATE
    count = FADE * RATE
    theta = np.linspace(0.0, np.pi / 2.0, count, endpoint=True, dtype=np.float64)[:, None]
    # Middle -> tail/head equal-power crossfade -> middle. Both joins follow adjacent samples.
    blend = source[-count:] * np.cos(theta) + source[:count] * np.sin(theta)
    loop = np.concatenate((source[count:-count], blend)).astype("<f4")
    gain = min(1.0, 0.94 / float(np.max(np.abs(loop))))
    loop *= gain
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [ffmpeg, "-v", "error", "-y", "-f", "f32le", "-ar", str(RATE), "-ac", "2", "-i", "pipe:0",
         "-c:a", "libvorbis", "-q:a", "5", "-metadata", "title=Chrono-Shift global background loop",
         "-metadata", "LOOPSTART=0", "-metadata", f"LOOPEND={len(loop)}", str(OUTPUT)],
        input=loop.tobytes(), check=True,
    )
    decoded_pcm = subprocess.run(
        [ffmpeg, "-v", "error", "-i", str(OUTPUT), "-f", "f32le", "pipe:1"],
        check=True, capture_output=True,
    ).stdout
    decoded = np.frombuffer(decoded_pcm, dtype="<f4").reshape(-1, 2)
    seam_step = float(np.max(np.abs(decoded[0] - decoded[-1])))
    ordinary_steps = np.abs(np.diff(decoded, axis=0))
    p999 = float(np.quantile(ordinary_steps, 0.999))
    assert len(decoded) == (LENGTH - FADE) * RATE
    assert np.isfinite(decoded).all() and np.max(np.abs(decoded)) < 1.0
    assert seam_step < p999, "Loop boundary exceeds normal high-percentile waveform changes"
    rms_seconds = np.sqrt(np.mean(decoded.reshape(-1, RATE, 2).astype(np.float64) ** 2, axis=(1, 2)))
    report = {
        "source": str(SOURCE), "source_sha256": hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
        "source_start_seconds": START, "source_end_seconds": START + LENGTH,
        "crossfade_seconds": FADE, "crossfade": "equal-power tail/head; middle then crossfade",
        "output": str(OUTPUT), "output_sha256": hashlib.sha256(OUTPUT.read_bytes()).hexdigest(),
        "sample_rate": RATE, "channels": 2, "samples": len(decoded), "duration_seconds": len(decoded) / RATE,
        "peak": float(np.max(np.abs(decoded))), "gain": gain,
        "rms": float(np.sqrt(np.mean(decoded.astype(np.float64) ** 2))),
        "join_sample_step": seam_step, "normal_step_p999": p999,
        "join_no_outlier": seam_step < p999,
        "minimum_second_rms": float(np.min(rms_seconds)), "no_silent_seconds": bool(np.min(rms_seconds) > 0.001),
        "encoder": "FFmpeg libvorbis quality 5", "loop_offset": 0.0,
    }
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
