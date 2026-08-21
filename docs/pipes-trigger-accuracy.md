<!-- doc-covers: crates/screenpipe-core/src/pipes/custom_triggers.rs, crates/screenpipe-core/src/pipes/mod.rs, crates/screenpipe-engine/src/pipes_api.rs -->
<!-- doc-verified: 7493feff7 -->

# Pipe trigger accuracy

The optional hybrid matcher uses
[`model2vec-rs` 0.2.1](https://github.com/MinishLab/model2vec-rs) with the
revision-pinned official
[`potion-multilingual-128M`](https://huggingface.co/minishlab/potion-multilingual-128M)
model. The model is downloaded only after an enabled pipe explicitly selects
`trigger.matcher: hybrid`; it is not bundled with screenpipe.

`trigger.matcher`は`lexical`（既定）または`hybrid`を受け付ける。既存pipeは指定不要で、従来どおり完全ローカルな字句判定だけを使う。

```yaml
trigger:
  matcher: hybrid
  custom:
    - 請求書メールを確認したら
  events:
    - email_triage
  confirm: true
```

`hybrid`を初めて使うpipeがある場合だけ、公式`minishlab/potion-multilingual-128M`の固定revision `73908c3438cf03b6a01bcb9611d62b23d0726f08`を`~/.screenpipe/models/`へ遅延取得する。モデルは同梱しない。未取得、取得中、offline、破損、load失敗時は字句判定を継続し、pipe schedulerを停止しない。

```text
recent local activity
        |
        v
length-scaled lexical matcher ---- accepted ----+
        |                                        |
        +-- hybrid only --> local embedding -----+--> confirm or run
                                                 |
cloud workflow_event (fixed label, >= 0.90) -----+
                    fallback only; local wins
```

字句閾値は情報量2以下で`0.85`、3–4で`0.70`、5以上で`0.50`。semantic閾値は同じ区分で`0.86 / 0.80 / 0.72`。完全一致は常に`1.0`である。

実行履歴は既存`trigger_type`を維持し、nullableな`trigger_details`へmatcher、trigger/event名、score/confidence、app/window、confirmation有無だけを返す。OCR本文、classifier description、timestamp列、raw event payloadは保存しない。確認通知のRunは同じmetadataを引き継ぎ、`trigger_type=confirmed_event`として一度だけ記録する。
