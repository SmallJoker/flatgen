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

flatgen.np_rivers = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	octaves = 1,
	persist = 0.6
}

minetest.register_on_mapgen_init(function(mgparams)
	flatgen.np_rivers.seed = mgparams.seed + 20
	minetest.set_mapgen_params({mgname="singlenode"})
end)

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
	
	local sidelen = maxp.x - minp.x + 1
	local c_cover = minetest.get_content_id(flatgen.cover)
	local c_under = minetest.get_content_id(flatgen.under)
	local c_ground = minetest.get_content_id(flatgen.ground)
	local c_ignore = minetest.get_content_id("ignore_me")
	local c_water = minetest.get_content_id("default:water_source")
	local nvals_rivers = minetest.get_perlin_map(flatgen.np_rivers, {x=sidelen, y=sidelen, z=sidelen}):get2dMap_flat({x=minp.x, y=minp.z})
	
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()
	
	local nixz = 1
	local terrain_cache = {}
	local original_cover_y = cover
	for z = minp.z, maxp.z do
	for x = minp.x, maxp.x do
		local n_rivers = math.abs(nvals_rivers[nixz] * 100)
		local elevation = 0
		if n_rivers < 5 then
			elevation = - math.ceil(5 - n_rivers)
		end
		if n_rivers > 20 then
			elevation = math.floor(n_rivers / 20)
		end
		
		terrain_cache[nixz] = original_cover_y + elevation
		nixz = nixz + 1
	end
	end
	
	nixz = 1
	for z = minp.z, maxp.z do
	for y = minp.y, maxp.y do
		local vi = area:index(minp.x, y, z)
		for x = minp.x, maxp.x do
			local cover = terrain_cache[nixz]
			if y > cover then
				if y <= original_cover_y then
					data[vi] = c_water
				end
				-- do nothing :)
			elseif y == cover then
				if y >= original_cover_y then
					data[vi] = c_cover
				else
					data[vi] = c_under
				end
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
			nixz = nixz + 1
		end
		nixz = nixz - sidelen
	end
	nixz = nixz + sidelen
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