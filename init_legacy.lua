-- Fallback code in case there's already a terrain configuration file existing
-- License: CC0
local params = { ... }
local terrain_file = params[1]

-- Y position where the terrain starts to generate
local generator_start_y = params[2]
-- Default settings: grass, dirt, dirt, dirt with stone ground
local layers = {
	{ "default:dirt_with_grass", 1 },
	{ "default:dirt", 3 },
	{ "default:stone", nil } -- nil = no limit
	-- Fake ignore to generate whenever you want: { "ignore_me", 1 }
}


minetest.set_mapgen_params({
	mgname = "singlenode",
	water_level = -31000,
	flags = "light"
})

local function readOrCreateTerrainSettings()
	local file = io.open(terrain_file, "r")
	if file then
		-- Load existing world file
		local data = minetest.deserialize(file:read("*all"))
		file:close()
		assert(data, "[flatgen] Can not deserialize the terrain file")
		layers = data
		return
	end
	-- Copy default params to the world file
	file = io.open(terrain_file, "w")
	file:write(minetest.serialize(layers))
	file:close()
end

readOrCreateTerrainSettings()

minetest.after(0, function()
	-- Transform node strings to content ID
	for i, v in ipairs(layers) do
		assert(minetest.registered_nodes[v[1]], "[flatgen] Unknown node: "..v[1])
		v[1] = minetest.get_content_id(v[1])
	end
end)


minetest.register_chatcommand("regenerate", {
	description = "Regenerates a <size>^3 nodes around you",
	params = "<size>",
	privs = {server=true},
	func = function(name, param)
		local size = tonumber(param) or 0

		if size < 10 then
			return false, "Please submit a size number >= 10"
		end

		size = math.floor(size / 2)
		local player = minetest.get_player_by_name(name)
		local pos = vector.round(player:getpos())

		flatgen_generate(
			vector.subtract(pos, size),
			vector.add(pos, size),
			0, true
		)
		return true, "Done!"
	end
})

local c_air = minetest.get_content_id("air")
function flatgen_getNode(y, regenerate)
	if y > generator_start_y then
		return c_air
	end

	local depth = generator_start_y
	for i, v in ipairs(layers) do
		if not v[2] or depth - v[2] < y then
			return v[1]
		end
		depth = depth - v[2]
	end
	return regenerate and c_air --or nil
end

function flatgen_generate(minp, maxp, seed, regenerate)
	if minp.y > generator_start_y then
		return -- Area outside of the generation area
	end

	if not flatgen_getNode(maxp.y) then
		return -- No node defined for that position or below
	end

	local vm, emin, emax
	if regenerate then -- Load regular VManip to regenerate area
		vm = minetest.get_voxel_manip()
		emin, emax = vm:read_from_map(minp, maxp)
	else -- Load VManip from map generator
		vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	end

	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()

	for z = minp.z, maxp.z do
	for y = minp.y, maxp.y do
		local vi = area:index(minp.x, y, z)
		local node = flatgen_getNode(y, regenerate)
		for x = minp.x, maxp.x do
			if node then
				data[vi] = node
			end
			vi = vi + 1
		end
	end
	end

	vm:set_data(data)
	if not regenerate then
		vm:set_lighting({day=0, night=0})
	end
	vm:calc_lighting()
	vm:write_to_map(data)
	if regenerate then
		vm:update_map()
	end
end

table.insert(minetest.registered_on_generateds, 1, flatgen_generate)

minetest.register_node(":ignore_me", {
	description = "You hacker you!",
	tiles = {"default_cloud.png"},
	paramtype = "light",
	sunlight_propagates = true,
	pointable = false,
	drop = "",
})