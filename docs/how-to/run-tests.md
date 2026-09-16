> status: current (2026-09-11)

# How to run tests

**When to use:** running unit or UI tests locally, or setting up a fresh simulator.

All commands are `just` recipes (run `just` from the repo root to list them). Don't use
`mcp_xcode_RunAllTests`/`mcp_xcode_RunSomeTests` or any other `mcp_xcode_*` tool to run tests.

## Target simulator

Single source of truth for the iOS/Catalyst target simulator — don't copy this UDID into other
docs, link here instead.

| Property | Value |
|---|---|
| Name | iPhone 17 |
| UDID | `6CEE2FAC-7D50-4BD0-95E2-1361EDD7FAF6` |
| OS | iOS 26.4.1 |

### One-time simulator setup

Disable the crash dialog so a mid-test crash doesn't block subsequent tests (persists across
reboots, reset if the simulator is erased):

```bash
xcrun simctl boot 6CEE2FAC-7D50-4BD0-95E2-1361EDD7FAF6 2>/dev/null; sleep 3
xcrun simctl spawn 6CEE2FAC-7D50-4BD0-95E2-1361EDD7FAF6 \
  defaults write com.apple.CrashReporter DialogType none
```

Verify: `xcrun simctl spawn 6CEE2FAC-7D50-4BD0-95E2-1361EDD7FAF6 defaults read com.apple.CrashReporter DialogType` should print `none`.

## Memory ceiling

16 GB Mac Mini. Each simulator clone adds ~500–750 MB RAM (copy-on-write). **3 workers is the
ceiling** — 5 stalls clone boot indefinitely with no output. `justfile` hardcodes 3; don't raise
it without more RAM.

## Commands

- `just test-unit` — Swift Testing package tests, no simulator.
- `just test-ui-legacy` — UI tests, 3 parallel workers. Temporary until WS3-T3.4 adds the
  `Smoke`/`Live` test plans, at which point `just test-smoke`/`just test-ui` take over.
- `just test-ui-one <SmartTubeUITests/Suite/testMethod>` — a single UI test.
- Device/app log capture during a test run: `docs/how-to/device-logs.md`.

## Physical Apple TV

Pair the Apple TV in Xcode and use `just tv-devices` to find its identifier. The
device recipes use development signing with an explicit team and bundle identifier;
use the installed app's identifier to retain its settings and login. They do not
start a simulator or change the project's signing settings.

```bash
just derived=/tmp/SmartTubeTVDerived build-tv-device <device> <team> <bundle>
just derived=/tmp/SmartTubeTVDerived install-tv-device <device>
just launch-tv-device <device> <bundle>
just derived=/tmp/SmartTubeTVDerived test-tv-device <device> <team> <bundle> TVFocusChainUITests/testMenuFromVideoListScrollsToTop /tmp/tv-focus.xcresult
just derived=/tmp/SmartTubeTVDerived test-tv-device <device> <team> <bundle> TVFocusChainUITests/testPlaybackRemainsActiveWithoutRemoteInput /tmp/tv-playback.xcresult
```

Use a new result path for each run. These two live tests need a signed-in account
and a populated Home feed. The playback test needs a video longer than six minutes;
it sends no remote input for six minutes and checks foreground state and advancing
playback. To verify a configured screen-saver timeout, that timeout must be shorter
than the observation interval. The test does not change system screen-saver settings.

`just derived=/tmp/SmartTubeTVDerived check-tv-device-build` compiles against the
physical tvOS SDK without signing when no development account is available.

## Known unit-test failure

`just test-unit` currently fails to build (pre-existing, not test-writing-related) — see
`AGENTS.md`'s Gotchas. Native-macOS-only code in `TOSPlayerView.swift`/
`TOSPlayerViewModel+WebBridge.swift` doesn't compile. Fixing it is WS4/WS5 scope.
