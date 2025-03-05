extends "res://objects/general_ui/settings_menu/settings_menu.gd"

var HatButton : GeneralButton
var GlassesButton : GeneralButton
var BackpackButton : GeneralButton

var Pla : Player

var hatId : int
var glassId : int
var bpId : int

const CosmeticSetting : Dictionary = {
	0 : "Default",
	1 : "Stacking",
	2 : "Clipping",
}

func _ready() -> void:
	super()
	var SettingsConfig = ModLoaderConfig.get_current_config("squiddy-Hatstack").data
	hatId = SettingsConfig["hats"]
	glassId = SettingsConfig["glasses"]
	bpId = SettingsConfig["backpacks"]
	
	var HatMenuResource = load("res://mods-unpacked/squiddy-Hatstack/overwrites/Hat Settings.tscn")
	var HatMenu = HatMenuResource.instantiate()
	var SettingContainer = get_node("Panel/SettingScroller/MarginContainer/SettingContainer")
	add_child(HatMenu)
	HatMenu.reparent(SettingContainer)
	
	HatButton = HatMenu.get_node("%HatButton")
	GlassesButton = HatMenu.get_node("%GlassesButton")
	BackpackButton = HatMenu.get_node("%BackpackButton")
	
	HatButton.text = CosmeticSetting[hatId]
	GlassesButton.text = CosmeticSetting[glassId]
	BackpackButton.text = CosmeticSetting[bpId]
	
	HatButton.connect("pressed", hat)
	GlassesButton.connect("pressed", glasses)
	BackpackButton.connect("pressed", backpack)


func hat() -> void:
	hatId += 1
	if hatId >= len(CosmeticSetting):
		hatId = 0
	HatButton.text = CosmeticSetting[hatId]
	
func glasses() -> void:
	glassId += 1
	if glassId >= len(CosmeticSetting):
		glassId = 0
	GlassesButton.text = CosmeticSetting[glassId]

func backpack() -> void:
	bpId += 1
	if bpId >= len(CosmeticSetting):
		bpId = 0
	BackpackButton.text = CosmeticSetting[bpId]

func close(save := false) -> void:
	super(save)
	var newConfig = ModLoaderConfig.get_current_config("squiddy-Hatstack")
	newConfig.data = {
		"hats": hatId,
		"glasses": glassId,
		"backpacks": bpId,
	}
	ModLoaderConfig.update_config(newConfig)
	ModLoaderConfig.refresh_current_configs()
