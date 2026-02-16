extends Node3D
class_name InteractableItem

@export var ItemHihglightMesh: MeshInstance3D


func GainFocus():
	ItemHihglightMesh.visible = true

func LoseFocus():
	ItemHihglightMesh.visible = false