extends RayCast3D

@onready var prompt_label: Label = $"../Control/Prompt"

var key_was_held: bool = false

var mouse_was_just_pressed = false

var last_collider = null



func _process(delta: float) -> void:
	if is_colliding():
		var collider = get_collider()
		if collider is Interactable:
			if last_collider and last_collider != collider:
				last_collider.hover_end()
				
			last_collider = collider
			prompt_label.text = collider.get_prompt()
			
			collider.hover_start()
			
			var key_is_down = Input.is_key_pressed(collider.prompt_keycode)
			
			if key_is_down and not key_was_held:
				collider.interact(owner)
			
			if mouse_was_just_pressed:
				collider.interact_with_mouse()
				mouse_was_just_pressed = false
			
			key_was_held = key_is_down
		else:
			if last_collider:
				last_collider.hover_end()
			prompt_label.text = ""
			key_was_held = false
	else:
		if last_collider:
				last_collider.hover_end()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		mouse_was_just_pressed = true
