extends RefCounted
class_name ArtifactCatalog

const RARITY_BASIC := "basic"
const RARITY_LEGENDARY := "legendary"

const ALL := {
	"ancestral_power": {"id":"ancestral_power","display_name":"Ancestral Power","rarity":RARITY_LEGENDARY,"description":"Damage dealt by spells +100%.","implemented":true,"effect_kind":"spell_damage_percent","effect_value":1.0,"effect_resource_id":"","icon":"res://assets/artefacts/1.png"},
	"ancient_pact": {"id":"ancient_pact","display_name":"Ancient Pact","rarity":RARITY_BASIC,"description":"When your castle reaches 0 HP, it heals to 20 HP and all enemies are stunned for 7 seconds. Can only be used once.","implemented":true,"effect_kind":"on_castle_zero_hp_heal_and_stun_once","effect_value":20,"effect_resource_id":"","icon":"res://assets/artefacts/2.png"},
	"ball_of_yarn": {"id":"ball_of_yarn","display_name":"Ball of Yarn","rarity":RARITY_BASIC,"description":"Resources are produced 10% faster.","implemented":true,"effect_kind":"resource_production_speed_percent","effect_value":0.10,"effect_resource_id":"","icon":"res://assets/artefacts/3.png"},
	"bandage_of_dexterity": {"id":"bandage_of_dexterity","display_name":"Bandage of Dexterity","rarity":RARITY_BASIC,"description":"All units receive +4% chance of evading attacks. After evading an attack, units gain a temporary 50% damage bonus.","implemented":true,"effect_kind":"friendly_evasion_chance","effect_value":0.04,"effect_resource_id":"","icon":"res://assets/artefacts/4.png"},
	"blade_of_vengeance": {"id":"blade_of_vengeance","display_name":"Blade of Vengeance","rarity":RARITY_BASIC,"description":"When your troops die, a blade is sent flying into the enemy, dealing 50 damage.","implemented":true,"effect_kind":"on_troop_died_delayed_blade_strike","effect_value":50,"effect_resource_id":"","icon":"res://assets/artefacts/5.png"},
	"blood_and_wine_amphora": {"id":"blood_and_wine_amphora","display_name":"Blood and Wine Amphora","rarity":RARITY_BASIC,"description":"Gain 2 Wine when you kill an enemy.","implemented":true,"effect_kind":"on_enemy_killed_add_resource","effect_value":2,"effect_resource_id":"wine","icon":"res://assets/artefacts/6.png"},
	"bloodbound_brick": {"id":"bloodbound_brick","display_name":"Bloodbound Brick","rarity":RARITY_BASIC,"description":"Your castle gains 1 HP whenever your troops die.","implemented":true,"effect_kind":"on_troop_died_heal_castle","effect_value":1,"effect_resource_id":"","icon":"res://assets/artefacts/7.png"},
	"bottomless_jug": {"id":"bottomless_jug","display_name":"Bottomless Jug","rarity":RARITY_BASIC,"description":"Receive 1000 Water upon picking up this artifact.","implemented":true,"effect_kind":"on_pickup_add_resource","effect_value":1000,"effect_resource_id":"water","icon":"res://assets/artefacts/9.png"},
	"broken_penny": {"id":"broken_penny","display_name":"Broken Penny","rarity":RARITY_BASIC,"description":"Gain 3 Gold for each point of damage dealt to your castle.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/10.png"},
	"cheaper_housing": {"id":"cheaper_housing","display_name":"Cheaper Housing","rarity":RARITY_BASIC,"description":"-25% to the construction cost of all buildings.","implemented":true,"effect_kind":"build_cost_multiplier","effect_value":0.75,"effect_resource_id":"","icon":"res://assets/artefacts/11.png"},
	"chi_fan": {"id":"chi_fan","display_name":"Chi Fan","rarity":RARITY_LEGENDARY,"description":"Increases your units' bonus HP by 5 HP each time you use a spell.","implemented":true,"effect_kind":"troop_all_hp_flat_per_resolved_spell_cast","effect_value":5,"effect_resource_id":"","icon":"res://assets/artefacts/12.png"},
	"clay_treasure": {"id":"clay_treasure","display_name":"Clay Treasure","rarity":RARITY_BASIC,"description":"Producing 1000 clay after equipping this artifact grants a Legendary Artifact.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/13.png"},
	"comfortable_handle": {"id":"comfortable_handle","display_name":"Comfortable Handle","rarity":RARITY_BASIC,"description":"All Wells have a 10% chance of producing 1 wood.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/14.png"},
	"comfy_bed": {"id":"comfy_bed","display_name":"Comfy Bed","rarity":RARITY_LEGENDARY,"description":"Increases all troop buildings' unit capacity by 1.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/15.png"},
	"crystal_mask": {"id":"crystal_mask","display_name":"Crystal Mask","rarity":RARITY_BASIC,"description":"Gain 1 Crystal when you kill an enemy.","implemented":true,"effect_kind":"on_enemy_killed_add_resource","effect_value":1,"effect_resource_id":"crystal","icon":"res://assets/artefacts/16.png"},
	"cupbearers_vessel": {"id":"cupbearers_vessel","display_name":"Cupbearer's Vessel","rarity":RARITY_BASIC,"description":"Receive 1 Wine for each Well or Big Well in your castle every 10 seconds.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/17.png"},
	"dead_rat": {"id":"dead_rat","display_name":"Dead Rat","rarity":RARITY_BASIC,"description":"Receive 150 Meat upon picking up this artifact.","implemented":true,"effect_kind":"on_pickup_add_resource","effect_value":150,"effect_resource_id":"meat","icon":"res://assets/artefacts/18.png"},
	"dummy_target": {"id":"dummy_target","display_name":"Dummy Target","rarity":RARITY_BASIC,"description":"Troops are produced 20% faster.","implemented":true,"effect_kind":"unit_production_speed_percent","effect_value":0.20,"effect_resource_id":"","icon":"res://assets/artefacts/20.png"},
	"emerald_shield": {"id":"emerald_shield","display_name":"Emerald Shield","rarity":RARITY_BASIC,"description":"Increases max castle HP by 30.","implemented":true,"effect_kind":"castle_max_hp_bonus","effect_value":30,"effect_resource_id":"","icon":"res://assets/artefacts/21.png"},
	"enchanted_totem": {"id":"enchanted_totem","display_name":"Enchanted Totem","rarity":RARITY_BASIC,"description":"Places a seal on 2 tiles.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/22.png"},
	"enchanted_vial": {"id":"enchanted_vial","display_name":"Enchanted Vial","rarity":RARITY_BASIC,"description":"Receive 250 Wine upon picking up this artifact.","implemented":true,"effect_kind":"on_pickup_add_resource","effect_value":250,"effect_resource_id":"wine","icon":"res://assets/artefacts/23.png"},
	"excavation_stone": {"id":"excavation_stone","display_name":"Excavation Stone","rarity":RARITY_BASIC,"description":"Get 90 resources of your choice 3 times.","implemented":true,"effect_kind":"on_pickup_queue_resource_choice","effect_value":90,"effect_count":3,"effect_resource_id":"","icon":"res://assets/artefacts/24.png"},
	"eye_of_the_swarm": {"id":"eye_of_the_swarm","display_name":"Eye of the Swarm","rarity":RARITY_BASIC,"description":"Damage dealt by your troops is increased by 20%.","implemented":true,"effect_kind":"troop_all_damage_percent","effect_value":0.20,"effect_resource_id":"","icon":"res://assets/artefacts/25.png"},
	"family_crossbow": {"id":"family_crossbow","display_name":"Family Crossbow","rarity":RARITY_BASIC,"description":"Receive temporary crossbowmen (2) at the start of every wave.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/26.png"},
	"filtered_fuel": {"id":"filtered_fuel","display_name":"Filtered Fuel","rarity":RARITY_BASIC,"description":"Each 1 water produced has a 4% chance of producing 1 fuel.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/27.png"},
	"flour_deity": {"id":"flour_deity","display_name":"Flour Deity","rarity":RARITY_LEGENDARY,"description":"Every 1 flour produced increases all player units' HP by 0.05%.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/28.png"},
	"frag_bomb": {"id":"frag_bomb","display_name":"Frag Bomb","rarity":RARITY_BASIC,"description":"Damage dealt by attacking buildings is increased by 25%.","implemented":true,"effect_kind":"attacking_building_damage_percent","effect_value":0.25,"effect_resource_id":"","icon":"res://assets/artefacts/29.png"},
	"free_coupon": {"id":"free_coupon","display_name":"Free Coupon","rarity":RARITY_BASIC,"description":"Grants a 100% discount for one item at the Trader.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/30.png"},
	"free_housing": {"id":"free_housing","display_name":"Free Housing","rarity":RARITY_BASIC,"description":"Upon constructing the next 3 buildings, all resources are returned.","implemented":true,"effect_kind":"build_cost_refund_full_next_n","effect_value":3,"effect_resource_id":"","icon":"res://assets/artefacts/31.png"},
	"garland": {"id":"garland","display_name":"Garland","rarity":RARITY_BASIC,"description":"Receive 30 of each resource.","implemented":true,"effect_kind":"on_pickup_add_all_resources","effect_value":30,"effect_resource_id":"","icon":"res://assets/artefacts/32.png"},
	"golden_arrow": {"id":"golden_arrow","display_name":"Golden Arrow","rarity":RARITY_BASIC,"description":"Enemies are damaged for 10% of their max HP after introduction.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/33.png"},
	"golden_ball": {"id":"golden_ball","display_name":"Golden Ball","rarity":RARITY_BASIC,"description":"Heal your castle for 10 HP when a production building is depleted. Can be used 5 times.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/34.png"},
	"golden_bull": {"id":"golden_bull","display_name":"Golden Bull","rarity":RARITY_BASIC,"description":"Receive 25 Wheat at the start of each wave.","implemented":true,"effect_kind":"on_wave_started_add_resource","effect_value":25,"effect_resource_id":"wheat","icon":"res://assets/artefacts/35.png"},
	"golden_wings": {"id":"golden_wings","display_name":"Golden Wings","rarity":RARITY_BASIC,"description":"Flying troops gain a 30% boost to attack speed and move speed.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/36.png"},
	"hand_of_the_avenged": {"id":"hand_of_the_avenged","display_name":"Hand of the Avenged","rarity":RARITY_BASIC,"description":"When one of your troops dies, a random unit of yours becomes enraged, receiving boosts to attack and movement speed.","implemented":true,"effect_kind":"on_troop_died_random_friendly_enrage","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/37.png"},
	"healing_banner": {"id":"healing_banner","display_name":"Healing Banner","rarity":RARITY_BASIC,"description":"Gives a 25% chance of friendly units leaving a lesser healing pool under them upon death.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/38.png"},
	"hearty_borscht": {"id":"hearty_borscht","display_name":"Hearty Borscht","rarity":RARITY_LEGENDARY,"description":"Increases unit limit by 6.","implemented":true,"effect_kind":"unit_limit_bonus","effect_value":6,"effect_resource_id":"","icon":"res://assets/artefacts/39.png"},
	"homemade_fireworks": {"id":"homemade_fireworks","display_name":"Homemade Fireworks","rarity":RARITY_BASIC,"description":"Receive a Fireworks spell every 3 waves.","implemented":true,"effect_kind":"on_wave_started_add_spell_every_n","effect_value":1,"effect_resource_id":"","effect_spell_id":"fireworks","effect_spell_amount":1,"effect_every_n_waves":3,"icon":"res://assets/artefacts/40.png"},
	"indescribable_figurine": {"id":"indescribable_figurine","display_name":"Indescribable Figurine","rarity":RARITY_BASIC,"description":"When your troop falls in battle, a dreadful creature will rise from their remains to fight for you. Has a cooldown of 140 seconds.","implemented":true,"effect_kind":"on_troop_died_recruit_unit","effect_value":0,"effect_resource_id":"","effect_unit_id":"cacodaemon","icon":"res://assets/artefacts/41.png"},
	"indestructible_shield": {"id":"indestructible_shield","display_name":"Indestructible Shield","rarity":RARITY_BASIC,"description":"Gain a 10% chance that units will completely block damage.","implemented":true,"effect_kind":"friendly_full_damage_block_chance","effect_value":0.10,"effect_resource_id":"","icon":"res://assets/artefacts/42.png"},
	"invigorating_nectar": {"id":"invigorating_nectar","display_name":"Invigorating Nectar","rarity":RARITY_BASIC,"description":"Heals all of your troops for 15% of their max HP at the start of each wave.","implemented":true,"effect_kind":"on_wave_started_heal_all_troops_percent_max","effect_value":0.15,"effect_resource_id":"","icon":"res://assets/artefacts/43.png"},
	"iron_helmet": {"id":"iron_helmet","display_name":"Iron Helmet","rarity":RARITY_BASIC,"description":"Increases max unit HP by 30.","implemented":true,"effect_kind":"troop_all_hp_flat","effect_value":30,"effect_resource_id":"","icon":"res://assets/artefacts/44.png"},
	"iron_hoe": {"id":"iron_hoe","display_name":"Iron Hoe","rarity":RARITY_BASIC,"description":"Increases production limits for starter buildings by 100%.","implemented":true,"effect_kind":"starter_building_production_limit_percent","effect_value":1.0,"effect_resource_id":"","icon":"res://assets/artefacts/45.png"},
	"mages_notebook": {"id":"mages_notebook","display_name":"Mage's Notebook","rarity":RARITY_BASIC,"description":"Gain a Spell of your choice 2 times.","implemented":true,"effect_kind":"on_pickup_open_spell_choice","effect_value":2,"effect_resource_id":"","effect_legendary_only":false,"icon":"res://assets/artefacts/46.png"},
	"mages_robe": {"id":"mages_robe","display_name":"Mage's Robe","rarity":RARITY_BASIC,"description":"Every Arcane unit on the battlefield provides a 3% boost to spell damage dealt.","implemented":true,"effect_kind":"spell_damage_percent_per_class_unit_on_field","effect_value":0.03,"effect_resource_id":"","effect_unit_class":"arcane","icon":"res://assets/artefacts/47.png"},
	"magic_acorn": {"id":"magic_acorn","display_name":"Magic Acorn","rarity":RARITY_BASIC,"description":"Producing 1000 wood after equipping this artifact grants an extra 500 wood.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/48.png"},
	"magic_prism": {"id":"magic_prism","display_name":"Magic Prism","rarity":RARITY_BASIC,"description":"Each Spell you cast has a 30% chance of being cast twice.","implemented":true,"effect_kind":"spell_double_cast_chance","effect_value":0.3,"effect_resource_id":"","icon":"res://assets/artefacts/49.png"},
	"masons_scroll": {"id":"masons_scroll","display_name":"Mason's Scroll","rarity":RARITY_BASIC,"description":"Heal your castle for 3 HP each time you use a Spell.","implemented":true,"effect_kind":"on_spell_cast_heal_castle","effect_value":3,"effect_resource_id":"","icon":"res://assets/artefacts/50.png"},
	"means_of_production": {"id":"means_of_production","display_name":"Means of Production","rarity":RARITY_BASIC,"description":"Receive all basic production buildings: Wheat Field, Sawmill, Iron Mine & Clay Mine.","implemented":true,"effect_kind":"on_pickup_add_building_recipes","effect_value":1,"effect_resource_id":"","effect_building_ids":["wheat_field","sawmill","iron_mine","clay_mine"],"icon":"res://assets/artefacts/51.png"},
	"medal": {"id":"medal","display_name":"Medal","rarity":RARITY_LEGENDARY,"description":"Increases max unit HP by 75.","implemented":true,"effect_kind":"troop_all_hp_flat","effect_value":75,"effect_resource_id":"","icon":"res://assets/artefacts/52.png"},
	"memento_mori": {"id":"memento_mori","display_name":"Memento Mori","rarity":RARITY_BASIC,"description":"All Rider units passively gain 1.0 HP/second.","implemented":true,"effect_kind":"periodic_class_regen_hp_per_sec","effect_value":1.0,"effect_resource_id":"","effect_period":1.0,"effect_unit_class":"rider","icon":"res://assets/artefacts/53.png"},
	"metal_mask": {"id":"metal_mask","display_name":"Metal Mask","rarity":RARITY_BASIC,"description":"Gain 3 Metal when you kill an enemy.","implemented":true,"effect_kind":"on_enemy_killed_add_resource","effect_value":3,"effect_resource_id":"metal","icon":"res://assets/artefacts/54.png"},
	"miners_lamp": {"id":"miners_lamp","display_name":"Miner's Lamp","rarity":RARITY_BASIC,"description":"Receive 25 Metal at the start of each wave.","implemented":true,"effect_kind":"on_wave_started_add_resource","effect_value":25,"effect_resource_id":"metal","icon":"res://assets/artefacts/55.png"},
	"moon_talisman": {"id":"moon_talisman","display_name":"Moon Talisman","rarity":RARITY_BASIC,"description":"Healer Mages (3) join you each time you upgrade your gaze.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/56.png"},
	"mystic_stone": {"id":"mystic_stone","display_name":"Mystic Stone","rarity":RARITY_BASIC,"description":"Every 1 second, a random enemy is dealt 12 damage.","implemented":true,"effect_kind":"periodic_random_enemy_damage","effect_value":12,"effect_resource_id":"","effect_period":1.0,"icon":"res://assets/artefacts/57.png"},
	"mystic_tome": {"id":"mystic_tome","display_name":"Mystic Tome","rarity":RARITY_BASIC,"description":"Receive 4 random spells upon picking up this artifact.","implemented":true,"effect_kind":"on_pickup_add_random_spells","effect_value":4,"effect_resource_id":"","effect_include_legendary":true,"icon":"res://assets/artefacts/58.png"},
	"nutritious_fruit": {"id":"nutritious_fruit","display_name":"Nutritious Fruit","rarity":RARITY_BASIC,"description":"All troops' HP is increased by 20%.","implemented":true,"effect_kind":"troop_all_hp_percent","effect_value":0.20,"effect_resource_id":"","icon":"res://assets/artefacts/60.png"},
	"old_dice": {"id":"old_dice","display_name":"Old Dice","rarity":RARITY_BASIC,"description":"Receive 40 random basic resources at the start of each wave.","implemented":true,"effect_kind":"on_wave_started_add_random_basic_resource","effect_value":40,"effect_resource_id":"","icon":"res://assets/artefacts/61.png"},
	"piggy_bank": {"id":"piggy_bank","display_name":"Piggy Bank","rarity":RARITY_BASIC,"description":"When constructing buildings, 10% of resources are returned.","implemented":true,"effect_kind":"build_cost_refund_percent","effect_value":0.1,"effect_resource_id":"","icon":"res://assets/artefacts/62.png"},
	"poor_mans_relic": {"id":"poor_mans_relic","display_name":"Poor Man's Relic","rarity":RARITY_BASIC,"description":"Every Grunt unit on the battlefield get a 2% boost of HP and a 3% boost to damage for other Grunt units.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/63.png"},
	"porcelain_chip": {"id":"porcelain_chip","display_name":"Porcelain Chip","rarity":RARITY_BASIC,"description":"Receive 25 Clay at the start of each wave.","implemented":true,"effect_kind":"on_wave_started_add_resource","effect_value":25,"effect_resource_id":"clay","icon":"res://assets/artefacts/64.png"},
	"prospectors_map": {"id":"prospectors_map","display_name":"Prospector's Map","rarity":RARITY_BASIC,"description":"Receive 150 Fuel upon picking up this artifact.","implemented":true,"effect_kind":"on_pickup_add_resource","effect_value":150,"effect_resource_id":"fuel","icon":"res://assets/artefacts/65.png"},
	"rams_horn": {"id":"rams_horn","display_name":"Ram's Horn","rarity":RARITY_BASIC,"description":"When you kill an enemy, a random unit of yours is healed for 20% of their max health.","implemented":true,"effect_kind":"on_enemy_killed_heal_random_troop_percent_max","effect_value":0.20,"effect_resource_id":"","icon":"res://assets/artefacts/66.png"},
	"red_eye": {"id":"red_eye","display_name":"Red Eye","rarity":RARITY_BASIC,"description":"All buildings work 5% faster.","implemented":true,"effect_kind":"all_production_speed_percent","effect_value":0.05,"effect_resource_id":"","icon":"res://assets/artefacts/67.png"},
	"royal_crown": {"id":"royal_crown","display_name":"Royal Crown","rarity":RARITY_BASIC,"description":"Receive 5 Fireworks upon picking up this artifact.","implemented":true,"effect_kind":"on_pickup_add_spell","effect_value":5,"effect_resource_id":"","effect_spell_id":"fireworks","icon":"res://assets/artefacts/68.png"},
	"royal_order": {"id":"royal_order","display_name":"Royal Order","rarity":RARITY_BASIC,"description":"Producing 1000 crystals after equipping this artifact grants 3 Legendary Spells.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/69.png"},
	"royal_rune": {"id":"royal_rune","display_name":"Royal Rune","rarity":RARITY_LEGENDARY,"description":"Reduces ALL King's Abilities cooldown by 25%.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/70.png"},
	"rune_shard_red": {"id":"rune_shard_red","display_name":"Rune Shard (Red)","rarity":RARITY_BASIC,"description":"Reduces the first King's Ability cooldown by 25%.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/71.png"},
	"rune_shard_blue": {"id":"rune_shard_blue","display_name":"Rune Shard (Blue)","rarity":RARITY_BASIC,"description":"Reduces the second King's Ability cooldown by 25%.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/72.png"},
	"rune_shard_green": {"id":"rune_shard_green","display_name":"Rune Shard (Green)","rarity":RARITY_BASIC,"description":"Reduces the third King's Ability cooldown by 25%.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/73.png"},
	"rusty_bell": {"id":"rusty_bell","display_name":"Rusty Bell","rarity":RARITY_LEGENDARY,"description":"Receive temporary Goose Riders (2) at the start of every wave.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/74.png"},
	"samurai_helm": {"id":"samurai_helm","display_name":"Samurai Helm","rarity":RARITY_BASIC,"description":"Warrior troops receive a 10% boost to damage, HP, and attack speed.","implemented":true,"effect_kind":"samurai_helm_bundle","effect_value":0.10,"effect_resource_id":"","effect_unit_class":"warrior","icon":"res://assets/artefacts/76.png"},
	"scarecrow_hat": {"id":"scarecrow_hat","display_name":"Scarecrow Hat","rarity":RARITY_BASIC,"description":"When one of your troops die, an explosive scarecrow will be created in its place. Has a cooldown of 40 seconds.","implemented":true,"effect_kind":"on_troop_died_spawn_scarecrow_effect","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/77.png"},
	"scribes_quill": {"id":"scribes_quill","display_name":"Scribe's Quill","rarity":RARITY_BASIC,"description":"Receive buildings: Magic School, Magic College & Archmage's University.","implemented":true,"effect_kind":"on_pickup_add_building_recipes","effect_value":1,"effect_resource_id":"","effect_building_ids":["magic_school","magic_college","archmages_university"],"icon":"res://assets/artefacts/78.png"},
	"second_chance": {"id":"second_chance","display_name":"Second Chance","rarity":RARITY_BASIC,"description":"Grants temporary units a 50% chance of being re-summoned.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/79.png"},
	"spellweavers_book": {"id":"spellweavers_book","display_name":"Spellweaver's Book","rarity":RARITY_BASIC,"description":"Damage dealt by spells +25%.","implemented":true,"effect_kind":"spell_damage_percent","effect_value":0.25,"effect_resource_id":"","icon":"res://assets/artefacts/80.png"},
	"stone_gaze": {"id":"stone_gaze","display_name":"Stone Gaze","rarity":RARITY_BASIC,"description":"Central cell in the castle now works even when you are not watching.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/81.png"},
	"strawberry_cocktail": {"id":"strawberry_cocktail","display_name":"Strawberry Cocktail","rarity":RARITY_BASIC,"description":"Provides 7 morale.","implemented":true,"effect_kind":"morale_flat_bonus","effect_value":7,"effect_resource_id":"","icon":"res://assets/artefacts/82.png"},
	"stunning_mace": {"id":"stunning_mace","display_name":"Stunning Mace","rarity":RARITY_BASIC,"description":"Champion units stun an enemy once every 20 attacks.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/83.png"},
	"sturdy_candle": {"id":"sturdy_candle","display_name":"Sturdy Candle","rarity":RARITY_BASIC,"description":"Increases the lifetime of all temporary units by 3 times.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/84.png"},
	"super_metal": {"id":"super_metal","display_name":"Super Metal","rarity":RARITY_LEGENDARY,"description":"Every 1 metal produced increases all player units' damage by 0.1%. Gives a Forge.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/85.png"},
	"suspicious_pile": {"id":"suspicious_pile","display_name":"Suspicious Pile","rarity":RARITY_BASIC,"description":"Allows clay, grapes and crystal to be traded at markets.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/86.png"},
	"sweeping_blade": {"id":"sweeping_blade","display_name":"Sweeping Blade","rarity":RARITY_BASIC,"description":"Sawmills and trees damage enemies when they are working.","implemented":true,"effect_kind":"on_working_building_damage_enemies","effect_value":0,"effect_resource_id":"","effect_building_ids":["tree","sawmill"],"icon":"res://assets/artefacts/87.png"},
	"tasty_fruit": {"id":"tasty_fruit","display_name":"Tasty Fruit","rarity":RARITY_BASIC,"description":"Increases unit limit by 2.","implemented":true,"effect_kind":"unit_limit_bonus","effect_value":2,"effect_resource_id":"","icon":"res://assets/artefacts/88.png"},
	"tax_decree": {"id":"tax_decree","display_name":"Tax Decree","rarity":RARITY_BASIC,"description":"Receive 250 Flour upon picking up this artifact.","implemented":true,"effect_kind":"on_pickup_add_resource","effect_value":250,"effect_resource_id":"flour","icon":"res://assets/artefacts/89.png"},
	"trusty_compass": {"id":"trusty_compass","display_name":"Trusty Compass","rarity":RARITY_LEGENDARY,"description":"Places a Legendary Seal on 3 tiles.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/91.png"},
	"twin_projectiles": {"id":"twin_projectiles","display_name":"Twin Projectiles","rarity":RARITY_BASIC,"description":"Ranged troops receive a 4% chance of shooting an additional projectile for each Warrior ally.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/93.png"},
	"vine_mask": {"id":"vine_mask","display_name":"Vine Mask","rarity":RARITY_BASIC,"description":"Gain 4 Grapes when you kill an enemy.","implemented":true,"effect_kind":"on_enemy_killed_add_resource","effect_value":4,"effect_resource_id":"grapes","icon":"res://assets/artefacts/96.png"},
	"voodoo_beads": {"id":"voodoo_beads","display_name":"Voodoo Beads","rarity":RARITY_BASIC,"description":"When choosing a reward, your first reroll is free.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/97.png"},
	"walrus_mask": {"id":"walrus_mask","display_name":"Walrus Mask","rarity":RARITY_BASIC,"description":"Damage to enemies from units is increased by 10%.","implemented":true,"effect_kind":"friendly_unit_damage_percent","effect_value":0.10,"effect_resource_id":"","icon":"res://assets/artefacts/98.png"},
	"wine_cup": {"id":"wine_cup","display_name":"Wine Cup","rarity":RARITY_BASIC,"description":"Every 30 wine spent permanently grants 1 morale.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/99.png"},
	"wood_pile": {"id":"wood_pile","display_name":"Wood Pile","rarity":RARITY_BASIC,"description":"Receive 25 Wood at the start of each wave.","implemented":true,"effect_kind":"on_wave_started_add_resource","effect_value":25,"effect_resource_id":"wood","icon":"res://assets/artefacts/100.png"},
	"wooden_horseshoe": {"id":"wooden_horseshoe","display_name":"Wooden Horseshoe","rarity":RARITY_BASIC,"description":"Gain 1 Wood when you kill an enemy.","implemented":true,"effect_kind":"on_enemy_killed_add_resource","effect_value":1,"effect_resource_id":"wood","icon":"res://assets/artefacts/101.png"},
	"wooden_key": {"id":"wooden_key","display_name":"Wooden Key","rarity":RARITY_BASIC,"description":"Gain 3 Wood when you create a unit.","implemented":true,"effect_kind":"","effect_value":0,"effect_resource_id":"","icon":"res://assets/artefacts/102.png"},
}

static func has_def(artifact_id: String) -> bool:
	return ALL.has(artifact_id)

static func get_def(artifact_id: String) -> Dictionary:
	return ALL.get(artifact_id, {})

static func get_all_ids() -> Array:
	return get_all_ids_sorted()

static func get_all_ids_sorted() -> Array:
	var ids: Array = ALL.keys()
	ids.sort_custom(func(a: String, b: String) -> bool:
		var def_a: Dictionary = ALL.get(a, {})
		var def_b: Dictionary = ALL.get(b, {})
		var rarity_a: String = str(def_a.get("rarity", ""))
		var rarity_b: String = str(def_b.get("rarity", ""))
		var rank_a := 0
		var rank_b := 0
		if rarity_a == RARITY_LEGENDARY:
			rank_a = 1
		if rarity_b == RARITY_LEGENDARY:
			rank_b = 1
		if rank_a != rank_b:
			return rank_a < rank_b

		var name_a: String = str(def_a.get("display_name", a)).to_lower()
		var name_b: String = str(def_b.get("display_name", b)).to_lower()
		if name_a != name_b:
			return name_a < name_b
		return a < b
	)
	return ids

static func get_all_defs() -> Array:
	var out: Array = []
	for artifact_id in get_all_ids_sorted():
		out.append(ALL.get(artifact_id, {}))
	return out

static func is_player_available(artifact_id: String) -> bool:
	var def := get_def(artifact_id)
	if def.is_empty():
		return false
	return bool(def.get("implemented", false))

static func get_player_available_ids_sorted() -> Array[String]:
	var ids: Array[String] = []
	for raw_id in get_all_ids_sorted():
		var artifact_id := String(raw_id)
		if is_player_available(artifact_id):
			ids.append(artifact_id)
	return ids

static func get_defs_by_rarity(rarity: String) -> Array:
	var out: Array = []
	for def in ALL.values():
		if def.get("rarity", "") == rarity:
			out.append(def)
	return out
