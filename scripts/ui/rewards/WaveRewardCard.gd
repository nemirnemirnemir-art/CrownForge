extends Panel
class_name WaveRewardCard

signal claim_reward

@onready var icon_rect: TextureRect = get_node_or_null("Icon")
@onready var label: Label = get_node_or_null("Label")
@onready var claim_button: Button = get_node_or_null("ClaimButton")

var reward_type: String = ""  # "denarii", "levy", "production", "prophecy"
var is_claimed: bool = false

func _ready() -> void:
	if claim_button:
		claim_button.pressed.connect(_on_claim_pressed)

func setup(type: String, icon: Texture2D, text: String) -> void:
	reward_type = type
	is_claimed = false
	
	if icon_rect:
		icon_rect.texture = icon
	if label:
		label.text = text
	
	visible = true

func _on_claim_pressed() -> void:
	if not is_claimed:
		is_claimed = true
		claim_reward.emit(reward_type)
		queue_free()  # Remove card after claiming
