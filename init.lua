-- flatgen mod for 100% flat maps - created by Krock
-- License: CC0
local terrain_file = minetest.get_worldpath() .."/flatgen_terrain.txt"

-- Y position where the terrain starts to generate
local generator_start_y = 1

-- Backwards compatiblity
local file = io.open(terrain_file, "r")
if file then
	minetest.log("warning", "[flatgen] Found an existing terrain file. "
		.. "Falling back to legacy code")
	local legacy_file = minetest.get_modpath("flatgen") .. "/init_legacy.lua"
	assert(loadfile(legacy_file))(terrain_file, generator_start_y)
	return
end

if not minetest.set_mapgen_setting then
	error("[flatgen] Your Minetest version is no longer supported."
		.. " (Version < 0.4.16)")
end

minetest.set_mapgen_setting("mg_name", "flat", true)
minetest.set_mapgen_setting("water_level", "-31000", true)
minetest.set_mapgen_setting("mg_flags",
	"light,nocaves,nodungeons,nolight,nodecorations", true)
minetest.set_mapgen_setting("mgflat_spflags", "nolakes,nohills", true)
minetest.set_mapgen_setting("mgflat_ground_level", tostring(generator_start_y), true)

-- Biomes still occur without this stuff
local set_mgparam = minetest.set_mapgen_setting_noiseparams
local function get_noiseparams(_offset)
	return {
		flags = "defaults",
		lacunarity = 0,
		offset = _offset,
		scale = 0,
		spread = {x=1,y=1,z=1},
		seed = 0,
		octaves = 0,
		persistence = 0
	}
end
set_mgparam("mg_biome_np_heat", get_noiseparams(60), true)
set_mgparam("mg_biome_np_heat_blend", get_noiseparams(0), true)
set_mgparam("mg_biome_np_humidity", get_noiseparams(67), true)
set_mgparam("mg_biome_np_humidity_blend", get_noiseparams(0), true)

-- Extend the depth of the grassland biome (y_min)
minetest.register_biome({
	name = "deep_grassy_deciduous_forest",
	node_top = "default:dirt_with_grass",
	depth_top = 1,
	node_filler = "default:dirt",
	depth_filler = 3,
	y_max = 31000,
	y_min = -1000,
	heat_point = 60,
	humidity_point = 67,
})
