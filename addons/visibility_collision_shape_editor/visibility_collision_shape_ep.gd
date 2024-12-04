@tool
class_name VisibilityCollisionShapeEP extends EditorPlugin

var _visibility_shape_handler : VisibilityCollisionShapeHandler

# OUR menu
var _3d_popup_menu : PopupMenu
var _2d_popup_menu : PopupMenu

# The OG menu
var _2d_view_menu : PopupMenu
var _3d_view_menu : PopupMenu

var name_to_id : Dictionary
var enabled_layers : Dictionary

# Since the button is already synced we only need to check of them if they are enabled
func is_set_visible(index) -> bool:
	return _2d_popup_menu.is_item_checked(index)

func _enter_tree() -> void:
	# Initialize the layer
	for i in 32:
		enabled_layers[i] = true
	
	# Add new options to 2D view popup menu
	var placeholder = Control.new()
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, placeholder)
	_2d_popup_menu = _bind_to_popup(placeholder, true)
	placeholder.queue_free()
	
	# Add new options to 3D view popup menu
	placeholder = Control.new()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, placeholder)
	_3d_popup_menu = _bind_to_popup(placeholder, false)
	placeholder.queue_free()
	
	_visibility_shape_handler = VisibilityCollisionShapeHandler.new()
	_visibility_shape_handler._visibility_ep = self
	
	Engine.get_main_loop().node_added.connect(_visibility_shape_handler._on_node_added)
	Engine.get_main_loop().node_removed.connect(_visibility_shape_handler._on_node_removed)
	scene_changed.connect(_on_scene_changed)
	scene_changed.connect(_visibility_shape_handler._on_scene_changed)
	
	VisibilityCollisionShapeSaveHandler.load_file(self)

func _exit_tree() -> void:
	# Delete OUR menu from the OG menu
	var idx = _2d_view_menu.get_item_index(name_to_id["collision_visibility_2d_id"])
	if idx != -1:
		_2d_view_menu.remove_item(idx)
	
	idx = _2d_view_menu.get_item_index(name_to_id["collision_visibility_3d_id"])
	if idx != -1:
		_3d_view_menu.remove_item(idx)
	
	# Delete the thread used for saving if it exist
	if VisibilityCollisionShapeSaveHandler._thread:
		VisibilityCollisionShapeSaveHandler._thread.wait_to_finish()
		VisibilityCollisionShapeSaveHandler._thread = null
	
	# Clear everything from OUR menu so we don't get memory leaks
	# Technically we could use Array to reduce the repetitive code
	# But at this point in time we want to clear our resources with as little overhead as possible
	_2d_popup_menu.clear(true)
	_3d_popup_menu.clear(true)
	
	_2d_popup_menu.queue_free()
	_3d_popup_menu.queue_free()

func _on_scene_changed(root_node: Node) -> void:
	if not is_instance_valid(root_node):
		return
	for popup_menu in [_2d_popup_menu, _3d_popup_menu]:
		if is_instance_valid(popup_menu) and popup_menu.is_item_checked(popup_menu.get_item_index(name_to_id["local_collision_id"])):
			_visibility_shape_handler.set_collision_visibility(true, true)
		if is_instance_valid(popup_menu) and popup_menu.is_item_checked(popup_menu.get_item_index(name_to_id["instanced_collision_id"])):
			_visibility_shape_handler.set_collision_visibility(true, false)

func _bind_to_popup(placeholder: Control, is_2d: bool) -> PopupMenu:
	# The placeholder is simply to get to the right parent so we only need to traverse a few times
	var parent = placeholder.get_node("../../../").get_child(0)
	
	var parent_popup_menu : PopupMenu = _find_menu_button(parent).get_popup()
	
	if is_2d:
		_2d_view_menu = parent_popup_menu
	else:
		_3d_view_menu = parent_popup_menu
	
	var collision_visibility_menu := PopupMenu.new()
	
	# I know you will raise your eyebrow reading this
	var id : int = parent_popup_menu.item_count + 100
	parent_popup_menu.add_submenu_node_item("Collision Visibility", collision_visibility_menu, id)
	name_to_id["collision_visibility_%s_id" % ("2d" if is_2d else "3d")] = id
	
	id = collision_visibility_menu.item_count
	collision_visibility_menu.add_check_item("Show Both",  id)
	name_to_id["show_all_id"] = id
	
	id = collision_visibility_menu.item_count
	collision_visibility_menu.add_check_item("Show Local", id)
	name_to_id["local_collision_id"] = id
	
	id = collision_visibility_menu.item_count
	collision_visibility_menu.add_check_item("Show Instanced", id)
	name_to_id["instanced_collision_id"] = id
	
	id = collision_visibility_menu.item_count
	collision_visibility_menu.add_item("Visibility Layer",  id)
	name_to_id["individual_layer_id"] = id
	
	for item_id in name_to_id.values():
		var set_enable := true if item_id != name_to_id["individual_layer_id"] else false
		collision_visibility_menu.set_item_as_checkable(collision_visibility_menu.get_item_index(item_id), set_enable)
		collision_visibility_menu.set_item_checked(collision_visibility_menu.get_item_index(item_id), set_enable)
	
	collision_visibility_menu.index_pressed.connect(_on_press_visibility.bind(collision_visibility_menu, parent_popup_menu))
	
	placeholder.hide()
	return collision_visibility_menu

func _find_menu_button(target: Node) -> MenuButton:
	for idx in range(target.get_child_count() -1, -1, -1):
		if target.get_child(idx) is MenuButton:
			return target.get_child(idx)
	return null

func _on_press_visibility(idx: int, collision_visibility_menu: PopupMenu, parent_popup: PopupMenu) -> void:
	if idx == collision_visibility_menu.get_item_index(name_to_id["show_all_id"]):
		var set_enable : bool = not collision_visibility_menu.is_item_checked(idx)
		collision_visibility_menu.set_item_checked(idx, set_enable)
		
		# Sync the Show Both button to local and instanced
		_set_collision_visibility(collision_visibility_menu.get_item_index(name_to_id["local_collision_id"]), collision_visibility_menu, set_enable)
		_set_collision_visibility(collision_visibility_menu.get_item_index(name_to_id["instanced_collision_id"]), collision_visibility_menu, set_enable)
		
		VisibilityCollisionShapeSaveHandler.save_file(self)
		
	elif idx == collision_visibility_menu.get_item_index(name_to_id["local_collision_id"]):
		var set_enable : bool = not collision_visibility_menu.is_item_checked(idx)
		_set_collision_visibility(collision_visibility_menu.get_item_index(name_to_id["local_collision_id"]), collision_visibility_menu, set_enable)
		
		# Sync the local button to Show Both button
		var instanced_collision_idx = collision_visibility_menu.get_item_index(name_to_id["instanced_collision_id"])
		if set_enable and collision_visibility_menu.is_item_checked(instanced_collision_idx):
			collision_visibility_menu.set_item_checked(collision_visibility_menu.get_item_index(name_to_id["show_all_id"]), true)
		
		elif not set_enable:
			collision_visibility_menu.set_item_checked(collision_visibility_menu.get_item_index(name_to_id["show_all_id"]), false)
		
		VisibilityCollisionShapeSaveHandler.save_file(self)
		
	elif idx == collision_visibility_menu.get_item_index(name_to_id["instanced_collision_id"]):
		var set_enable : bool = not collision_visibility_menu.is_item_checked(idx)
		_set_collision_visibility(collision_visibility_menu.get_item_index(name_to_id["instanced_collision_id"]), collision_visibility_menu, set_enable)
		
		# Sync the instanced button to Show Both button
		var local_collision_idx = collision_visibility_menu.get_item_index(name_to_id["local_collision_id"])
		if set_enable and collision_visibility_menu.is_item_checked(local_collision_idx):
			collision_visibility_menu.set_item_checked(collision_visibility_menu.get_item_index(name_to_id["show_all_id"]), true)
		
		elif not set_enable:
			collision_visibility_menu.set_item_checked(collision_visibility_menu.get_item_index(name_to_id["show_all_id"]), false)
		
		VisibilityCollisionShapeSaveHandler.save_file(self)
		
	elif idx == collision_visibility_menu.get_item_index(name_to_id["individual_layer_id"]):
		# Hide the View menu
		parent_popup.visible = false
		
		var popup = load("res://addons/visibility_collision_shape_editor/scenes/Visibility Window.tscn").instantiate()
		popup.close_requested.connect(func(): popup.queue_free())
		popup.visibility_ep = self
		
		# Get from singleton instead of using EditorInterface directly because it only exist on the editor
		Engine.get_singleton("EditorInterface").popup_dialog_centered(popup)
		
		# Sync the layer button to the current settings
		popup.sync_button_layer()
		
		# I don't remember why its calling this originally but i think its redundant now
		#VisibilityCollisionShapeSaveHandler.save_file(self)

# Enable/disable the Local/Instanced button
func _set_collision_visibility(idx: int, collision_visibility_menu: PopupMenu, enable: bool) -> void:
	if not idx == collision_visibility_menu.get_item_index(name_to_id["local_collision_id"]) \
		and not idx == collision_visibility_menu.get_item_index(name_to_id["instanced_collision_id"]):
		return
	
	collision_visibility_menu.set_item_checked(idx, enable)
	
	var synced_idx : int
	if collision_visibility_menu == _2d_popup_menu:
		synced_idx = _sync_item_idx(_2d_popup_menu, _3d_popup_menu, idx)
		_3d_popup_menu.set_item_checked(synced_idx, enable)
	else:
		synced_idx = _sync_item_idx(_3d_popup_menu, _2d_popup_menu, idx)
		_2d_popup_menu.set_item_checked(synced_idx, enable)
	
	_visibility_shape_handler.set_collision_visibility(enable,\
											idx == collision_visibility_menu.get_item_index(name_to_id["local_collision_id"]))

# Sync item index from the 2D menu to the 3D menu
func _sync_item_idx(from: PopupMenu, to: PopupMenu, target_idx: int) -> int:
	if target_idx == from.get_item_index(name_to_id["local_collision_id"]):
		return to.get_item_index(name_to_id["local_collision_id"])
	else:
		return to.get_item_index(name_to_id["instanced_collision_id"])
