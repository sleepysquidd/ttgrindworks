extends "res://objects/globals/item_service.gd"

#0 : "Default",
#1 : "Stacking",
#2 : "Clipping",

const ConfigConversion: Dictionary = {
	1: "hats",
	2: "glasses",
	3: "backpacks"
}

func apply_inventory() -> void:
	var player := Util.get_player()
	var items: Array[Item] = player.stats.items
	var hat: Array[ItemAccessory]
	var glasses: Array[ItemAccessory]
	var backpack: Array[ItemAccessory]
	
	# Iterate through items to find accessories
	# As well as any special items
	# Setting values like this ensures only the newest items are applied
	for item in items:
		match item.slot:
			Item.ItemSlot.HAT:
				hat.append(item)
			Item.ItemSlot.GLASSES:
				glasses.append(item)
			Item.ItemSlot.BACKPACK:
				backpack.append(item)
		for value in item.player_values.keys():
			player.set(value, item.player_values[value])
	
		# If a script item is found, run the load method
		if item.item_script:
			var item_node := ItemScript.add_item_script(Util.get_player(), item.item_script)
			if item_node is ItemScript:
				item_node.on_load(item)
	
	# Place accessory items on player
	var SettingsConfig = ModLoaderConfig.get_current_config("squiddy-Hatstack")
	var hatSetting = SettingsConfig.data["hats"]
	var glassesSetting = SettingsConfig.data["glasses"]
	var backpackSetting = SettingsConfig.data["backpacks"]
	
	if hat:
		match int(hatSetting):
			0: # Default
				var accessory_placement = ItemAccessory.get_placement(hat[len(hat)-1], player.character.dna)
				var model = hat[len(hat)-1].model.instantiate()
				player.toon.hat_bone.add_child(model)
				model.position = accessory_placement.position
				model.rotation_degrees = accessory_placement.rotation
				model.scale = accessory_placement.scale
			_: #Stacking and clipping
				for item in hat:
					var accessory_placement = ItemAccessory.get_placement(item, player.character.dna)
					var model = item.model.instantiate()
					player.toon.hat_bone.add_child(model)
					model.position = accessory_placement.position
					model.rotation_degrees = accessory_placement.rotation
					model.scale = accessory_placement.scale
		
	if glasses:
		match int(glassesSetting):
			0: # Default
				var accessory_placement = ItemAccessory.get_placement(glasses[len(glasses)-1], player.character.dna)
				var model = glasses[len(glasses)-1].model.instantiate()
				player.toon.glasses_bone.add_child(model)
				model.position = accessory_placement.position
				model.rotation_degrees = accessory_placement.rotation
				model.scale = accessory_placement.scale
			_: # Stacking and Clipping
				for item in glasses:
					var accessory_placement = ItemAccessory.get_placement(item, player.character.dna)
					var model = item.model.instantiate()
					player.toon.glasses_bone.add_child(model)
					model.position = accessory_placement.position
					model.rotation_degrees = accessory_placement.rotation
					model.scale = accessory_placement.scale
		
	if backpack:
		match int(backpackSetting):
			0: # Default
				var accessory_placement = ItemAccessory.get_placement(backpack[len(backpack)-1], player.character.dna)
				var model = backpack[len(backpack)-1].model.instantiate()
				player.toon.backpack_bone.add_child(model)
				model.position = accessory_placement.position
				model.rotation_degrees = accessory_placement.rotation
				model.scale = accessory_placement.scale
			_: # Stacking and Clipping
				for item in backpack:
					var accessory_placement = ItemAccessory.get_placement(item, player.character.dna)
					var model = item.model.instantiate()
					player.toon.backpack_bone.add_child(model)
					model.position = accessory_placement.position
					model.rotation_degrees = accessory_placement.rotation
					model.scale = accessory_placement.scale
