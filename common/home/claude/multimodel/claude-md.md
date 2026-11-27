## マルチモデル開発体制
- 役割: Planning=Opus 5.5 / Implementation=Sonnet 5.5 / Research=Haiku 5.5（読み取り専用）/ Code Review=Sonnet 5.5（`code-reviewer`、同一モデル系列であり別プロバイダーの独立レビューではない）/ Architecture Escalation=Opus 5.5（`architecture-reviewer`）。
- 設計セッション: `/design-to-issues`。実装セッション: `/implement-issue`。詳細手順は各 Skill にある。subagent は `~/.claude/agents/`。
- 仕様・目的・受入条件・変更許可範囲は実装側が独断で変えない。設計変更が必要ならエスカレーションし、重要な採否は User が決める。採否の報告は Human Decision 形式（上記）に従う。
- 委譲は任意。小さい作業は直接行う。ネストは最大 2 階層・同時 4 件。

## ローカルLLM委譲（Phase 1、処理専用）
- 対象は「判断が要らず、検証が安い」処理のみ: リポジトリ内ファイルの複数ファイル調査、大きなログ/ファイルの要約、分類・構造化抽出。委譲は親の明示判断でのみ行い、自動ディスパッチはしない。
- 窓口は `local-delegate`（Haiku 5.5）。ワーカーとモデル: `local-investigator`=`tsumgi/qwen3.8-27b`（複数ファイル調査・日本語要約）/ `local-tracer`=`tsumgi/qwen3.8-flash-next-coder`（単純な trace・コード説明・ログ解析）/ `local-background`=`tsumgi/qwen3.6-35b-a3b-short`（低優先・overflow）。
- ワーカーは読み取り専用・助言専用で権威を持たない。結果は file:line 等の証拠で検証してから使う。検証なしに採用しない。リトライ（同一 agent/model で 1 回まで）とメトリクスは Opencode 側 `local-workers.toml` マニフェストが正であり、ここでは再定義しない。
- 設計判断・レビューの可否・セキュリティ判断・曖昧な要件の解釈は委譲しない。委譲したのに原文を全文読み直す使い方はしない（節約にならない）。
