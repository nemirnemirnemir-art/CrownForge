# Tasks: AI Chat Style Guide

**Feature**: AI Chat Style Guide  
**Branch**: `008-ai-chat-style-guide`  
**Created**: 2024-12-28  
**Status**: Draft

## Overview

This document contains implementation tasks for creating the AI Chat Style Guide. The feature is documentation-only (no code changes) and will result in a single markdown file (`docs/ai-chat-style-guide.md`) that defines visual formatting standards for AI agent responses in Cursor IDE chat.

## Dependencies & Story Completion Order

**User Story Dependencies**:
- **US1** (P1) - Read formatted AI responses quickly → **MVP**: Can be delivered independently
- **US2** (P1) - Understand response status at a glance → **MVP**: Can be delivered independently  
- **US3** (P2) - Navigate long responses efficiently → Depends on US1 (needs formatting structure)
- **US4** (P2) - Get explicit clarification requests → Can be delivered independently

**Recommended MVP Scope**: US1 + US2 (both P1 stories provide immediate value)

## Implementation Strategy

**MVP First**: Deliver US1 + US2 to provide immediate value (readable responses with status indicators)  
**Incremental Delivery**: Add US3 (navigation for long responses) and US4 (clarification requests) in subsequent phases

## Phase 1: Setup

**Goal**: Initialize style guide document structure

**Independent Test**: Style guide file exists at `docs/ai-chat-style-guide.md` with basic structure

### Tasks

- [x] T001 Create style guide document structure in docs/ai-chat-style-guide.md
- [x] T002 Add title and overview section describing purpose and scope in docs/ai-chat-style-guide.md
- [x] T003 Add table of contents section with navigation links in docs/ai-chat-style-guide.md

## Phase 2: Foundational Rules

**Goal**: Establish core formatting rules and emoji status indicators

**Independent Test**: Style guide contains sections for overview, core rules, and emoji indicators that can be validated independently

### Tasks

- [x] T004 Add "Обзор" section explaining purpose of style guide in docs/ai-chat-style-guide.md
- [x] T005 Add "Основные правила форматирования" section with summary block requirement (FR-001) in docs/ai-chat-style-guide.md
- [x] T006 Add "Индикаторы статуса (эмодзи)" section explaining ✅/❌/❓ usage rules in docs/ai-chat-style-guide.md
- [x] T007 Document emoji status indicator meanings (✅ = работает, ❌ = не работает, ❓ = требует уточнения) in docs/ai-chat-style-guide.md
- [x] T008 Document emoji indicator placement rules (start of summary, before list items) in docs/ai-chat-style-guide.md

## Phase 3: User Story 1 - Read formatted AI responses quickly (P1)

**Story Goal**: Users can quickly scan AI responses with visual indicators (emojis, headings, lists) instead of reading long paragraphs

**Independent Test**: Style guide contains rules for summary blocks, emoji indicators, and list formatting that enable quick scanning. Example response demonstrates formatted structure with emojis and headers.

**Acceptance Criteria**:
- Summary block at top with emoji status indicators
- Each list item has corresponding emoji (✅/❌/❓) before text
- Conclusion block starts with summary emoji status

### Tasks

- [x] T009 [US1] Add "Блок резюме" subsection describing 2-4 line summary requirement (FR-001) in docs/ai-chat-style-guide.md
- [x] T010 [US1] Document summary block format with emoji status indicator at start in docs/ai-chat-style-guide.md
- [x] T011 [US1] Add "Форматирование списков" section explaining emoji indicator usage in lists (FR-002) in docs/ai-chat-style-guide.md
- [x] T012 [US1] Document list formatting rules (emoji before each status-related item) in docs/ai-chat-style-guide.md
- [x] T013 [US1] Add "Использование списков вместо абзацев" section for 3+ related items (FR-006) in docs/ai-chat-style-guide.md
- [x] T014 [US1] Document when to use lists vs paragraphs (3+ items = lists) in docs/ai-chat-style-guide.md

## Phase 4: User Story 2 - Understand response status at a glance (P1)

**Story Goal**: Users can immediately identify if something works, doesn't work, or needs clarification by scanning emoji indicators

**Independent Test**: Style guide contains clear rules for status indicators that enable 3-second status identification. Example demonstrates passing tests (✅), failing tests (❌), and clarification needs (❓).

**Acceptance Criteria**:
- Passing tests have ✅, failing tests have ❌
- Unclear requirements use ❓ with explicit statement of what's needed
- Mixed-status conclusions use combination emojis (✅❌) with explanation

### Tasks

- [x] T015 [US2] Add "Использование индикаторов статуса" section with detailed rules for ✅/❌/❓ in docs/ai-chat-style-guide.md
- [x] T016 [US2] Document ✅ indicator usage (works correctly, matches documentation, test passed) in docs/ai-chat-style-guide.md
- [x] T017 [US2] Document ❌ indicator usage (doesn't work, error, test failed) in docs/ai-chat-style-guide.md
- [x] T018 [US2] Document ❓ indicator usage (needs clarification, insufficient data) in docs/ai-chat-style-guide.md
- [x] T019 [US2] Add "Смешанный статус" section explaining ✅❌ combination emoji usage in docs/ai-chat-style-guide.md
- [x] T020 [US2] Document mixed-status formatting rules (combination emojis in summary, breakdown per item) in docs/ai-chat-style-guide.md

## Phase 5: User Story 3 - Navigate long responses efficiently (P2)

**Story Goal**: Users can jump to relevant sections in long responses (log analysis, documentation checks) using clear headers and structure

**Independent Test**: Style guide contains rules for structuring long responses with headers. Example demonstrates navigation through "Что проверяли", "Детали", "Вывод" sections.

**Acceptance Criteria**:
- Log analysis reports have sections: "Что проверяли", "Детали / Логи", "Сопоставление с документацией", "Вывод"
- Each finding is in a separate list item with appropriate formatting
- Code/configuration values are highlighted with monospace font

### Tasks

- [x] T021 [US3] Add "Структура длинных ответов" section explaining header requirements (FR-003) in docs/ai-chat-style-guide.md
- [x] T022 [US3] Document section header format (## for main sections, ### for subsections) in docs/ai-chat-style-guide.md
- [x] T023 [US3] Add "Стандартные секции" subsection with recommended section names ("Что проверяли", "Детали", "Выводы") in docs/ai-chat-style-guide.md
- [x] T024 [US3] Document when to use section headers (long responses 10+ lines) in docs/ai-chat-style-guide.md
- [x] T025 [US3] Add "Выделение параметров и чисел" section for code formatting (FR-005) in docs/ai-chat-style-guide.md
- [x] T026 [US3] Document monospace formatting rules (`` `value` ``) for parameters, metrics, configuration values in docs/ai-chat-style-guide.md
- [x] T027 [US3] Add "Блок выводов" section explaining conclusion block requirement (FR-004) in docs/ai-chat-style-guide.md
- [x] T028 [US3] Document conclusion block format ("Вывод" / "Итог" / "Выводы" with emoji status) in docs/ai-chat-style-guide.md

## Phase 6: User Story 4 - Get explicit clarification requests (P2)

**Story Goal**: Users understand exactly what decision or information is needed when AI uses ❓ status indicator

**Independent Test**: Style guide contains explicit rules for clarification requests. Example demonstrates ❓ usage with clear statement of what's needed from user.

**Acceptance Criteria**:
- Conflicting documentation uses ❓ and explicitly states what decision is needed
- Multiple design options clearly list each option and what user needs to respond
- Insufficient data reports specify what additional data or context is needed

### Tasks

- [x] T029 [US4] Add "Запросы на уточнение" section explaining ❓ usage requirement (FR-007) in docs/ai-chat-style-guide.md
- [x] T030 [US4] Document explicit clarification request format (what decision/information is needed) in docs/ai-chat-style-guide.md
- [x] T031 [US4] Add examples of clarification requests (conflicting docs, design choices, insufficient data) in docs/ai-chat-style-guide.md

## Phase 7: Examples Section (FR-008)

**Goal**: Provide minimum 2 realistic examples demonstrating all formatting rules

**Independent Test**: Style guide contains at least 2 complete example responses (feature check and bug analysis) that demonstrate all rules from FR-001 through FR-007

### Tasks

- [x] T032 Add "Примеры оформления ответов" section header in docs/ai-chat-style-guide.md
- [x] T033 Create "Пример 1: Проверка фичи" example demonstrating all formatting rules (summary, emoji, sections, lists, code, conclusion) in docs/ai-chat-style-guide.md
- [x] T034 Create "Пример 2: Анализ баг-репорта" example demonstrating all formatting rules (summary, mixed status, clarification, sections, conclusion) in docs/ai-chat-style-guide.md
- [x] T035 Validate Example 1 covers all user stories (US1-US4) and functional requirements (FR-001 through FR-007) in docs/ai-chat-style-guide.md
- [x] T036 Validate Example 2 covers all user stories (US1-US4) and functional requirements (FR-001 through FR-007) in docs/ai-chat-style-guide.md

## Phase 8: Quick Checklist & Edge Cases (FR-009)

**Goal**: Add quick reference checklist and edge case handling

**Independent Test**: Style guide contains "как оформлять любой ответ" checklist at the end that covers all core rules

### Tasks

- [x] T037 Add "Граничные случаи" section explaining edge case handling in docs/ai-chat-style-guide.md
- [x] T038 Document neutral information handling (✅ for completed or omit emoji) in docs/ai-chat-style-guide.md
- [x] T039 Document very short response structure (1-2 lines: minimal summary + emoji only) in docs/ai-chat-style-guide.md
- [x] T040 Document technical error handling (assume markdown available, maintain structure) in docs/ai-chat-style-guide.md
- [x] T041 Add "Чеклист: Как оформить любой ответ" section at the end (FR-009) in docs/ai-chat-style-guide.md
- [x] T042 Create quick checklist items covering all core rules (summary, emoji, headers, lists, code, conclusion) in docs/ai-chat-style-guide.md

## Phase 9: Polish & Cross-Cutting Concerns

**Goal**: Finalize style guide, validate against spec, integrate with main.md

**Independent Test**: Style guide is complete, validated against all acceptance scenarios, and linked from main.md

### Tasks

- [x] T043 Validate style guide length (max 1-2 screens as per FR-009 constraint) in docs/ai-chat-style-guide.md
- [x] T044 Review style guide against all acceptance scenarios from spec.md
- [x] T045 Review style guide against all functional requirements (FR-001 through FR-010) from spec.md
- [x] T046 Verify link exists in main.md AI orientation section (FR-010) - check main.md
- [x] T047 Verify link path is correct (docs/ai-chat-style-guide.md) in main.md
- [x] T048 Perform manual review of style guide readability and completeness

## Task Summary

**Total Tasks**: 48

**Tasks by Phase**:
- Phase 1 (Setup): 3 tasks
- Phase 2 (Foundational): 5 tasks
- Phase 3 (US1 - P1): 6 tasks
- Phase 4 (US2 - P1): 6 tasks
- Phase 5 (US3 - P2): 8 tasks
- Phase 6 (US4 - P2): 3 tasks
- Phase 7 (Examples): 5 tasks
- Phase 8 (Checklist): 6 tasks
- Phase 9 (Polish): 6 tasks

**Parallel Opportunities**:
- T004-T008 can be worked on in parallel (foundational sections)
- T009-T014 can be worked on in parallel (US1 formatting rules)
- T015-T020 can be worked on in parallel (US2 status indicators)
- T021-T028 can be worked on in parallel (US3 structure rules)
- T032-T036 can be worked on in parallel (example validation)

**MVP Scope** (US1 + US2):
- Phases 1-4 (T001-T020): 20 tasks covering core formatting and status indicators

