# Weapon Size Unification - Inventory

Документация всех 20 оружий: визуальные узлы, коллизии, текущая логика масштабирования.

## Список оружий (из player.tscn)

1. Arrow (ArrowNormalized.tres)
2. AuraWeapon (AuraWeaponNormalized.tres)
3. Banana (BananaNormalized.tres)
4. ChainLightning (ChainLightningNormalized.tres)
5. ChaosAround (ChaosAroundNormalized.tres)
6. DroneWeapon (DroneWeaponNormalized.tres)
7. FireBallWeapon (FireBallWeaponNormalized.tres)
8. FrozenCloud (FrozenCloudNormalized.tres)
9. PingPongWeapon (PingPongWeaponNormalized.tres)
10. Poisonflask (PoisonflaskNormalized.tres)
11. Saw (SawNormalized.tres)
12. Shotgun (ShotgunNormalized.tres)
13. Shuriken (ShurikenNormalized.tres)
14. SwingAttack (SwingAttackNormalized.tres)
15. WeaponCircle (WeaponCircleNormalized.tres)
16. BoulderWeapon (BoulderNormalized.tres)
17. BubbleWeapon (BubbleNormalized.tres)
18. MinesWeapon (MinesNormalized.tres)
19. LaserSkyWeapon (LaserSkyNormalized.tres)
20. SwordToTheMouse (SwordToMouseNormalized.tres)

---

## 1. Arrow

**Config:** `gameplay/weapons/ArrowNormalized.tres`  
**Scene:** `gameplay/missile/ArrowProjectile.tscn`  
**Script:** `gameplay/weapons/Projectile.gd` (базовый класс)

### Визуальные узлы:
- `AnimatedSprite2D` (path: `.`)
  - `position = Vector2(-12, 0)`
  - `scale = Vector2(0.703125, 0.5)` ⚠️ **Текущий масштаб в редакторе**

### Коллизии:
- `CollisionShape2D` (path: `.`)
  - `shape = CircleShape2D`
  - `radius = 3.0` ⚠️ **Базовый размер коллизии**

### Текущая логика масштабирования:
- ❌ Нет специальной логики масштабирования в скрипте
- Используется базовый `Projectile.gd` с `_size_scale` (deprecated)

---

## 2. AuraWeapon

**Config:** `gameplay/weapons/AuraWeaponNormalized.tres`  
**Scene:** `gameplay/weapons/AuraWeaponProjectile.tscn`  
**Script:** `gameplay/weapons/AuraWeaponProjectile.gd`

### Визуальные узлы:
- `Area2D` (path: `.`)
  - `scale = Vector2(0.404762, 0.387097)` ⚠️ **Масштаб на корневом узле**
- `AnimatedSprite2D` (path: `.`)
  - `scale = Vector2(2.19301, 2.17911)` ⚠️ **Масштаб спрайта**

### Коллизии:
- `CollisionShape2D` (path: `.`)
  - `shape = CircleShape2D`
  - `radius = 61.0082` ⚠️ **Базовый размер коллизии**

### Текущая логика масштабирования:
- ❌ Нет специальной логики масштабирования в скрипте

---

## 3. Banana

**Config:** `gameplay/weapons/BananaNormalized.tres`  
**Scene:** `gameplay/missile/BananaProjectile.tscn`  
**Script:** `gameplay/weapons/Projectile.gd` (базовый класс)

### Визуальные узлы:
- `AnimatedSprite2D` (path: `.`)
  - `position = Vector2(-1, 1)`
  - `scale = Vector2(0.1, 0.1)` ⚠️ **Текущий масштаб в редакторе**

### Коллизии:
- `CollisionShape2D` (path: `.`)
  - `shape = CircleShape2D`
  - ⚠️ **Радиус не указан в .tscn (нужно проверить в редакторе)**

### Текущая логика масштабирования:
- ❌ Нет специальной логики масштабирования в скрипте

---

## 4. ChainLightning

**Config:** `gameplay/weapons/ChainLightningNormalized.tres`  
**Scene:** `gameplay/missile/ChainLightningProjectile.tscn`  
**Script:** `gameplay/weapons/Projectile.gd` (базовый класс)

### Визуальные узлы:
- `AnimatedSprite2D` (path: `.`)
  - `position = Vector2(0, -21)`
  - `scale = Vector2(0.1, 0.1)` ⚠️ **Текущий масштаб в редакторе**

### Коллизии:
- `CollisionShape2D` (path: `.`)
  - `shape = CircleShape2D`
  - ⚠️ **Радиус не указан в .tscn (нужно проверить в редакторе)**

### Текущая логика масштабирования:
- ❌ Нет специальной логики масштабирования в скрипте

---

## 5. ChaosAround

**Config:** `gameplay/weapons/ChaosAroundNormalized.tres`  
**Scene:** `gameplay/weapons/ChaosAroundManager.tscn` → `ChaosAroundOrb.tscn`  
**Script:** `gameplay/weapons/ChaosAroundManager.gd` → `ChaosAroundOrb.gd`

### Визуальные узлы (Orb):
- `AnimatedSprite2D` (path: `.`)
  - ⚠️ **Масштаб не указан (по умолчанию Vector2(1, 1))**

### Коллизии (Orb):
- `CollisionShape2D` (path: `.`)
  - `shape = CircleShape2D`
  - `radius = 16.0` ⚠️ **Базовый размер коллизии**

### Текущая логика масштабирования:
- ❌ Нет специальной логики масштабирования в скрипте

---

## 6. DroneWeapon

**Config:** `gameplay/weapons/DroneWeaponNormalized.tres`  
**Scene:** `gameplay/weapons/DroneWeaponProjectile.tscn`  
**Script:** `gameplay/weapons/DroneWeaponProjectile.gd`

### Визуальные узлы:
- `AnimatedSprite2D` (path: `.`)
  - `position = Vector2(3, 4)`
  - `scale = Vector2(0.25, 0.216)` ⚠️ **Текущий масштаб в редакторе**
- `Sprite2D` (path: `Shadow`)
  - `scale = Vector2(0.2, 0.086)` ⚠️ **Масштаб тени**

### Коллизии:
- `CollisionShape2D` (path: `.`)
  - `shape = CircleShape2D`
  - ⚠️ **Радиус не указан в .tscn (нужно проверить в редакторе)**

### Текущая логика масштабирования:
- ❌ Нет специальной логики масштабирования в скрипте

---

## 7. FireBallWeapon

**Config:** `gameplay/weapons/FireBallWeaponNormalized.tres`  
**Scene:** `gameplay/weapons/FireBallProjectile.tscn`  
**Script:** `gameplay/weapons/FireBallProjectile.gd`

### Визуальные узлы:
- `AnimatedSprite2D` (path: `.`)
  - `scale = Vector2(0.1, 0.1)` ⚠️ **Текущий масштаб в редакторе**
- `AnimatedSprite2D2` (path: `.`)
  - `visible = false` (explosion)
  - `scale = Vector2(3, 3)` ⚠️ **Масштаб взрыва**

### Коллизии:
- `CollisionShape2D` (path: `.`)
  - `shape = CircleShape2D`
  - `radius = 12.0` ⚠️ **Базовый размер коллизии**

### Текущая логика масштабирования:
- ❌ Нет специальной логики масштабирования в скрипте

---

## 8. FrozenCloud

**Config:** `gameplay/weapons/FrozenCloudNormalized.tres`  
**Scene:** `gameplay/weapons/FrozenCloudProjectile.tscn`  
**Script:** `gameplay/weapons/FrozenCloudProjectile.gd`

### Визуальные узлы:
- `AnimatedSprite2D` (path: `.`)
  - ⚠️ **Масштаб не указан (по умолчанию Vector2(1, 1))**

### Коллизии:
- `CollisionShape2D` (path: `.`)
  - `shape = CircleShape2D`
  - `radius = 50.0` ⚠️ **Базовый размер коллизии**

### Текущая логика масштабирования:
- ❌ Нет специальной логики масштабирования в скрипте

---

## 9. PingPongWeapon

**Config:** `gameplay/weapons/PingPongWeaponNormalized.tres`  
**Scene:** `gameplay/missile/PingPongProjectile.tscn`  
**Script:** `gameplay/weapons/Projectile.gd` (базовый класс)

### Визуальные узлы:
- `AnimatedSprite2D` (path: `.`)
  - `scale = Vector2(0.327039, 0.313642)` ⚠️ **Текущий масштаб в редакторе**

### Коллизии:
- `CollisionShape2D` (path: `.`)
  - `shape = CircleShape2D`
  - `radius = 6.0` ⚠️ **Базовый размер коллизии**

### Текущая логика масштабирования:
- ❌ Нет специальной логики масштабирования в скрипте

---

## 10. Poisonflask

**Config:** `gameplay/weapons/PoisonflaskNormalized.tres`  
**Scene:** `gameplay/weapons/PoisonflaskProjectile.tscn`  
**Script:** `gameplay/weapons/PoisonflaskProjectile.gd`

### Визуальные узлы:
- `AnimatedSprite2D` (path: `.`)
  - ⚠️ **Масштаб не указан (по умолчанию Vector2(1, 1))**

### Коллизии:
- `CollisionShape2D` (path: `.`)
  - `shape = CircleShape2D`
  - `radius = 50.0` ⚠️ **Базовый размер коллизии**

### Текущая логика масштабирования:
- ❌ Нет специальной логики масштабирования в скрипте

---

## 11. Saw

**Config:** `gameplay/weapons/SawNormalized.tres`  
**Scene:** `gameplay/missile/SawProjectile.tscn`  
**Script:** `gameplay/weapons/Projectile.gd` (базовый класс)

### Визуальные узлы:
- `AnimatedSprite2D` (path: `.`)
  - `scale = Vector2(0.5, 0.5)` ⚠️ **Текущий масштаб в редакторе**

### Коллизии:
- `CollisionShape2D` (path: `.`)
  - `scale = Vector2(1.42103, 1.58037)` ⚠️ **Масштаб коллизии**
  - `shape = CircleShape2D`
  - ⚠️ **Радиус не указан в .tscn (нужно проверить в редакторе)**

### Текущая логика масштабирования:
- ❌ Нет специальной логики масштабирования в скрипте

---

## 12. Shotgun

**Config:** `gameplay/weapons/ShotgunNormalized.tres`  
**Scene:** `gameplay/weapons/ShotgunProjectile.tscn`  
**Script:** `gameplay/weapons/ShotgunProjectile.gd`

### Визуальные узлы:
- `AnimatedSprite2D` (path: `.`)
  - `position = Vector2(0, 1)`
  - ⚠️ **Масштаб не указан (по умолчанию Vector2(1, 1))**

### Коллизии:
- `CollisionShape2D` (path: `.`)
  - `shape = CircleShape2D`
  - `radius = 3.16228` ⚠️ **Базовый размер коллизии**

### Текущая логика масштабирования:
- ❌ Нет специальной логики масштабирования в скрипте

---

## 13. Shuriken

**Config:** `gameplay/weapons/ShurikenNormalized.tres`  
**Scene:** `gameplay/missile/ShurikenProjectile.tscn`  
**Script:** `gameplay/weapons/Projectile.gd` (базовый класс)

### Визуальные узлы:
- `AnimatedSprite2D` (path: `.`)
  - `scale = Vector2(0.4, 0.4)` ⚠️ **Текущий масштаб в редакторе**

### Коллизии:
- `CollisionShape2D` (path: `.`)
  - `shape = CircleShape2D`
  - ⚠️ **Радиус не указан в .tscn (нужно проверить в редакторе)**

### Текущая логика масштабирования:
- ❌ Нет специальной логики масштабирования в скрипте

---

## 14. SwingAttack

**Config:** `gameplay/weapons/SwingAttackNormalized.tres`  
**Scene:** `gameplay/weapons/SwingAttackProjectile.tscn`  
**Script:** `gameplay/weapons/SwingAttackProjectile.gd`

### Визуальные узлы:
- `AnimatedSprite2D` (path: `.`)
  - ⚠️ **Масштаб не указан (по умолчанию Vector2(1, 1))**

### Коллизии:
- `CollisionShape2D` (path: `.`)
  - `position = Vector2(12, 51)`
  - `rotation = -0.898845`
  - `shape = CapsuleShape2D`
  - `height = 267.544` ⚠️ **Базовый размер коллизии**

### Текущая логика масштабирования:
- ❌ Нет специальной логики масштабирования в скрипте

---

## 15. WeaponCircle

**Config:** `gameplay/weapons/WeaponCircleNormalized.tres`  
**Scene:** `gameplay/missile/WeaponCircleProjectile.tscn`  
**Script:** `gameplay/weapons/Projectile.gd` (базовый класс)

### Визуальные узлы:
- `AnimatedSprite2D` (path: `.`)
  - ⚠️ **Масштаб не указан (по умолчанию Vector2(1, 1))**

### Коллизии:
- `CollisionShape2D` (path: `.`)
  - `shape = CircleShape2D`
  - ⚠️ **Радиус не указан в .tscn (нужно проверить в редакторе)**

### Текущая логика масштабирования:
- ❌ Нет специальной логики масштабирования в скрипте

---

## 16. BoulderWeapon

**Config:** `gameplay/weapons/BoulderNormalized.tres`  
**Scene:** `gameplay/weapons/BoulderWeaponProjectile.tscn`  
**Script:** `gameplay/weapons/BoulderWeaponProjectile.gd`

### Визуальные узлы:
- `AnimatedSprite2D` (path: `Visual`)
  - `position = Vector2(0, -48)`
  - `scale = Vector2(0.4, 0.4)` ⚠️ **Текущий масштаб в редакторе**

### Коллизии:
- `StaticBody2D` (path: `Collider`)
  - `position = Vector2(0, -48)`
  - `scale = Vector2(0.4, 0.4)` ⚠️ **Масштаб коллайдера**
- `CollisionShape2D` (path: `Collider`)
  - `shape = CircleShape2D`
  - `radius = 62.5` ⚠️ **Базовый размер коллизии**
- `Area2D` (path: `DamageArea`)
  - `CollisionShape2D` с тем же `CircleShape2D`

### Текущая логика масштабирования:
- ❌ Нет специальной логики масштабирования в скрипте

---

## 17. BubbleWeapon

**Config:** `gameplay/weapons/BubbleNormalized.tres`  
**Scene:** `gameplay/weapons/BubbleProjectile.tscn`  
**Script:** `gameplay/weapons/BubbleProjectile.gd`

### Визуальные узлы:
- `AnimatedSprite2D` (path: `Visual`)
  - `scale = Vector2(0.4, 0.4)` ⚠️ **Текущий масштаб в редакторе**
- `AnimatedSprite2D` (path: `ExplosionSprite`)
  - `visible = false` (explosion)

### Коллизии:
- `CollisionShape2D` (path: `.`)
  - `shape = CircleShape2D`
  - `radius = 18.0` ⚠️ **Базовый размер коллизии (flight)**
- `Area2D` (path: `ExplosionArea`)
  - `CollisionShape2D` с `CircleShape2D`
  - `radius = 28.0` ⚠️ **Базовый размер коллизии (explosion)**

### Текущая логика масштабирования:
- ❌ Нет специальной логики масштабирования в скрипте

---

## 18. MinesWeapon

**Config:** `gameplay/weapons/MinesNormalized.tres`  
**Scene:** `gameplay/weapons/MinesWeaponProjectile.tscn`  
**Script:** `gameplay/weapons/MinesWeaponProjectile.gd`

### Визуальные узлы:
- `Sprite2D` (path: `Shadow`)
  - `position = Vector2(0, 15)`
  - `scale = Vector2(0.4, 0.4)` ⚠️ **Масштаб тени**
- `AnimatedSprite2D` (path: `VisualIdle`)
  - `scale = Vector2(0.4, 0.4)` ⚠️ **Текущий масштаб в редакторе**
- `AnimatedSprite2D` (path: `VisualExplosion`)
  - `visible = false` (explosion)
  - `scale = Vector2(0.4, 0.4)` ⚠️ **Масштаб взрыва**

### Коллизии:
- `Area2D` (path: `VisualIdle/MineCollisionArea`)
  - `CollisionShape2D` с `scale = Vector2(0.777485, 0.611501)`
  - `shape = CircleShape2D`
  - `radius = 56.9316` ⚠️ **Базовый размер коллизии**
- `Area2D` (path: `TriggerArea`)
  - `CollisionShape2D` с `CircleShape2D`
  - `radius = 12.1655` ⚠️ **Базовый размер триггера**
- `Area2D` (path: `ExplosionArea`)
  - `scale = Vector2(1.5, 1.5)` ⚠️ **Масштаб области взрыва**
  - `CollisionShape2D` с `RectangleShape2D`
  - `size = Vector2(50, 50)` ⚠️ **Базовый размер взрыва**

### Текущая логика масштабирования:
- ❌ Нет специальной логики масштабирования в скрипте

---

## 19. LaserSkyWeapon

**Config:** `gameplay/weapons/LaserSkyNormalized.tres`  
**Scene:** `gameplay/weapons/LaserSkyProjectile.tscn`  
**Script:** `gameplay/weapons/LaserSkyProjectile.gd`

### Визуальные узлы:
- `Sprite2D` (path: `ImpactVisual`)
  - `scale = Vector2(1.53397, 2.19197)` ⚠️ **Масштаб визуала попадания**
- `AnimatedSprite2D` (path: `BeamSprite`)
  - `position = Vector2(0.5, -249)`
  - `scale = Vector2(0.979167, 1)` ⚠️ **Масштаб луча**
  - `offset = Vector2(0, -500)`

### Коллизии:
- `CollisionShape2D` (path: `.`)
  - `rotation = 1.5708`
  - `scale = Vector2(1.44144, 1.67674)` ⚠️ **Масштаб коллизии**
  - `shape = CapsuleShape2D`
  - `radius = 26.0` ⚠️ **Базовый размер коллизии**
  - `height = 70.0` ⚠️ **Базовая высота коллизии**

### Текущая логика масштабирования:
- ❌ Нет специальной логики масштабирования в скрипте

---

## 20. SwordToTheMouse

**Config:** `gameplay/weapons/SwordToMouseNormalized.tres`  
**Scene:** `gameplay/weapons/SwordToTheMouseProjectile.tscn`  
**Script:** `gameplay/weapons/SwordToTheMouseProjectile.gd`

### Визуальные узлы:
- `AnimatedSprite2D` (path: `.`)
  - `position = Vector2(42, -3)`
  - `rotation = -0.0161139`
  - `scale = Vector2(0.838385, 0.375151)` ⚠️ **Текущий масштаб в редакторе**

### Коллизии:
- `CollisionShape2D` (path: `.`)
  - `position = Vector2(49.0396, -0.231428)`
  - `rotation = 1.57617`
  - `scale = Vector2(-0.977037, 1.46179)` ⚠️ **Масштаб коллизии**
  - `shape = CapsuleShape2D`
  - `radius = 7.5` ⚠️ **Базовый размер коллизии**
  - `height = 100.0` ⚠️ **Базовая высота коллизии**

### Текущая логика масштабирования:
- ❌ Нет специальной логики масштабирования в скрипте

---

## Шаблон для заполнения:

```markdown
## N. [WeaponName]

**Config:** `path/to/WeaponNormalized.tres`  
**Scene:** `path/to/WeaponProjectile.tscn`  
**Script:** `path/to/WeaponProjectile.gd`

### Визуальные узлы:
- `[NodeType]` (path: `[path]`)
  - `scale = Vector2(x, y)` или другие параметры размера

### Коллизии:
- `[NodeType]` (path: `[path]`)
  - `shape = [ShapeType]`
  - Размеры: `[size parameters]`

### Текущая логика масштабирования:
- ✅/❌ Есть/нет специальная логика
- Описание текущей логики (если есть)
```

