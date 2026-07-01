extends RefCounted
class_name WavePreviewFlow


func update_wave_timer_previews(wave_timer_bar, current_wave: int, intro_pending: bool, selection_pending: bool, prophecy_level: int, prophecy_queue: Array, current_index: int, display_slots: Array, display_index: int, show_trader: bool, show_boss: bool, preview_builder: Callable, intro_builder: Callable, trader_builder: Callable, boss_builder: Callable) -> void:
	print("[WavePreviewFlow] Update: current_wave=%d, intro=%s, selection=%s, level=%d, queue=%d, show_trader=%s, show_boss=%s" % [current_wave, intro_pending, selection_pending, prophecy_level, prophecy_queue.size(), show_trader, show_boss])
	if wave_timer_bar == null:
		return
	if selection_pending and prophecy_queue.is_empty():
		var startup_wave: int = current_wave
		if intro_builder.is_valid():
			wave_timer_bar.set_wave_preview(startup_wave, intro_builder.call(prophecy_level))
		for sequence_index in range(1, 4):
			wave_timer_bar.set_wave_preview(startup_wave + sequence_index, {
				"wave_title": "Wave %d" % sequence_index,
				"display_wave_number": sequence_index,
				"flag_label": "%d" % sequence_index,
				"mob_counts": {},
				"rewards": [],
			})
		if prophecy_level < 4 and intro_builder.is_valid():
			wave_timer_bar.set_wave_preview(startup_wave + 4, intro_builder.call(prophecy_level + 1))
		elif boss_builder.is_valid():
			wave_timer_bar.set_wave_preview(startup_wave + 4, boss_builder.call())
		return
	var base_wave: int = current_wave + 1
	var offset: int = 0
	if intro_pending and intro_builder.is_valid():
		wave_timer_bar.set_wave_preview(base_wave, intro_builder.call(prophecy_level))
		offset += 1
	for i in range(current_index, prophecy_queue.size()):
		var absolute_wave: int = base_wave + offset
		var display_number: int = display_index + 1 + offset
		if i < display_slots.size():
			display_number = int(display_slots[i])
		var preview: Dictionary = preview_builder.call(prophecy_queue[i], display_number) if preview_builder.is_valid() else {}
		wave_timer_bar.set_wave_preview(absolute_wave, preview)
		offset += 1
	if show_trader and trader_builder.is_valid():
		wave_timer_bar.set_wave_preview(base_wave + offset, trader_builder.call())
		if prophecy_level < 4 and intro_builder.is_valid():
			wave_timer_bar.set_wave_preview(base_wave + offset + 1, intro_builder.call(prophecy_level + 1))
	elif show_boss and boss_builder.is_valid():
		wave_timer_bar.set_wave_preview(base_wave + offset, boss_builder.call())


func clear_future_wave_previews(wave_timer_bar, current_wave: int) -> void:
	if wave_timer_bar == null:
		return
	for i in range(6):
		wave_timer_bar.clear_wave_preview(current_wave + 1 + i)
