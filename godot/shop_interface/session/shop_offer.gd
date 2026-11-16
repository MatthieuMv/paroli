extends RefCounted
class_name ShopOffer
## One known item on the shop shelf. Created and updated only by ShopSession.

# --- Member variables ---

## `ShopSession.JOKER` or `ShopSession.BONUS`.
var family: StringName
## Offered content; never an owned identity at the time of stocking.
var definition: IllustratedDefinition
## Asking price in coins.
var price: int = 0
## True once bought; the slot stays empty until the next stock.
var sold: bool = false
