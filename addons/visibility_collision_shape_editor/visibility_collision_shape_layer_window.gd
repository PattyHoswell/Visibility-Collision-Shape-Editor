@tool
class_name VisibilityCollisionShapeLayerWindow extends Window

@export var _enable_all_button : Button
@export var _disable_all_button : Button

@export var all_layer_buttons : Array[Button]

var visibility_ep : VisibilityCollisionShapeEP

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Change the button color to the project settings accent color
	var editor_settings = Engine.get_singleton("EditorInterface").get_editor_settings()
	var project_accent_color = editor_settings.get_setting("interface/theme/accent_color")
	
	# We only need to set from one of the button because they are all using the same resource
	var button = all_layer_buttons[0]
	button.get_theme_stylebox("normal").bg_color = project_accent_color * 0.8
	button.get_theme_stylebox("pressed").bg_color = project_accent_color
	button.get_theme_stylebox("hover").bg_color = project_accent_color
	
	_enable_all_button.pressed.connect(_set_all_layer.bind(true))
	_disable_all_button.pressed.connect(_set_all_layer.bind(false))

func _set_all_layer(enable: bool) -> void:
	for idx in all_layer_buttons.size():
		var button = all_layer_buttons[idx]
		button.set_pressed_no_signal(enable)
		visibility_ep.enabled_layers[idx] = enable
	visibility_ep._visibility_shape_handler.set_collision_visibility(enable and visibility_ep.is_set_visible(visibility_ep.name_to_id["local_collision_id"]), true)
	visibility_ep._visibility_shape_handler.set_collision_visibility(enable and visibility_ep.is_set_visible(visibility_ep.name_to_id["instanced_collision_id"]), false)
	VisibilityCollisionShapeSaveHandler.save_file(visibility_ep)

func sync_button_layer() -> void:
	for idx in all_layer_buttons.size():
		var button = all_layer_buttons[idx]
		button.toggled.connect(func(toggled_on: bool):
			visibility_ep.enabled_layers[idx] = toggled_on
			visibility_ep._visibility_shape_handler.set_collision_visibility(visibility_ep.is_set_visible(visibility_ep.name_to_id["local_collision_id"]), true)
			visibility_ep._visibility_shape_handler.set_collision_visibility(visibility_ep.is_set_visible(visibility_ep.name_to_id["instanced_collision_id"]), false))
		
		button.button_pressed = visibility_ep.enabled_layers[idx]
		
		button.toggled.connect(func(toggled_on: bool): VisibilityCollisionShapeSaveHandler.save_file(visibility_ep))
	
