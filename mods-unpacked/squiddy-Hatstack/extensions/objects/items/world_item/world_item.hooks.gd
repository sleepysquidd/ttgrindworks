extends Object

var SettingsConfig: ModConfig
var lastItem

#0 : "Default",
#1 : "Stacking",
#2 : "Clipping",

const ConfigConversion: Dictionary = {
	1: "hats",
	2: "glasses",
	3: "backpacks"
}

func _ready(chain: ModLoaderHookChain) -> void:
	SettingsConfig = ModLoaderConfig.get_current_config("squiddy-Hatstack")
	chain.execute_next_async()

func apply_item(chain: ModLoaderHookChain) -> void:
	if not Util.get_player():
		return
	
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
			print("Stacking: Implement")
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

func body_entered(chain: ModLoaderHookChain,body):
	if not body is Player:
		return
		
	chain.reference_object.s_collected.emit()
	
	# Turn of monitoring
	set_deferred('monitoring', false)
	#$ReactionArea.set_deferred('monitoring', false)
	chain.reference_object.body_not_reacting(body)
	
	# Apply the item
	chain.reference_object.apply_item()
	
	# Show UI
	var ui = load('res://objects/items/ui/item_get_ui/item_get_ui.tscn').instantiate()
	ui.item = chain.reference_object.item
	chain.reference_object.get_tree().get_root().add_child(ui)
	
	# Play the item collection sound
	chain.reference_object.item.play_collection_sound()
	
	if chain.reference_object.model.has_method('modify'):
		chain.reference_object.model.modify(ui.model)
	
	if chain.reference_object.model.has_method('custom_collect'):
		await chain.reference_object.model.custom_collect()
	else:
		## Default collection animations
		var tween = chain.reference_object.create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		# Passive Collection
		if not chain.reference_object.item is ItemAccessory:
			tween.tween_property(chain.reference_object.model, 'scale', Vector3(0, 0, 0), 1.0)
		# Accessory collection
		else:
			var accessory_placement: AccessoryPlacement = ItemAccessory.get_placement(chain.reference_object.item, Util.get_player().character.dna)
			## Failsafe for if no item placement 
			if not accessory_placement:
				push_warning(chain.reference_object.item.item_name + " has no AccessoryPlacement specified for this Toon's DNA!")
				tween.kill()
				chain.reference_object.model.queue_free()
				chain.reference_object.queue_free()
				return
				
			var modSetting = SettingsConfig.data[ConfigConversion[chain.reference_object.item.slot]]
			if modSetting == 0: # Default
				pass
			elif modSetting == 1: # Stacking
				print("STACK")
				if lastItem:
					var lastAcc: AccessoryPlacement = ItemAccessory.get_placement(lastItem, Util.get_player().character.dna)
					var lastMod = lastItem.model.instantiate()
					var lastSize = lastMod.get_children()[0].get_aabb().size.y
					#print(lastAcc.scale.y * lastSize)
					#print(chain.reference_object.model.get_children()[0])
					accessory_placement.position += Vector3(0, lastAcc.scale.y * lastSize, 0)
					#print(lastItem.get_children()[0].get_aabb().size.y)
			elif modSetting == 2: # Clipping
				pass
				
			lastItem = chain.reference_object.item
			chain.reference_object.bob_tween.kill()
			chain.reference_object.rotation_tween.kill()
			tween.set_parallel(true)
			tween.tween_property(chain.reference_object.model, 'position', accessory_placement.position, 1.0)
			tween.tween_property(chain.reference_object.model, 'scale', accessory_placement.scale, 1.0)
			tween.tween_property(chain.reference_object.model, 'rotation_degrees', accessory_placement.rotation, 1.0)
			tween.tween_callback(func():
				chain.reference_object.model.position = accessory_placement.position
				chain.reference_object.model.scale = accessory_placement.scale
				chain.reference_object.model.rotation_degrees = accessory_placement.rotation)
		await tween.finished
		tween.kill()
	chain.reference_object.queue_free()
