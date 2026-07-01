# Work Report Structure Policy

Last updated: 01.04.2026

## When to Report

- After task completion
- Following build/verification step
- Only when there are tangible results to report

## Report Format (Simplified Russian)

The final report must follow this exact format on Russian:

```
✅ Реализация завершена

### Что было сделано
[Описание проблемы и как она была исправлена]

### Как проверить
1. [Шаг 1 для проверки]
2. [Шаг 2 для проверки]
3. [Шаг 3 и т.д.]

### Результат
Все поставленные задачи выполненны [или: X% выполненно]
```

## Key Rules

1. **Language**: Report in Russian only
2. **What to include**:
   - Brief description of the problem
   - What was fixed (no technical implementation details)
   - Clear verification steps for the user to test
   - Completion percentage (or "All tasks completed")

3. **What to EXCLUDE**:
   - ❌ Lists of modified files (GameScene.gd, DebugSpawnActions.gd, etc.)
   - ❌ Information about created test files
   - ❌ Implementation details, code changes, or technical approaches
   - ❌ Lines of code changed, function names, internal logic
   - ❌ "Still needed" or unfinished work items in completed reports
   - ❌ Section "Решение:" (Solution section is not needed)
   - ❌ "Добавлены тесты" (Information about added tests is not needed)

4. **Completion status**:
   - If all tasks done: `Все поставленные задачи выполненны`
   - If partial: `X% выполненно` (where X is the percentage of work remaining)

## Example Report

```
✅ Реализация завершена

### Что было сделано
Исправлен баг где мобы из дебаг-кнопок (F10 меню) спавнились внутри замка вместо области респа портала, и не имели правильного setup для движения.

### Как проверить
1. Нажать F10 → открыть Debug Spawn меню
2. Нажать кнопку любого моба (GoblinBandit, WallBuster, Dragon, etc.)
3. Результат: Мобы появляются в ring вокруг портала (правая часть экрана), движутся к стене
4. Консоль: [GameScene] Debug spawn goblin_bandit x1 -> 1
5. Сравнить: поведение одинаковое для дебаг-кнопок и wave/prophecy spawn

### Результат
Все поставленные задачи выполненны
```

## Verification Checklist

Before submitting final report:

- [ ] Task description is clear and in Russian
- [ ] Verification steps are numbered and specific
- [ ] No file paths or implementation details included
- [ ] No test file information included
- [ ] Completion status is clearly stated
- [ ] Report follows the exact format above

## Token Economy

This policy prioritizes clarity and token efficiency:
- Focus on what user needs to know (problem → fix → how to verify)
- No internal implementation details
- Concise but complete
- Result: actionable, user-focused reports
