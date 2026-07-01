# Clickcer Documentation
 
Last updated: 02.04.2026
 
This file is the top-level index for the `docs/` folder.
 
## Start here
 
1. `docs/WIKI_HOME.md` - documentation entrypoint
2. `docs/AGENTS.md` - agent contract, execution rules, canonical reading order
3. `docs/project_description.md` - high-level project requirements and current directives
4. `docs/GAME_OVERVIEW.md` - non-technical overview of the game, its core fantasy, loop, mechanics, and long-term motivation
 
## Core canonical docs
 
1. `docs/PROJECT_NAVIGATOR.md` - file-level orientation and main runtime entrypoints
2. `docs/ARCHITECTURE.md` - runtime ownership, orchestration boundaries, and composition rules
3. `docs/policies/AGENT_RULES.md` - project agent rules
4. `docs/policies/ENGINEERING_STANDARDS.md` - implementation and architecture standards
5. `docs/policies/DOCUMENTATION_POLICY.md` - documentation update and canonicality rules
6. `docs/policies/GDSCRIPT_WARNING_PREVENTION.md` - anti-warning checklist for GDScript work
 
## Focused system references

1. `docs/PROJECT_NAVIGATOR.md` - search-first file lookup for runtime owners and entrypoints
2. `docs/ARCHITECTURE.md` - runtime boundaries, lifecycle rules, and orchestration ownership
3. `docs/wiki_buildings/` - current curated building reference used for practical building lookup
4. `docs/dev/TEN_KINGS_PROTOTYPE.md` - focused reference for the standalone Ten Kings dev prototype
5. Dedicated `docs/wiki/systems/*.md` pages are not present in this repo snapshot; do not treat those paths as live references
 
## Supporting references
 
1. `docs/HERO_ADDING_CHECKLIST.md`
2. `docs/MARKERS_STANDARD.md`
3. `docs/TECH_DEBT.md`
4. `docs/PROJECT_MERMAID_BIG_GRAPH.md` - visual orientation map only, not canonical behavior spec
 
## Imported and reference material
 
1. `the_king_is_watching_gdd/` - external game design reference outside `docs/`
 
## Rule of thumb
 
If a mechanic, flow, economy rule, or architecture detail changes, update the canonical docs in the same task:
 
1. `docs/PROJECT_NAVIGATOR.md`
2. `docs/ARCHITECTURE.md`
3. affected focused docs that actually exist for the touched area (for example `docs/wiki_buildings/` or `docs/HERO_ADDING_CHECKLIST.md`)
