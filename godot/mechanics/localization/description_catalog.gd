extends RefCounted
class_name DescriptionCatalog
## Human-authored player copy. Keywords carry tooltips; named rule fields carry balance values.
## Edit sentences here, never reconstruct prose from condition-tree fragments.

# --- Static functions ---

## Create independent descriptions so editor/debug instances never share mutable copy.
static func create() -> Dictionary[StringName, AuthoredDescription]:
	return {
		&"all_for_one": AuthoredDescription.new(
			"{kw:validated|Played}: +{n:reward:per_die}% {kw:mult} per other matching {kw:validated|played} die.",
			"{kw:validated|Joué} : +{n:reward:per_die} % {kw:mult} par autre dé {kw:validated|joué} de même valeur."
		),
		&"house_builder": AuthoredDescription.new(
			"+{n:reward:constant}% {kw:mult} as part of a {kw:combination.full_house}.",
			"+{n:reward:constant} % {kw:mult} dans une {kw:combination.full_house}."
		),
		&"jackpot": AuthoredDescription.new(
			"{kw:validated|Played}: +{n:reward:constant}% {kw:mult} on a 6.",
			"{kw:validated|Joué} : +{n:reward:constant} % {kw:mult} sur un 6."
		),
		&"odd_master": AuthoredDescription.new(
			"{kw:validated|Played}: +{n:reward:per_die}% {kw:mult} per {kw:validated|played} odd die.",
			"{kw:validated|Joué} : +{n:reward:per_die} % {kw:mult} par dé impair {kw:validated|joué}."
		),
		&"even_master": AuthoredDescription.new(
			"{kw:validated|Played}: +{n:reward:per_die}% {kw:mult} per {kw:validated|played} even die.",
			"{kw:validated|Joué} : +{n:reward:per_die} % {kw:mult} par dé pair {kw:validated|joué}."
		),
		&"rainbow": AuthoredDescription.new(
			"{kw:validated|Played}: +{n:reward:coefficient}% {kw:mult} per distinct {kw:validated|played} value.",
			"{kw:validated|Joué} : +{n:reward:coefficient} % {kw:mult} par valeur {kw:validated|jouée} distincte."
		),
		&"lone_wolf": AuthoredDescription.new(
			"{kw:validated|Played}: +{n:reward:per_die}% {kw:mult} per {kw:held|held} die.",
			"{kw:validated|Joué} : +{n:reward:per_die} % {kw:mult} par dé {kw:held|gardé}."
		),
		&"guardian": AuthoredDescription.new(
			"{kw:held|Held}: +{n:reward:constant}% {kw:mult} if a matching die is {kw:validated|played}.",
			"{kw:held|Gardé} : +{n:reward:constant} % {kw:mult} si un dé de même valeur est {kw:validated|joué}."
		),
		&"golden_touch": AuthoredDescription.new(
			"Gain this die’s value in {kw:coins|coins} when it {kw:member|scores}.",
			"Gagne sa valeur en {kw:coins|pièces} quand ce dé {kw:member|marque}."
		),
		&"stepping_stones": AuthoredDescription.new(
			"In a {kw:combination.short_straight}: +{n:short_straight:constant}% {kw:mult}. In a {kw:combination.long_straight}: +{n:long_straight:constant}%.",
			"Dans une {kw:combination.short_straight} : +{n:short_straight:constant} % {kw:mult}. Dans une {kw:combination.long_straight} : +{n:long_straight:constant} %."
		),
		&"relentless": AuthoredDescription.new(
			"{kw:validated|Played}: +{n:reward:coefficient}% {kw:mult} per {kw:reroll|manual roll} of this die. Resets after playing it or each {kw:round|round}.",
			"{kw:validated|Joué} : +{n:reward:coefficient} % {kw:mult} par {kw:reroll|lancer manuel} de ce dé. Remis à zéro après l’avoir joué ou à chaque {kw:round|manche}."
		),
		&"crescendo": AuthoredDescription.new(
			"{kw:validated|Played} higher than its previous played value: gain +{n:reward:step}% {kw:mult} for this {kw:round|round}, starting now.",
			"{kw:validated|Joué} plus haut que sa précédente valeur jouée : gagne +{n:reward:step} % {kw:mult} pour cette {kw:round|manche}, dès ce coup."
		),
		&"deja_vu": AuthoredDescription.new(
			"+{n:reward:constant}% {kw:mult} when {kw:validated|played} again with the same value this {kw:round|round}.",
			"+{n:reward:constant} % {kw:mult} si {kw:validated|joué} à nouveau avec la même valeur cette {kw:round|manche}."
		),
		&"alternator": AuthoredDescription.new(
			"+{n:reward:constant}% {kw:mult} when {kw:validated|played} again with a different value this {kw:round|round}.",
			"+{n:reward:constant} % {kw:mult} si {kw:validated|joué} à nouveau avec une autre valeur cette {kw:round|manche}."
		),
		&"solo_talent": AuthoredDescription.new(
			"+{n:reward:constant} {kw:mult} as the {kw:combination.single}.",
			"+{n:reward:constant} {kw:mult} en tant que {kw:combination.single}."
		),
		&"solo_act": AuthoredDescription.new(
			"+{n:reward:constant} {kw:points} on {kw:combination.single}.",
			"+{n:reward:constant} {kw:points} sur un {kw:combination.single}."
		),
		&"pair_partner": AuthoredDescription.new(
			"+{n:reward:constant} {kw:mult} as part of a {kw:combination.pair}.",
			"+{n:reward:constant} {kw:mult} dans une {kw:combination.pair}."
		),
		&"better_together": AuthoredDescription.new(
			"+{n:reward:constant} {kw:points} on {kw:combination.pair}.",
			"+{n:reward:constant} {kw:points} sur une {kw:combination.pair}."
		),
		&"double_partner": AuthoredDescription.new(
			"+{n:reward:constant} {kw:mult} in {kw:combination.two_pairs}.",
			"+{n:reward:constant} {kw:mult} dans une {kw:combination.two_pairs}."
		),
		&"double_date": AuthoredDescription.new(
			"+{n:reward:constant} {kw:points} on {kw:combination.two_pairs}.",
			"+{n:reward:constant} {kw:points} sur une {kw:combination.two_pairs}."
		),
		&"triple_bond": AuthoredDescription.new(
			"+{n:reward:constant} {kw:mult} as part of a {kw:combination.three_of_a_kind}.",
			"+{n:reward:constant} {kw:mult} dans un {kw:combination.three_of_a_kind}."
		),
		&"three_company": AuthoredDescription.new(
			"+{n:reward:constant} {kw:points} on {kw:combination.three_of_a_kind}.",
			"+{n:reward:constant} {kw:points} sur un {kw:combination.three_of_a_kind}."
		),
		&"sure_footing": AuthoredDescription.new(
			"+{n:reward:constant} {kw:mult} as part of a {kw:combination.short_straight}.",
			"+{n:reward:constant} {kw:mult} dans une {kw:combination.short_straight}."
		),
		&"short_journey": AuthoredDescription.new(
			"+{n:reward:constant} {kw:points} on {kw:combination.short_straight}.",
			"+{n:reward:constant} {kw:points} sur une {kw:combination.short_straight}."
		),
		&"house_guest": AuthoredDescription.new(
			"+{n:reward:constant} {kw:mult} as part of a {kw:combination.full_house}.",
			"+{n:reward:constant} {kw:mult} dans une {kw:combination.full_house}."
		),
		&"open_house": AuthoredDescription.new(
			"+{n:reward:constant} {kw:points} on {kw:combination.full_house}.",
			"+{n:reward:constant} {kw:points} sur une {kw:combination.full_house}."
		),
		&"last_mile": AuthoredDescription.new(
			"+{n:reward:constant} {kw:mult} as part of a {kw:combination.long_straight}.",
			"+{n:reward:constant} {kw:mult} dans une {kw:combination.long_straight}."
		),
		&"long_journey": AuthoredDescription.new(
			"+{n:reward:constant} {kw:points} on {kw:combination.long_straight}.",
			"+{n:reward:constant} {kw:points} sur une {kw:combination.long_straight}."
		),
		&"four_together": AuthoredDescription.new(
			"+{n:reward:constant} {kw:mult} as part of a {kw:combination.four_of_a_kind}.",
			"+{n:reward:constant} {kw:mult} dans un {kw:combination.four_of_a_kind}."
		),
		&"four_corners": AuthoredDescription.new(
			"+{n:reward:constant} {kw:points} on {kw:combination.four_of_a_kind}.",
			"+{n:reward:constant} {kw:points} sur un {kw:combination.four_of_a_kind}."
		),
		&"family_bond": AuthoredDescription.new(
			"+{n:reward:constant} {kw:mult} as part of a {kw:combination.five_of_a_kind}.",
			"+{n:reward:constant} {kw:mult} dans un {kw:combination.five_of_a_kind}."
		),
		&"family_reunion": AuthoredDescription.new(
			"+{n:reward:constant} {kw:points} on {kw:combination.five_of_a_kind}.",
			"+{n:reward:constant} {kw:points} sur un {kw:combination.five_of_a_kind}."
		),
		&"family_spirit": AuthoredDescription.new(
			"{kw:validated|Played}: +{n:reward:per_die} {kw:mult} per other matching {kw:validated|played} die.",
			"{kw:validated|Joué} : +{n:reward:per_die} {kw:mult} par autre dé {kw:validated|joué} de même valeur."
		),
		&"one_or_nothing": AuthoredDescription.new(
			"{kw:validated|Played}: +{n:reward:constant} {kw:mult} on a 1.",
			"{kw:validated|Joué} : +{n:reward:constant} {kw:mult} sur un 1."
		),
		&"six_addict": AuthoredDescription.new(
			"{kw:validated|Played}: +{n:reward:constant} {kw:mult} on a 6.",
			"{kw:validated|Joué} : +{n:reward:constant} {kw:mult} sur un 6."
		),
		&"odd_charm": AuthoredDescription.new(
			"{kw:validated|Played}: +{n:reward:constant} {kw:mult} on an odd value.",
			"{kw:validated|Joué} : +{n:reward:constant} {kw:mult} sur un nombre impair."
		),
		&"even_charm": AuthoredDescription.new(
			"{kw:validated|Played}: +{n:reward:constant} {kw:mult} on an even value.",
			"{kw:validated|Joué} : +{n:reward:constant} {kw:mult} sur un nombre pair."
		),
		&"lucky_seven": AuthoredDescription.new(
			"{kw:validated|Played}: +{n:reward:constant} {kw:mult} if another {kw:validated|played} die brings their sum to 7.",
			"{kw:validated|Joué} : +{n:reward:constant} {kw:mult} si un autre dé {kw:validated|joué} porte leur somme à 7."
		),
		&"unique": AuthoredDescription.new(
			"{kw:validated|Played}: +{n:reward:constant} {kw:mult} with at least 2 other {kw:validated|played} dice, none matching this die.",
			"{kw:validated|Joué} : +{n:reward:constant} {kw:mult} avec au moins 2 autres dés {kw:validated|joués}, tous de valeur différente de ce dé."
		),
		&"small_circle": AuthoredDescription.new(
			"{kw:validated|Played}: +{n:reward:per_die} {kw:mult} per {kw:held|held} die.",
			"{kw:validated|Joué} : +{n:reward:per_die} {kw:mult} par dé {kw:held|gardé}."
		),
		&"squad": AuthoredDescription.new(
			"+{n:reward:constant} {kw:mult} in {kw:combination.two_pairs} or {kw:combination.four_of_a_kind} with exactly 4 dice {kw:validated|played}.",
			"+{n:reward:constant} {kw:mult} dans une {kw:combination.two_pairs} ou un {kw:combination.four_of_a_kind}, avec exactement 4 dés {kw:validated|joués}."
		),
		&"quiet_strength": AuthoredDescription.new(
			"+{n:reward:constant} {kw:mult} per {kw:validation|play} while {kw:held|held}.",
			"+{n:reward:constant} {kw:mult} par {kw:validation|coup} tant que {kw:held|gardé}."
		),
		&"pocket_money": AuthoredDescription.new(
			"+{n:reward:constant} {kw:coins|coins} when this die {kw:member|scores}.",
			"+{n:reward:constant} {kw:coins|pièces} quand ce dé {kw:member|marque}."
		),
		&"paid_leave": AuthoredDescription.new(
			"+{n:reward:constant} {kw:coins|coin} per {kw:validation|play} while {kw:held|held}.",
			"+{n:reward:constant} {kw:coins|pièce} par {kw:validation|coup} tant que {kw:held|gardé}."
		),
		&"rolling_income": AuthoredDescription.new(
			"+{n:reward:constant} {kw:coins|coin} whenever this die is {kw:reroll|manually rolled}.",
			"+{n:reward:constant} {kw:coins|pièce} quand ce dé est {kw:reroll|lancé manuellement}."
		),
		&"extremities": AuthoredDescription.new(
			"+{n:reward:constant} {kw:mult} at either end of a {kw:straight|straight}.",
			"+{n:reward:constant} {kw:mult} à une extrémité d’une {kw:straight|suite}."
		),
		&"neighbours": AuthoredDescription.new(
			"{kw:validated|Played}: +{n:reward:constant} {kw:mult} with both adjacent values {kw:validated|played}.",
			"{kw:validated|Joué} : +{n:reward:constant} {kw:mult} avec les deux valeurs voisines {kw:validated|jouées}."
		),
		&"first_instinct": AuthoredDescription.new(
			"{kw:validated|Played}: +{n:reward:constant} {kw:mult} if never {kw:reroll|manually rolled} this {kw:round|round}.",
			"{kw:validated|Joué} : +{n:reward:constant} {kw:mult} si jamais {kw:reroll|lancé manuellement} cette {kw:round|manche}."
		),
		&"persistence": AuthoredDescription.new(
			"{kw:validated|Played}: +{n:reward:coefficient} {kw:mult} per {kw:reroll|manual roll} of this die. Resets after playing it or each {kw:round|round}.",
			"{kw:validated|Joué} : +{n:reward:coefficient} {kw:mult} par {kw:reroll|lancer manuel} de ce dé. Remis à zéro après l’avoir joué ou à chaque {kw:round|manche}."
		),
		&"opening_act": AuthoredDescription.new(
			"+{n:reward:constant} {kw:mult} if {kw:validated|played} on the first {kw:validation|play} of the {kw:round|round}.",
			"+{n:reward:constant} {kw:mult} si {kw:validated|joué} au premier {kw:validation|coup} de la {kw:round|manche}."
		),
		&"grand_finale": AuthoredDescription.new(
			"+{n:reward:constant} {kw:mult} if {kw:validated|played} with one {kw:validation|play} left.",
			"+{n:reward:constant} {kw:mult} si {kw:validated|joué} au dernier {kw:validation|coup} disponible."
		),
		&"echo": AuthoredDescription.new(
			"+{n:reward:constant} {kw:mult} when {kw:validated|played} again with the same value this {kw:round|round}.",
			"+{n:reward:constant} {kw:mult} si {kw:validated|joué} à nouveau avec la même valeur cette {kw:round|manche}."
		),
		&"match_master": AuthoredDescription.new(
			"+{n:reward:per_die} {kw:points} per die in a {kw:matching|matching combination}.",
			"+{n:reward:per_die} {kw:points} par dé d’une {kw:matching|combinaison de dés identiques}."
		),
		&"bipolarity": AuthoredDescription.new(
			"+{n:reward:per_die} {kw:points} per {kw:validated|played} 1 or 6.",
			"+{n:reward:per_die} {kw:points} par 1 ou 6 {kw:validated|joué}."
		),
		&"mathmind": AuthoredDescription.new(
			"+{n:reward:constant} {kw:points} if {kw:validated|played} dice total 15.",
			"+{n:reward:constant} {kw:points} si les dés {kw:validated|joués} totalisent 15."
		),
		&"odd_squad": AuthoredDescription.new(
			"+{n:reward:per_die} {kw:points} per {kw:validated|played} odd die.",
			"+{n:reward:per_die} {kw:points} par dé impair {kw:validated|joué}."
		),
		&"even_squad": AuthoredDescription.new(
			"+{n:reward:per_die} {kw:points} per {kw:validated|played} even die.",
			"+{n:reward:per_die} {kw:points} par dé pair {kw:validated|joué}."
		),
		&"variety_show": AuthoredDescription.new(
			"+{n:reward:coefficient} {kw:points} per distinct {kw:validated|played} value.",
			"+{n:reward:coefficient} {kw:points} par valeur {kw:validated|jouée} distincte."
		),
		&"less_is_more": AuthoredDescription.new(
			"+{n:reward:per_die} {kw:points} per {kw:held|held} die.",
			"+{n:reward:per_die} {kw:points} par dé {kw:held|gardé}."
		),
		&"backup": AuthoredDescription.new(
			"+{n:reward:per_die} {kw:points} per {kw:held|held} die matching a {kw:validated|played} die.",
			"+{n:reward:per_die} {kw:points} par dé {kw:held|gardé} de même valeur qu’un dé {kw:validated|joué}."
		),
		&"stonks": AuthoredDescription.new(
			"Gains {n:reward:constant} {kw:coins|coin} in sell value per won {kw:round|round}.",
			"Gagne {n:reward:constant} {kw:coins|pièce} de valeur de vente par {kw:round|manche} gagnée."
		),
		&"window_shopper": AuthoredDescription.new(
			"Gains +{n:refresh_growth:constant} {kw:mult} per paid {kw:shop_refresh|shop refresh}. Starts at +0.",
			"Gagne +{n:refresh_growth:constant} {kw:mult} par {kw:shop_refresh|renouvellement payant}. Débute à +0."
		),
		&"portfolio": AuthoredDescription.new(
			"+{kw:mult} equal to your {kw:joker|Jokers}’ total sell value.",
			"+{kw:mult} égal à la valeur de vente totale de vos {kw:joker|Jokers}."
		),
		&"alignment": AuthoredDescription.new(
			"+{n:reward:per_die} {kw:points} per die in a {kw:straight|straight}.",
			"+{n:reward:per_die} {kw:points} par dé d’une {kw:straight|suite}."
		),
		&"missing_link": AuthoredDescription.new(
			"{kw:straight|Straights} may skip one value. Example: 1–2–4–5.",
			"Les {kw:straight|suites} peuvent sauter une valeur. Exemple : 1–2–4–5."
		),
		&"last_chance": AuthoredDescription.new(
			"+{n:reward:constant} {kw:points} with no {kw:reroll|manual rolls} left.",
			"+{n:reward:constant} {kw:points} sans {kw:reroll|lancer manuel} restant."
		),
		&"extra_time": AuthoredDescription.new(
			"+{n:reward:constant} {kw:validation|play} per {kw:round|round}.",
			"+{n:reward:constant} {kw:validation|coup} par {kw:round|manche}."
		),
		&"second_chance": AuthoredDescription.new(
			"+{n:reward:constant} {kw:reroll|manual roll} per {kw:round|round}.",
			"+{n:reward:constant} {kw:reroll|lancer manuel} par {kw:round|manche}."
		),
		&"momentum": AuthoredDescription.new(
			"+{n:reward:coefficient} {kw:points} per previous {kw:validation|play} this {kw:round|round}.",
			"+{n:reward:coefficient} {kw:points} par {kw:validation|coup} précédent cette {kw:round|manche}."
		),
		&"habit": AuthoredDescription.new(
			"+{n:reward:constant} {kw:points} for the same {kw:combination|combination} as the previous {kw:validation|play} this {kw:round|round}.",
			"+{n:reward:constant} {kw:points} pour la même {kw:combination|combinaison} qu’au {kw:validation|coup} précédent de cette {kw:round|manche}."
		),
		&"variety": AuthoredDescription.new(
			"+{n:reward:constant} {kw:points} for a different {kw:combination|combination} from the previous {kw:validation|play} this {kw:round|round}.",
			"+{n:reward:constant} {kw:points} pour une autre {kw:combination|combinaison} qu’au {kw:validation|coup} précédent de cette {kw:round|manche}."
		),
	}
