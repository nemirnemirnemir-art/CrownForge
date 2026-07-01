extends RefCounted
class_name EncounterStateBuilder

## Builds encounter dictionaries including options with requirement statuses

const EncounterUIBuilderScript := preload("res://scripts/encounters/modules/EncounterUIBuilder.gd")

var _ui_builder := EncounterUIBuilderScript.new()

func decorate_options_for_ui(options: Array, resource_core: Node) -> Array:
    return _ui_builder.decorate_options_for_ui(options, resource_core)
