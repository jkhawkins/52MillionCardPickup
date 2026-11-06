# 52 Million Card Pickup

A native PC incremental/clicker game built with **Godot 4.7.2** from the approved game design document in [`docs/GDD.md`](docs/GDD.md).

One green casino worktable. One card per click. Fifty-two cards of capacity. Count, upgrade, automate, and deposit **52,000,000 cards** in one continuous run.

## Status

Playable implementation of the approved feature set, with original replaceable art/audio, local saves, accessibility options, six balance agents, and an optional Steamworks achievement bridge. Balance is validated by automated agents; human playtest and Steam store publication are separate release steps.

## Play

Download the Windows or Linux artifact from the repository's **Build PC and preview** GitHub Actions run, extract it, and run the executable. The Web artifact is a convenience preview, not the Steam build.

Default controls:

| Input | Action |
|---|---|
| Left click / Space | Pick up cards |
| Hold left click / Space | Hold-to-pickup |
| D | Start or cancel deposit |
| 1–5 | Activate owned abilities |
| L | Deck Ledger |
| U | Focus upgrade tree |
| Escape | Pause / settings |

All gameplay inputs can be remapped in Settings.

## Build from source

1. Install Godot **4.7.2** (standard, not .NET) and matching export templates.
2. Open `project.godot` in Godot, or run:

```sh
godot --headless --path . --editor --quit
godot --path .
```

Headless rules tests:

```sh
godot --headless --path . --script res://tests/test_rules.gd
```

Balance agents (same live rules and costs):

```sh
godot --headless --path . --script res://simulation/run_balance.gd -- --seed=52 --minutes=240 --out=simulation/results/run.json
```

Desktop exports:

```sh
godot --headless --path . --export-release "Windows Desktop" build/windows/52MillionCardPickup.exe
godot --headless --path . --export-release "Linux" build/linux/52MillionCardPickup.x86_64
```

The GitHub Actions workflow builds Windows, Linux, and Web artifacts from the same source.

## Repository map

- `game/core/rules.gd` — UI-independent simulation, economy, cards, ledger, abilities, events, achievements, save state.
- `game/main.gd` — one-screen worktable UI, input, tutorial, settings, ledger, results.
- `game/ui/table_art.gd` — evolving table presentation and representative card effects.
- `game/systems/` — atomic local persistence, adaptive audio, optional Steam bridge.
- `data/upgrades.json` — canonical 104-entry catalog generated from the GDD tables.
- `data/balance.json` — explicit economy tuning pass.
- `simulation/` — six balance agents using the live rules.
- `tests/` — headless regression suite.
- `tools/` — catalog and original asset generators.
- `docs/` — GDD, implementation decisions, balance reports, Steam release checklist.

## Saving

Local autosave every 10 seconds, after purchases, and on focus loss/close. Saves use `user://save.json` with a last-known-good backup. No offline progress is calculated. Pause stops gameplay timers.

## Steam

The standalone game does not require Steam. To enable Steam achievements, install a matching GodotSteam build/GDExtension, set your public App ID and achievement API names in `data/steam.json`, and follow [`docs/STEAM_RELEASE.md`](docs/STEAM_RELEASE.md). Never commit partner credentials or the Steamworks SDK.

## License

Game source and original procedural assets: MIT (`LICENSE`). Bundled fonts retain their SIL Open Font Licenses in `assets/fonts/`. Godot engine licensing is listed in `THIRDPARTY.md`.
