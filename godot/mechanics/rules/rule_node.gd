extends Resource
class_name RuleNode
## Shared immutable authoring node. Mutable counters and ownership belong to runtime state.

# --- Member functions ---

## Validate the complete graph, rejecting cycles before evaluation or text generation.
func validate() -> PackedStringArray:
	return _validate_graph([], "rule")

## Return owned rule dependencies for recursive validation; shared subresources are allowed.
func dependencies() -> Array[RuleNode]:
	return []

## Validate only this node; concrete subclasses enforce their own data invariants.
func local_errors() -> PackedStringArray:
	return []

## Walk the active path, not a global visited set, to distinguish sharing from cycles.
func _validate_graph(ancestors: Array[RuleNode], path: String) -> PackedStringArray:
	if self in ancestors:
		return [path + ": cyclic rule graph"]
	if ancestors.size() >= 64:
		return [path + ": maximum rule nesting exceeded"]
	var errors: PackedStringArray = []
	for issue: String in local_errors():
		errors.append(path + ": " + issue)
	var branch: Array[RuleNode] = ancestors.duplicate()
	branch.append(self)
	var nodes: Array[RuleNode] = dependencies()
	for index: int in nodes.size():
		if not nodes[index]:
			errors.append(path + "/%d: missing rule" % index)
		else:
			errors.append_array(nodes[index]._validate_graph(branch, path + "/%d" % index))
	return errors

## Authored semantic IDs referenced by this node; concrete nodes expose dynamic keyword links.
func keyword_ids() -> Array[StringName]:
	return []

## Validate translation links alongside structure before admitting content to a catalog.
func validate_keywords(words: KeywordCatalog) -> PackedStringArray:
	var errors: PackedStringArray = validate()
	if not words:
		errors.append("Missing keyword catalog")
		return errors
	errors.append_array(words.validate())
	if errors.is_empty():
		errors.append_array(_validate_keyword_links(words))
	return errors

## Traverse only structurally valid acyclic graphs, retaining localized data ownership.
func _validate_keyword_links(words: KeywordCatalog) -> PackedStringArray:
	var errors: PackedStringArray = []
	for keyword_id: StringName in keyword_ids():
		if not words.find_keyword(keyword_id):
			errors.append("Missing keyword: " + String(keyword_id))
	for child: RuleNode in dependencies():
		errors.append_array(child._validate_keyword_links(words))
	return errors
