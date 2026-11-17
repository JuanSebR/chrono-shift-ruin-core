"""Build an isolated Windows Release project; never copy profiles or development tools.

Use official 4.7.2.stable Windows release templates in --templates.
The working directory must be new and outside the source project.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]
TEXT = {".gd", ".tscn", ".tres", ".gdshader", ".godot"}
DYNAMIC = [
    "assets/sprites/jefe/derived/atlases/*.png",
    "assets/sprites/jefe/laser_vertical_*.png",
    "assets/sprites/Dialogos/derived/*.png",
    "assets/tiles/sala 3/derived/module_levitation/*.png",
    "assets/tiles/sala 3/derived/module_disappearance_v2/*.png",
    "assets/tiles/sala 3/derived/pickup_interacting/*.png",
    "assets/ui/hud/health/*.png",
]
FINAL_FILES = ["personaje End.png", "thanks for playing End.png", "thaks for playing 2 End.png", "return Bottom End.png"]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--work", type=Path, required=True)
    parser.add_argument("--templates", type=Path, required=True)
    parser.add_argument("--godot", type=Path, default=Path("C:/Godot/godot.exe.exe"))
    args = parser.parse_args()
    work = args.work.resolve()
    if work == ROOT or ROOT in work.parents or work.exists():
        raise SystemExit("C.O.R.E.-9: La exportacion necesita una carpeta nueva fuera del proyecto. Sin pisar la ruina original.")
    assert (args.templates / "version.txt").read_text().strip() == "4.7.2.stable"
    work.mkdir(parents=True)
    stage = work / "project"
    stage.mkdir()
    selected = {"project.godot", "export_presets.cfg", "icon.svg", "default_bus_layout.tres"}
    selected.update(p.name for p in ROOT.glob("*.gd"))
    selected.update(p.name for p in ROOT.glob("*.tres"))
    for directory, suffix in [("scenes", ".tscn"), ("scripts", ".gd"), ("shaders", ".gdshader")]:
        selected.update(p.relative_to(ROOT).as_posix() for p in (ROOT / directory).rglob("*" + suffix))
    for pattern in DYNAMIC:
        selected.update(p.relative_to(ROOT).as_posix() for p in ROOT.glob(pattern))
    selected.update("assets/Final/" + name for name in FINAL_FILES)
    # Resolve literal resource references recursively, including animation and texture resources.
    scanned = set()
    while selected - scanned:
        relative = (selected - scanned).pop()
        scanned.add(relative)
        source = ROOT / relative
        assert source.is_file(), relative
        if source.suffix in TEXT:
            for reference in re.findall(r'res://([^"\r\n]+)', source.read_text(encoding="utf-8-sig")):
                if relative == "project.godot" and reference.startswith("addons/"):
                    continue
                candidate = ROOT / reference
                if candidate.is_file():
                    assert not reference.startswith(("tools/", "tests/", "addons/", "backups/", "artifacts/")), reference
                    selected.add(reference)
    manifest = []
    for relative in sorted(selected):
        source = ROOT / relative
        destination = stage / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
        manifest.append({"path": relative, "sha256": sha(source), "bytes": source.stat().st_size})
        uid = Path(str(source) + ".uid")
        if uid.exists():
            shutil.copy2(uid, Path(str(destination) + ".uid"))
        metadata = Path(str(source) + ".import")
        if metadata.exists():
            shutil.copy2(metadata, Path(str(destination) + ".import"))
            for imported in re.findall(r'res://(\.godot/imported/[^"\]\r\n]+)', metadata.read_text(encoding="utf-8")):
                cache = ROOT / imported
                for cached in cache.parent.glob(cache.stem + ".*"):
                    target = stage / cached.relative_to(ROOT)
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(cached, target)
    # Release-only build transformations. Keep the complete development project untouched.
    project = stage / "project.godot"
    content = project.read_text(encoding="utf-8")
    content = content.replace('enabled=PackedStringArray("res://addons/core9_editor_inspector/plugin.cfg")', 'enabled=PackedStringArray()')
    project.write_text(content, encoding="utf-8")
    room = stage / "scripts/rooms/room5.gd"
    content = room.read_text(encoding="utf-8")
    branch = '\tif OS.get_cmdline_user_args().has("--room5-manual-diagnostic"):\n\t\tencounter_activation_enabled = false\n'
    assert content.count(branch) == 1
    room.write_text(content.replace(branch, ""), encoding="utf-8")
    progress = stage / "scripts/game_progress.gd"
    content = progress.read_text(encoding="utf-8")
    branch = '\tif not OS.get_environment("CHRONOSHIFT_ROOM5_PROFILE").is_empty():\n\t\treturn\n'
    assert content.count(branch) == 1
    progress.write_text(content.replace(branch, ""), encoding="utf-8")
    (work / "source_manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    roaming = work / "export_profile/Roaming"
    templates = roaming / "Godot/export_templates/4.7.2.stable"
    templates.mkdir(parents=True)
    for source in args.templates.iterdir():
        if source.suffix == ".exe" or source.name == "version.txt" or source.suffix == ".dll":
            shutil.copy2(source, templates / source.name)
    env = os.environ.copy()
    env["APPDATA"] = str(roaming)
    env.pop("CHRONOSHIFT_ROOM5_PROFILE", None)
    output = ROOT / "build/windows/Chrono-Shift_Ruin_Core.exe"
    output.parent.mkdir(parents=True, exist_ok=True)
    commands = [
        [str(args.godot), "--headless", "--editor", "--recovery-mode", "--path", str(stage), "--import"],
        [str(args.godot), "--headless", "--recovery-mode", "--path", str(stage), "--export-release", "Windows Desktop Release", str(output)],
    ]
    for name, command in zip(["import", "export"], commands):
        with (work / (name + ".out.log")).open("w", encoding="utf-8") as stdout, (work / (name + ".err.log")).open("w", encoding="utf-8") as stderr:
            completed = subprocess.run(command, env=env, cwd=work, stdout=stdout, stderr=stderr, creationflags=subprocess.CREATE_NO_WINDOW)
        if completed.returncode:
            raise SystemExit(f"C.O.R.E.-9: {name} fallo ({completed.returncode}). Los logs contienen el desastre.")
    print(json.dumps({"output": str(output), "bytes": output.stat().st_size, "sha256": sha(output), "work": str(work), "runtime_files": len(manifest)}, indent=2), flush=True)


if __name__ == "__main__":
    main()
