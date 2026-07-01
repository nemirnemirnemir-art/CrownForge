from pathlib import Path
import os
import shutil


ROOT = Path("C:/Godot/clickcer")


FILE_MOVES = {
    # scripts root
    "scripts/GameScene.gd": "scripts/game/GameScene.gd",
    "scripts/MainUI.gd": "scripts/ui/hud/MainUI.gd",
    "scripts/MapLayout.gd": "scripts/map/MapLayout.gd",
    "scripts/MapSlot.gd": "scripts/map/MapSlot.gd",
    "scripts/Wall.gd": "scripts/map/Wall.gd",
    "scripts/Mob.gd": "scripts/mob/Mob.gd",
    "scripts/HeroOnField.gd": "scripts/hero/HeroOnField.gd",
    "scripts/HeroCombat.gd": "scripts/hero/HeroCombat.gd",
    "scripts/HeroHealth.gd": "scripts/hero/HeroHealth.gd",
    "scripts/HeroProjectile.gd": "scripts/hero/HeroProjectile.gd",
    "scripts/HeroAnimationLoader.gd": "scripts/hero/HeroAnimationLoader.gd",
    "scripts/SmallBones.gd": "scripts/hero/types/SmallBones.gd",
    "scripts/HeroBar.gd": "scripts/ui/hud/HeroBar.gd",
    "scripts/HeroBarDisplay.gd": "scripts/hero/legacy/HeroBarDisplay.gd",
    "scripts/HeroCard.gd": "scripts/ui/overlays/HeroCard.gd",
    "scripts/HeroUpgradesPanel.gd": "scripts/ui/overlays/HeroUpgradesPanel.gd",
    "scripts/StageSlider.gd": "scripts/ui/hud/StageSlider.gd",
    "scripts/SkillsPanel.gd": "scripts/ui/hud/SkillsPanel.gd",
    "scripts/DebugMenu.gd": "scripts/ui/debug/DebugMenu.gd",
    "scripts/DamagePopup.gd": "scripts/ui/overlays/DamagePopup.gd",
    "scripts/DamagePopupPool.gd": "scripts/systems/DamagePopupPool.gd",
    "scripts/HealingPopup.gd": "scripts/ui/overlays/HealingPopup.gd",
    "scripts/ResourcePopup.gd": "scripts/ui/overlays/ResourcePopup.gd",
    "scripts/DropItem.gd": "scripts/items/DropItem.gd",
    "scripts/Skill1Effect.gd": "scripts/effects/Skill1Effect.gd",
    "scripts/TreeCollisionSetup.gd": "scripts/map/TreeCollisionSetup.gd",
    "scripts/CombatTest.gd": "scripts/dev/CombatTest.gd",
    "scripts/FaceRigTest.gd": "scripts/dev/FaceRigTest.gd",
    "scripts/TestPolygon.gd": "scripts/dev/TestPolygon.gd",
    "scripts/CooldownCircle.gd": "scripts/ui/widgets/CooldownCircle.gd",
    "scripts/organize_levy_assets.gd": "scripts/dev/tools/organize_levy_assets.gd",
    "scripts/update_levy_configs.gd": "scripts/dev/tools/update_levy_configs.gd",
    # scenes root
    "scenes/GameScene.tscn": "scenes/game/GameScene.tscn",
    "scenes/MainUI.tscn": "scenes/ui/hud/MainUI.tscn",
    "scenes/MapLayout.tscn": "scenes/map/MapLayout.tscn",
    "scenes/MapSlot.tscn": "scenes/map/MapSlot.tscn",
    "scenes/Wall.tscn": "scenes/map/Wall.tscn",
    "scenes/HeroBar.tscn": "scenes/ui/hud/HeroBar.tscn",
    "scenes/HeroCard.tscn": "scenes/ui/overlays/HeroCard.tscn",
    "scenes/HeroOnField.tscn": "scenes/heroes/HeroOnField.tscn",
    "scenes/HeroProjectile.tscn": "scenes/projectiles/HeroProjectile.tscn",
    "scenes/HeroUpgradesPanel.tscn": "scenes/ui/overlays/HeroUpgradesPanel.tscn",
    "scenes/StageSlider.tscn": "scenes/ui/hud/StageSlider.tscn",
    "scenes/DebugMenu.tscn": "scenes/ui/debug/DebugMenuRoot.tscn",
    "scenes/DamagePopup.tscn": "scenes/ui/overlays/DamagePopup.tscn",
    "scenes/HealingPopup.tscn": "scenes/ui/overlays/HealingPopup.tscn",
    "scenes/ResourcePopup.tscn": "scenes/ui/overlays/ResourcePopup.tscn",
    "scenes/DropItem.tscn": "scenes/items/DropItem.tscn",
    "scenes/Skill1Effect.tscn": "scenes/effects/Skill1Effect.tscn",
    "scenes/CombatTest.tscn": "scenes/dev/CombatTest.tscn",
    "scenes/FaceRigTest.tscn": "scenes/dev/FaceRigTest.tscn",
    "scenes/testpolygon.tscn": "scenes/dev/TestPolygon.tscn",
    "scenes/Archer.tscn": "scenes/dev/ArcherSample.tscn",
    # scenes/ui root
    "scenes/ui/OptionsMenu.tscn": "scenes/ui/settings/OptionsMenu.tscn",
    "scenes/ui/SettingsMenu.tscn": "scenes/ui/settings/SettingsMenu.tscn",
    "scenes/ui/BuildingMenu.tscn": "scenes/ui/building/BuildingMenu.tscn",
    "scenes/ui/BuildingCategoryFilter.tscn": "scenes/ui/building/BuildingCategoryFilter.tscn",
    "scenes/ui/InventoryBar.tscn": "scenes/ui/inventory/InventoryBar.tscn",
    "scenes/ui/InventorySlot.tscn": "scenes/ui/inventory/InventorySlot.tscn",
    "scenes/ui/ItemTooltip.tscn": "scenes/ui/inventory/ItemTooltip.tscn",
    "scenes/ui/GazeUpgradeBar.tscn": "scenes/ui/gaze/GazeUpgradeBar.tscn",
    "scenes/ui/GazeUpgradeTooltip.tscn": "scenes/ui/gaze/GazeUpgradeTooltip.tscn",
    "scenes/ui/VzorZone.tscn": "scenes/ui/gaze/VzorZone.tscn",
    "scenes/ui/HeroHireItem.tscn": "scenes/ui/hire/HeroHireItem.tscn",
    "scenes/ui/HireInfoPanel.tscn": "scenes/ui/hire/HireInfoPanel.tscn",
    "scenes/ui/WaveTimerBar.tscn": "scenes/ui/hud/WaveTimerBar.tscn",
    "scenes/ui/ResourceBar.tscn": "scenes/ui/hud/ResourceBar.tscn",
    "scenes/ui/ResourceBar_NEW.tscn": "scenes/ui/hud/ResourceBar_NEW.tscn",
    "scenes/ui/ResourceBarPrimary.tscn": "scenes/ui/hud/ResourceBarPrimary.tscn",
    "scenes/ui/ResourceBarSecondary.tscn": "scenes/ui/hud/ResourceBarSecondary.tscn",
    "scenes/ui/PopulationBar.tscn": "scenes/ui/hud/PopulationBar.tscn",
    "scenes/ui/DenariiDisplay.tscn": "scenes/ui/hud/DenariiDisplay.tscn",
    "scenes/ui/GameSpeedUI.tscn": "scenes/ui/hud/GameSpeedUI.tscn",
    "scenes/ui/BossHpBar.tscn": "scenes/ui/hud/BossHpBar.tscn",
    "scenes/ui/MoodPanel.tscn": "scenes/ui/hud/MoodPanel.tscn",
    "scenes/ui/WallHealthUI.tscn": "scenes/ui/hud/WallHealthUI.tscn",
    "scenes/ui/WaveTooltip.tscn": "scenes/ui/overlays/WaveTooltip.tscn",
    "scenes/ui/PopulationTooltip.tscn": "scenes/ui/overlays/PopulationTooltip.tscn",
    "scenes/ui/HomeseekerArrivalOverlay.tscn": "scenes/ui/overlays/HomeseekerArrivalOverlay.tscn",
    "scenes/ui/MinotaurArrivalOverlay.tscn": "scenes/ui/overlays/MinotaurArrivalOverlay.tscn",
    "scenes/ui/FloatingText.tscn": "scenes/ui/overlays/FloatingText.tscn",
    "scenes/ui/GameOverPanel.tscn": "scenes/ui/overlays/GameOverPanel.tscn",
    "scenes/ui/DebugMenu.tscn": "scenes/ui/debug/DebugMenu.tscn",
    "scenes/ui/DebugSpawnMenu.tscn": "scenes/ui/debug/DebugSpawnMenu.tscn",
    "scenes/ui/TestDebugPanel.tscn": "scenes/ui/debug/TestDebugPanel.tscn",
    "scenes/ui/PerksTestPanel.tscn": "scenes/ui/debug/PerksTestPanel.tscn",
    "scenes/ui/FPSOverlay.tscn": "scenes/ui/debug/FPSOverlay.tscn",
    "scenes/ui/ScaleButton.tscn": "scenes/ui/widgets/ScaleButton.tscn",
    "scenes/ui/SliderButton.tscn": "scenes/ui/widgets/SliderButton.tscn",
    "scenes/ui/SelectionBorder.tscn": "scenes/ui/widgets/SelectionBorder.tscn",
    "scenes/ui/UnitSelectionOutline.tscn": "scenes/ui/widgets/UnitSelectionOutline.tscn",
    "scenes/ui/BuffGrid.tscn": "scenes/ui/widgets/BuffGrid.tscn",
    "scenes/ui/ForgePanel.tscn": "scenes/ui/town/ForgePanel.tscn",
    # scripts/ui root
    "scripts/ui/OptionsMenu.gd": "scripts/ui/settings/OptionsMenu.gd",
    "scripts/ui/SettingsMenu.gd": "scripts/ui/settings/SettingsMenu.gd",
    "scripts/ui/BuildingMenu.gd": "scripts/ui/building/BuildingMenu.gd",
    "scripts/ui/BuildingCategoryFilter.gd": "scripts/ui/building/BuildingCategoryFilter.gd",
    "scripts/ui/BuildingToolButton.gd": "scripts/ui/building/BuildingToolButton.gd",
    "scripts/ui/InventoryBar.gd": "scripts/ui/inventory/InventoryBar.gd",
    "scripts/ui/InventorySlot.gd": "scripts/ui/inventory/InventorySlot.gd",
    "scripts/ui/ItemTooltip.gd": "scripts/ui/inventory/ItemTooltip.gd",
    "scripts/ui/GazeUpgradeBar.gd": "scripts/ui/gaze/GazeUpgradeBar.gd",
    "scripts/ui/GazeUpgradeTooltip.gd": "scripts/ui/gaze/GazeUpgradeTooltip.gd",
    "scripts/ui/VzorZone.gd": "scripts/ui/gaze/VzorZone.gd",
    "scripts/ui/HeroHireItem.gd": "scripts/ui/hire/HeroHireItem.gd",
    "scripts/ui/HireInfoPanel.gd": "scripts/ui/hire/HireInfoPanel.gd",
    "scripts/ui/WaveTimerBar.gd": "scripts/ui/hud/WaveTimerBar.gd",
    "scripts/ui/ResourceBarPrimary.gd": "scripts/ui/hud/ResourceBarPrimary.gd",
    "scripts/ui/ResourceBarSecondary.gd": "scripts/ui/hud/ResourceBarSecondary.gd",
    "scripts/ui/ResourceBarManual.gd": "scripts/ui/hud/ResourceBarManual.gd",
    "scripts/ui/PopulationBar.gd": "scripts/ui/hud/PopulationBar.gd",
    "scripts/ui/DenariiDisplay.gd": "scripts/ui/hud/DenariiDisplay.gd",
    "scripts/ui/GameSpeedUI.gd": "scripts/ui/hud/GameSpeedUI.gd",
    "scripts/ui/BossHpBar.gd": "scripts/ui/hud/BossHpBar.gd",
    "scripts/ui/WallHealthUI.gd": "scripts/ui/hud/WallHealthUI.gd",
    "scripts/ui/WaveTooltip.gd": "scripts/ui/overlays/WaveTooltip.gd",
    "scripts/ui/PopulationTooltip.gd": "scripts/ui/overlays/PopulationTooltip.gd",
    "scripts/ui/HomeseekerArrivalOverlay.gd": "scripts/ui/overlays/HomeseekerArrivalOverlay.gd",
    "scripts/ui/MinotaurArrivalOverlay.gd": "scripts/ui/overlays/MinotaurArrivalOverlay.gd",
    "scripts/ui/FloatingText.gd": "scripts/ui/overlays/FloatingText.gd",
    "scripts/ui/GameOverPanel.gd": "scripts/ui/overlays/GameOverPanel.gd",
    "scripts/ui/DebugSpawnMenu.gd": "scripts/ui/debug/DebugSpawnMenu.gd",
    "scripts/ui/TestDebugPanel.gd": "scripts/ui/debug/TestDebugPanel.gd",
    "scripts/ui/PerksTestPanel.gd": "scripts/ui/debug/PerksTestPanel.gd",
    "scripts/ui/FPSOverlay.gd": "scripts/ui/debug/FPSOverlay.gd",
    "scripts/ui/ForgePanel.gd": "scripts/ui/town/ForgePanel.gd",
    # widget scripts currently in scenes/ui
    "scenes/ui/ScaleButton.gd": "scripts/ui/widgets/ScaleButton.gd",
    "scenes/ui/SliderButton.gd": "scripts/ui/widgets/SliderButton.gd",
}


DIR_MOVES = {
    "scripts/hero_ai": "scripts/hero/ai",
    "scripts/hero_bar": "scripts/hero/bar",
    "scripts/hero_card": "scripts/hero/card",
    "scripts/hero_components": "scripts/hero/components",
    "scripts/hero_modules": "scripts/hero/modules",
    "scripts/hero_states": "scripts/hero/states",
    "scripts/mob_components": "scripts/mob/components",
    "scripts/mob_modules": "scripts/mob/modules",
    "scripts/mob_states": "scripts/mob/states",
    "scripts/mobs": "scripts/mob/types",
    "scripts/debug": "scripts/dev/verify",
    "scripts/biomes": "scripts/map/biomes",
    "scripts/core": "scripts/spells/core",
    "scripts/spells/sheep": "scripts/spells/entities/sheep",
    "scripts/tools": "tooling/python",
}


def move_file(src_rel: str, dst_rel: str, moved: list[tuple[str, str]], conflicts: list[str]) -> None:
    src = ROOT / src_rel
    dst = ROOT / dst_rel
    if not src.exists():
        return
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.exists():
        conflicts.append(f"dst exists: {src_rel} -> {dst_rel}")
        return
    shutil.move(str(src), str(dst))
    moved.append((src_rel.replace("\\", "/"), dst_rel.replace("\\", "/")))


def merge_move_dir(src_rel: str, dst_rel: str, moved: list[tuple[str, str]], conflicts: list[str]) -> None:
    src = ROOT / src_rel
    dst = ROOT / dst_rel
    if not src.exists() or not src.is_dir():
        return
    dst.mkdir(parents=True, exist_ok=True)
    for child in src.rglob("*"):
        rel = child.relative_to(src)
        target = dst / rel
        if child.is_dir():
            target.mkdir(parents=True, exist_ok=True)
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.exists():
            conflicts.append(f"dst exists: {child.relative_to(ROOT)} -> {target.relative_to(ROOT)}")
            continue
        shutil.move(str(child), str(target))
        moved.append((str(child.relative_to(ROOT)).replace("\\", "/"), str(target.relative_to(ROOT)).replace("\\", "/")))

    for d, _, _ in os.walk(src, topdown=False):
        p = Path(d)
        if p.exists() and not any(p.iterdir()):
            p.rmdir()


def main() -> None:
    moved: list[tuple[str, str]] = []
    conflicts: list[str] = []

    for src, dst in FILE_MOVES.items():
        move_file(src, dst, moved, conflicts)

    for src, dst in DIR_MOVES.items():
        merge_move_dir(src, dst, moved, conflicts)

    replacements: dict[str, str] = {}
    for src, dst in moved:
        replacements[f"res://{src}"] = f"res://{dst}"

    for src, dst in DIR_MOVES.items():
        src = src.replace("\\", "/")
        dst = dst.replace("\\", "/")
        replacements[f"res://{src}/"] = f"res://{dst}/"

    text_exts = {".gd", ".tscn", ".tres", ".godot", ".cfg", ".md", ".json", ".txt"}
    updated_count = 0
    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
        if ".godot" in path.parts:
            continue
        if path.suffix.lower() not in text_exts:
            continue
        try:
            original = path.read_text(encoding="utf-8")
        except Exception:
            continue
        updated = original
        for old, new in replacements.items():
            updated = updated.replace(old, new)
        if updated != original:
            path.write_text(updated, encoding="utf-8")
            updated_count += 1

    print(f"Moved entries: {len(moved)}")
    print(f"Updated text files: {updated_count}")
    print(f"Conflicts: {len(conflicts)}")
    for item in conflicts[:50]:
        print(item)


if __name__ == "__main__":
    main()
