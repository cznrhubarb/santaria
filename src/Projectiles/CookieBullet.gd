extends KinematicBody2D

export var BulletSpeed = 400
var type = "bullet"
var damage = 10

var direction = Vector2()

func _physics_process(delta):
	var collision_info = move_and_collide(direction * BulletSpeed * delta)
	if collision_info:
		var collider = collision_info.collider
		if collider.type == "enemy":
			collider.take_damage(damage)
		queue_free()
