@tool
class_name VisibilityCollisionShapeHandler

var _visibility_ep : VisibilityCollisionShapeEP
var _instanced_nodes : Array[Node]
var _local_nodes : Array[Node]

func _can_handle(object: Object) -> bool:
	return Engine.is_editor_hint() \
	and (object is CollisionPolygon2D \
	or object is CollisionPolygon3D \
	or object is CollisionShape2D \
	or object is CollisionShape3D) \
	and not _local_nodes.has(object) \
	and not _instanced_nodes.has(object)

func _parse(object: Object) -> void:
	var node : Node = object;
	_add_to_array(object)

func _on_node_added(node: Node) -> void:
	if _can_handle(node):
		_parse(node)

func _on_node_removed(node: Node) -> void:
	if node is CollisionPolygon2D \
	or node is CollisionPolygon3D \
	or node is CollisionShape2D \
	or node is CollisionShape3D:
		_local_nodes.erase(node)
		_instanced_nodes.erase(node)

func _on_scene_changed(root_node: Node) -> void:
	for array in [_instanced_nodes, _local_nodes]:
		for index in range(array.size() -1, -1, -1):
			var node = array[index]
			if not is_instance_valid(node):
				array.remove_at(index)

func _get_all_node_recursively(current_array: Array, current_node: Node) -> Array:
	var result = current_array
	if current_node.get_child_count() <= 0:
		return result
	for child in current_node.get_children():
		if (child is CollisionPolygon2D \
		or child is CollisionPolygon3D \
		or child is CollisionShape2D \
		or child is CollisionShape3D) \
		and not _local_nodes.has(child) \
		and not _instanced_nodes.has(child):
			current_array.append(child)
		result = _get_all_node_recursively(current_array, child)
	return result

func _add_to_array(node:Node) ->void:
	if is_instance_valid(node):
		if node.owner == Engine.get_main_loop().edited_scene_root:
			_local_nodes.append(node)
			node.visible = _visibility_ep.is_set_visible(_visibility_ep.name_to_id["local_collision_id"])
		else:
			_instanced_nodes.append(node)
			node.visible = _visibility_ep.is_set_visible(_visibility_ep.name_to_id["instanced_collision_id"])
	
func set_collision_visibility(enable: bool, local: bool):
	if local:
		for node in _local_nodes:
			if not is_instance_valid(node):
				continue
			
			if enable and _has_checked_layer(node):
				node.visible = true
			else:
				node.visible = false
	else:
		for node in _instanced_nodes:
			if not is_instance_valid(node):
				continue
			
			if enable and _has_checked_layer(node):
				node.visible = true
			else:
				node.visible = false

func _has_checked_layer(node: Node) -> bool:
	for layer in _visibility_ep.enabled_layers:
		# Check if any layer the node is on is enabled
		if _visibility_ep.enabled_layers[layer] \
		and _is_valid_parent(node) \
		and node.get_parent().get_collision_layer_value(layer + 1):
			return true
		
		# This is for case where the collision shape doesnt have a valid parent but has a shape
		elif _visibility_ep.enabled_layers[layer] \
		and not _is_valid_parent(node) \
		and layer < 20 \
		and node.has_method("get_visibility_layer_bit") \
		and node.get_visibility_layer_bit(layer):
			return true
		
		# Check if the parent is not valid also don't have get_visibility_layer_bit method
		# This shouldn't happend but if it does then enable them anyway because we don't know how to check if they are "valid"
		elif not _is_valid_parent(node) and not node.has_method("get_visibility_layer_bit"):
			return true
	
	return false

func _is_valid_parent(node: Node) -> bool:
	var parent = node.get_parent()
	return parent is CollisionObject2D or parent is CollisionObject3D
