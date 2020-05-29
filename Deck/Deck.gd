extends Spatial

class_name Deck

export var card_scene: PackedScene

var deck := []

onready var card_spawn_point := $CardSpawnPoint as Spatial

func _ready() -> void:
	randomize()
	reset()
	shuffle()
	
func reset() -> void:
	deck = []
	# I can't decide if this is bad code or not (probably is tbh)
	for card_color in range(0, Card.CardColor.size()):
		for card_shading in range(0, Card.CardShading.size()):
			for card_shape in range(0, Card.CardShading.size()):
				for card_number in range(1, Card.MAX_NUMBER + 1):
					var card := card_scene.instance() as Card
					card.color = card_color
					card.shading = card_shading
					card.shape = card_shape
					card.number = card_number
					deck.push_back(card)

func shuffle() -> void:
	deck.shuffle()

func draw_card() -> Card:
	var card := deck.pop_back() as Card
	scale.y = deck.size() / 81.0 + 0.01
	return card
