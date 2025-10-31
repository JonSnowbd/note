@tool
extends PanelContainer

@export var code: CodeEdit

@export var run_button: Button
@export var clear_button: Button

var expression: Expression

func _init() -> void:
	expression = Expression.new()

func _ready() -> void:
	run_button.pressed.connect(func():
		run_code()
	)
	clear_button.pressed.connect(func():
		code.text = ""
	)
	code.syntax_highlighter = GDScriptSyntaxHighlighter.new()

func run_code():
	var err = expression.parse(code.text)
	if err != OK:
		push_error("Note lab script error: "+expression.get_error_text())
		return
	var result = expression.execute()
	if expression.has_execute_failed():
		push_error("Note lab script error: "+expression.get_error_text())
		return
