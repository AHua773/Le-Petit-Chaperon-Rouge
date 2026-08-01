extends Node

signal fragment_collected(fragment_id: String, collected_count: int)

const TOTAL_FRAGMENTS := 6
const FRAGMENT_NAMES := {
	"memory_01": "Pink Bow",
	"memory_02": "Broken Signpost",
	"memory_03": "The Watching Eye",
	"memory_04": "Hunter's Late Weapon",
	"memory_05": "Door Deed and Key",
	"memory_06": "Wolf-Crest Shield",
}
const FRAGMENT_ORDER := [
	"memory_01",
	"memory_02",
	"memory_03",
	"memory_04",
	"memory_05",
	"memory_06",
]
const MEMORY_ARCHIVE := {
	"memory_01": {
		"index": "01",
		"name": "Pink Bow",
		"artifact": "A ribbon tied to obedience",
		"memory": "Mother: Follow the path. Don't ask where it leads. Find the six forgotten objects in the forest.",
		"story": "Mother tied the bow before Little Red left the village. The knot looked tender, but every pull tightened the same instruction: stay visible, stay agreeable, and never ask who chose the road. The first rule reached her disguised as affection.",
		"truth": "Care can become discipline when love is used to make obedience feel natural. Little Red was taught to fear deviation before she was old enough to understand the path.",
		"connection": "The journey begins with an order that sounds protective. Recovering the bow lets Little Red separate her mother's love from the rule hidden inside it.",
	},
	"memory_02": {
		"index": "02",
		"name": "Broken Signpost",
		"artifact": "An erased direction",
		"memory": "Little Red: There used to be a path here, but the villagers say I remembered it wrong.",
		"story": "The sign once pointed away from the village road. Its letters were scraped out, its boards split, and vines were encouraged to cover what remained. When Little Red remembered the missing turn, the villagers did not deny the sign. They taught her to doubt herself instead.",
		"truth": "Power does not only block alternatives. It erases their evidence, then calls anyone who remembers them confused. The hidden road survives because memory survives.",
		"connection": "This object identifies the entrance to the true route. Once every memory is restored, Little Red must return to the signpost and trust what she remembers.",
	},
	"memory_03": {
		"index": "03",
		"name": "The Watching Eye",
		"artifact": "The village gaze",
		"memory": "Villager: If you see her leave the path, tell the others. It isn't malice. It's the rule.",
		"story": "No single villager needed to follow Little Red. Each person watched a little, repeated a warning, and reported every step away from the road. Their shared gaze turned the forest edge into a fence without walls.",
		"truth": "Surveillance becomes strongest when ordinary people perform it for one another and call it responsibility. The rule survives through the fear of being seen disobeying it.",
		"connection": "The eye explains why the obvious road feels compulsory. To find the hidden route, Little Red must stop treating the village's gaze as proof that she is wrong.",
	},
	"memory_04": {
		"index": "04",
		"name": "Hunter's Late Weapon",
		"artifact": "Protection that arrived afterward",
		"memory": "Hunter: When it is all over, I will break down the door. My mark can only protect this small circle by the wall.",
		"story": "The hunter's weapon rests beside a refuge too small to save the forest. His mark can clear the wolves nearby, but only after Little Red has already crossed their territory. He promises to break the door when the danger has become undeniable.",
		"truth": "Institutional protection can be real and still be late, narrow, and insufficient. It often responds to visible harm instead of confronting the conditions that allowed the harm.",
		"connection": "The hunter's mark creates a brief safe circle, not an escape. Little Red must use that limited protection without mistaking it for rescue.",
	},
	"memory_05": {
		"index": "05",
		"name": "Door Deed and Key",
		"artifact": "A promise of safety and ownership",
		"memory": "Grandmother: Child, I did not lock the door. The house learned to close it for them.",
		"story": "The deed says who owns the house. The key says who may enter. Yet Grandmother's door began obeying people who possessed neither. The house learned their rules until confinement looked like shelter and permission looked like safety.",
		"truth": "A protected space can become a controlled space. Doors, homes, and rules do not guarantee safety when the same power decides who may cross them.",
		"connection": "The key reveals that the bright front entrance is a trap. Reaching Grandmother requires refusing the door that has been presented as the only proper way inside.",
	},
	"memory_06": {
		"index": "06",
		"name": "Wolf-Crest Shield",
		"artifact": "The emblem of permitted violence",
		"memory": "Wolf: You think I am the wolf? I am the darkness they permit to exist.",
		"story": "The wolf's crest is carried like an official seal. The creature does not hide from the road or the house because both have already made room for it. When challenged, it speaks with the confidence of something protected by the rules it appears to violate.",
		"truth": "The wolf is not a flaw in the system. It is violence the system recognizes, excuses, and allows to continue. Defeating one body would leave the permission untouched.",
		"connection": "This is why the Defining Wolf cannot be killed here. Little Red wins by restoring the erased truth, rejecting the false entrance, and walking the hidden road.",
	},
}

var collected_fragments: Dictionary = {}


func collect_fragment(fragment_id: String) -> bool:
	if fragment_id.is_empty() or collected_fragments.has(fragment_id):
		return false

	collected_fragments[fragment_id] = true
	fragment_collected.emit(fragment_id, get_collected_count())
	return true


func restore_fragments(fragment_ids: PackedStringArray) -> void:
	collected_fragments.clear()
	for fragment_id in fragment_ids:
		if fragment_id.is_empty() or not FRAGMENT_NAMES.has(fragment_id):
			continue
		collected_fragments[fragment_id] = true
		fragment_collected.emit(fragment_id, get_collected_count())


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


func get_fragment_display_name(fragment_id: String) -> String:
	return str(FRAGMENT_NAMES.get(fragment_id, fragment_id))


func get_fragment_archive(fragment_id: String) -> Dictionary:
	var archive: Dictionary = MEMORY_ARCHIVE.get(fragment_id, {})
	return archive.duplicate(true)


func get_collected_fragment_ids() -> PackedStringArray:
	var fragment_ids := PackedStringArray()
	for fragment_id in FRAGMENT_ORDER:
		if has_fragment(fragment_id):
			fragment_ids.append(fragment_id)
	return fragment_ids


func get_missing_fragment_names(fragment_ids: PackedStringArray) -> PackedStringArray:
	var missing_names := PackedStringArray()
	for fragment_id in fragment_ids:
		if not has_fragment(fragment_id):
			missing_names.append(get_fragment_display_name(fragment_id))

	return missing_names


func get_collected_count() -> int:
	return collected_fragments.size()


func get_total_count() -> int:
	return TOTAL_FRAGMENTS
