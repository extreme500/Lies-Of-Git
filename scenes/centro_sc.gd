extends Node2D

var velocidade_angular = 90.0

func _process(delta):
	rotation += deg_to_rad(velocidade_angular) * delta
