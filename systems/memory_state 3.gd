extends Node

signal fragment_collected(fragment_id: String, collected_count: int)

const TOTAL_FRAGMENTS := 6

var collected_fragments: Dictionary = {}


func collect_fragment(fragment_id: String) -> bool:
	if fragment_id.is_empty() or collected_fragments.has(fragment_id):
		return false

	collected_fragments[fragment_id] = true
	fragment_collected.emit(fragment_id, get_collected_count())
	return true


func has_fragment(fragment_id: String) -> bool:
	return collected_fragments.has(fragment_id)


func has_fragments(fragment_ids: PackedStringArray) -> bool:
	for fragment_id in fragment_ids:
		if not has_fragment(fragment_id):
			return false

	return true


func count_matching(fragment_ids: PackedStringArray) -> int:
	var count := 0
	for fragment_id in fragment_ids:
		if has_fragment(fragment_id):
			count += 1

	return count


func get_collected_count() -> int:
	return collected_fragments.size()


func get_total_count() -> int:
	return TOTAL_FRAGMENTS
