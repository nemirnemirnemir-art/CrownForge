extends RefCounted
class_name HeroAnimationLoader

## Utility class to automatically create SpriteFrames from PNG files

static func create_spriteframes_for_hero(icon_id: String) -> SpriteFrames:
    var frames: SpriteFrames = SpriteFrames.new()
    
    # Paths to PNG files
    var walk_path: String = "res://assets/heroes/%s.png" % icon_id
    var attack_path: String = "res://assets/heroes/%s_attack.png" % icon_id
    
    # Check if files exist
    var walk_exists: bool = ResourceLoader.exists(walk_path)
    var attack_exists: bool = ResourceLoader.exists(attack_path)
    
    if not walk_exists and not attack_exists:
        print("[HeroAnimationLoader] No animation files found for %s" % icon_id)
        return frames
    
    # Add walk animation
    frames.add_animation("walk")
    if walk_exists:
        var walk_texture: Texture2D = load(walk_path)
        frames.add_frame("walk", walk_texture)
        frames.set_animation_speed("walk", 6.0)
        frames.set_animation_loop("walk", true)
    elif attack_exists:
        # Use attack as fallback
        frames.add_frame("walk", load(attack_path))
        frames.set_animation_speed("walk", 6.0)
        frames.set_animation_loop("walk", true)
    
    # Add attack animation
    frames.add_animation("attack")
    if attack_exists:
        var attack_texture: Texture2D = load(attack_path)
        frames.add_frame("attack", attack_texture)
        frames.set_animation_speed("attack", 4.0)
        frames.set_animation_loop("attack", false)
    elif walk_exists:
        # Use walk as fallback
        frames.add_frame("attack", load(walk_path))
        frames.set_animation_speed("attack", 4.0)
        frames.set_animation_loop("attack", false)
    
    return frames

static func save_spriteframes(icon_id: String, sprite_frames: SpriteFrames) -> bool:
    # Avoid writing into res:// at runtime (exported builds / restricted environments)
    if not Engine.is_editor_hint():
        return false
    var path: String = "res://assets/heroes/%s_spriteframes.tres" % icon_id
    var error: Error = ResourceSaver.save(sprite_frames, path)
    if error == OK:
        print("[HeroAnimationLoader] Saved SpriteFrames to %s" % path)
        return true
    else:
        # Silent fail to avoid log spam / startup errors
        return false

static func create_all_hero_spriteframes() -> void:
    # This is an editor utility; do not run in-game.
    if not Engine.is_editor_hint():
        return
    var hero_types: Array[String] = ["swordman", "archer"]
    
    for icon_id in hero_types:
        var sprite_frames_path: String = "res://assets/heroes/%s_spriteframes.tres" % icon_id
        # Only create if doesn't exist
        if not ResourceLoader.exists(sprite_frames_path):
            var frames: SpriteFrames = create_spriteframes_for_hero(icon_id)
            if frames.get_animation_names().size() > 0:
                save_spriteframes(icon_id, frames)
                print("[HeroAnimationLoader] Created SpriteFrames for %s" % icon_id)
