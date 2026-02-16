# Base item class that stores the core data about game items
# Can be equipment, consumables, etc

class_name BaseItem
extends Resource

# Item type, each can belong to several types if needed
@export_flags(
	"CONSUMABLE",
	"WEAPON",
	"ARMOR",
	"CURRENCY",
	"MISC_RESOURCE") var item_type = 0

# Name of item to display
@export var name: String

# String value for backend receipts
@export var code_name: StringName

# Visual representation of item in the world
@export var body: PackedScene

# UI representation of item (For hot bars, storage, etc)
@export var icon: Texture2D