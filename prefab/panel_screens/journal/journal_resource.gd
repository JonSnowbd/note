@tool
extends Resource
class_name NoteJournalResource

signal word_updated

@export_file("*.gd") var scripts: Array[String] = [
	"uid://btvdvje538ery"
]
@export var documents: Array[NoteJournalDocument] = []
@export var words: Dictionary[String,Variant] = {}


class Piece extends Object:
	signal changed
	var title: String
	var uuid: String
	var root: NoteJournalResource
	func _initial_data():
		pass
	func _serialize() -> Dictionary:
		return {}
	func _deserialize(data: Dictionary):
		pass
	func _make_entry() -> Button:
		return null
	func _make_rep() -> Control:
		return null
	func _make_editor() -> Control:
		return null
	func _update():
		pass

func set_word(word: String, val: Variant):
	words[word] = val
	word_updated.emit()
