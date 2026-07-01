extends RefCounted
class_name ProphecyWaveCardTooltipBuilder


static func make_custom_tooltip(
    node_name: String,
    interactive: bool,
    dragging_self: bool,
    option_patterns: Array,
    use_fixed_hover_panel: bool,
    debug_tooltip: bool,
    tooltip_scene: PackedScene
) -> Control:
    if use_fixed_hover_panel:
        return null

    if not interactive:
        if debug_tooltip:
            print("[ProphecyWaveCard] _make_custom_tooltip blocked: interactive=false name=", node_name)
        return null

    if dragging_self:
        if debug_tooltip:
            print("[ProphecyWaveCard] _make_custom_tooltip blocked: dragging name=", node_name)
        return null

    if option_patterns == null or option_patterns.is_empty():
        if debug_tooltip:
            print("[ProphecyWaveCard] _make_custom_tooltip blocked: empty patterns name=", node_name, " patterns=", option_patterns)
        return null

    if not tooltip_scene:
        if debug_tooltip:
            print("[ProphecyWaveCard] _make_custom_tooltip blocked: missing scene name=", node_name)
        return null

    var inst := tooltip_scene.instantiate()
    if debug_tooltip:
        print("[ProphecyWaveCard] _make_custom_tooltip instantiate ok name=", node_name, " inst=", inst)

    if inst and inst.has_method("setup"):
        if debug_tooltip:
            print("[ProphecyWaveCard] _make_custom_tooltip calling setup patterns=", option_patterns.size())
        inst.setup(option_patterns)

    return inst as Control
