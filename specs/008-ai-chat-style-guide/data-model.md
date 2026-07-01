# Data Model: AI Response Structure

**Date**: 2024-12-28  
**Feature**: AI Chat Style Guide  
**Phase**: Phase 1 - Design

## Response Structure Model

This document defines the data model for AI agent responses according to the style guide.

## Entity: AI Response

### Attributes

**summary_block** (required)
- **Type**: String (2-4 lines)
- **Description**: Brief description of what was checked/done and overall status
- **Format**: Plain text with optional emoji status indicator
- **Example**: "✅ **Chain Lightning работает правильно**\nПроверено соответствие документации: все адаптеры томов применены корректно."

**status_indicator** (required)
- **Type**: Emoji (✅ | ❌ | ❓ | ✅❌)
- **Description**: Visual status marker at start of summary
- **Values**: 
  - ✅ = works correctly / matches documentation / test passed
  - ❌ = doesn't work / error / test failed
  - ❓ = needs clarification / insufficient data / unclear
  - ✅❌ = mixed status (explain in summary)
- **Position**: Start of summary block

**content_sections** (optional for short responses, required for long)
- **Type**: Array[ResponseSection]
- **Description**: Structured sections with headers for long responses
- **Min Length**: 0 (for 1-2 line responses)
- **Format**: Markdown headers (## or ###)
- **Examples**: "Что проверяли", "Детали", "Выводы"

**conclusion_block** (optional for short, required for long responses)
- **Type**: String
- **Description**: Final summary section with emoji status
- **Format**: "Вывод" / "Итог" / "Выводы" header + content + emoji
- **Min Length**: 0 (for 1-2 line responses)

**code_highlights** (optional)
- **Type**: Array[InlineCode]
- **Description**: Important parameters, numbers, metrics in monospace
- **Format**: Inline code blocks (`` `value` ``)
- **Examples**: `` `max_enemies=200` ``, `` `60 FPS` ``

**list_items** (required when 3+ related items)
- **Type**: Array[ListItem]
- **Description**: Use lists instead of paragraphs for 3+ related items
- **Format**: Markdown lists with emoji indicators (✅/❌/❓) before each item
- **Min Length**: 0 (if <3 items, use paragraph)

**clarification_requests** (required when status_indicator = ❓)
- **Type**: String
- **Description**: Explicit statement of what is needed from user
- **Format**: Plain text after ❓ emoji
- **Required**: Yes, when using ❓

## Entity: ResponseSection

### Attributes

**header** (required)
- **Type**: String (Markdown header level 2 or 3)
- **Format**: `## Section Name` or `### Subsection Name`
- **Examples**: "## Что проверяли", "### Детали логов"

**content** (required)
- **Type**: String (Markdown formatted)
- **Description**: Section content with lists, code blocks, paragraphs

**items** (optional)
- **Type**: Array[ListItem]
- **Description**: List items within section (with emoji indicators)

## Entity: ListItem

### Attributes

**emoji_indicator** (required if status-related)
- **Type**: Emoji (✅ | ❌ | ❓)
- **Description**: Status indicator before list item text
- **Position**: Start of list item

**text** (required)
- **Type**: String
- **Description**: List item content

**Example**: `- ✅ Первый пункт работает правильно`

## Response Type Variations

### Very Short Response (1-2 lines)

**Minimal Structure**:
```
summary_block: "✅ [Brief status]"
status_indicator: ✅ | ❌ | ❓
content_sections: [] (empty)
conclusion_block: "" (empty)
```

### Short Response (3-10 lines)

**Structure**:
```
summary_block: "✅ [Status summary (2-4 lines)]"
status_indicator: ✅ | ❌ | ❓
content_sections: [] (optional, can use simple paragraphs)
conclusion_block: "**Вывод**: [Summary with emoji]" (optional)
```

### Long Response (10+ lines)

**Full Structure**:
```
summary_block: "✅ [Status summary (2-4 lines)]"
status_indicator: ✅ | ❌ | ❓ | ✅❌
content_sections: [
  { header: "## Что проверяли", content: "..." },
  { header: "## Детали", content: "..." },
  { header: "## Сопоставление с документацией", content: "..." }
]
conclusion_block: "## Вывод\n\n✅ [Final status summary]"
```

## Validation Rules

1. **summary_block** MUST always be present (FR-001)
2. **status_indicator** MUST be at start of summary_block (FR-002)
3. **content_sections** MUST use markdown headers (##, ###) for long responses (FR-003)
4. **conclusion_block** MUST include emoji status for long responses (FR-004)
5. **code_highlights** MUST use monospace formatting (`` `value` ``) for parameters (FR-005)
6. **list_items** MUST be used instead of paragraphs for 3+ related items (FR-006)
7. **clarification_requests** MUST be explicit when status_indicator = ❓ (FR-007)

## State Transitions

**Response Generation Flow**:
1. Determine response type (short/long) based on content length
2. Create summary_block with status_indicator
3. If long response → add content_sections with headers
4. Format content (lists, code highlights)
5. If long response → add conclusion_block with emoji
6. Validate against all requirements (FR-001 through FR-007)

