treecapitator = {}
treecapitator.limit = 20 -- limit height of trees
treecapitator.radius = 2 --area around the trees that is cut down
treecapitator.tree_group = {"default:tree","default:jungletree","default:pine_tree","default:acacia_tree","default:aspen_tree"}
treecapitator.tool_group = {"default:axe_steel","default:axe_bronze","default:axe_diamond","default:axe_mese"}
treecapitator.tool_wear  = 30 --how much the tool is worn per node
--figure out some way to get if tree was generated

--features, quickly cut down trees using axes (steel, bronze, diamond, mese), will collect all drops, fast way to get a lot of trees, 
--if inventory is full, it won't treecapitate, automatically puts items into inventory, damages any axes in inventory, not just wielded
--item, very fast and efficient, will put items on ground if run out of space in inventory


function treecapitator.wear_tool(inv)
	--wear down the tool for each node mined
	local listlength = inv:get_size("main")
	
	for i = 1,listlength do
		local stack = inv:get_stack("main", i)
		if stack:to_table() then
			local stackname = stack:to_table().name
			if minetest.get_item_group(stackname, "treecapitator") ~= 0 then
				--damage tools in inventory to allow mining all tree nodes
				stack:set_wear(stack:get_wear()+treecapitator.tool_wear)
				inv:set_stack("main", i, stack)
				break
			end
		end
	end
end
function treecapitator.treecapitator(pos,digger)
	local min = {x=pos.x-treecapitator.radius,y=pos.y-5,z=pos.z-treecapitator.radius}
	local max = {x=pos.x+treecapitator.radius,y=pos.y+treecapitator.limit,z=pos.z+treecapitator.radius}
	local vm = minetest.get_voxel_manip()	
	local emin, emax = vm:read_from_map(min,max)
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()
	
	local tree   = minetest.get_content_id("default:tree")
	local air    = minetest.get_content_id("air")
	local leaves = minetest.get_content_id("default:leaves")

	local inv = digger:get_inventory()
	
	
	for x = -treecapitator.radius,treecapitator.radius  do
		for z = -treecapitator.radius,treecapitator.radius  do
			for y = -5,treecapitator.limit  do
				local p_pos = area:index(pos.x+x,pos.y+y,pos.z+z)
							
				local name = minetest.get_name_from_content_id(data[p_pos])
				if minetest.get_item_group(name, "tree") ~= 0 then
					data[p_pos] = air
					treecapitator.wear_tool(inv)
					if inv:room_for_item("main", name) == true then
						inv:add_item("main", name)
					else
						minetest.add_item({x=pos.x+x,y=pos.y+y,z=pos.z+z}, name)
					end
					
				elseif minetest.get_item_group(name, "leaves") ~= 0 then
					data[p_pos] = air
					treecapitator.wear_tool(inv)
					--do random drops
					if math.random() > 0.9 then
						local drop = minetest.registered_items[name]["drop"]
						local tablelength = tablelength(drop.items)
						local droplist = drop.items[math.random(1,tablelength)]
						
						local drop_item = droplist.items[1]
							
						if inv:room_for_item("main", drop_item) == true then
							inv:add_item("main", drop_item)
						else
							minetest.add_item({x=pos.x+x,y=pos.y+y,z=pos.z+z}, drop_item)
						end
					end

				elseif minetest.get_item_group(name, "leafdecay") ~= 0 then
					data[p_pos] = air
					treecapitator.wear_tool(inv)
					if inv:room_for_item("main", name) == true then
						inv:add_item("main", name)
					else
						minetest.add_item({x=pos.x+x,y=pos.y+y,z=pos.z+z}, name)
					end	
				end
			end
		end
	end
	
	
	vm:set_data(data)
	vm:calc_lighting()
	vm:write_to_map()
	vm:update_map()
end

function tablelength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

--override trees to treecapitate
for _,t in pairs(treecapitator.tree_group) do
	minetest.override_item(t, {
		after_dig_node = function(pos, oldnode, oldmetadata, digger)
			local wield_item = digger:get_wielded_item()
			local item = wield_item:to_table().name
			--only treecapitate with higher level axes
			if minetest.get_item_group(item, "treecapitator") ~= 0 then
				local inv = digger:get_inventory()
				if inv:room_for_item("main", t) == true then
					treecapitator.treecapitator(pos,digger)
				end
			end
		end,
	})
end

--override tool groups
for _,t in pairs(treecapitator.tool_group) do
	minetest.override_item(t, {
		groups = {treecapitator=1},
	})
end
