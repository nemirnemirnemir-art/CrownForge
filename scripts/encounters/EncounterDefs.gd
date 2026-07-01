class_name EncounterDefs
extends RefCounted


static func get_standard_encounter_ids() -> Array[String]:
	return [
		"befitting_a_king",
		"blazing_orb",
		"bull_in_a_bottle",
		"cursed_crown",
		"devil_you_know",
		"dish_best_served_warm",
		"drought",
		"flames_of_reckoning",
		"forest_king",
		"forest_spirits",
		"freezing_forests",
		"happy_accident",
		"sits_around_castle",
		"invitation",
		"nap_too_far",
		"male_loneliness_solution",
		"stoned_audience",
		"suspiciously_cozy_cat",
		"came_unprepared",
		"boomstick",
		"tis_but_a_scratch",
		"spite_your_face",
		"tome_questionable_wisdom",
		"unfortunate_jump",
		"whirlwind",
	]


static func get_encounter(encounter_id: String) -> Dictionary:
	var all: Dictionary = _build_standard_encounters()
	var value: Variant = all.get(encounter_id, null)
	if value == null or not (value is Dictionary):
		return {}
	return (value as Dictionary).duplicate(true)


static func _build_standard_encounters() -> Dictionary:
	return {
		"befitting_a_king": _encounter("befitting_a_king", "Befitting a King", "Goblin emissary Farto offers peace in exchange for a truce — but granting it lets them regroup.", [
			_option("mercy_decree", "A King should be Merciful", [_effect_resource_add("steel", 100)]),
			_option("strong_hand", "A King should be Strong", [_effect_morale_add(10), _effect_spawn_enemy("goblin_pig", 20)]),
			_option("cunning_ploy", "A King should be Cunning", [_effect_troops_add("longbowman", 3)]),
		]),
		"blazing_orb": _encounter("blazing_orb", "The Blazing Orb", "A fiery orb crashes in a meadow; the court mage wants to study it, the bard is spreading panic.", [
			_option("change_the_tune", "Order the bard to change his tune", [_effect_troops_add("fire_mage", 3)]),
			_option("heat_bathhouse", "Use this artifact to heat the royal bathhouse", [_effect_ui_action("open_reward_menu_building_upgrades", 2, 75)]),
			_option("mages_study", "Let your mages study it", [_effect_building_add("magic_college", 1), _effect_resource_add("crystal", 100)]),
		]),
		"bull_in_a_bottle": _encounter("bull_in_a_bottle", "Bull in a Bottle", "The chief alchemist unveils a Potion of Bull's Energy — productivity skyrockets, but side effects are severe.", [
			_option("mass_production", "Greenlight mass production", [_effect_building_add("magic_college", 2), _effect_lose_troops(4)]),
			_option("strict_control", "Strictly control its usage", [_effect_resource_add("wood", 100), _effect_resource_add("grapes", 200)]),
			_option("military_application", "Look for a military application", [_effect_troops_add("swordsman", 5)]),
		]),
		"cursed_crown": _encounter("cursed_crown", "The Cursed Crown", "A dramatic crown found in the treasury — the court mage calls it powerful, the councillor calls it cursed.", [
			_option("destroy_it", "Destroy this fashion disaster", [_effect_ui_action("open_reward_menu_building_upgrades", 2, 50)]),
			_option("empower_madhouse", "Empower your Madhouse", [_effect_troops_add("madman", 4)]),
			_option("wear_it", "Wear it: superstitions be damned", [_effect_morale_add(7)]),
		]),
		"devil_you_know": _encounter("devil_you_know", "The Devil You Know", "Cultists have summoned El Diavolo — a demon you've \"collaborated\" with before.", [
			_option("sign_contract", "Offer him terms to kill the cultists", [_effect_troops_add("infernals", 4)]),
			_option("call_priests", "Summon priests to exorcize the demon", [_effect_troops_add("healer_mage", 2)]),
			_option("sell_souls", "\"El Diavolo, old pal! I have souls to sell you.\"", [_effect_resource_add("gold", 400), _effect_lose_troops(2)]),
		]),
		"dish_best_served_warm": _encounter("dish_best_served_warm", "A Dish Best Served...Warm?", "Battle mage Redrum presents his mother's sausage recipe at a cooking competition and demands your honest opinion.", [
			_option("praise_dish", "Compliment Redrum's dish extravagantly", [_effect_spell_add("healing_pool", 2)]),
			_option("royal_beheading", "To serve such an awful dish deserves a beheading!", [_effect_building_add("execution_ground", 1), _effect_troops_add("madman", 1)]),
			_option("fake_allergy", "Politely fake a magical food allergy", [_effect_ui_action("open_reward_menu_advanced_production")]),
		]),
		"drought": _encounter("drought", "Drought", "A starving peasant collapses in the throne room — fewer workers means a smaller crop.", [
			_option("noble_granaries", "Demand the nobility share their food", [_effect_resource_add("wheat", 250)]),
			_option("drain_moats", "Drain the moats for drinking water", [_effect_resource_add("wood", 150)]),
			_option("draw_curtains", "Draw the curtains", [_effect_resource_add("wine", 150)]),
		]),
		"flames_of_reckoning": _encounter("flames_of_reckoning", "The Flames of Reckoning", "A wildfire spreads from the forest, threatening fields and farms.", [
			_option("controlled_fire", "Control the spread, but no drastic measures", [_effect_resource_add("wood", 100)]),
			_option("rescue_villagers", "Save the villagers, at all costs", [_effect_troops_add("peasant", 3), _effect_resource_add("wood", 50)]),
			_option("let_it_burn", "What a beautiful sight. Let it all burn!", [_effect_ui_action("open_reward_menu_troop_bonuses")]),
		]),
		"forest_king": _encounter("forest_king", "The Forest King", "A towering boar calling himself King of the Forest leads an army of sentient mushrooms to protest your logging.", [
			_option("renewable_forestry", "Issue a Green Renewable Forestry decree", [_effect_resource_add("wood", 100)]),
			_option("hunt_boar", "\"I'm the only King here! Kill the boar!\"", [_effect_resource_add("wheat", 100)]),
			_option("mushroom_dream", "Talking Mushrooms? This must be a dream", [_effect_troops_add("mushroom_warrior", 2)]),
		]),
		"forest_spirits": _encounter("forest_spirits", "Forest Spirits", "Luminous forest spirits have been guiding subjects to bountiful berries — but more visitors may displease them.", [
			_option("tax_goods", "Tax the Forest Goods", [_effect_all_resources_add(10)]),
			_option("crystal_harvest", "Spirits make for good mana crystals...", [_effect_resource_add("crystal", 100)]),
			_option("spirit_pact", "Construct a shrine for the spirits", [_effect_building_add("magic_school", 1)]),
		]),
		"freezing_forests": _encounter("freezing_forests", "Freezing Forests", "An unprecedented cold has turned lumberjacks into popsicles; survivors demand health insurance and reasonable hours.", [
			_option("improve_quarters", "Improve their quarters", [_effect_spell_add("deforestation", 1)]),
			_option("introduce_shifts", "Allow more rest time by introducing shifts", [_effect_building_add("sawmill", 1)]),
			_option("send_soldiers", "Dispatch soldiers to... motivate them", [_effect_troops_add("swordsman", 2), _effect_resource_add("wood", 50)]),
		]),
		"happy_accident": _encounter("happy_accident", "A Happy Accident", "Crocodile eggs ordered for the moat turned out to be mermaid eggs — and mermaids aren't effective against goblins.", [
			_option("farm_ponds", "Place them in ponds near your farms", [_effect_open_building_upgrades()]),
			_option("sell_to_sultan", "Sell them to Sultan Saltyoldman II", [_effect_resource_add("gold", 100)]),
			_option("private_reserve", "Create a private reserve for them to reside", [_effect_max_hp_add(20)]),
		]),
		"sits_around_castle": _encounter("sits_around_castle", "He Sits Around the Castle", "Years of royal feasting have had consequences — the truth stares back from the gilded mirror.", [
			_option("new_trend", "Just call it a new trend", [_effect_building_add("hospital", 2), _effect_resource_lose("wheat", 30)]),
			_option("get_in_shape", "Get yourself in shape", [_effect_building_add("arena", 1), _effect_resource_add("wood", 70)]),
			_option("break_mirrors", "Destroy all the mirrors in the kingdom", [_effect_resource_add("wine", 100)]),
		]),
		"invitation": _encounter("invitation", "The Invitation", "The Queen Mother invites her \"special little man\" to the annual boar hunt — a long journey away from the castle.", [
			_option("sell_invitation", "Sell the invitation", [_effect_denarii_add(50)]),
			_option("accept_invitation", "Accept the invitation", [_effect_all_resources_add(15)]),
			_option("local_hunt", "Propose a local goblin hunt instead", [_effect_ui_action("open_reward_menu_base_production", 2), _effect_spawn_enemy("wall_buster", 20)]),
		]),
		"nap_too_far": _encounter("nap_too_far", "A Nap Too Far", "A bold peasant is caught napping against a tree; the relaxation epidemic is spreading.", [
			_option("work_or_else", "Introduce a \"Work or Else\" policy", [_effect_spell_add("fireworks", 5)]),
			_option("lead_by_example", "Lead by example", [_effect_open_building_upgrades()]),
			_option("try_magic", "Try using magic", [_effect_ui_action("open_reward_menu_spells", 3)]),
		]),
		"male_loneliness_solution": _encounter("male_loneliness_solution", "The Solution for Male Loneliness", "Sir Grimgar, transformed into stone by a curse, is spreading seditious philosophical questions among the troops.", [
			_option("hire_mage", "Hire a mage to lift the curse", [_effect_morale_add(10)]),
			_option("royal_statue", "Officially declare him a Royal Statue", [_effect_building_add("hero_statue", 1), _effect_resource_add("wood", 70)]),
			_option("knight_solidarity", "Order your knights to join him in solidarity", [_effect_troops_add("black_swordsman", 1)]),
		]),
		"stoned_audience": _encounter("stoned_audience", "A Stoned Audience", "Medusa's concert turned half the village into garden decorations; agricultural output will suffer.", [
			_option("break_curse", "Attempt to break the curse with magic", [_effect_ui_action("open_reward_menu_legendary_spells"), _effect_resource_add("ore", 150)]),
			_option("slay_medusa", "Slay Medusa and weaponize her head", [_effect_ui_action("open_reward_menu_elite_barracks", 2)]),
			_option("peaceful_talk", "Negotiate peacefully with Medusa", [_effect_transmute("fuel"), _effect_ui_action("open_reward_menu_legendary_spells", 1)]),
		]),
		"suspiciously_cozy_cat": _encounter("suspiciously_cozy_cat", "A Suspiciously Cozy Cat", "A skeleton is found in a luxury armchair with a smug black cat on its lap — the man was alive hours ago.", [
			_option("adopt_cat", "She is adorable, adopt the cat", [_effect_all_resources_add(35)]),
			_option("brick_room", "Brick up the entire room with the cat inside", [_effect_resource_lose("wine", 50), _effect_gaze_upgrade()]),
			_option("magical_contract", "Form a magical contract with the cat", [_effect_spell_add("fireworks", 5)]),
		]),
		"came_unprepared": _encounter("came_unprepared", "They Came Unprepared", "The Ironfang Riders, led by Tharg the Conqueror, demand tributes of food, gold, and supplies for \"peace\".", [
			_option("strengthen_walls", "Let's see what they can do against our walls...", [_effect_max_hp_add(20)]),
			_option("full_gaze", "Unleash your full magical gaze", [_effect_ui_action("open_reward_menu_spells")]),
			_option("mud_bath", "Buy time to prepare a... special mud bath", [_effect_ui_action("open_reward_menu_artifacts", 1, 50)]),
		]),
		"boomstick": _encounter("boomstick", "This ... is my BOOMSTICK!", "An oddly dressed traveler bursts in brandishing a strange metallic weapon, claiming it destroys undead and dragons.", [
			_option("purchase_boomstick", "Purchase the traveler's Boomstick", [_effect_ui_action("open_reward_menu_troop_bonuses", 2)]),
			_option("behead_traveler", "Behead him for offending your royal presence!", [_effect_ui_action("open_reward_menu_building_upgrades", 2)]),
			_option("reality_secrets", "Fish for the secrets of reality-hopping magic", [_effect_building_add("tesla_tower", 2), _effect_resource_add("metal", 80)]),
		]),
		"tis_but_a_scratch": _encounter("tis_but_a_scratch", "Tis But a Scratch!", "The infamous Dark Knight blocks a strategic bridge, regenerating every limb and calling all injuries \"mere scratches\".", [
			_option("recruit_knight", "Attempt to recruit the knight", [_effect_troops_add("undead_bone_warrior", 1), _effect_morale_add(7)]),
			_option("build_detour", "Build a detour around the knight", [_effect_building_add("arena", 1), _effect_resource_add("wood", 60)]),
			_option("cleanse_knight", "Un-undead the Dark Knight", [_effect_troops_add("assassin", 1)]),
		]),
		"spite_your_face": _encounter("spite_your_face", "To Spite Your Face", "Western merchants return with rare goods — but an eager soldier sneezed on their spices and the chief merchant.", [
			_option("give_them_what_they_want", "Give them what they want", [_effect_resource_add("wine", 100)]),
			_option("favorable_trade", "Offer them favorable trade", [_effect_ui_action("open_reward_menu_artifacts")]),
			_option("outwit_merchant", "Try to outwit the merchant", [_effect_resource_add("metal", 110)]),
		]),
		"tome_questionable_wisdom": _encounter("tome_questionable_wisdom", "The Tome of Questionable Wisdom", "A sinister book titled \"100 Otherworldly Wisdoms from Friendly Eldritch Spirits\" was found near bloodstains in the woods.", [
			_option("peruse_tome", "Peruse the tome", [_effect_resource_lose("grapes", 50), _effect_gaze_upgrade()]),
			_option("sell_tome", "Sell the tome", [_effect_resource_add("gold", 100)]),
			_option("defile_tome", "Defile the tome", [_effect_morale_add(7)]),
		]),
		"unfortunate_jump": _encounter("unfortunate_jump", "An Unfortunate Jump", "Peasant Willard's Jump Test of the grain reserves ends with a sickening thud — the granaries are dangerously low.", [
			_option("blame_volunteer", "Blame the volunteer", [_effect_ui_action("open_reward_menu_base_production", 2)]),
			_option("blame_farmers", "Blame the farmers", [_effect_building_add("wheat_field", 1)]),
			_option("blame_method", "Blame the method", [_effect_resource_add("wheat", 100)]),
		]),
		"whirlwind": _encounter("whirlwind", "Whirlwind", "A tornado rages beyond the scout's position, flinging debris and Lord Gerald's horse.", [
			_option("save_families", "Tell your troops to save their families", [_effect_morale_add(10)]),
			_option("save_nobility", "Tell your servants to save the nobility", [_effect_resource_add("gold", 100), _effect_resource_add("wine", 150)]),
			_option("divine_will", "Do nothing: this is the divine will at work", [_effect_resource_add("wood", 700), _effect_morale_add(-8)]),
		]),
	}


static func _encounter(encounter_id: String, title: String, description: String, options: Array) -> Dictionary:
	return {
		"id": encounter_id,
		"title": title,
		"description": description,
		"options": options,
	}


static func _option(option_id: String, label: String, effects: Array, requirements: Dictionary = {}) -> Dictionary:
	return {
		"id": option_id,
		"label": label,
		"effects": effects,
		"requirements": requirements,
	}


static func _resource_requirements(resources: Dictionary, consume_on_select: bool = true) -> Dictionary:
	return {
		"resources": resources,
		"consume_on_select": consume_on_select,
	}


static func _effect_resource_add(resource_id: String, amount: int) -> Dictionary:
	return {
		"kind": "resource_add",
		"resource_id": resource_id,
		"amount": amount,
	}


static func _effect_denarii_add(amount: int) -> Dictionary:
	return {
		"kind": "denarii_add",
		"amount": amount,
	}


static func _effect_all_resources_add(amount: int) -> Dictionary:
	return {
		"kind": "all_resources_add",
		"amount": amount,
	}


static func _effect_resource_lose(resource_id: String, amount: int) -> Dictionary:
	return {
		"kind": "resource_lose",
		"resource_id": resource_id,
		"amount": amount,
	}


static func _effect_spell_add(spell_id: String, amount: int) -> Dictionary:
	return {
		"kind": "spell_add",
		"spell_id": spell_id,
		"amount": amount,
	}


static func _effect_spawn_enemy(enemy_id: String, amount: int) -> Dictionary:
	return {
		"kind": "spawn_enemy",
		"enemy_id": enemy_id,
		"amount": amount,
	}


static func _effect_lose_troops(amount: int, random: bool = true) -> Dictionary:
	return {
		"kind": "lose_troops",
		"amount": amount,
		"random": random,
	}


static func _effect_max_hp_add(amount: int) -> Dictionary:
	return {
		"kind": "max_hp_add",
		"amount": amount,
	}


static func _effect_transmute(target_resource: String) -> Dictionary:
	return {
		"kind": "transmute",
		"target_resource": target_resource,
	}


static func _effect_gaze_upgrade() -> Dictionary:
	return {
		"kind": "gaze_upgrade",
	}


static func _effect_open_building_upgrades() -> Dictionary:
	return _effect_ui_action("open_reward_menu_building_upgrades")


static func _effect_ui_action(action_id: String, count: int = 1, chance_percent: int = 100) -> Dictionary:
	return {
		"kind": "ui_action",
		"action_id": action_id,
		"count": count,
		"chance_percent": chance_percent,
	}


static func _effect_troops_add(troop_id: String, amount: int) -> Dictionary:
	return {
		"kind": "troops_add",
		"troop_id": troop_id,
		"amount": amount,
	}


static func _effect_morale_add(amount: int) -> Dictionary:
	return {
		"kind": "morale_add",
		"amount": amount,
	}


static func _effect_building_add(building_id: String, amount: int) -> Dictionary:
	return {
		"kind": "building_add",
		"building_id": building_id,
		"amount": amount,
	}
