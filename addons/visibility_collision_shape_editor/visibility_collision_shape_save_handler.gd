class_name VisibilityCollisionShapeSaveHandler

const CONFIG_PATH = "res://addons/visibility_collision_shape_editor/config.ini"
static var _thread : Thread

static func save_file(visibility_ep : VisibilityCollisionShapeEP, threaded: bool = true):
	if threaded and _thread and _thread.is_started():
		_thread.wait_to_finish()
	var config_file := ConfigFile.new()
	config_file.set_value("Show or Hide", "Show Both", _is_checked(visibility_ep, visibility_ep._2d_popup_menu, "show_all_id"))
	config_file.set_value("Show or Hide", "Show Local", _is_checked(visibility_ep, visibility_ep._2d_popup_menu, "local_collision_id"))
	config_file.set_value("Show or Hide", "Show Instanced", _is_checked(visibility_ep, visibility_ep._2d_popup_menu, "instanced_collision_id"))
	for idx in visibility_ep.enabled_layers.size():
		var layer = visibility_ep.enabled_layers[idx]
		config_file.set_value("Layers", str(idx + 1), layer)
	if threaded:
		# This shouldn't happend but in edge case where the thread is somehow null before saving then create it again
		_check_null_thread()
		
		_thread.start(func():
			# Call deferred is used to call the function on the main thread
			if config_file.save(CONFIG_PATH) != OK:
				push_error.bind("Unable to save config").call_deferred()
				return)
	else:
		if config_file.save(CONFIG_PATH) != OK:
			push_error("Unable to save config")

static func load_file(visibility_ep : VisibilityCollisionShapeEP, threaded: bool = true):
	if not FileAccess.file_exists(CONFIG_PATH):
		return
	
	var config_file := ConfigFile.new()
	if threaded:
		_check_null_thread()
		_thread.start(func():
			# Call deferred is used to call the function on the main thread
			if config_file.load(CONFIG_PATH) != OK:
				push_error.bind("Unable to load config").call_deferred()
				return
			_on_load_finished.bind(visibility_ep, config_file).call_deferred())
	else:
		if config_file.load(CONFIG_PATH) != OK:
			push_error("Unable to load config")
			return
		_on_load_finished(visibility_ep, config_file)
	

static func _on_load_finished(visibility_ep : VisibilityCollisionShapeEP, config_file: ConfigFile):
	for popup_menu in [visibility_ep._2d_popup_menu, visibility_ep._3d_popup_menu]:
		popup_menu.set_item_checked(_get_index(visibility_ep, popup_menu, "show_all_id"), config_file.get_value("Show or Hide", "Show Both", true))
		popup_menu.set_item_checked(_get_index(visibility_ep, popup_menu, "local_collision_id"), config_file.get_value("Show or Hide", "Show Local", true))
		popup_menu.set_item_checked(_get_index(visibility_ep, popup_menu, "instanced_collision_id"), config_file.get_value("Show or Hide", "Show Instanced", true))
	
	for idx in visibility_ep.enabled_layers.size():
		visibility_ep.enabled_layers[idx] = config_file.get_value("Layers", str(idx + 1), true)

static func _check_null_thread():
	if not _thread:
		_thread = Thread.new()

static func _is_checked(visibility_ep : VisibilityCollisionShapeEP, popup_menu : PopupMenu, str: String) -> bool:
	return visibility_ep._2d_popup_menu.is_item_checked(popup_menu.get_item_index(visibility_ep.name_to_id[str]))

static func _get_index(visibility_ep : VisibilityCollisionShapeEP, popup_menu : PopupMenu, str: String) -> bool:
	return popup_menu.get_item_index(visibility_ep.name_to_id[str])
