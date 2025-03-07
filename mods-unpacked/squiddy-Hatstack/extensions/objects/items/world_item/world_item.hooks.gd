extends Object

var SettingsConfig: ModConfig

#0 : "Default",
#1 : "Stacking",
#2 : "Clipping",

const ConfigConversion: Dictionary = {
	1: "hats",
	2: "glasses",
	3: "backpacks"
}

func apply_item(chain: ModLoaderHookChain) -> void:
	if not Util.get_player():
		return
		
	SettingsConfig = ModLoaderConfig.get_current_config("squiddy-Hatstack")
	
	var stats = Util.get_player().stats
	
	for stat in chain.reference_object.item.stats_add:
		if str(stat) in stats:
			if stat == 'money':
				print("Calling special money func")
				stats.add_money(chain.reference_object.item.stats_add[stat])
			else:
				stats[stat] += chain.reference_object.item.stats_add[stat]
	
	for stat in chain.reference_object.item.stats_multiply:
		if str(stat) in stats:
			stats[stat] *= chain.reference_object.item.stats_multiply[stat]
		elif stat.begins_with("gag_boost:"):
			var track: String = stat.get_slice(":", 1)
			if track in stats.gag_effectiveness:
				stats.gag_effectiveness[track] *= chain.reference_object.item.stats_multiply[stat]
	
	# Set player values
	for value in chain.reference_object.item.player_values:
		Util.get_player().set(value, chain.reference_object.item.player_values[value])
	
	# Run the item script if there is one
	if chain.reference_object.item.item_script:
		var item_node := ItemScript.add_item_script(Util.get_player(),chain.reference_object.item.item_script)
		if item_node is ItemScript:
			item_node.on_collect(chain.reference_object.item,chain.reference_object.model)
	
	# Reparent accessories to the player
	# They will get tweened into position after this
	if chain.reference_object.item is ItemAccessory:
		var bone := ItemAccessory.get_bone(chain.reference_object.item,Util.get_player())
		var modSetting = SettingsConfig.data[ConfigConversion[chain.reference_object.item.slot]]
		if modSetting == 0: # Default
			chain.reference_object.remove_current_item(bone)
		elif modSetting == 1: # Stacking
			pass # The position doesn't change here, kinda unneeded
		elif modSetting == 2: # Clipping
			pass # We don't really need to do anything
			
		chain.reference_object.model.reparent(bone)
	
	if chain.reference_object.model.has_method('collect'):
		chain.reference_object.model.collect()
	
	# Add the item to the player's item array
	if chain.reference_object.item.remember_item:
		Util.get_player().stats.items.append(chain.reference_object.item)
		print('added %s to item list (world item)' % chain.reference_object.item.item_name)
		ItemService.s_item_applied.emit(chain.reference_object.item)
