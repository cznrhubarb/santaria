extends KinematicBody2D

var Speed = 100
var type = "child"

var game_hud
var hp_bar
var health = 100
var weapons
var curses
var anim_player
var is_moving = false
var dialog
var shoot_in_reverse = false
var run_in_reverse = false
var under_penalty = false
var penalty_delay = 1
var penalty_timer = penalty_delay
var step_sounds
var step_sound_one_is_next = true
var step_delay = 0
#hack
var already_dead = false

func _ready():
	game_hud = get_node("../../GameHud")
	hp_bar = get_node("../../GameHud/HP_Bar")
	anim_player = get_node("AnimationPlayer")
	dialog = get_tree().get_root().find_node("GiftDialog", true, false)
	randomize()
	weapons = []
	curses = []
	step_sounds = [ get_node("StepOne"), get_node("StepTwo") ]

func add_weapon(weapon):
	weapons.push_front(weapon)

func add_curse(curse):
	var curse_ui = get_tree().get_root().find_node("CurseListUI", true, false)
	curse_ui.add_curse_icon(curse.resource)
	
	curses.push_front(curse)
	if curse.key == "quake":
		find_node("ChildCamera").shake(9999, 20, 4)
		get_node("Quake").play()
	elif curse.key == "gift_horse":
		dialog.find_node("WeaponText").text = "???"
		dialog.find_node("CurseText").text = "???"
	elif curse.key == "reverse_shot":
		shoot_in_reverse = true
	elif curse.key == "reverse_run":
		run_in_reverse = true
	elif curse.key == "penalty":
		under_penalty = true

func has_curse(curse_name):
	for curse in curses:
		if curse.key == curse_name:
			return true
	return false

func _physics_process(delta):
	if under_penalty:
		penalty_timer -= delta
		if penalty_timer <= 0:
			penalty_timer = penalty_delay
			var game_hud = get_tree().get_root().find_node("GameHud", true, false)
			var cost = 2
			if game_hud.score > cost:
				game_hud.add_score(-cost)
	
	is_moving = false
	var delta_pos = Vector2()
	if Input.is_action_pressed("move_right"):
		delta_pos.x += Speed
		is_moving = true
	
	elif Input.is_action_pressed("move_left"):
		delta_pos.x -= Speed
		is_moving = true

	if Input.is_action_pressed("move_up"):
		delta_pos.y -= Speed
		is_moving = true
	elif Input.is_action_pressed("move_down"):
		delta_pos.y += Speed
		is_moving = true
	
	if run_in_reverse:
		delta_pos = Vector2(-delta_pos.x, -delta_pos.y)
	
	move_and_slide(delta_pos)
	updateAnimation()
	
	step_delay -= delta
	if is_moving:
		if step_delay <= 0:
			step_delay = 0.12
			var snd = step_sounds[(0 if step_sound_one_is_next else 1)]
			step_sound_one_is_next = not step_sound_one_is_next
			snd.play()
	
	for weapon in weapons:
		weapon.cooldown(delta)
	if Input.is_action_pressed("shoot"):
		shoot(get_shot_direction(), true)

func _input(event):
	if event.is_action_pressed("shoot"):
		shoot(get_shot_direction(), false)

func get_shot_direction():
	var dir = (get_global_mouse_position() - position).normalized()
	if shoot_in_reverse:
		dir = dir.rotated(3.14159)
	return dir

func shoot(direction, auto):
	if not dialog.visible:
		for weapon in weapons:
			var bullet = weapon.shoot(direction, auto)
			if bullet:
				bullet.position = position
				get_node("Shoot").play()
				get_parent().add_child(bullet)

func take_damage(value):
	health -= value
	update_health()
	
func update_health():
	if hp_bar:
		hp_bar.update_health(health)
	else:
		print("no HP bar found")
	if health <= 0 and not already_dead:
		already_dead = true
		print("You have died.")
		# TODO: VFX
		get_tree().get_root().find_node("GameHud", true, false).add_child(load("res://scn/DeadScreen.tscn").instance())
		
func updateAnimation():
	if is_moving:
		anim_player.playback_speed = Speed/100.0
	else:
		anim_player.playback_speed = 0
		
	var direction = get_shot_direction()
	if abs(direction.x) >= abs(direction.y):
		if direction.x >=0:
			anim_player.play("WalkRight")
		else:
			anim_player.play("WalkLeft")
	else:
		if direction.y >=0:
			anim_player.play("WalkDown")
		else:
			anim_player.play("WalkUp")
