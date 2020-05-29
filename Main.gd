extends Spatial

export var debug_mode := false
export var start := Vector2(0.0, 0.0)
export var step := Vector2(3.0, 2.0)
export var size := Vector2(3, 4)
export var draw_time := 0.25

var drawn_cards := []
var selected_cards := []
var _card_final_y_offset := 0.0
var has_game_ended := false

onready var deck := $Deck as Deck
onready var card_collection_loc := $CardCollectLocation as Spatial

func _ready() -> void:
	_redraw_cards()

func _on_card_clicked(card: Card) -> void:
	if card.selected:
		selected_cards.erase(card)
	else:
		selected_cards.append(card)
	card.toggle_selection()
	if selected_cards.size() == 3:
		var is_set: bool = self.callv("_is_set", selected_cards)
		for card in selected_cards:
			if is_set:
				var target_rot: Vector3 = card.rotation
				target_rot.y = card_collection_loc.rotation.y
				card.move_to(
					card_collection_loc.translation
						+ Vector3(0.0, _card_final_y_offset, 0.0),
					target_rot,
					0.5
				)
				_card_final_y_offset += 0.025
				drawn_cards.erase(card)
			card.toggle_selection()
		selected_cards.clear()
		if is_set:
			if !_do_sets_remain():
				_redraw_cards()
			elif debug_mode:
				_highlight_set()

func _redraw_cards() -> void:
	while !_do_sets_remain() and !has_game_ended:
		_clear_current_cards()
		for y in range(0, size.y):
			for x in range(0, size.x):
				_draw_and_move_card(
					Vector3(start.x + step.x * x, 0.0, start.y + step.y * y),
					draw_time
				)
				yield(get_tree().create_timer(draw_time), "timeout")
		for card in drawn_cards:
			(card as Card).flip()
		for card in drawn_cards:
			yield(card, "flip_completed")
	if debug_mode:
		_highlight_set()
# for debugging purposes
func _highlight_set() -> void:
	var set := _find_set(drawn_cards, [])
	for card_raw in set:
		var card: Card = card_raw
		card.move_to(
			card.translation + Vector3(0.0, 1.0, 0.0),
			Vector3(card.rotation.x, PI, card.rotation.z),
			1.0
		)

# place to move to
func _draw_and_move_card(pos: Vector3, time: float) -> void:
	var drawn_card := deck.draw_card()
	if drawn_card != null:
		add_child(drawn_card)
		drawn_cards.append(drawn_card)
		var _success = drawn_card.connect("card_clicked", self, "_on_card_clicked")
		var spawn_transform := (deck.get_node("CardSpawnPoint") as Spatial)\
				.get_global_transform()
		drawn_card.translation = spawn_transform.origin
		drawn_card.rotation.y = spawn_transform.basis.z.angle_to(Vector3(0, 0, 1))
		var target_rot := drawn_card.rotation
		target_rot.y = PI
		drawn_card.move_to(pos, target_rot, time)
	else:
		_clear_current_cards()
		has_game_ended = true

func _clear_current_cards() -> void:
	while drawn_cards.size() > 0:
		(drawn_cards.pop_back() as Card).queue_free()

func _do_sets_remain() -> bool:
	return _find_set(drawn_cards, []).size() > 0

# returns an array of arrays that each contain 3 cards
func _find_all_sets() -> Array:
	var unpicked := drawn_cards.duplicate()
	var sets := []
	var all_sets_found := false
	while !all_sets_found:
		var set := _find_set(unpicked, [])
		if set.size() > 0:
			for card in set:
				unpicked.erase(card)
			sets.append(set)
		else:
			all_sets_found = true
	return sets

func _find_set(cards: Array, picked: Array) -> Array:
	if picked.size() == 3:
		if self.callv("_is_set", picked):
			return picked;
		else:
			return []
	var unpicked := cards.duplicate()
	while unpicked.size() > 0:
		var next = unpicked.pop_back()
		if picked.has(next):
			continue
		picked.push_back(next)
		var set_found := _find_set(cards, picked)
		if set_found.size() > 0:
			return set_found
		picked.pop_back()
	return []

func _is_set(one: Card, two: Card, three: Card) -> bool:
	return _numbers_are_set(one, two, three) \
			and _shapes_are_set(one, two, three) \
			and _shadings_are_set(one, two, three) \
			and _colors_are_set(one, two, three)

func _numbers_are_set(one: Card, two: Card, three: Card) -> bool:
	return one.number == two.number \
			and two.number == three.number \
			and one.number == three.number \
			or one.number != two.number \
			and two.number != three.number \
			and one.number != three.number

func _shapes_are_set(one: Card, two: Card, three: Card) -> bool:
	return one.shape == two.shape \
			and two.shape == three.shape \
			and one.shape == three.shape \
			or one.shape != two.shape \
			and two.shape != three.shape \
			and one.shape != three.shape

func _shadings_are_set(one: Card, two: Card, three: Card) -> bool:
	return one.shading == two.shading \
			and two.shading == three.shading \
			and one.shading == three.shading \
			or one.shading != two.shading \
			and two.shading != three.shading \
			and one.shading != three.shading

func _colors_are_set(one: Card, two: Card, three: Card) -> bool:
	return one.color == two.color \
			and two.color == three.color \
			and one.color == three.color \
			or one.color != two.color \
			and two.color != three.color \
			and one.color != three.color
