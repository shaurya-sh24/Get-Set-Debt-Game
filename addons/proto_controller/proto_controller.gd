# ProtoController v1.0 by Brackeys
# CC0 License
# Intended for rapid prototyping of first-person games.
# Happy prototyping!

extends CharacterBody3D
@onready var camera_3d: Camera3D = $Head/Camera3D
@onready var texture_rect: TextureRect = $Head/Control/TextureRect
@onready var showdown_button: Button = $Head/Camera3D/CanvasLayer/Control/ShowdownButton
@onready var use_button: Button = $Head/Camera3D/CanvasLayer/Control/UseButton
@onready var main: Node3D = $".."
@onready var combo_label: Label = $Head/Control/ComboLabel
@onready var help_label: Label = $Head/Control/HelpLabel

@onready var head_control: Control = $Head/Control

@onready var color_rect: ColorRect = $Head/Control/ColorRect

@onready var round_stats: Control = $Head/Control/RoundStats
@onready var score_label: Label = $Head/Control/RoundStats/ScoreLabel
@onready var interest_earned_label: Label = $Head/Control/RoundStats/InterestEarnedLabel
@onready var new_quota_label: Label = $Head/Control/RoundStats/NewQuotaLabel
@onready var next_round_button: Button = $Head/Control/RoundStats/NextRoundButton


## Can we move around?
@export var can_move : bool = true
## Are we affected by gravity?
@export var has_gravity : bool = true
## Can we press to jump?
@export var can_jump : bool = true
## Can we hold to run?
@export var can_sprint : bool = false
## Can we press to enter freefly mode (noclip)?
@export var can_freefly : bool = false

@export_group("Speeds")
## Look around rotation speed.
@export var look_speed : float = 0.002
## Normal speed.
@export var base_speed : float = 3.0
## Speed of jump.
@export var jump_velocity : float = 4.5
## How fast do we run?
@export var sprint_speed : float = 10.0
## How fast do we freefly?
@export var freefly_speed : float = 25.0

@export_group("Input Actions")
## Name of Input Action to move Left.
@export var input_left : String = "ui_left"
## Name of Input Action to move Right.
@export var input_right : String = "ui_right"
## Name of Input Action to move Forward.
@export var input_forward : String = "ui_up"
## Name of Input Action to move Backward.
@export var input_back : String = "ui_down"
## Name of Input Action to Jump.
@export var input_jump : String = "ui_accept"
## Name of Input Action to Sprint.
@export var input_sprint : String = "sprint"
## Name of Input Action to toggle freefly mode.
@export var input_freefly : String = "freefly"

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false

## IMPORTANT REFERENCES
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
@onready var round_label: Label = $Head/Control/RoundLabel
@onready var chips_label: Label = $Head/Control/ChipsLabel

func _ready() -> void:
	next_round_button.focus_mode = Control.FOCUS_NONE
	color_rect.modulate.a = 1
	remove_color_bg()
	
	
	SignalBus.connect("enable_showdown_button", enable_showdown_button)
	SignalBus.connect("disable_showdown_button", disable_showdown_button)
	SignalBus.connect("hide_showdown_button", hide_showdown_button)
	SignalBus.connect("show_showdown_button", show_showdown_button)
	
	SignalBus.connect("enable_use_button", enable_use_button)
	SignalBus.connect("disable_use_button", disable_use_button)
	SignalBus.connect("hide_use_button", hide_use_button)
	SignalBus.connect("show_use_button", show_use_button)
	
	SignalBus.connect("give_help", give_help)
	SignalBus.connect("show_round_stats_panel", show_round_stats_panel)
	
	capture_mouse()
	check_input_mappings()
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x

func _unhandled_input(event: InputEvent) -> void:
	# Mouse capturing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if main.state != 3 and main.state != 6:
			capture_mouse()
			show_mouse()
		#capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
		hide_mouse()
	
	if Input.is_key_pressed(KEY_F):
		if showdown_button.visible and !showdown_button.disabled:
			showdown_button.pressed.emit()
		if use_button.visible and !use_button.disabled:
			use_button.pressed.emit()
	# Look around
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)
	
	# Toggle freefly mode
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()

func _physics_process(delta: float) -> void:
	# If freeflying, handle freefly and nothing else
	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return
	
	# Apply gravity to velocity
	if has_gravity:
		if not is_on_floor():
			velocity += get_gravity() * delta

	# Apply jumping
	if can_jump:
		if Input.is_action_just_pressed(input_jump) and is_on_floor():
			velocity.y = jump_velocity

	# Modify speed based on sprinting
	if can_sprint and Input.is_action_pressed(input_sprint):
			move_speed = sprint_speed
	else:
		move_speed = base_speed

	# Apply desired movement to velocity
	if can_move:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if move_dir:
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		velocity.x = 0
		velocity.y = 0
	
	# Use velocity to actually move
	move_and_slide()


## Rotate us to look around.
## Base of controller rotates around y (left/right). Head rotates around x (up/down).
## Modifies look_rotation based on rot_input, then resets basis and rotates by look_rotation.
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)

func make_current_camera():
	camera_3d.current = true

func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false

func hide_mouse():
	texture_rect.visible = false

func show_mouse():
	texture_rect.visible = true
	

func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false


## Checks if some Input Actions haven't been created.
## Disables functionality accordingly.
func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. No InputAction found for input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. No InputAction found for input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. No InputAction found for input_back: " + input_back)
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
		can_jump = false
	if can_sprint and not InputMap.has_action(input_sprint):
		push_error("Sprinting disabled. No InputAction found for input_sprint: " + input_sprint)
		can_sprint = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("Freefly disabled. No InputAction found for input_freefly: " + input_freefly)
		can_freefly = false

func enable_showdown_button():
	showdown_button.disabled = false
func disable_showdown_button():
	showdown_button.disabled = true
func show_showdown_button():
	showdown_button.visible = true
func hide_showdown_button():
	showdown_button.visible = false

func enable_use_button():
	use_button.disabled = false
func disable_use_button():
	use_button.disabled = true
func show_use_button():
	use_button.visible = true
func hide_use_button():
	use_button.visible = false


func _on_button_pressed() -> void:
	AudioManager.play_sfx("ui", -15)
	SignalBus.showdown_button_clicked.emit()


func _on_use_button_pressed() -> void:
	AudioManager.play_sfx("ui", -15)
	SignalBus.use_button_clicked.emit()

func show_combo_label(desc: String) -> void:
	combo_label.text = desc
	combo_label.visible =true
	combo_label.scale = Vector2.ONE
	combo_label.modulate.a = 1.0
	
	combo_label.pivot_offset = combo_label.size * 0.5

	var tween = create_tween()
	
	tween.parallel().tween_property(combo_label, "scale", Vector2(2, 2), 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(combo_label, "modulate:a", 0.0, 1.5).set_delay(0.5)

	await get_tree().create_timer(2.5).timeout
	combo_label.visible = false
	combo_label.scale = Vector2.ONE
	combo_label.modulate.a = 1.0

func interactions_enabled(state):
	head_control.visible = state

func _process(delta: float) -> void:
	chips_label.text = "CHIPS: " + str(PlayerData.money)
	round_label.text = "ROUND: " + str(PlayerData.round)

func remove_color_bg():
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 0, 2.0)

func give_help(desc: String):
	create_tween().tween_property(help_label, "text", desc, 0.5)
	await get_tree().create_timer(4.0).timeout
	create_tween().tween_property(help_label, "text", "", 0.5)


func _on_next_round_button_pressed() -> void:
	AudioManager.play_sfx("ui", -15)
	round_stats.visible = false
	SignalBus.next_round_button_pressed.emit()

func show_round_stats_panel(RoundScore: int, CurrentQuota: int, InterestEarned: int, NewQuota: int) -> void:
	round_stats.visible = true
	score_label.text = str(RoundScore) + "/" + str(CurrentQuota)
	interest_earned_label.text = str(InterestEarned)
	new_quota_label.text = str(NewQuota)
