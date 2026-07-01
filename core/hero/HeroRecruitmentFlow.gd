extends RefCounted
class_name HeroRecruitmentFlow


func hire_hero_copy(hero_data, recruitment_service, base_id: String, emit_created: Callable, emit_recruited: Callable, request_save: Callable) -> String:
    if hero_data == null:
        return ""
    if not hero_data.has_hero(base_id):
        return ""
    if recruitment_service == null:
        return ""
    var result: Dictionary = recruitment_service.hire_copy(base_id)
    if not bool(result.get("success", false)):
        return ""
    var hero_id := str(result.get("hero_id", ""))
    var hero: Dictionary = hero_data.get_hero(hero_id)
    if emit_created.is_valid():
        emit_created.call(hero_id, hero)
    if emit_recruited.is_valid():
        emit_recruited.call(hero_id)
    if request_save.is_valid():
        request_save.call()
    return hero_id


func ensure_hero_template(hero_data, base_id: String, display_name: String = "", cost: float = 0.0) -> bool:
    if hero_data == null:
        return false
    var normalized_id := String(base_id).strip_edges().to_lower()
    if normalized_id == "":
        return false
    if hero_data.has_hero(normalized_id):
        return true
    var template_name := String(display_name).strip_edges()
    if template_name == "":
        template_name = normalized_id.capitalize()
    var base_hp: float = float(hero_data.get_base_hp(normalized_id))
    var base_dmg: float = float(hero_data.get_base_damage(normalized_id))
    return hero_data.create_hero(normalized_id, template_name, normalized_id, cost, "", base_hp, base_dmg)


func try_recruit_hero(hero_data, recruitment_service, hero_type: String, emit_created: Callable, emit_recruited: Callable, request_save: Callable) -> bool:
    if recruitment_service == null:
        return false
    var result: Dictionary = recruitment_service.recruit(hero_type)
    if not bool(result.get("success", false)):
        return false
    var hero_id := str(result.get("hero_id", ""))
    var hero: Dictionary = hero_data.get_hero(hero_id)
    if emit_created.is_valid():
        emit_created.call(hero_id, hero)
    if emit_recruited.is_valid():
        emit_recruited.call(hero_id)
    if request_save.is_valid():
        request_save.call()
    return true
