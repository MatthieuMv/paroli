extends PanelContainer
class_name CoinChip
## Coin purse readout. Shows the host's balance; it never grants or spends coins.

# --- Member variables ---

## Removes the count-up and punch.
var reduced_motion: bool = false
## Balance currently drawn, tweened toward the host value.
var shown_coins: float = 0.0:
	set(value):
		shown_coins = value
		if is_node_ready():
			_count.text = Juice.number(roundf(value))
## Active count-up, replaced when the balance changes again.
var _tween: Tween
## Balance readout.
@onready var _count: Label = $Row/Count
## Drawn coin, used as the landing point for flying rewards.
@onready var _icon: CoinIcon = $Row/Icon

# --- Member functions ---

## Ready callback: draw the initial balance.
func _ready() -> void:
	_count.text = Juice.number(roundf(shown_coins))

## Set the balance, optionally counting up with a punch.
func set_coins(value: int, animate: bool) -> void:
	if _tween:
		_tween.kill()
	if not animate or reduced_motion:
		shown_coins = float(value)
		return
	_tween = create_tween()
	_tween.tween_property(self, "shown_coins", float(value), 0.3)
	Juice.punch(self, 0.16, 0.4)

## Global center of the coin, where flying rewards should land.
func anchor() -> Vector2:
	return _icon.get_global_transform() * (_icon.size * 0.5)
