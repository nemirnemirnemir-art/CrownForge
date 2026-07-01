extends RefCounted
class_name TraderTransactionLogic

## Handles buying logic and purchases in the Trader menu

const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")

func buy_tile(tile: Control, economy_core: Node, tree: SceneTree, update_affordability_callback: Callable, roll_upgrades_callback: Callable, roll_troops_callback: Callable, resource_amount: int) -> void:
    if tile == null:
        return
    if economy_core == null:
        return
    var price := _resolve_price(tile, tree)
    if not economy_core.call("spend_gold", float(price)):
        update_affordability_callback.call()
        return

    var kind := String(tile.get("kind"))
    var payload: Variant = tile.get("payload")
    _match_purchase(kind, payload, tree, roll_upgrades_callback, roll_troops_callback, update_affordability_callback, resource_amount)
    
    if tile.has_method("set_purchased"):
        tile.set_purchased(true)
    update_affordability_callback.call()

func _resolve_price(tile: Control, tree: SceneTree) -> int:
    var price := int(tile.get("price"))
    if price <= 0:
        return max(0, price)
    var artifact_core := tree.root.get_node_or_null("ArtifactCore") if tree and tree.root else null
    if artifact_core == null:
        return price
    if not artifact_core.has_method("has_trader_free_coupon"):
        return price
    if not bool(artifact_core.call("has_trader_free_coupon")):
        return price
    if artifact_core.has_method("consume_trader_free_coupon"):
        var consumed := bool(artifact_core.call("consume_trader_free_coupon"))
        if consumed:
            return 0
    return price

func _match_purchase(kind: String, payload: Variant, tree: SceneTree, roll_upgrades_callback: Callable, roll_troops_callback: Callable, update_affordability_callback: Callable, resource_amount: int) -> void:
    match kind:
        "building":
            var building_id := String(payload)
            var building_registry = tree.root.get_node_or_null("BuildingRegistry") if tree else null
            if building_registry and building_registry.has_method("add_recipe") and building_id != "":
                building_registry.call("add_recipe", building_id, 1)
        "artifact":
            var artifact_id := String(payload)
            var artifact_core = tree.root.get_node_or_null("ArtifactCore") if tree else null
            if artifact_core and artifact_id != "":
                artifact_core.call("add_artifact", artifact_id, true)
        "spell":
            var spell_id := String(payload)
            if spell_id == "":
                return
            var spell_panel = tree.get_first_node_in_group("spell_panel") if tree else null
            var spell_core = tree.root.get_node_or_null("SpellCore") if tree else null
            if spell_panel and spell_panel.has_method("add_spell"):
                var config = PathRegistryScript.load_spell_config(spell_id)
                if config:
                    spell_panel.call("add_spell", config)
            elif spell_core and spell_core.has_method("add_spell"):
                spell_core.call("add_spell", spell_id, 1)
        "resource":
            var resource_id := String(payload)
            var resource_core = tree.root.get_node_or_null("ResourceCore") if tree else null
            if resource_core and resource_id != "" and resource_amount > 0:
                resource_core.call("add_resource", resource_id, resource_amount)
        "building_upgrade":
            if payload is Dictionary:
                var d := payload as Dictionary
                var slot_index := int(d.get("slot_index", -1))
                var upgrade_id := String(d.get("upgrade_id", ""))
                var upgrade_core = tree.root.get_node_or_null("BuildingUpgradeCore") if tree else null
                if upgrade_core and slot_index >= 0 and upgrade_id != "":
                    upgrade_core.call("apply_upgrade", slot_index, upgrade_id)
                    roll_upgrades_callback.call()
                    roll_troops_callback.call()
                    update_affordability_callback.call()
                else:
                    return
        "troop_training":
            var gs = tree.get_first_node_in_group("game_scene") if tree else null
            if gs and gs.has_method("open_reward_menu_troop_bonuses"):
                gs.call("open_reward_menu_troop_bonuses")
            elif gs and gs.has_method("open_troop_bonus_menu"):
                gs.call("open_troop_bonus_menu")
