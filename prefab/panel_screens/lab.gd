@tool
extends PanelContainer

@export var code: CodeEdit

@export var run_button: Button
@export var clear_button: Button

const default_source = """extends Node

func _work():
	# Do stuff here
	print("Hello world!")"""

func _ready() -> void:
	code.text = default_source
	run_button.pressed.connect(func():
		run_code()
	)
	clear_button.pressed.connect(func():
		code.text = default_source
	)
	code.syntax_highlighter = GDScriptSyntaxHighlighter.new()

func run_code():
	var run_script = GDScript.new()
	run_script.source_code = code.text
	run_script.reload()
	var instance = run_script.new()
	instance._work()
