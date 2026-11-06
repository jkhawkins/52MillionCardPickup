# Steam release checklist

The repository builds a standalone PC game. Publishing to Steam requires the owner's Steamworks partner account and is not performed by this codebase.

## 1. App setup

- Create the Steamworks app and record its public numeric App ID.
- Complete store presence, capsule art, screenshots, trailer, pricing, age rating, and review.
- Configure Windows (and optional Linux) depots and launch options.
- Create the 20 achievement API names listed in `data/steam.json` and upload their icons.

## 2. GodotSteam

- Install a GodotSteam editor/export template or GDExtension matching Godot 4.7.2 and your target architectures.
- Set `data/steam.json`:
  - `enabled: true`
  - `app_id: <your public App ID>`
  - verify each local achievement key maps to the exact Steamworks API name.
- Export with the matching Steam-enabled templates. The adapter initializes Steam only when enabled and the singleton is present; otherwise local achievements continue to work.
- Include the required Steam redistributable library with the depot according to the SDK instructions.
- Never commit `steam_appid.txt` if it contains anything other than the public App ID, and never commit SDK headers/libraries, partner credentials, tokens, or depot keys.

## 3. Launch configuration

Windows depot launch option: `52MillionCardPickup.exe`.
Linux depot launch option: `52MillionCardPickup.x86_64`.

For local Steam testing, place a `steam_appid.txt` containing only the public App ID next to the executable if your GodotSteam setup requires it. Remove it for the uploaded depot unless the integration documentation says otherwise.

## 4. Achievements

Achievements are cosmetic and grant no gameplay bonus. The bridge calls `setAchievement` and `storeStats` when a local badge unlocks. Verify each unlock in the Steamworks test environment. Do not reset player stats from the game.

## 5. Build verification

- Run the headless rules tests.
- Run the six balance agents and review `docs/BALANCE.md`.
- Export Windows and Linux from the tagged release commit.
- Smoke-test clean install, save/resume, pause/focus loss, remapping, reduced motion, high contrast, all five abilities, completion, Endless, and fresh run.
- Upload depots with SteamPipe, set the test branch password, and verify launch from the Steam client.
- Submit the build for Steam review before release.

## 6. What is intentionally not included

No Steam DRM wrapper, microtransactions, cloud saves, leaderboards, trading cards, or online telemetry are implemented because they are outside the approved GDD. Local saves are the approved save model. Adding any of those would require explicit design approval.
