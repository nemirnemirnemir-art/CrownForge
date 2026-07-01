# Clarification Request: Weapon Documentation System

**Date**: 2024-12-28  
**Status**: Open  
**Requested By**: `/speckit.clarify` command

---

## Summary

After reviewing the current specification (`spec.md`) and implementation progress, several areas require clarification to ensure accurate task completion and prioritization.

---

## Clarifications Needed

### 1. Tome Interactions Documentation Status (Phase 4 - T027-T034)

**Current Situation**:
- Tasks T027-T034 are marked as "pending" in `tasks.md`
- However, the created guides (`chain-lightning.md` and `boulder.md`) already contain comprehensive "Tome Interactions" and "Adapter Rules" sections
- Chain Lightning guide has complete tome interaction documentation (Size→Damage, Pierce→ChainTargets, Count behavior)
- Boulder guide has complete tome interaction documentation (baseline effects, no adapters)

**Question**: 
- Should tasks T027-T034 be marked as completed since the content is already present?
- Or do these tasks require additional verification/testing that hasn't been done yet?
- Should we verify that tome interaction documentation matches actual code behavior before marking as complete?

**Recommendation**: Mark T027-T034 as completed if documentation matches code, OR add subtasks for code verification.

---

### 2. Scope of Weapon Documentation (All Weapons vs. Existing Only)

**Current Situation**:
- Specification mentions "~20 weapon types" in the project (SC-001, Assumptions)
- Only 3 guides created: Orientation (standards), Chain Lightning, Boulder
- Many other weapons exist (Drone, FireBall, SwingAttack, Shotgun, Aura, Banana, etc.) based on `.tres` files found

**Questions**:
- Should documentation be created for ALL ~20 weapon types, or only for those with existing documentation?
- What is the priority order for documenting remaining weapons?
- Should we document weapons that are partially implemented or have known bugs?

**Current Status**: Only weapons with existing documentation were integrated (Chain Lightning, Boulder, Orientation).

**Recommendation**: Clarify if MVP scope includes only existing docs, or if additional weapons should be documented.

---

### 3. Context7 Validation Process (Phase 5 - T035-T042)

**Current Situation**:
- Tasks T035-T042 require Context7 validation of Godot 4.3 API references
- Not clear if validation should be:
  - Manual (reviewer checks Context7 for each API)
  - Automated (script that uses Context7 API to validate)
  - Semi-automated (checklist with Context7 links)

**Questions**:
- How should Context7 validation be performed? Manual review or automated?
- Should validation results be embedded in documentation or stored separately?
- What happens if Context7 is unavailable? Fallback process?

**Recommendation**: Define validation process (manual vs automated) and document fallback if Context7 unavailable.

---

### 4. Verification Status Consistency

**Current Situation**:
- Chain Lightning marked as `[ПРОВЕРЕНО]` (verified)
- Boulder marked as `[ТРЕБУЕТ ПРОВЕРКИ]` (needs verification)
- Tome interactions already documented but Phase 4 tasks still pending

**Questions**:
- Should Phase 4 tasks (T027-T034) include verification/testing, not just documentation?
- Should verification status be updated after Phase 4 completion?
- Who is responsible for verification? Developer, tester, or documentation maintainer?

**Recommendation**: Clarify if Phase 4 includes verification or if verification is separate phase.

---

### 5. Template Compliance (Phase 6 - T043-T047)

**Current Situation**:
- Tasks T043-T047 verify template compliance
- Guides already created following template structure
- Template includes verification status section (added in T018)

**Questions**:
- Should T043-T047 be verification tasks (checking if guides match template)?
- Or are they documentation tasks (updating template itself)?
- Should we verify guides match template programmatically or manually?

**Recommendation**: Clarify if these are verification tasks or if guides need updates to match latest template version.

---

### 6. Cross-References Status (Phase 7 - T048-T050)

**Current Situation**:
- Tasks T048-T050 are marked as pending
- However, guides already contain "Cross-References" sections with links to:
  - Source documentation (`docs/DefaultWeaponDocumentation.md`, etc.)
  - `main.md` (Section 10)
  - `NORMALIZED_WEAPON_SYSTEM.md`

**Questions**:
- Are current cross-references sufficient, or do tasks T048-T050 require additional cross-references?
- Should cross-references be bidirectional (from `main.md` to guides)?
- Should cross-references be validated (check if links work)?

**Recommendation**: Clarify if additional cross-references needed or if existing ones are sufficient.

---

### 7. Remaining Weapons Priority

**Current Situation**:
- Many weapons exist but are not documented:
  - Drone (has special adapters, mentioned in spec)
  - Aura (has special adapters, mentioned in spec)
  - Shotgun (has special adapters, mentioned in spec)
  - FireBall, SwingAttack, Banana, and others

**Questions**:
- Which weapons should be documented next after MVP?
- Should weapons with special adapters (Drone, Aura, Shotgun) be prioritized?
- Should we document all weapons eventually, or only those with complex behavior?

**Recommendation**: Define priority order for documenting remaining weapons post-MVP.

---

## Proposed Resolutions

### Option A: Mark Completed Tasks as Done

**Action**: Review tasks T027-T034, T043-T047, T048-T050 and mark as completed if content already exists.

**Impact**: 
- Reduces pending tasks
- Clarifies what still needs to be done
- May miss verification/testing requirements

### Option B: Add Verification Subtasks

**Action**: Add verification subtasks for tome interactions, template compliance, and cross-references.

**Impact**:
- Ensures quality through verification
- Increases task count
- May delay MVP completion

### Option C: Clarify MVP Scope

**Action**: Explicitly define MVP scope as "integrate existing documentation" vs "document all weapons".

**Impact**:
- Clarifies expectations
- May reduce scope if MVP is existing docs only
- Sets clear boundaries for post-MVP work

---

## Questions for Stakeholder

1. **Should tasks T027-T034 be marked as completed** since tome interactions are already documented in guides?

2. **What is the MVP scope** - existing documentation integration only, or include additional weapon documentation?

3. **How should Context7 validation be performed** - manual, automated, or semi-automated?

4. **Should Phase 4 include verification** or is verification separate?

5. **Are current cross-references sufficient** or do tasks T048-T050 require additional work?

6. **Which weapons should be documented next** after MVP completion?

---

## Next Steps

**Pending Clarifications**: Wait for stakeholder responses to questions above

**Immediate Actions** (if clarifications not needed):
- Review and potentially mark T027-T034, T043-T047, T048-T050 as completed if content exists
- Proceed with Phase 5 (Context7 validation) using defined process
- Plan Phase 6 and 7 based on remaining work

---

**Last Updated**: 2024-12-28  
**Status**: Awaiting Clarification



