## マルチモデル開発体制
- 役割: Planning=Opus 5.5 / Implementation=Sonnet 5.5 / Research=Haiku 5.5（読み取り専用）/ Code Review=Sonnet 5.5（`code-reviewer`、同一モデル系列であり別プロバイダーの独立レビューではない）/ Architecture Escalation=Opus 5.5（`architecture-reviewer`）。
- 設計セッション: `/design-to-issues`。実装セッション: `/implement-issue`。詳細手順は各 Skill にある。subagent は `~/.claude/agents/`。
- 仕様・目的・受入条件・変更許可範囲は実装側が独断で変えない。設計変更が必要ならエスカレーションし、重要な採否は User が決める。採否の報告は Human Decision 形式（上記）に従う。
- 委譲は任意。小さい作業は直接行う。ネストは最大 2 階層・同時 4 件。
