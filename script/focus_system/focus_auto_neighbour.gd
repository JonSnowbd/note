extends Node
class_name FocusAutoNeighbour

## Automatically sets up the parent's children neighbours.
## Works for: VBoxContainer, HBoxContainer, GridContainer.
## Automatically updates each time re-layout happens.

@export var exclude: Array[Control] = []
@export var horizontal_loop: bool = false
@export var vertical_loop: bool = false
## When up is pressed at the end of a non-vertically looped column, this is the result.
@export var top_exit_ramp: Control
## When down is pressed at the end of a non-vertically looped column, this is the result.
@export var bottom_exit_ramp: Control
## When left is pressed at the end of a non-horizontally looped row, this is the result.
@export var left_exit_ramp: Control
## When right is pressed at the end of a non-horizontally looped row, this is the result.
@export var right_exit_ramp: Control

func _clear_focus_groups(control: Control):
	control.focus_neighbor_top = ""
	control.focus_neighbor_right = ""
	control.focus_neighbor_bottom = ""
	control.focus_neighbor_left = ""
func _set_focus_groups_to_ramps(control: Control):
	if top_exit_ramp != null:
		control.focus_neighbor_top = control.get_path_to(top_exit_ramp)
	if right_exit_ramp != null:
		control.focus_neighbor_right = control.get_path_to(right_exit_ramp)
	if bottom_exit_ramp != null:
		control.focus_neighbor_bottom = control.get_path_to(bottom_exit_ramp)
	if left_exit_ramp != null:
		control.focus_neighbor_left = control.get_path_to(left_exit_ramp)
func update_child_focus_states():
	var parent = get_parent()
	var child_nodes: Array[Control] = []
	for child in parent.get_children():
		if child is Control and child.visible and !exclude.has(child):
			child_nodes.append(child as Control)
	if parent is BoxContainer:
		var horizontal = !parent.vertical

		if horizontal:
			_update_box(child_nodes, horizontal, left_exit_ramp, right_exit_ramp)
		else:
			_update_box(child_nodes, horizontal, top_exit_ramp, bottom_exit_ramp)
		
		for c in child_nodes:
			if horizontal:
				if top_exit_ramp != null:
					c.focus_neighbor_top = c.get_path_to(top_exit_ramp)
				else:
					c.focus_neighbor_top = ""
				if bottom_exit_ramp != null:
					c.focus_neighbor_bottom = c.get_path_to(bottom_exit_ramp)
				else:
					c.focus_neighbor_bottom = ""
			else:
				if left_exit_ramp != null:
					c.focus_neighbor_left = c.get_path_to(left_exit_ramp)
				else:
					c.focus_neighbor_left = ""
				if right_exit_ramp != null:
					c.focus_neighbor_right = c.get_path_to(right_exit_ramp)
				else:
					c.focus_neighbor_right = ""
	
	if parent is GridContainer:
		_update_grid(child_nodes, parent.columns)

func ind_1_to_2(ind: int, columns: int) -> Vector2i:
	return Vector2i(ind % columns, floori(ind/columns))
func ind_2_to_1(ind: Vector2i, columns: int) -> int:
	return (ind.y*columns) + ind.x
func _update_grid(children: Array[Control], columns: int):
	if len(children) == 0:
		return
	if len(children) == 1:
		return
	
	var slice: Array[Control] = [] 
	var total_rows: int = (floori(len(children)/columns))+1
	
	# Update Vertical scanlines.
	for x in range(columns):
		slice.clear()
		for y in range(total_rows):
			var ind = ind_2_to_1(Vector2i(x,y), columns)
			if ind >= 0 and ind < len(children):
				slice.append(children[ind])
		_update_box(slice, false, top_exit_ramp, bottom_exit_ramp)
	# Update Horizontal scanlines.
	for y in range(total_rows):
		slice.clear()
		for x in range(columns):
			var ind = ind_2_to_1(Vector2i(x,y), columns)
			if ind >= 0 and ind < len(children):
				slice.append(children[ind])
		_update_box(slice, true, left_exit_ramp, right_exit_ramp)

func _update_box(children: Array[Control], horizontal: bool, negative_control: Control, positive_control: Control):
	if len(children) == 0:
		return
	if len(children) == 1:
		if horizontal:
			if negative_control != null:
				children[0].focus_neighbor_left = children[0].get_path_to(negative_control)
			else:
				children[0].focus_neighbor_left = ""
			if positive_control != null:
				children[0].focus_neighbor_right = children[0].get_path_to(positive_control)
			else:
				children[0].focus_neighbor_right = ""
		else:
			if negative_control != null:
				children[0].focus_neighbor_top = children[0].get_path_to(negative_control)
			else:
				children[0].focus_neighbor_top = ""
			if positive_control != null:
				children[0].focus_neighbor_bottom = children[0].get_path_to(positive_control)
			else:
				children[0].focus_neighbor_bottom = ""
		return
	for i in range(len(children)):
		if i == 0: # First node X | O | O | O
			if horizontal:
				if horizontal_loop:
					children[i].focus_neighbor_left = children[i].get_path_to(children[-1])
				elif negative_control != null:
					children[i].focus_neighbor_left = children[i].get_path_to(negative_control)
				children[i].focus_neighbor_right = children[i].get_path_to(children[i+1])
			else:
				if vertical_loop:
					children[i].focus_neighbor_top = children[i].get_path_to(children[-1])
				elif negative_control != null:
					children[i].focus_neighbor_top = children[i].get_path_to(negative_control)
				children[i].focus_neighbor_bottom = children[i].get_path_to(children[i+1])
		elif i+1 >= len(children): # End Node O | O | O | X
			if horizontal:
				if horizontal_loop:
					children[i].focus_neighbor_right = children[i].get_path_to(children[0])
				elif positive_control != null:
					children[i].focus_neighbor_right = children[i].get_path_to(positive_control)
				children[i].focus_neighbor_left = children[i].get_path_to(children[i-1])
			else:
				if vertical_loop:
					children[i].focus_neighbor_bottom = children[i].get_path_to(children[0])
				elif positive_control != null:
					children[i].focus_neighbor_bottom = children[i].get_path_to(positive_control)
				children[i].focus_neighbor_top = children[i].get_path_to(children[i-1])
		else: # Middle Nodes O | X | X | O
			if horizontal:
				children[i].focus_neighbor_left = children[i].get_path_to(children[i-1])
				children[i].focus_neighbor_right = children[i].get_path_to(children[i+1])
			else:
				children[i].focus_neighbor_top = children[i].get_path_to(children[i-1])
				children[i].focus_neighbor_bottom = children[i].get_path_to(children[i+1])

func _ready() -> void:
	var parent = get_parent()
	if parent is Container:
		parent.sort_children.connect(update_child_focus_states)
func _enter_tree() -> void:
	update_child_focus_states()
