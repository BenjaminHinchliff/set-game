extends Spatial

class_name Card

signal move_completed
signal flip_completed
signal card_clicked(card)

enum CardColor {
	RED,
	GREEN,
	PURPLE
}

enum CardShading {
	OPEN,
	STRIPED,
	SOLID
}

enum CardShape {
	DIAMOND,
	OVAL,
	SQUIGGLE
}

const MAX_NUMBER: int = 3

export var atlas_nr_cards := Vector2(9, 9)
export(CardColor) var color setget set_color
export(CardShading) var shading setget set_shading
export(CardShape) var shape setget set_shape
export(int, 1, 3) var number := 1 setget set_number

var ready := false
var is_moving := false
var selected := false

onready var tween := $Tween as Tween
onready var front := $Front as MeshInstance

func _ready() -> void:
	ready = true
	front.material_override = front["material/0"].duplicate()
	_update_card()

func _to_string() -> String:
	return "(%d, %d, %d, %d)" % [color, shading, shape, number]

func _on_Tween_tween_completed(object: Object, key: NodePath) -> void:
	if object == self and key == ":translation":
		emit_signal("move_completed")
		is_moving = false
	if object == self and key == ":rotation":
		emit_signal("flip_completed")

func _on_Card_input_event(
		_camera: Node,
		event: InputEvent,
		_click_position: Vector3,
		_click_normal: Vector3,
		_shape_idx: int
	) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		emit_signal("card_clicked", self)

func toggle_selection():
	selected = !selected
	if selected:
		front.material_override.albedo_color = Color(1.0, 1.0, 0.0)
	else:
		front.material_override.albedo_color = Color(1.0, 1.0, 1.0)

func flip() -> void:
	var target_rot := Vector3(rotation.x + PI, rotation.y, rotation.z)
	var _success = tween.interpolate_property(self, "rotation",
			rotation, target_rot, 1.0, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	_success = tween.start()
	
func move_to(pos: Vector3, target_rot: Vector3, time: float) -> void:
	var _success = tween.interpolate_property(self, "translation",
			translation, pos, time, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	_success = tween.start()
	# move card to correct dest rotation
	_success = tween.interpolate_property(self, "rotation",
			rotation, target_rot, time, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	_success = tween.start()
	is_moving = true

# updates card's UV when a property is changed
func set_color(new_color: int) -> void:
	color = new_color
	_update_card()
	
func set_shading(new_shading: int) -> void:
	shading = new_shading
	_update_card()
	
func set_shape(new_shape: int) -> void:
	shape = new_shape
	_update_card()
	
func set_number(new_number: int) -> void:
	number = new_number
	_update_card()

func _update_card() -> void:
	if ready:
		var front_material := front.material_override
		var pos := _get_x_y()
		var uv_size = Vector2(1.0, 1.0) / atlas_nr_cards
		front_material.uv1_offset.x = uv_size.x * pos[0]
		front_material.uv1_offset.y = uv_size.y * pos[1]
		front_material.uv1_scale.x = uv_size.x
		front_material.uv1_scale.y = uv_size.y
	
func _get_x_y() -> Array:
	return [int(shape) * 3 + number - 1, int(color) * 3 + int(shading)];
