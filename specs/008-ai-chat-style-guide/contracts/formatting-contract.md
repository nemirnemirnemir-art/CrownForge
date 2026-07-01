# Formatting Contract: AI Response Template

**Date**: 2024-12-28  
**Feature**: AI Chat Style Guide  
**Phase**: Phase 1 - Design

## Contract Overview

This document defines the mandatory and optional formatting elements for AI agent responses in Cursor IDE chat.

## Response Template Structure

### Template for Long Responses (10+ lines)

```markdown
✅ **[Brief Status Summary]** (or ❌/❓)

[2-4 line summary describing what was checked/done and overall status]

## Что проверяли

[Brief description of what was being verified]

## Детали

[Detailed findings with:
- ✅/❌/❓ indicators before each status item in lists
- Code formatting for parameters: `` `value` ``
- Lists for 3+ related items
]

## Сопоставление с документацией

[Documentation comparison, if applicable]

## Вывод

✅ [Final status summary with emoji indicator]

[Brief conclusion paragraph]
```

### Template for Short Responses (3-10 lines)

```markdown
✅ **[Brief Status Summary]**

[2-4 line summary describing what was checked/done and overall status]

[Optional content paragraph or brief list]

[Optional conclusion: **Вывод**: ✅ [Summary]]
```

### Template for Very Short Responses (1-2 lines)

```markdown
✅ [Brief status message with emoji indicator]

[Optional one-line detail]
```

## Mandatory Elements

### 1. Summary Block (All Response Types)

**Required**: YES (always)  
**Format**: 2-4 lines text block  
**Must Include**: 
- Status indicator emoji at start (✅/❌/❓)
- Brief description of what was checked/done
- Overall status

**Example**:
```markdown
✅ **Chain Lightning работает правильно**

Проверено соответствие документации: все адаптеры томов применены корректно.
Все проектили получают правильные бонусы цепей.
```

### 2. Status Indicator (All Response Types)

**Required**: YES (always)  
**Position**: Start of summary block  
**Values**: ✅ (works), ❌ (error), ❓ (needs clarification), ✅❌ (mixed)  
**Usage**: Must be at very start of response before any other text

### 3. Emoji Indicators in Lists (When Lists Used)

**Required**: YES (when list contains status-related items)  
**Position**: Before each list item  
**Format**: `- ✅ Item text` or `- ❌ Item text`

**Example**:
```markdown
- ✅ Первый тест пройден
- ❌ Второй тест провален
- ✅ Третий тест пройден
```

### 4. Code Formatting for Parameters (When Parameters Referenced)

**Required**: YES (when referencing code/configuration values)  
**Format**: Inline code (`` `value` ``)  
**Usage**: All parameters, numbers, metrics, configuration values

**Example**:
```markdown
Параметр `` `max_enemies=200` `` установлен корректно.
```

### 5. Lists for 3+ Items (When Applicable)

**Required**: YES (when presenting 3+ related items)  
**Format**: Markdown lists instead of paragraphs  
**Usage**: Multiple findings, check results, steps

### 6. Explicit Clarification Requests (When Using ❓)

**Required**: YES (when status_indicator = ❓)  
**Format**: Explicit text stating what is needed from user  
**Must Include**: What decision/information is needed

**Example**:
```markdown
❓ **Требуется уточнение**

Документация противоречива. Нужен выбор: использовать подход A или B?
```

## Optional Elements

### 1. Section Headers (Long Responses Only)

**Required**: NO (only for long responses 10+ lines)  
**Format**: Markdown headers (## for main sections, ### for subsections)  
**Recommended Sections**: "Что проверяли", "Детали", "Выводы"

### 2. Conclusion Block (Long Responses Only)

**Required**: NO (only for long responses 10+ lines)  
**Format**: "## Вывод" section with emoji status indicator  
**Content**: Final summary with overall status

### 3. Multiple Sections (Long Responses Only)

**Required**: NO (optional, based on response complexity)  
**Recommended**: Structure with clear section separation for navigation

## Formatting Rules by Element Type

### Headers

- **Level 2** (##): Main sections (Что проверяли, Детали, Вывод)
- **Level 3** (###): Subsections within main sections
- **Position**: After summary block, before conclusion
- **Usage**: Only for long responses (10+ lines)

### Lists

- **Type**: Unordered lists (-) for most cases
- **Indicators**: Emoji (✅/❌/❓) before each item if status-related
- **Min Items**: Use lists when 3+ related items (FR-006)
- **Format**: `- ✅ Item text` or `- Item text` (without emoji if not status-related)

### Code Blocks

- **Inline Code**: `` `value` `` for parameters, metrics, configuration
- **Code Blocks**: \`\`\`language for multi-line code examples (if needed)
- **Usage**: All code references, file paths, configuration values

### Emojis

- **Status Indicators**: ✅ ❌ ❓ (always at start of summary and conclusion)
- **List Item Indicators**: ✅ ❌ ❓ (before each status-related list item)
- **Mixed Status**: ✅❌ (in summary when both success and failure present)
- **Rendering**: Direct Unicode characters (no fallback needed in Cursor IDE)

## Edge Cases

### Case 1: Neutral Information (No Clear Status)

**Approach**: Use ✅ for "completed successfully" or omit emoji for purely informational content

**Template**:
```markdown
[Brief informational message without status indicator, OR]
✅ [Completed successfully message]
```

### Case 2: Mixed Status

**Approach**: Use combination emojis (✅❌) in summary, then break down per item

**Template**:
```markdown
✅❌ **Смешанный статус**

[Summary explaining mix of success and failure]

## Результаты проверки

- ✅ Первая проверка прошла
- ❌ Вторая проверка провалилась
- ✅ Третья проверка прошла
```

### Case 3: Very Short Response (1-2 lines)

**Approach**: Minimum structure - only summary with emoji

**Template**:
```markdown
✅ [Brief status message]

[Optional one-line detail]
```

### Case 4: Technical Error Preventing Formatting

**Approach**: Assume markdown always available (per spec clarification). If formatting fails, maintain structure but continue using emoji indicators.

**Template**: Same as normal template (markdown assumed available in Cursor IDE)

## Validation Checklist

Before sending response, verify:

- [ ] Summary block present (2-4 lines) with status indicator
- [ ] Status indicator (✅/❌/❓) at start of summary
- [ ] If long response: section headers (##) used
- [ ] If long response: conclusion block with emoji present
- [ ] All parameters/values formatted as inline code (`` `value` ``)
- [ ] Lists used for 3+ related items
- [ ] Emoji indicators before status-related list items
- [ ] If ❓ used: explicit clarification request included
- [ ] Response readable in single screen (if possible)

