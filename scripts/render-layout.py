#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


CANVAS_DEFAULT = {"width": 1920, "height": 1080}


def lua_bool(value):
    return "true" if value else "false"


def lua_string(value):
    return '"' + str(value).replace("\\", "\\\\").replace('"', '\\"') + '"'


def bartender_position(block, canvas):
    anchor = block.get("anchor", "BOTTOMLEFT")
    scale = block.get("scale", 1)
    if anchor == "TOPRIGHT":
        point = "TOPRIGHT"
        x = round(block["x"] - canvas["width"])
        y = round(block["y"] - canvas["height"])
    elif anchor == "BOTTOM":
        point = "BOTTOM"
        x = round(block["x"] - canvas["width"] / 2)
        y = round(block["y"])
    else:
        point = "BOTTOMLEFT"
        x = round(block["x"])
        y = round(block["y"])

    return {
        "point": point,
        "x": x,
        "y": y,
        "scale": scale,
    }


def suf_position(frame, canvas):
    return {
        "point": "BOTTOMLEFT",
        "relativePoint": "BOTTOMLEFT",
        "x": round(frame["x"]),
        "y": round(frame["y"]),
    }


def render_bartender(layout, profile_key):
    canvas = layout.get("canvas", CANVAS_DEFAULT)
    action_bars = layout["actionBars"]
    by_bar = {}
    pet_bar = None

    for block in action_bars.values():
        bar = block["bar"]
        if bar == "pet":
            pet_bar = block
        else:
            by_bar[int(bar)] = block

    def action_bar_entry(index):
        block = by_bar.get(index)
        if not block:
            return f"""[{index}] = {{
["enabled"] = false,
["version"] = 3,
}}"""

        pos = bartender_position(block, canvas)
        rows = int(block.get("rows", 1))
        rows_line = f'["rows"] = {rows},\n' if rows != 1 else ""
        return f"""[{index}] = {{
["version"] = 3,
["position"] = {{
["x"] = {pos["x"]},
["point"] = {lua_string(pos["point"])},
["scale"] = {pos["scale"]},
["y"] = {pos["y"]},
}},
["padding"] = 4,
{rows_line}["showgrid"] = true,
["hidemacrotext"] = true,
}}"""

    entries = ",\n".join(action_bar_entry(i) for i in range(1, 11))
    pet_pos = bartender_position(pet_bar, canvas) if pet_bar else {"x": 0, "y": 180, "point": "BOTTOMLEFT", "scale": 0.72}

    return f"""
Bartender4DB = {{
["namespaces"] = {{
["StatusTrackingBar"] = {{
["profiles"] = {{
[{lua_string(profile_key)}] = {{
["enabled"] = false,
["version"] = 3,
}},
}},
}},
["ActionBars"] = {{
["profiles"] = {{
[{lua_string(profile_key)}] = {{
["actionbars"] = {{
{entries},
[13] = {{
["enabled"] = false,
["version"] = 3,
}},
[15] = {{
["enabled"] = false,
["version"] = 3,
}},
}},
}},
}},
}},
["ExtraActionBar"] = {{
["profiles"] = {{
[{lua_string(profile_key)}] = {{
["version"] = 3,
["position"] = {{
["x"] = 0,
["point"] = "BOTTOM",
["scale"] = 0.9,
["y"] = 248,
}},
}},
}},
}},
["MicroMenu"] = {{
["profiles"] = {{
[{lua_string(profile_key)}] = {{
["enabled"] = false,
["version"] = 3,
}},
}},
}},
["BagBar"] = {{
["profiles"] = {{
[{lua_string(profile_key)}] = {{
["enabled"] = false,
["version"] = 3,
}},
}},
}},
["BlizzardArt"] = {{
["profiles"] = {{
[{lua_string(profile_key)}] = {{
["enabled"] = false,
["version"] = 3,
}},
}},
}},
["StanceBar"] = {{
["profiles"] = {{
[{lua_string(profile_key)}] = {{
["enabled"] = false,
["version"] = 3,
}},
}},
}},
["PetBar"] = {{
["profiles"] = {{
[{lua_string(profile_key)}] = {{
["version"] = 3,
["position"] = {{
["x"] = {pet_pos["x"]},
["point"] = {lua_string(pet_pos["point"])},
["scale"] = {pet_pos["scale"]},
["y"] = {pet_pos["y"]},
}},
["padding"] = 4,
["showgrid"] = true,
}},
}},
}},
["Vehicle"] = {{
["profiles"] = {{
[{lua_string(profile_key)}] = {{
["version"] = 3,
["position"] = {{
["x"] = 0,
["point"] = "BOTTOM",
["scale"] = 0.9,
["y"] = 248,
}},
}},
}},
}},
["XPBar"] = {{
["profiles"] = {{
[{lua_string(profile_key)}] = {{
["enabled"] = false,
["version"] = 3,
}},
}},
}},
["RepBar"] = {{
["profiles"] = {{
[{lua_string(profile_key)}] = {{
["enabled"] = false,
["version"] = 3,
}},
}},
}},
}},
["profileKeys"] = {{
[{lua_string(profile_key)}] = {lua_string(profile_key)},
}},
["profiles"] = {{
[{lua_string(profile_key)}] = {{
["buttonlock"] = false,
["lock"] = false,
["focuscastmodifier"] = false,
["blizzardVehicle"] = true,
["outofrange"] = "hotkey",
["tooltip"] = "nocombat",
["snapping"] = true,
["minimapIcon"] = {{
["hide"] = false,
}},
}},
}},
}}
"""


def render_masque(profile_key):
    groups = [
        "Bartender4",
        "Bartender4_1",
        "Bartender4_2",
        "Bartender4_3",
        "Bartender4_4",
        "Bartender4_PetBar",
        "Bartender4_Flyout",
        "Bartender4_StanceBar",
    ]
    group_entries = []
    for group in groups:
        upgraded = '["Upgraded"] = true,\n' if group != "Bartender4" and group != "Bartender4_Flyout" else ""
        group_entries.append(f"""[{lua_string(group)}] = {{
["SkinID"] = "Classic Enhanced",
["Backdrop"] = true,
["Shadow"] = true,
["Gloss"] = false,
{upgraded}["Inherit"] = false,
}}""")

    return f"""
MasqueDB = {{
["namespaces"] = {{}},
["profileKeys"] = {{
[{lua_string(profile_key)}] = "Default",
}},
["profiles"] = {{
["Default"] = {{
["Groups"] = {{
{",\n".join(group_entries)},
}},
["API_VERSION"] = 110210,
}},
}},
}}
"""


def render_suf(layout, profile_key):
    frames = layout["frames"]
    positions = {}
    for key in ["player", "pet", "target", "targettarget", "focus"]:
        positions[key] = suf_position(frames[key], layout["canvas"])

    def position_entry(key):
        pos = positions[key]
        return f"""[{lua_string(key)}] = {{
["y"] = {pos["y"]},
["x"] = {pos["x"]},
["point"] = {lua_string(pos["point"])},
["relativePoint"] = {lua_string(pos["relativePoint"])},
}}"""

    def unit_entry(key, portrait_enabled=False):
        frame = frames[key]
        return f"""[{lua_string(key)}] = {{
["width"] = {round(frame["w"])},
["height"] = {round(frame["h"])},
["portrait"] = {{
["enabled"] = {lua_bool(portrait_enabled)},
}},
["powerBar"] = {{
["colorType"] = "type",
["height"] = 0.7,
["background"] = true,
["order"] = 20,
}},
["healthBar"] = {{
["colorType"] = "class",
["height"] = 1.2,
["background"] = true,
["order"] = 10,
["reactionType"] = "npc",
}},
}}"""

    return f"""
ShadowedUFDB = {{
["profileKeys"] = {{
[{lua_string(profile_key)}] = "Default",
}},
["global"] = {{
["infoID"] = 3,
}},
["profiles"] = {{
["Default"] = {{
["locked"] = true,
["hidden"] = {{
["player"] = true,
["pet"] = true,
["target"] = true,
["focus"] = true,
["cast"] = true,
}},
["positions"] = {{
{",\n".join(position_entry(k) for k in ["player", "pet", "target", "targettarget", "focus"])},
["party"] = {{
["y"] = 695,
["x"] = 20,
["point"] = "TOPLEFT",
["relativePoint"] = "BOTTOMLEFT",
}},
["raid"] = {{
["anchorPoint"] = "C",
}},
}},
["units"] = {{
{",\n".join(unit_entry(k, False) for k in ["player", "pet", "target", "targettarget", "focus"])},
}},
}},
}},
}}
"""


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--version-key", default="tbc-anniversary-cn")
    parser.add_argument("--layout", default=None)
    parser.add_argument("--profile-key", default="Autyan - 无情")
    parser.add_argument("--profile-name", default="Autyan")
    parser.add_argument("--output", default=None)
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parents[1]
    version_root = repo_root / "src" / "versions" / args.version_key
    if args.layout:
        layout_path = Path(args.layout)
    else:
        version_data = json.loads((version_root / "version.json").read_text())
        layout_path = version_root / version_data["defaultLayout"]

    layout = json.loads(layout_path.read_text())
    output_dir = Path(args.output) if args.output else repo_root / "configs" / args.version_key / args.profile_name
    output_dir.mkdir(parents=True, exist_ok=True)

    files = {
        "Bartender4.lua": render_bartender(layout, args.profile_key),
        "Masque.lua": render_masque(args.profile_key),
        "ShadowedUnitFrames.lua": render_suf(layout, args.profile_key),
    }
    for name, content in files.items():
        (output_dir / name).write_text(content)

    print(f"Rendered {len(files)} files to {output_dir}")


if __name__ == "__main__":
    main()
