# Documentation Canon Cleanup Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Bring project documentation to one English canonical set with current wave timing, Denarii, and sell/destroy rules.

**Architecture:** Keep a small canonical docs spine (`AGENTS.md` + policy docs + system pages), remove stale duplicates, and centralize mechanic rules in system pages referenced by architecture and navigator docs.

**Tech Stack:** Markdown docs, grep-based consistency checks.

---

### Task 1: Canon update for waves/economy/buildings docs

**Files:**
- Modify: `docs/wiki/systems/WAVES_AND_PROPHECY.md`
- Modify: `docs/wiki/systems/TOWN_AND_ECONOMY.md`
- Modify: `docs/wiki/systems/BUILDINGS.md`

**Step 1: Write canonical wave timing text**

Add explicit canon:
- Wave 0 at 100s from run start.
- Prophecy waves every 60s.
- Trader wave after 60s.
- Next prophecy cycle starts after 90s.
- Mark as current canon that may change.

**Step 2: Write canonical Denarii text**

Add explicit canon:
- Denarii comes from reward systems tied to mob kills and selling recipes.
- Selling any recipe gives exactly 5 Denarii.
- Future sources may include king boosts and later systems.

**Step 3: Write canonical sell/destroy semantics**

Add explicit canon:
- Sell is build-menu recipe selling only (+5 Denarii).
- Destroy removes placed buildings except seals.
- Resource-producing building destroy: removed, no recipe return.
- Unit-producing/bonus/infrastructure destroy: recipe returned to build inventory.
- Destroy never refunds build resources.

### Task 2: Align root architecture/index docs to canonical system pages

**Files:**
- Modify: `docs/ARCHITECTURE.md`
- Modify: `docs/PROJECT_NAVIGATOR.md`
- Modify: `docs/README.md`
- Modify: `docs/WIKI_HOME.md`

**Step 1: Point to canonical pages only**

Ensure all top-level docs link to system pages for wave timing, Denarii, and sell/destroy canon.

**Step 2: Keep rule language strict**

Confirm docs-update-in-same-task rule remains explicit.

### Task 3: Cleanup outdated docs and broken links

**Files:**
- Delete: approved obsolete/legacy docs that conflict with current canon

**Step 1: Remove approved obsolete docs**

Delete approved obsolete docs and stale legacy docs with conflicting canon.

**Step 2: Fix references to removed files**

Update references in surviving docs so links resolve.

### Task 4: Language and contradiction checks

**Files:**
- Modify as needed from grep results.

**Step 1: Russian text sweep**

Run a docs-wide Cyrillic search and eliminate remaining Russian in canonical docs.

**Step 2: Contradiction sweep**

Search for old timing, Denarii, and sell/destroy statements and replace with canonical wording.

### Task 5: Verification and handoff

**Files:**
- N/A

**Step 1: Run consistency checks**

Run grep checks for:
- references to deleted docs,
- outdated wave timing values,
- old Denarii claims,
- old sell/destroy semantics.

**Step 2: Handoff report**

Prepare changed/deleted file list, canon fixes, risks, and explicit confirmation docs were updated.

