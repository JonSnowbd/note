extends NoteAppFragment

@export var root_control: TabContainer

var roots: Dictionary[StringName, Container] = {}
var view_fns: Dictionary[StringName, Callable] = {}
var trees: Dictionary[StringName, NoteAppShell.ShellNode]

func fragment_update(shell: NoteAppShell, props: Dictionary[StringName,Variant]):
	var callables: Dictionary[StringName, Callable] = {}
	callables.assign(props.get(&"tabs", {}))
	
	for k in view_fns:
		if !callables.has(k):
			shell.clean_subview(trees.get(k))
			roots[k].queue_free()
			trees.erase(k)
			view_fns.erase(k)
			roots.erase(k)
	
	for k in callables.keys():
		if roots.has(k):
			pass
		else:
			var new_tab = MarginContainer.new()
			new_tab.name = k
			root_control.add_child(new_tab)
			roots[k] = new_tab
			view_fns[k] = callables[k]

func fragment_post_update(shell: NoteAppShell, self_node: NoteAppShell.ShellNode):
	for k in view_fns.keys():
		trees[k] = shell.subview(trees.get(k, null), roots[k], view_fns[k])
