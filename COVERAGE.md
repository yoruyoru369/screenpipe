# Screenpipe Coverage

Screenpipe tracks coverage at two complementary layers:

- Tauri/WebDriver E2E coverage: real product UX and local API behavior by platform.
- Core engine coverage: Rust behavioral flow coverage across capture, audio, DB, accessibility, and engine crates.

These dashboards are behavioral maps, not a replacement for line or branch coverage.
Use them to see which product risks are represented, then layer runtime job
results and `cargo llvm-cov` data on top when judging release confidence.

## Dashboards

- E2E dashboard: [apps/screenpipe-app-tauri/e2e/COVERAGE.md](apps/screenpipe-app-tauri/e2e/COVERAGE.md)
- Core engine dashboard: [docs/coverage/CORE.md](docs/coverage/CORE.md)

## Current Snapshot

### Tauri E2E

- Mapped specs: 117
- Declared test blocks: 334
- Weighted coverage points: 261.3

| Platform | Specs | Declared tests | Weighted points | Layers | Features | Critical score |
| --- | --- | --- | --- | --- | --- | --- |
| windows | 89 | 288 | 235.3 | 15 | 93 | 92% |
| macos | 113 | 297 | 232.1 | 17 | 99 | 90% |
| linux | 79 | 248 | 206.0 | 14 | 89 | 88% |

### Core Engine

- Mapped suites: 32
- Mapped Rust files: 325
- Active test blocks: 3145
- Ignored/manual test blocks: 140
- Weighted coverage points: 2585.3

| Platform | Suites | Active tests | Ignored tests | Weighted points | Layers | Flows | Critical score |
| --- | --- | --- | --- | --- | --- | --- | --- |
| windows | 29 | 3015 | 132 | 2525.7 | 21 | 11 | 100% |
| macos | 29 | 3067 | 115 | 2535.7 | 22 | 11 | 100% |
| linux | 25 | 2688 | 105 | 2229.5 | 20 | 11 | 100% |

## Refresh

From `apps/screenpipe-app-tauri`:

```bash
bun run coverage:all
bun run coverage:all:check
```

For core line coverage, install/use `cargo llvm-cov` and feed its JSON
summary into `coverage:core`; the core dashboard documents the exact command.
