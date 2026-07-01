extends SceneTree

const MapLayoutScene := preload("res://scenes/map/MapLayout.tscn")


func _init() -> void:
	var map_layout := MapLayoutScene.instantiate() as MapLayout
	if map_layout == null:
		push_error("[test_maplayout_spawn_markers_follow_portal_node] failed to instantiate MapLayout")
		quit(1)
		return

	map_layout.spawn_markers_offset = Vector2(120.0, -30.0)
	get_root().add_child(map_layout)
	call_deferred("_run_test", map_layout)


func _run_test(map_layout: MapLayout) -> void:
	await process_frame

	var portal_node := map_layout.get_node_or_null("Portal") as Node2D
	var portal_marker := map_layout.get_node_or_null("PortalMarker") as MapMarker
	if portal_node == null or portal_marker == null:
		push_error("[test_maplayout_spawn_markers_follow_portal_node] portal node/marker missing")
		quit(1)
		return

	if portal_marker.position.distance_to(portal_node.position) > 0.01:
		push_error("[test_maplayout_spawn_markers_follow_portal_node] portal marker must match Portal node position")
		quit(1)
		return

	var spawn_markers: Array[MapMarker] = []
	for child in map_layout.get_children():
		if child is MapMarker:
			var marker := child as MapMarker
			if marker.marker_type == MapMarker.MarkerType.SPAWN:
				spawn_markers.append(marker)

	if spawn_markers.size() != 32:
		push_error("[test_maplayout_spawn_markers_follow_portal_node] expected 32 spawn markers, got %d" % spawn_markers.size())
		quit(1)
		return

	var expected_center := portal_node.position + map_layout.spawn_markers_offset
	var average := Vector2.ZERO
	for marker in spawn_markers:
		average += marker.position
	average /= float(spawn_markers.size())

	if average.distance_to(expected_center) > 2.0:
		push_error("[test_maplayout_spawn_markers_follow_portal_node] marker center must follow portal + offset")
		quit(1)
		return

	print("[test_maplayout_spawn_markers_follow_portal_node] PASS")
	quit(0)
