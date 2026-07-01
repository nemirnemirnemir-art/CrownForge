# Documentation Policy

Last updated: 26.03.2026

## Mandatory updates in feature/mechanic tasks

When gameplay, economy, UI flow, timing, or architecture changes, documentation must be updated in the same task.

Required minimum:

1. `docs/PROJECT_NAVIGATOR.md`
2. `docs/ARCHITECTURE.md`
3. Relevant focused doc(s) that actually exist for the touched subsystem.

For hero scene architecture changes, also update:

4. `docs/HERO_ADDING_CHECKLIST.md`

## Canonicality and cleanup

1. Keep one canonical source per mechanic; avoid duplicated conflicting notes.
2. Remove or replace outdated documents when behavior changes.
3. If a document becomes non-canonical, delete it or replace it with a redirect note.

## Mermaid map policy

1. `docs/PROJECT_MERMAID_BIG_GRAPH.md` is a visual orientation map, not a canonical behavior spec.
2. Keep the graph concise: include key subsystems and high-value flows only.
3. Update the graph when runtime topology changes (module ownership, major flow links, canonical path moves).
4. Keep canonical behavior and exact ownership in:
   - `docs/PROJECT_NAVIGATOR.md`
   - `docs/ARCHITECTURE.md`
   - focused subsystem docs that actually exist in the repository
5. Before completion, verify Mermaid rendering and ensure node names/paths still match the codebase.

## Completion requirement

In the final response for such tasks, explicitly confirm that documentation was updated.

## Review checklist

1. Are gameplay timings and state transitions current?
2. Are reward/economy sources current?
3. Are build/sell/destroy rules current?
4. Are cross-links valid and non-duplicated?
5. Are all docs written in English?

## External API validation (Context7)

1. For docs that reference external APIs (for example Godot 4.3 methods/nodes), validate with Context7.
2. If Context7 is unavailable, explicitly state that limitation and document fallback verification source(s).
3. Do not claim API-valid status without Context7 evidence or explicit fallback evidence.
