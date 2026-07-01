extends SceneTree

const WaveRewardMenuScene := preload("res://scenes/ui/rewards/WaveRewardMenu.tscn")

func _init() -> void:
	var menu := WaveRewardMenuScene.instantiate() as WaveRewardMenu
	if menu == null:
		push_error("[test_wave_reward_menu_prophecy_defaults] failed to instantiate WaveRewardMenu")
		quit(1)
		return
	get_root().add_child(menu)
	call_deferred("_run_test", menu)


func _run_test(menu: WaveRewardMenu) -> void:
	menu.open([], 1, true)
	await process_frame

	if menu.cards_container == null:
		push_error("[test_wave_reward_menu_prophecy_defaults] cards_container is null")
		quit(1)
		return

	var cards := menu.cards_container.get_children()
	if cards.size() != 4:
		push_error("[test_wave_reward_menu_prophecy_defaults] expected 4 default prophecy cards for level 1, got %d" % cards.size())
		quit(1)
		return

	var joined := ""
	for child in cards:
		var card := child as WaveRewardCard
		if card == null or card.label == null:
			continue
		joined += card.label.text + "\n"

	if joined.find("Denarii 10") == -1:
		push_error("[test_wave_reward_menu_prophecy_defaults] missing Denarii 10 card in level 1 default bundle")
		quit(1)
		return
	if joined.find("Levy Barracks") == -1:
		push_error("[test_wave_reward_menu_prophecy_defaults] missing Levy Barracks card in level 1 default bundle")
		quit(1)
		return
	if joined.find("Basic Production") == -1:
		push_error("[test_wave_reward_menu_prophecy_defaults] missing Basic Production card in level 1 default bundle")
		quit(1)
		return
	if joined.find("Prophecy") == -1:
		push_error("[test_wave_reward_menu_prophecy_defaults] missing Prophecy card in level 1 default bundle")
		quit(1)
		return

	print("[test_wave_reward_menu_prophecy_defaults] PASS")
	quit(0)
