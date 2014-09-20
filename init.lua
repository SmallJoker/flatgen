-- flatgen mod for 100% flat maps - created by Krock
-- License: WTFPL
local flatgen = {}

-- Default, grass cover, dirt in between, stone under it
flatgen.cover	= "default:dirt_with_grass"
flatgen.under	= "default:dirt"
flatgen.ground	= "default:stone"

--[[ Templates:
- Sand everywhere
	flatgen.cover	= "default:sand"
	flatgen.under	= "default:sand"
	flatgen.ground	= "default:sand"
	
- Desert sand, sand, sandstone
	flatgen.cover	= "default:desert_sand"
	flatgen.under	= "default:sand"
	flatgen.ground	= "default:sandstone"

- Wool, wool, obsidian
	flatgen.cover	= "wool:white"
	flatgen.under	= "wool:white"
	flatgen.ground	= "default:obsidian"
]]

flatgen.cover_y		= 1		-- Y position of the cover node [1]
flatgen.depth		= 3		-- Depth of the "under" node [3]
flatgen.limit_y		= true	-- False = map generation stops at 100m under cover_y

minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_params({mgname="singlenode"})
end)

local lastPos = {x=6.66,y=6.66,z=6.66}

minetest.register_on_generated(function(minp, maxp, seed)
	local cover, depth, limit = flatgen.cover_y, flatgen.depth, flatgen.limit_y
	if minp.y > cover then
		return
	end
	if limit then
		limit = cover - 100
		if maxp.y < limit then
			return
		end
	end
	if vector.equals(minp, lastPos) then
		return
	end
	lastPos = vector.new(minp)
	
	local c_cover = minetest.get_content_id(flatgen.cover)
	local c_under = minetest.get_content_id(flatgen.under)
	local c_ground = minetest.get_content_id(flatgen.ground)
	local c_ignore = minetest.get_content_id("ignore_me")

	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()
	
	for z = minp.z, maxp.z do
	for y = minp.y, maxp.y do
		local vi = area:index(minp.x, y, z)
		for x = minp.x, maxp.x do
			if y > cover then
				-- do nothing :)
			elseif y == cover then
				data[vi] = c_cover
			elseif y >= cover - depth then
				data[vi] = c_under
			elseif limit then
				if y > limit then
					data[vi] = c_ground
				elseif y <= limit and y >= limit - 10 then
					data[vi] = c_ignore
				end
			else
				data[vi] = c_ground
			end
			vi = vi + 1
		end
	end
	end
	
	vm:set_data(data)
	vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map(data)
end)

minetest.register_node(":ignore_me", {
	description = "You hacker you!",
	tiles = {"default_cloud.png"},
	paramtype = "light",
	sunlight_propagates = true,
	pointable = false,
	drop = "",
})