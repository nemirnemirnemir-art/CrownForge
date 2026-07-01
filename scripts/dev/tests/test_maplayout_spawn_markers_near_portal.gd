extends SceneTree

const MapLayoutScene := preload("res://scenes/map/MapLayout.tscn")


func _init() -> void:
	var map_layout := MapLayoutScene.instantiate() as MapLayout
	if map_layout == null:
		push_error("[test_maplayout_spawn_markers_near_portal] failed to instantiate MapLayout")
		quit(1)
		return

	get_root().add_child(map_layout)
	call_deferred("_run_test", map_layout)


func _run_test(map_layout: MapLayout) -> void:
	await process_frame

	var portal_marker := map_layout.get_node_or_null("PortalMarker") as MapMarker
	if portal_marker == null:
		push_error("[test_maplayout_spawn_markers_near_portal] PortalMarker is missing")
		quit(1)
		return

	var spawn_markers: Array[MapMarker] = []
	for child in map_layout.get_children():
		if child is MapMarker:
			var marker := child as MapMarker
			if marker.marker_type == MapMarker.MarkerType.SPAWN:
				spawn_markers.append(marker)

	if spawn_markers.size() != 32:
		push_error("[test_maplayout_spawn_markers_near_portal] expected 32 spawn markers, got %d" % spawn_markers.size())
		quit(1)
		return

	var center := portal_marker.position
	var avg := Vector2.ZERO
	for marker in spawn_markers:
		var dist := marker.position.distance_to(center)
		if dist < 75.0 or dist > 95.0:
			push_error("[test_maplayout_spawn_markers_near_portal] marker %s has invalid distance %.2f" % [marker.name, dist])
			quit(1)
			return
		avg += marker.position

	avg /= float(spawn_markers.size())
	if avg.distance_to(center) > 2.0:
		push_error("[test_maplayout_spawn_markers_near_portal] ring center drift is too high: %.2f" % avg.distance_to(center))
		quit(1)
		return

	print("[test_maplayout_spawn_markers_near_portal] PASS")
	quit(0)
