class_name HurtBox
extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready():
	collision_layer = 0
	collision_mask = 2
	self.area_entered.connect(on_area_entered)

func on_area_entered(hit_box: HitBox) -> void:
	if hit_box == null: return
	# TODO: Deal Damage
	print("Damage Dealt")
