extends RefCounted
class_name EffectResolver
## Pure command planner. Does not recognize combinations, dispatch events, or mutate game state.

# --- Static functions ---

## Resolve one owner per call; global Jokers use a context with an empty source_die_id.
static func resolve(definition: BuildDefinition, context: EffectContext) -> EffectResolution:
	var result: EffectResolution = EffectResolution.new()
	if not definition or not context:
		result.errors.append("Definition and context are required")
		return result
	result.errors.append_array(definition.validate())
	result.errors.append_array(context.validate())
	if (definition is UpgradeDefinition or definition is BonusDefinition) and context.source_die_id == &"":
		result.errors.append("Die-bound definitions require an owner die")
	if definition is JokerDefinition and context.source_die_id != &"":
		result.errors.append("Global Jokers must not carry an owner die")
	if not result.errors.is_empty():
		return result
	for effect: EffectDefinition in definition.effects:
		if effect.trigger != context.event:
			continue
		if effect.condition and not effect.condition.matches(context):
			continue
		for action: EffectAction in effect.actions:
			for command: EffectCommand in action.commands(context):
				command.event_id = context.event_id
				command.owner_id = context.owner_id
				command.definition_id = definition.id
				command.effect_id = effect.id
				command.source_die_id = context.source_die_id
				result.commands.append(command)
	return result
