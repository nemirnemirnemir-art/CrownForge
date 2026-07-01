# Damage Popup Enhancement

**SPEC ID:** 016-damage-popup-enhancement  
**Status:** Ready for Implementation  
**Date:** 2025-01-XX

## 1. Context

**Game:** Dungeon Clicker Realm, Godot 4.3, 2D field.

**Current State:**
- Damage popups appear when mobs are hit by heroes or player mouse clicks
- Basic popup exists (`DamagePopup.tscn`, `DamagePopup.gd`) but is mostly empty
- Popups are instantiated in `Mob.gd` when damage is taken
- Current implementation is minimal - no animations

## 2. Goal

Enhance damage popup visual feedback with smooth animations:
- Popup appears quickly above the mob
- Floats upward during display
- Scales down smoothly to 70% of original size
- Fades out slowly (slow fading)

## 3. Requirements

### Functional Requirements

- Popup appears when:
  - Hero attacks a mob (melee or ranged)
  - Player clicks a mob with mouse
- Animation sequence (all animations run in parallel):
  1. Quick appearance (fast spawn) - 0.1 seconds (scale from 0 to 100% or fade in)
  2. Float upward movement (30 pixels over 1.5s) - parallel, ease-out
  3. Smooth scale down to 70% size (over 1.5s) - parallel, ease-out
  4. Slow fade out (over 1.5s) - parallel, ease-out
- Total animation duration: 1.5 seconds
- Easing: Ease-out (плавное замедление в конце) для всех анимаций

### Visual Requirements

- Text displays damage value
- Upward movement during animation: 30 pixels upward over 1.5 seconds
- Scale animation: 100% → 70%
- Opacity animation: 100% → 0% (slow fade)

## 4. Out of Scope

- Different popup styles for different damage types
- Critical hit indicators
- Damage number formatting (colors, sizes based on damage amount)
- Multiple simultaneous popups management

## 5. Clarifications

### Session 2025-01-XX

- Q: Какова общая длительность анимации попапа (от появления до полного исчезновения)? → A: 1.5 секунды
- Q: На какое расстояние вверх должен перемещаться попап во время анимации? → A: 30 пикселей
- Q: Как должны выполняться анимации (последовательно или параллельно)? → A: Параллельно - все анимации одновременно
- Q: Как быстро должен появляться попап (время появления)? → A: 0.1 секунды
- Q: Какая плавность анимации (easing)? → A: Ease-out (плавное замедление в конце)








































