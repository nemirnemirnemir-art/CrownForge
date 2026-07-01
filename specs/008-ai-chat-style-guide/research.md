# Research: AI Chat Style Guide

**Date**: 2024-12-28  
**Feature**: AI Chat Style Guide  
**Phase**: Phase 0 - Research

## Research Summary

This document consolidates research findings for creating a style guide for AI agent responses in Cursor IDE chat interface. All clarifications from specification have been addressed, and formatting patterns have been researched.

## 1. Markdown Formatting Best Practices

### Decision: Style Guide Structure

**Rationale**: Based on analysis of existing project documentation (`.cursorrules`, `main.md`, `docs/MAIN_ORIENTATION_THELASTONE.md`), the project uses:
- Clear section headers (##, ###)
- Structured lists with bullets
- Code blocks with language tags when applicable
- Mixed Russian/English language (Russian for explanations, English for technical terms)

**Chosen Structure**:
1. Overview section (purpose, scope)
2. Core formatting rules (summary blocks, emoji indicators)
3. Response structure guidelines (short vs long responses)
4. Detailed formatting rules (headers, lists, code highlighting)
5. Examples section (minimum 2 realistic examples)
6. Quick checklist at the end

**Alternatives Considered**:
- Reference-style guide (like API docs) - Rejected: too technical, users need quick scanning
- Tutorial-style walkthrough - Rejected: too verbose, violates "1-2 screens" constraint
- Template collection only - Rejected: insufficient, needs rules explanation

## 2. Emoji Rendering in Cursor IDE

### Decision: Direct Emoji Usage

**Rationale**: Cursor IDE uses standard markdown rendering that supports Unicode emojis. Based on specification clarifications:
- Format: Markdown-only (Cursor IDE specifically)
- Emojis: ✅/❌/❓ render correctly in markdown
- Fallback: Not needed (spec assumes markdown always available)

**Chosen Approach**: Use emoji characters directly in markdown (✅ ❌ ❓) without fallback mechanisms.

**Alternatives Considered**:
- Text-based alternatives ([OK], [ERROR]) - Rejected: violates visual scanning requirement
- HTML entity codes - Rejected: unnecessary complexity for markdown
- Image sprites - Rejected: violates markdown-only constraint

## 3. Response Formatting Patterns

### Decision: Adaptive Structure Based on Response Length

**Rationale**: Specification clarification (Q3) established:
- Short responses (1-2 lines): Minimum structure (summary + emoji only)
- Long responses: Full structure (summary + headers + conclusion)

**Chosen Pattern**:
- **Very Short (1-2 lines)**: ✅ Brief summary with emoji status indicator
- **Short (3-10 lines)**: Summary + content + optional conclusion with emoji
- **Long (10+ lines)**: Summary + structured sections (##) + conclusion block with emoji

**Examples from Specification**:
- Feature check reports: "Что проверяли" → "Детали" → "Вывод"
- Log analysis: "Что проверяли" → "Детали / Логи" → "Сопоставление с документацией" → "Вывод"
- Bug reports: Status summary → Problem details → Solution steps → Conclusion

**Alternatives Considered**:
- Fixed structure for all responses - Rejected: violates flexibility requirement, too verbose for short responses
- No minimum structure - Rejected: violates FR-001 (all responses must have summary)

## 4. Example Response Templates

### Decision: Feature Check + Bug Analysis Examples

**Rationale**: Specification FR-008 requires "minimum 2 examples: 'проверка фичи' and 'анализ баг-репорта'". These cover:
- Feature verification (status checking, documentation comparison)
- Bug analysis (problem identification, solution steps, status reporting)

**Chosen Examples**:

1. **Feature Check Example**:
   - Context: Checking if Chain Lightning weapon works correctly with tomes
   - Demonstrates: Summary block, status indicators, structured sections, conclusion block
   - Covers: User Story 1, 2, 3

2. **Bug Analysis Example**:
   - Context: Analyzing drone freeze issue from logs
   - Demonstrates: Problem identification, mixed status (✅❌), explicit clarification requests
   - Covers: User Story 2, 4

**Example Structure**:
```markdown
## Example 1: Feature Check

[Full example response demonstrating all rules]

## Example 2: Bug Analysis

[Full example response demonstrating all rules]
```

**Alternatives Considered**:
- Single comprehensive example - Rejected: doesn't meet FR-008 requirement (minimum 2)
- Three or more examples - Considered but deferred: minimum 2 meets requirement, can expand later

## 5. Quick Checklist Format

### Decision: Inline Checklist at End of Document

**Rationale**: Specification FR-009 requires checklist "как оформлять любой ответ" at the end. Existing project documentation (`.cursorrules`) uses simple bullet lists for quick reference.

**Chosen Format**:
- Short bullet points (one rule per point)
- Ordered by response generation flow (summary → content → conclusion)
- Reference emoji indicators explicitly

**Chosen Checklist Structure**:
1. Start with summary block (2-4 lines + emoji)
2. Use emoji indicators for status items
3. Structure long responses with headers
4. Highlight parameters with code formatting
5. Use lists for 3+ items
6. Include conclusion block for long responses
7. State explicit clarification needs when using ❓

**Alternatives Considered**:
- Table format - Rejected: harder to scan, violates "quick" requirement
- Hierarchical tree - Rejected: too complex for quick reference
- Interactive checklist - Rejected: violates markdown-only constraint

## 6. Integration with main.md

### Decision: Link in AI Orientation Section

**Rationale**: Specification FR-010 requires link in "AI orientation/rules section". Existing `main.md` has section 0 "Главный документ и манифест" which includes references to documentation (already updated in spec phase).

**Chosen Integration**:
- Link placed in section 0 (already done during spec phase)
- Format: Standard markdown link to `docs/ai-chat-style-guide.md`
- Context: Mentioned alongside `MAIN_ORIENTATION_THELASTONE.md` reference

**Alternatives Considered**:
- Separate section for style guide - Rejected: violates existing structure pattern
- Embedded rules in main.md - Rejected: violates "separate document" requirement and would exceed "1-2 screens" constraint

## Research Validation

All research tasks completed. No blocking unknowns remain. Ready for Phase 1 design.

