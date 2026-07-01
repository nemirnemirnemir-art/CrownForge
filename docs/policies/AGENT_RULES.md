# Agent Rules

Last updated: 12.02.2026

## Core behavior

1. Do the work directly whenever technically possible.
2. Do not shift executable work to the user unless there is a real hard limitation.
3. If blocked by missing critical data, ask one targeted question after completing all non-blocked work.

## Accuracy and evidence

1. Never invent technical values, file paths, behavior, or results.
2. If a value cannot be verified, mark it clearly as unknown and explain why.
3. Prefer evidence from current code over assumptions.

## Communication

1. Replies to the user are in Russian.
2. Keep explanations concise and actionable.
3. For requested lists, provide clean list output without unnecessary noise.

## Delivery discipline

1. Before claiming completion, verify changed behavior using available checks.
2. If runtime validation is unavailable in the environment, state that explicitly and provide a manual checklist.
3. Any gameplay/mechanic change requires documentation updates in the same task (see `docs/policies/DOCUMENTATION_POLICY.md`).
4. For hero scene changes, use centralized resolution (`HeroSceneRegistry`) and avoid branch-based scene routing.
5. For external API claims in docs, validate via Context7 when available or provide explicit fallback evidence.
6. For hero scene edits, do not introduce inherited wrapper roots in `res://scenes/heroes/*.tscn` (no editor-yellow inherited nodes).

## AI test creation restriction

1. In this project, AI agents must not create additional ad-hoc test scripts by default.
2. This restriction remains in force even if `superpowers:test-driven-development` is active.
3. Creating new files under `scripts/dev/tests/` is forbidden unless the user explicitly requests a test or explicitly approves a specific new test file.
4. Existing tests may be updated only when strictly necessary to keep already approved coverage aligned with changed behavior.
5. Default verification mode for gameplay and artifact work in this project is careful code changes plus user manual in-game verification.
6. Agents must not justify new AI-created tests with generic arguments such as future regressions, possible later AI changes, or extra safety.
7. User preference is the source of truth here: AI-created additional test scripts are considered zero-value unless explicitly requested.
