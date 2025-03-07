extends Object

const ConfigConversion: Dictionary = {
	1: "hats",
	2: "glasses",
	3: "backpacks"
}

func get_placement(chain: ModLoaderHookChain, item: ItemAccessory, dna: ToonDNA) -> AccessoryPlacement:
	var modSetting = ModLoaderConfig.get_current_config("squiddy-Hatstack")
	var returnPlacement: AccessoryPlacement
	var offset := Vector3(0, 0, 0)
	
	if item.slot == Item.ItemSlot.BACKPACK:
		for place in item.accessory_placements:
			if place is AccessoryPlacementBody and place.body_type == dna.body_type:
				returnPlacement = place
	else:
		for place in item.accessory_placements:
			if place is AccessoryPlacementHead:
				if place.species == dna.species and place.head_index == dna.head_index:
					returnPlacement = place
	
	if modSetting.data[ConfigConversion[item.slot]] == 1:
		for oldItem in Util.get_player().stats.items:
			if oldItem.slot != item.slot or oldItem == item:
				continue
			
			var newModel = oldItem.model.instantiate()
			
			var size = newModel.get_children()[0].get_aabb().size
			var scale = newModel.get_children()[0].scale
			
			var placement: AccessoryPlacement
			if oldItem.slot == Item.ItemSlot.BACKPACK:
				for place in oldItem.accessory_placements:
					if place is AccessoryPlacementBody and place.body_type == dna.body_type:
						placement = place
			else:
				for place in oldItem.accessory_placements:
					if place is AccessoryPlacementHead:
						if place.species == dna.species and place.head_index == dna.head_index:
							placement = place
			
			if oldItem.slot == Item.ItemSlot.GLASSES:
				offset += (size * scale * placement.scale) * 0.25
			else:
				offset += (size * scale * placement.scale)
				
			newModel.free()
			
		if item.slot == Item.ItemSlot.HAT:
			returnPlacement.position.y += offset.y
			returnPlacement.position.z -= offset.y / 2
		elif item.slot == Item.ItemSlot.BACKPACK:
			returnPlacement.position.z -= offset.z
		elif item.slot == Item.ItemSlot.GLASSES:
			returnPlacement.position.z += offset.z
		
	return returnPlacement

func apply_item(chain: ModLoaderHookChain, player: Player) -> void:
	chain.reference_object.apply_item(player)
	
	if not player.is_node_ready():
		await player.ready
	
	var mod = chain.reference_object.model.instantiate()
	var bone = ItemAccessory.get_bone(chain.reference_object,player)
	
	var modSetting = ModLoaderConfig.get_current_config("squiddy-Hatstack")
	
	if modSetting.data[ConfigConversion[chain.reference_object.slot]] == 0:
		for accessory in bone.get_children():
			accessory.queue_free()
		
	bone.add_child(mod)
	var placement = ItemAccessory.get_placement(chain.reference_object,player.toon.toon_dna)
	mod.position = placement.position
	mod.rotation_degrees = placement.rotation
	mod.scale = placement.scale
	if mod.has_method('setup'):
		mod.setup(self)
