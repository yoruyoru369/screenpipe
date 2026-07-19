# SOP to disabled pipe draft

The Artifacts SOP viewer can turn a reviewed SAF v1 `kind=sop` artifact into a new, inert `pipe.md` draft.

```text
SAF SOP
  |
  +-- POST /pipes/drafts/preview-from-sop  (no write)
  |      slug / title / natural-language trigger / prompt
  |      duplicate gate: slug, title, purpose, inputs, outputs
  |
  +-- edit and preview again
  |
  +-- POST /pipes/drafts/from-sop          (gate runs again)
         create a new path atomically
         schedule: manual
         enabled: false
         permissions: reader
         trigger.confirm: true
```

An exact slug or title match is `SKIP`. A purpose similarity of at least `0.80` combined with input app/source overlap of at least `0.50` is also `SKIP`. The API has no force bypass. Creation re-evaluates both the gate and path absence, never overwrites an existing pipe, never enables a pipe, and performs no external mutation.
