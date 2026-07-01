# Phase 6: Editor Sync - Summary

## Выполненные изменения

### Исправления в коде

1. **BubbleProjectile.gd**:
   - Убрано сохранение базовых значений из `_ready()`
   - Базовые значения теперь сохраняются только в `setup()` через `_store_base_values()`
   - Это гарантирует, что значения читаются из редактора, а не перезаписываются

2. **BoulderWeaponProjectile.gd**:
   - Убрано сохранение `_base_sprite_scale` из `_ready()`
   - Базовые значения сохраняются в `setup()` через `_store_base_values()`

3. **ChaosAroundOrb.gd**:
   - Убрано сохранение `_base_sprite_scale` из `_ready()`
   - Базовые значения сохраняются в `setup()` перед применением масштаба

### Принцип работы

Все оружия теперь следуют единому принципу:
- **`_ready()`**: Только инициализация узлов и подключение сигналов, **без сохранения базовых значений**
- **`setup()`**: Вызывает `_store_base_values()` для чтения значений из редактора, затем применяет масштаб через `_apply_size_scale()`

Это гарантирует, что:
1. Настройки редактора не перезаписываются в `_ready()`
2. Базовые значения читаются из редактора в момент `setup()`
3. Масштаб применяется только при необходимости (когда `size_level > 0`)

## Что нужно проверить вручную в Godot Editor

### Для каждого оружия (20 штук):

1. **Открыть сцену оружия в 2D редакторе** (например, `gameplay/missile/ArrowProjectile.tscn`)

2. **Проверить визуальные узлы**:
   - `AnimatedSprite2D` или `Sprite2D` должен иметь `scale`, который соответствует желаемому виду на уровне 0
   - Этот `scale` будет сохранен как `base_scale` в `_store_base_values()`

3. **Проверить коллизии**:
   - `CollisionShape2D` должен иметь размер (`radius`, `size`), который соответствует визуальному спрайту
   - Коллизия должна накрывать видимый спрайт логично (не меньше/не больше)

4. **Запустить игру и проверить**:
   - При `size_level = 0` визуал и коллизия должны совпадать с тем, что видно в редакторе
   - При изменении `size_level` в конфиге (`.tres` файл) размер должен увеличиваться пропорционально

### Список оружий для проверки:

1. Arrow - `gameplay/missile/ArrowProjectile.tscn`
2. AuraWeapon - `gameplay/weapons/AuraWeaponProjectile.tscn`
3. Banana - `gameplay/missile/BananaProjectile.tscn`
4. ChainLightning - `gameplay/missile/ChainLightningProjectile.tscn`
5. ChaosAround - `gameplay/weapons/ChaosAroundManager.tscn` → `ChaosAroundOrb.tscn`
6. DroneWeapon - `gameplay/weapons/DroneWeaponProjectile.tscn`
7. FireBallWeapon - `gameplay/weapons/FireBallProjectile.tscn`
8. FrozenCloud - `gameplay/weapons/FrozenCloudProjectile.tscn`
9. PingPongWeapon - `gameplay/missile/PingPongProjectile.tscn`
10. Poisonflask - `gameplay/weapons/PoisonflaskProjectile.tscn`
11. Saw - `gameplay/missile/SawProjectile.tscn`
12. Shotgun - `gameplay/weapons/ShotgunProjectile.tscn`
13. Shuriken - `gameplay/missile/ShurikenProjectile.tscn`
14. SwingAttack - `gameplay/weapons/SwingAttackProjectile.tscn`
15. WeaponCircle - `gameplay/missile/WeaponCircleProjectile.tscn`
16. BoulderWeapon - `gameplay/weapons/BoulderWeaponProjectile.tscn`
17. BubbleWeapon - `gameplay/weapons/BubbleProjectile.tscn`
18. MinesWeapon - `gameplay/weapons/MinesWeaponProjectile.tscn`
19. LaserSkyWeapon - `gameplay/weapons/LaserSkyProjectile.tscn`
20. SwordToTheMouse - `gameplay/weapons/SwordToTheMouseProjectile.tscn`

## Критерии успеха

✅ **В редакторе**: Визуал и коллизия совпадают по размеру и позиции  
✅ **В игре при `size_level = 0`**: Визуал и коллизия совпадают с редактором  
✅ **В игре при `size_level > 0`**: Размер увеличивается пропорционально (+5% за уровень)  
✅ **Множественные запуски**: Размер не накапливается, остается стабильным

## Следующий шаг

После проверки всех оружий в редакторе и игре → **Phase 7: Testing** - формальное тестирование всех 20 оружий.

