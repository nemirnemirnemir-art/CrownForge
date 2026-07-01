extends Panel
class_name RewardArtifactCard

signal selected(artifact_id: String)

@onready var icon_bg: ColorRect = get_node_or_null("IconBG")
@onready var icon_texture: TextureRect = get_node_or_null("Icon")
@onready var name_label: Label = get_node_or_null("NameLabel")
@onready var description_label: Label = get_node_or_null("DescriptionLabel")
@onready var choose_button: Button = get_node_or_null("ChooseButton")

var artifact_id: String = ""

func _ready() -> void:
    if choose_button:
        choose_button.pressed.connect(_on_choose_pressed)

func setup(new_artifact_id: String) -> void:
    artifact_id = new_artifact_id
    var def := ArtifactCatalog.get_def(artifact_id)
    if name_label:
        name_label.text = str(def.get("display_name", artifact_id))
    if description_label:
        description_label.text = str(def.get("description", ""))
    if icon_texture:
        var icon_path: String = str(def.get("icon", ""))
        if icon_path != "" and ResourceLoader.exists(icon_path):
            icon_texture.texture = load(icon_path)
        else:
            icon_texture.texture = null
    if icon_bg:
        var implemented := bool(def.get("implemented", false))
        icon_bg.color = Color(0.25, 0.55, 1.0, 1.0) if implemented else Color(1.0, 0.25, 0.25, 1.0)

func _on_choose_pressed() -> void:
    if artifact_id != "":
        selected.emit(artifact_id)
