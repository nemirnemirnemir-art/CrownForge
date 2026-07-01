# Quick Start: AI Chat Style Guide

**Date**: 2024-12-28  
**Feature**: AI Chat Style Guide  
**Purpose**: Quick reference for formatting AI agent responses

## Quick Reference

### Response Structure (All Types)

1. **Start with summary** (2-4 lines) + emoji status (✅/❌/❓)
2. **Add content**: Sections with headers (##) for long responses
3. **End with conclusion**: "Вывод" section with emoji for long responses

### Status Indicators

- ✅ = Works correctly / Matches documentation / Test passed
- ❌ = Doesn't work / Error / Test failed  
- ❓ = Needs clarification / Insufficient data
- ✅❌ = Mixed status (explain in summary)

### Formatting Rules

- **Code/Parameters**: `` `value` `` (inline code)
- **Lists**: Use for 3+ related items with emoji indicators
- **Headers**: ## for main sections (long responses only)
- **Clarification**: Explicit request required when using ❓

## Response Templates

### Very Short (1-2 lines)
```markdown
✅ [Brief status]

[Optional one-line detail]
```

### Short (3-10 lines)
```markdown
✅ **[Status Summary]**

[2-4 line summary]

[Content paragraph or brief list]

[Optional: **Вывод**: ✅ [Summary]]
```

### Long (10+ lines)
```markdown
✅ **[Status Summary]**

[2-4 line summary]

## Что проверяли
[Description]

## Детали
[Findings with lists and code formatting]

## Вывод
✅ [Final summary with emoji]
```

## Checklist: Как оформить любой ответ

1. ✅ Начать с резюме (2-4 строки) с эмодзи статуса в начале
2. ✅ Использовать эмодзи показатели (✅/❌/❓) перед пунктами списка со статусом
3. ✅ Для длинных ответов: структурировать заголовками (##, ###)
4. ✅ Выделять параметры/числа моноширинным шрифтом (`` `value` ``)
5. ✅ Использовать списки для 3+ связанных пунктов
6. ✅ Для длинных ответов: включить блок "Вывод" с эмодзи статуса
7. ✅ При использовании ❓: явно указать, что нужно от пользователя

## Examples

See `docs/ai-chat-style-guide.md` for full examples (Feature Check and Bug Analysis).

