<!-- doc-covers: crates/screenpipe-engine/src/pipes_api.rs, crates/screenpipe-engine/src/routes/artifacts.rs, apps/screenpipe-app-tauri/components/settings/pipes-section.tsx, apps/screenpipe-app-tauri/components/settings/saf-sop-view.tsx -->
<!-- doc-verified: 7493feff7 -->

# Teach mode

Teach mode records a bounded, privacy-minimized trajectory and turns it into a reviewable SOP.

```text
Pipes: 作業を教える
          |
          v
POST /pipes/teach/start -- one session, max 2h / 10,000 events
          |
          +-- UI: app/window/click/input length/frame ID
          +-- tools: name/status/execution ID
          +-- omitted: keys, typed text, clipboard, prompts,
                       tool args/results, screenshots
          |
          +-- cancel --> no artifact
          |
          +-- stop --> SOP SAF v1 + sop.md --> Artifacts review
```

API:

- `POST /pipes/teach/start`
- `GET /pipes/teach/status`
- `POST /pipes/teach/stop`
- `POST /pipes/teach/cancel`

A second start returns `409`. Stopping an empty session returns `422` and keeps the session active so the user can perform a reviewable action or cancel. Move and scroll bursts are compressed. Screen context is locally PII-redacted and limited to 160 characters.
