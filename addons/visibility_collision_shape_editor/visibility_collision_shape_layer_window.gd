@tool
class_name VisibilityCollisionShapeLayerWindow extends Window

@export var _enable_all_button : Button
@export var _disable_all_button : Button

@export var all_layer_buttons : Array[Button]

var visibility_ep : VisibilityCollisionShapeEP
var attached_menu : PopupMenu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_enable_all_button.pressed.connect(_set_all_layer.bind(true))
	_disable_all_button.pressed.connect(_set_all_layer.bind(false))

func _set_all_layer(enable: bool) -> void:
	for idx in all_layer_buttons.size():
		var button = all_layer_buttons[idx]
		button.set_pressed_no_signal(enable)
		visibility_ep.enabled_layers[idx] = enable
	visibility_ep._visibility_eip.set_collision_visibility(enable and visibility_ep.is_set_visible(visibility_ep.name_to_id["local_collision_id"]), true)
	visibility_ep._visibility_eip.set_collision_visibility(enable and visibility_ep.is_set_visible(visibility_ep.name_to_id["instanced_collision_id"]), false)
	VisibilityCollisionShapeSaveHandler.save_file(visibility_ep)

func sync_button_layer() -> void:
	for idx in all_layer_buttons.size():
		var button = all_layer_buttons[idx]
		button.toggled.connect(func(toggled_on: bool):
			visibility_ep.enabled_layers[idx] = toggled_on
			visibility_ep._visibility_eip.set_collision_visibility(visibility_ep.is_set_visible(visibility_ep.name_to_id["local_collision_id"]), true)
			visibility_ep._visibility_eip.set_collision_visibility(visibility_ep.is_set_visible(visibility_ep.name_to_id["instanced_collision_id"]), false))
		
		button.button_pressed = visibility_ep.enabled_layers[idx]
		
		button.toggled.connect(func(toggled_on: bool): VisibilityCollisionShapeSaveHandler.save_file(visibility_ep))
	
