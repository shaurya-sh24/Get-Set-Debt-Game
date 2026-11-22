extends Area3D

@onready var mesh: MeshInstance3D = $"../MeshInstance3D2" # Your Cylinder Mesh
@onready var sub_viewport: SubViewport = $"../SubViewport"

func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouse:
		# 1. Get the local collision position relative to the mesh
		var local_pos = mesh.global_transform.affine_inverse() * event_position
		
		# 2. Get the exact local size dimensions of the primitive mesh
		# This handles Godot's default sizes and protects against scaling issues
		var mesh_size: Vector3 = mesh.mesh.get_aabb().size
		
		# 3. Normalize coordinates to a perfect 0.0 to 1.0 UV range
		# We divide by mesh_size to counteract any baked-in size offsets
		var uv_x = (local_pos.x / mesh_size.x) + 0.5
		var uv_y = (local_pos.z / mesh_size.z) + 0.5
		
		# 4. Clamp the values so moving the mouse outside the bounds doesn't send wild values
		uv_x = clamp(uv_x, 0.0, 1.0)
		uv_y = clamp(uv_y, 0.0, 1.0)
		
		# 5. Calculate final pixel position
		var pixel_pos = Vector2(uv_x, uv_y) * Vector2(sub_viewport.size)
		
		# 6. Duplicate and push the event
		var v_event = event.duplicate()
		v_event.position = pixel_pos
		v_event.global_position = pixel_pos
		
		sub_viewport.push_input(v_event)
