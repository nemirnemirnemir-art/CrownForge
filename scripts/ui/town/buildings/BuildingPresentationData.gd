extends RefCounted
class_name BuildingPresentationData

const DATA := {
    "big_well": {
        "description": "Produces water.",
        "upgrades": [],
    },
    "grape_bushes": {
        "description": "Produces grapes.",
        "upgrades": [],
    },
    "small_wheat_field": {
        "description": "Produces wheat.",
        "upgrades": [],
    },
    "starter_clay_mine": {
        "description": "Produces clay.",
        "upgrades": [],
    },
    "starter_crystal_mine": {
        "description": "Produces crystals.",
        "upgrades": [],
    },
    "starter_gold_mine": {
        "description": "Produces gold.",
        "upgrades": [],
    },
    "starter_iron_mine": {
        "description": "Produces ore.",
        "upgrades": [],
    },
    "tree": {
        "description": "Produces wood.",
        "upgrades": [],
    },
    "well": {
        "description": "Produces water.",
        "upgrades": [],
    },
    "clay_mine": {
        "description": "Produces clay.",
        "upgrades": [
            {"name": "Zero Waste", "desc": "10% chance of repairing your castle for 1 HP with each production cycle."},
            {"name": "Clay Mine Production", "desc": "Boosts production by 35%."},
        ],
    },
    "crystal_mine": {
        "description": "Produces crystals.",
        "upgrades": [
            {"name": "Magic Aura", "desc": "Passively increases spell damage dealt by 10%."},
            {"name": "Crystal Mine Production", "desc": "Boosts production by 30%."},
        ],
    },
    "gold_mine": {
        "description": "Produces gold.",
        "upgrades": [
            {"name": "Rich Veins", "desc": "50% chance of receiving extra Gold 2 with each production cycle."},
            {"name": "Gold Mine Production", "desc": "Boosts production by 25%."},
        ],
    },
    "iron_mine": {
        "description": "Produces ore.",
        "upgrades": [
            {"name": "Troop Inspiration", "desc": "Passively increases damage dealt by and HP of Warrior troops by 10%."},
            {"name": "Iron Mine Production", "desc": "Boosts production by 30%."},
        ],
    },
    "sawmill": {
        "description": "Produces wood.",
        "upgrades": [
            {"name": "Sawmill Production", "desc": "Boosts production by 25%."},
            {"name": "Friendly Lumberjacks", "desc": "Provides a 20% boost to the production of neighbouring tiles."},
        ],
    },
    "vineyard": {
        "description": "Produces grapes.",
        "upgrades": [
            {"name": "Grape Varieties", "desc": "Each vineyard passively provides 5 morale."},
            {"name": "Vineyard Production", "desc": "Boosts production by 30%."},
        ],
    },
    "wheat_field": {
        "description": "Produces wheat.",
        "upgrades": [
            {"name": "Farm Production", "desc": "Boosts production by 30%."},
            {"name": "Gold Diggers", "desc": "25% chance of receiving extra Gold 1 with each production cycle."},
        ],
    },
    "animal_farm": {
        "description": "Produces meat.",
        "upgrades": [
            {"name": "Production Speed", "desc": "Boosts production by 30%."},
            {"name": "Troop Inspiration", "desc": "Passively increases damage dealt by and HP of Rider troops by 10%."},
        ],
    },
    "fishermans_hut": {
        "description": "Produces meat.",
        "upgrades": [
            {"name": "Production Speed", "desc": "Boosts production by 30%."},
            {"name": "Quality Lure", "desc": "50% chance of receiving extra Meat 2 with each production cycle."},
        ],
    },
    "forge": {
        "description": "Smelts ore into steel.",
        "upgrades": [
            {"name": "Efficient Processing", "desc": "Consumes Ore 2 to produce Steel 2."},
            {"name": "Troop Inspiration", "desc": "Passively increases damage dealt by and HP of Ranged troops by 10%."},
        ],
    },
    "fuel_pump": {
        "description": "Produces oil.",
        "upgrades": [
            {"name": "Production Speed", "desc": "Boosts production by 30%."},
            {"name": "Gifts of the Earth", "desc": "20% chance of producing a random extra resource."},
        ],
    },
    "market": {
        "description": "Enables trading of various resources.",
        "upgrades": [
            {"name": "Charismatic Traders", "desc": "Each active market provides 5 morale."},
            {"name": "Faster Trading", "desc": "Boosts production by 25%."},
        ],
    },
    "mill": {
        "description": "Makes flour out of wheat.",
        "upgrades": [
            {"name": "Efficient Processing", "desc": "Consumes Wheat 2 to produce Flour 2."},
            {"name": "Troop Inspiration", "desc": "Passively increases damage dealt by and HP of Flying troops by 10%."},
        ],
    },
    "winery": {
        "description": "Makes wine out of grapes.",
        "upgrades": [
            {"name": "Production Speed", "desc": "Boosts production by 30%."},
            {"name": "Wine for All", "desc": "50% chance of producing 1 extra wine."},
        ],
    },
    "small_peasants_hut": {
        "description": "Recruits weak peasants.",
        "upgrades": [],
    },
    "peasants_hut": {
        "description": "Recruits peasants. Higher capacity than the starter hut.",
        "upgrades": [
            {"name": "Capacity", "desc": "Increases capacity by 2."},
            {"name": "Insurance", "desc": "Upon a Peasant's death, you receive Gold 2."},
            {"name": "Peasants' power", "desc": "Increases Peasants' HP and damage dealt by 30%."},
        ],
    },
    "archery": {
        "description": "Recruits Crossbowmen.",
        "upgrades": [
            {"name": "Precise shots", "desc": "Archers deal double damage once every 5 attacks."},
            {"name": "Archers' capacity", "desc": "Increases capacity by 2."},
            {"name": "Stunning arrows", "desc": "Archers stun enemies at full HP for 2s."},
        ],
    },
    "gnome_dome": {
        "description": "Recruits Gnomes.",
        "upgrades": [
            {"name": "Refund", "desc": "Upon a Gnome's death, you receive 5 gold."},
            {"name": "Damage", "desc": "Increases damage dealt by gnomes by 100%."},
            {"name": "Capacity", "desc": "Increases capacity by 5."},
        ],
    },
    "hunters": {
        "description": "Produces Hunters that slow enemies.",
        "upgrades": [
            {"name": "Stinky nets", "desc": "Hunters poison enemies, dealing 10 bonus damage over time."},
            {"name": "Hunters' capacity", "desc": "Increases capacity by 2."},
        ],
    },
    "madhouse": {
        "description": "Recruits Madmen that use hit-and-run tactics.",
        "upgrades": [
            {"name": "Madman Evasion", "desc": "Grants Madmen a 35% evasion chance."},
            {"name": "Madman Capacity", "desc": "Increases capacity by 2."},
            {"name": "Alcohol Needles", "desc": "Madmen inflict drunk on enemies. Drunk enemies move slower and have trouble tracking targets."},
        ],
    },
    "militia_camp": {
        "description": "Recruits Militia and Brigade units.",
        "upgrades": [
            {"name": "Militia HP", "desc": "Increases militia HP by 50%."},
            {"name": "Militia capacity", "desc": "Increases capacity by 2."},
            {"name": "Mega dude", "desc": "Produces a MEGA militia after recruiting 4 base troops."},
        ],
    },
    "slingers_tree": {
        "description": "Recruits Slingers.",
        "upgrades": [
            {"name": "Slingers' capacity", "desc": "Increases capacity by 3."},
            {"name": "Heavy stones", "desc": "Slingers have 3% chance of stunning an enemy for 1s."},
            {"name": "Slingers' HP", "desc": "Increases Slingers' HP by 200%."},
        ],
    },
    "swordsmen_barracks": {
        "description": "Recruits Swordsmen.",
        "upgrades": [
            {"name": "Damage dealt by Swordsmen", "desc": "Increases damage dealt by swordsmen by 100%."},
            {"name": "Swordsmen's Capacity", "desc": "Increases capacity by 2."},
        ],
    },
    "whipmens_house": {
        "description": "Recruits Whipmen that buff allies' attack and movement speed.",
        "upgrades": [
            {"name": "Whipmen's capacity", "desc": "Increases capacity by 2."},
            {"name": "Whipmen's HP", "desc": "Increases Whipmen's HP by 400%."},
        ],
    },
    "academy_of_fire": {
        "description": "Recruits Fire Mages.",
        "upgrades": [
            {"name": "Combustion", "desc": "Fireballs set enemies on fire, dealing 6 bonus damage over time."},
            {"name": "Damage dealt by Mages", "desc": "Increases damage dealt by Fire Mages by 50%."},
            {"name": "Fire Mages' Capacity", "desc": "Increases capacity by 2."},
        ],
    },
    "academy_of_nature": {
        "description": "Recruits Healer Mages.",
        "upgrades": [
            {"name": "Healer Mages' capacity", "desc": "Increases capacity by 1."},
            {"name": "Healer Mage damage", "desc": "Increases Healer Mage damage by 25%."},
        ],
    },
    "barbarian_tent": {
        "description": "Produces Barbarians.",
        "upgrades": [
            {"name": "Weapon melting", "desc": "Grants 8 metal upon a Barbarian's death."},
            {"name": "Cheaper production", "desc": "Troops are 50% cheaper to produce."},
            {"name": "Barbarians' damage", "desc": "Increases Barbarians' damage by 100%."},
        ],
    },
    "falcons_camp": {
        "description": "Spawns Black Swordsmen.",
        "upgrades": [
            {"name": "Mentoring", "desc": "Increases HP of all Grunt troops by 100% if there is at least 1 Black Swordsman on the battlefield"},
            {"name": "Black Swordsmen's attack range", "desc": "Increases Black Swordsmen's attack range."},
            {"name": "Black Swordsmen's HP", "desc": "Increases Black Swordsmen's HP by 200%"},
        ],
    },
    "firing_range": {
        "description": "Spawns Musketeers.",
        "upgrades": [
            {"name": "Critical shots", "desc": "Musketeers have a 10% chance of dealing 500% damage."},
            {"name": "Musketeers' capacity", "desc": "Increases capacity by 2."},
            {"name": "Cheaper production", "desc": "Troops are 40% cheaper to produce."},
        ],
    },
    "geese_training_field": {
        "description": "Recruits Goose Riders.",
        "upgrades": [
            {"name": "Capacity", "desc": "Increases capacity by 1."},
            {"name": "Damage", "desc": "Increases damage dealt by Goose Riders by 60%"},
            {"name": "Cheaper production", "desc": "Troops are 50% cheaper to produce."},
        ],
    },
    "hive": {
        "description": "Spawns Bumblebees.",
        "upgrades": [
            {"name": "Bumblebees' capacity", "desc": "Increases capacity by 2."},
            {"name": "Sting attack", "desc": "Bumblebees poison their enemies, dealing bonus 30 damage over time."},
        ],
    },
    "longbowmens_camp": {
        "description": "Spawns Longbowmen.",
        "upgrades": [
            {"name": "Damage dealt by Longbowmen", "desc": "Increases damage dealt by Longbowmen by 100%"},
            {"name": "Burning arrows", "desc": "Longbowmen set enemies on fire, dealing bonus 20 damage over time."},
            {"name": "Longbowmen's capacity", "desc": "Increases capacity by 2."},
        ],
    },
    "minotaur_camp": {
        "description": "Produces Minotaurs.",
        "upgrades": [
            {"name": "Vampirism", "desc": "Minotaurs heal for 50% of the damage dealt."},
            {"name": "Trait Upgrade", "desc": "Minotaurs also provide 3% extra damage to [Flying] troops, up to 30%."},
            {"name": "Stunning Blow", "desc": "Minotaurs stum enemies with their special attack for 1s."},
        ],
    },
    "paladins_campus": {
        "description": "Produces Paladin Mages.",
        "upgrades": [
            {"name": "Paladins' capacity", "desc": "Increases capacity by 2."},
            {"name": "Spell damage buff", "desc": "Passively increases spell damage by 10%."},
            {"name": "Paladins' HP", "desc": "Increases Paladins' HP by 100%."},
        ],
    },
    "pumpkin_field": {
        "description": "Recruits Pumpkin warriors.",
        "upgrades": [
            {"name": "Pumpkin Warriors' capacity", "desc": "Increases capacity by 3."},
            {"name": "HP and Damage", "desc": "Increases damage dealt by and HP of Pumpkin Warriors by 30%"},
        ],
    },
    "stables": {
        "description": "Recruits Horsemen.",
        "upgrades": [
            {"name": "Squires' HP", "desc": "Increases HP by 40%."},
            {"name": "Squires' capacity", "desc": "Increases capacity by 1."},
            {"name": "Survivor", "desc": "When the horse dies, the rider continues fighting."},
        ],
    },
    "academy_of_lightning": {
        "description": "Produces Lightning Mages.",
        "upgrades": [
            {"name": "Lightning Mages' capacity", "desc": "Increases capacity by 2."},
            {"name": "HP and Damage", "desc": "Increases damage dealt by and HP of Lightning Mages by 50%."},
            {"name": "Jumping Lightning", "desc": "Provides 2 extra lightning jumps."},
        ],
    },
    "ballista_factory": {
        "description": "Creates Ballistae that shoot from afar and slow enemy advance.",
        "upgrades": [
            {"name": "Damage and slowness", "desc": "Increases damage by 25% and applies slow to shot enemies."},
            {"name": "Ballistae capacity", "desc": "Increases capacity by 1."},
            {"name": "Long shot", "desc": "Projectiles deal more damage the further they fly."},
        ],
    },
    "black_unicorn_field": {
        "description": "Spawns Black Unicorns.",
        "upgrades": [
            {"name": "Damage dealt by Black Unicorns", "desc": "Increases damage dealt by Black Unicorns by 100%."},
            {"name": "Boosters of Morale", "desc": "Each Black Unicorn increases morale by 5."},
        ],
    },
    "catapult_factory": {
        "description": "Creates Catapults that shoot from afar and deal area-of-effect damage.",
        "upgrades": [
            {"name": "Catapult capacity", "desc": "Increases capacity by 1."},
            {"name": "Stun chance", "desc": "Catapults gain a 20% chance of stunning enemies."},
            {"name": "Long shot", "desc": "Projectiles deal more damage the further they fly."},
        ],
    },
    "giants_bedding": {
        "description": "Awakens Giants from their sleep to fight for you, but each awakening damages your castle for 20 HP.",
        "upgrades": [
            {"name": "Sawdust", "desc": "Receive 100 Wood after waking up a Giant."},
            {"name": "Wheat Straws", "desc": "Receive 100 Wheat after waking up a Giant."},
        ],
    },
    "hydra_pond": {
        "description": "Produces Hydras.",
        "upgrades": [
            {"name": "Hydras' HP", "desc": "Increases Hydra HP by 100%."},
            {"name": "Capacity", "desc": "Increases capacity by 1."},
            {"name": "Trait Upgrade", "desc": "Each Hydra on the battlefield increases damage dealt by all units by 10%, up to 50%."},
        ],
    },
    "lion_circus": {
        "description": "Produces Griffins.",
        "upgrades": [
            {"name": "Versatility", "desc": "Griffins receive bonuses from all troop classes and are counted as all-class; their production cost is increased by 100%."},
        ],
    },
    "pangolin_stump": {
        "description": "Produces Pangolins.",
        "upgrades": [
            {"name": "Pangolins' HP", "desc": "Increases Pangolins' HP by 50%."},
            {"name": "War of attrition", "desc": "When rolling, Pangolins weaken enemies, decreasing their attack and movement speed."},
            {"name": "Pangolins' evasion", "desc": "Gives Pangolins 25% evasion."},
        ],
    },
    "ram_pasture": {
        "description": "Transforms Black Sheep into Rams.",
        "upgrades": [
            {"name": "Rams' HP", "desc": "Increases Rams' HP by 50%."},
            {"name": "Spell damage", "desc": "Each Ram increases spell damage dealt by 20%."},
            {"name": "Twins", "desc": "10% chance of producing an extra Ram."},
        ],
    },
    "white_unicorn_field": {
        "description": "Spawns White Unicorns.",
        "upgrades": [
            {"name": "Unicorns' HP", "desc": "Increases Unicorns' HP by 100%."},
            {"name": "Spell Damage", "desc": "Each Unicorn increases spell damage dealt by 10%."},
        ],
    },
    "archmages_university": {
        "description": "Generates legendary spells.",
        "upgrades": [
            {"name": "Illusion of Choice", "desc": "Generates a legendary spell choice instead of a random legendary spell."},
            {"name": "Archmage's Tempo", "desc": "Boosts legendary spell generation speed by 20%."},
        ],
    },
    "arena": {
        "description": "Provides 25 morale while active.",
        "upgrades": [
            {"name": "Fight Betting", "desc": "Earn 1 gold every 3s while working."},
            {"name": "Higher Morale", "desc": "Provides an additional 15 morale."},
        ],
    },
    "brick_factory": {
        "description": "Repairs the castle walls.",
        "upgrades": [
            {"name": "Repair speed", "desc": "Boosts production by 100%."},
            {"name": "Fortifications", "desc": "When castle HP is full, accumulates charges; 5 charges increase max HP by 1 (max 100)."},
        ],
    },
    "buddhist_temple": {
        "description": "Upgrades provide passive effects.",
        "upgrades": [
            {"name": "Production Speed Buff", "desc": "Passively increases all production by 5%."},
            {"name": "Troop Damage Buff", "desc": "Passively increases all troop damage by 10%."},
            {"name": "Spell Damage Buff", "desc": "Passively increases spell damage by 10%."},
        ],
    },
    "concert": {
        "description": "Boosts production speed of all buildings under gaze by 30% while active.",
        "upgrades": [
            {"name": "Music for Your Soul", "desc": "Provides 10 morale while the Concert is active under gaze."},
            {"name": "Music for Your Body", "desc": "Provides 5 passive morale."},
        ],
    },
    "execution_ground": {
        "description": "Executes Grunt units and provides Denarii.",
        "upgrades": [
            {"name": "High Bounties", "desc": "Gain 2 extra Denarii per unit executed."},
            {"name": "Troop Inspiration", "desc": "Passively increases damage dealt and HP of Grunt troops by 10%."},
        ],
    },
    "fairy_fountain": {
        "description": "Produces random resources.",
        "upgrades": [
            {"name": "Production Speed", "desc": "Boosts production speed by 25%."},
            {"name": "Anti-Goblin Dust", "desc": "Damages enemies for 15 with each production cycle."},
        ],
    },
    "hero_statue": {
        "description": "Provides troop stat upgrades.",
        "upgrades": [
            {"name": "Hero Statue Speed", "desc": "Boosts troop bonus reward generation speed by 25%."},
        ],
    },
    "hospital": {
        "description": "Heals injured troops while active.",
        "upgrades": [
            {"name": "Masters of healing", "desc": "Heals 50% more."},
            {"name": "Masters of morale", "desc": "Each active hospital provides 5 morale."},
        ],
    },
    "kings_statue": {
        "description": "Speeds up the King's Ability cooldown recovery while active.",
        "upgrades": [
            {"name": "Crystal Clarity", "desc": "25% chance of receiving extra Crystal 1 with each production cycle."},
            {"name": "Troop Inspiration", "desc": "Passively increases damage and HP of Champion troops by 10%."},
        ],
    },
    "magic_ball": {
        "description": "Increases spell damage dealt by 50% while active.",
        "upgrades": [
            {"name": "More spell damage", "desc": "Increases spell damage by an additional 30%."},
            {"name": "Witchcraft", "desc": "Provides Arcane troops with a 15% boost to damage dealt."},
        ],
    },
    "magic_college": {
        "description": "Generates basic spells.",
        "upgrades": [
            {"name": "Illusion of Choice", "desc": "Generates a spell choice instead of a random spell."},
            {"name": "Magic College Speed", "desc": "Boosts spell generation speed by 20%."},
        ],
    },
    "magic_school": {
        "description": "Slowly generates basic spells.",
        "upgrades": [
            {"name": "Illusion of Choice", "desc": "No longer generates random spells but grants spell choices instead."},
            {"name": "Magic School Speed", "desc": "Boosts spell production by 25%."},
        ],
    },
    "monument_to_the_kings_gaze": {
        "description": "Adjacent buildings start working without needing to watch them.",
        "upgrades": [],
    },
    "research_laboratory": {
        "description": "Produces blueprints for buildings.",
        "upgrades": [],
    },
    "research_table": {
        "description": "Produces blueprints for buildings.",
        "upgrades": [],
    },
    "tavern": {
        "description": "Reduces wine consumption by 50% and increases the morale bonus from wine by 20.",
        "upgrades": [
            {"name": "Higher Morale", "desc": "Provides 5 additional morale."},
        ],
    },
    "tesla_tower": {
        "description": "Attacks enemies with jumping lightning strikes.",
        "upgrades": [
            {"name": "Attack Speed", "desc": "Boosts attack speed by 40%."},
            {"name": "Additional Chain", "desc": "Lightning chains 1 more time."},
            {"name": "Damage", "desc": "Increases damage dealt by 40%."},
        ],
    },
    "wheel_of_fortune": {
        "description": "Creates a small resource pack.",
        "upgrades": [
            {"name": "Production Speed", "desc": "Boosts production speed by 25%."},
        ],
    },
    "basic_construction": {
        "description": "Can be upgraded into a building of choice after 30s active. Transforms into one of six Established Production buildings: Wheat Field, Sawmill, Iron Mine, Clay Mine, Vineyard, Crystal Mine.",
        "upgrades": [],
    },
    "clay_gold_mine": {
        "description": "Produces gold and clay.",
        "upgrades": [],
    },
    "clay_iron_mine": {
        "description": "Produces ore and clay.",
        "upgrades": [],
    },
    "clay_sawmill": {
        "description": "Produces wood and clay.",
        "upgrades": [],
    },
    "gold_iron_mine": {
        "description": "Produces gold and ore.",
        "upgrades": [],
    },
    "gold_sawmill": {
        "description": "Produces wood and gold.",
        "upgrades": [],
    },
    "goldsmiths_farm": {
        "description": "Produces wheat and gold.",
        "upgrades": [],
    },
    "iron_sawmill": {
        "description": "Produces wood and ore.",
        "upgrades": [],
    },
    "lumberjacks_farm": {
        "description": "Produces wood and wheat.",
        "upgrades": [],
    },
    "potters_farm": {
        "description": "Produces wheat and clay.",
        "upgrades": [],
    },
}

static func get_description(building_id: String, fallback: String = "") -> String:
    var data: Variant = DATA.get(String(building_id).strip_edges().to_lower(), {})
    if data is Dictionary:
        var description: String = String((data as Dictionary).get("description", "")).strip_edges()
        if description != "":
            return description
    return fallback

static func get_upgrades(building_id: String) -> Array:
    var data: Variant = DATA.get(String(building_id).strip_edges().to_lower(), {})
    if not (data is Dictionary):
        return []
    var raw_upgrades: Variant = (data as Dictionary).get("upgrades", [])
    if not (raw_upgrades is Array):
        return []
    var out: Array = []
    for entry in raw_upgrades:
        if entry is Dictionary:
            out.append((entry as Dictionary).duplicate(true))
    return out

static func has_upgrades(building_id: String) -> bool:
    return not get_upgrades(building_id).is_empty()
