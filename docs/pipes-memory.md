<!-- doc-covers: crates/screenpipe-core/src/pipes, crates/screenpipe-engine/src/pipes_api.rs, crates/screenpipe-engine/src/pipe_store.rs -->
<!-- doc-verified: 7493feff7 -->

# Pipe memory.md

Every pipe receives the same `memory.md` policy in its system prompt. Pipe-specific prompts no longer need to copy that policy.

```text
pipe starts
   |
   +--> read ./memory.md when present
   |
   +--> execute the pipe task
   |
   +--> durable lesson learned?
            | no  -> leave memory.md unchanged
            | yes -> append 1-3 short dated lines
                         |
                         +--> over 150 lines or 8 KB?
                                  yes -> warn and do not auto-delete
```

The runtime never rewrites or deletes user memory. `GET /pipes` and `GET /pipes/:id` expose metadata only:

```json
{
  "memory": {
    "exists": true,
    "size_bytes": 420,
    "line_count": 12,
    "updated_at": "2026-07-19T08:00:00Z",
    "over_limit": false
  }
}
```

`GET /pipes/:id/memory` lazily returns the same metadata plus at most 8 KB of content. Pipe IDs are restricted to one path component, and there is intentionally no memory editing API.
