--[[
  Hydroponics
  Omikhleia 2020.
  MIT-lisenced.
--]]

minetest.register_node("mt_future:hydroponic_substrate_empty", {
  description = "Hydroponic substrate",
  tiles = {
     -- top, bottom, right, left, back, front
    "wool_white.png",
    "pipeworks_storage_tank_back.png",
    pipeworks.liquid_texture.."^pipeworks_storage_tank_front_0.png",
    pipeworks.liquid_texture.."^pipeworks_storage_tank_front_0.png",
    pipeworks.liquid_texture.."^pipeworks_storage_tank_front_0.png",
    pipeworks.liquid_texture.."^pipeworks_storage_tank_front_0.png"
  },
  paramtype = "light",
  paramtype2 = "facedir",
  groups = {cracky=1, pipe=1},
  pipe_connections = { left=1, right=1, front=1, back=1 },

  sounds = default.node_sound_metal_defaults(),
  after_place_node = function(pos)
    pipeworks.scan_for_pipe_objects(pos)
  end,
  after_dig_node = function(pos)
    pipeworks.scan_for_pipe_objects(pos)
  end,
  on_place = pipeworks.rotate_on_place,
  on_rotate = pipeworks.fix_after_rotation
})
pipeworks.flowables.register.simple("mt_future:hydroponic_substrate_empty")

minetest.register_node("mt_future:hydroponic_substrate_loaded", {
  description = "Wet hydroponic substrate",
  tiles = {
      -- top, bottom, right, left, back, front
      "wool_white.png",
      "pipeworks_storage_tank_back.png",
      pipeworks.liquid_texture.."^pipeworks_storage_tank_front_10.png",
      pipeworks.liquid_texture.."^pipeworks_storage_tank_front_10.png",
      pipeworks.liquid_texture.."^pipeworks_storage_tank_front_10.png",
      pipeworks.liquid_texture.."^pipeworks_storage_tank_front_10.png"
    },
  paramtype = "light",
  paramtype2 = "facedir",
  groups = {cracky=1, pipe=1, soil=3, not_in_creative_inventory=1},
  pipe_connections = { left=1, right=1, front=1, back=1 },
  sounds = default.node_sound_metal_defaults(),

  after_dig_node = function(pos)
    pipeworks.scan_for_pipe_objects(pos)
  end,
  drop = "mt_future:hydroponic_substrate_empty",
})
pipeworks.flowables.register.simple("mt_future:hydroponic_substrate_loaded")

-- ABMs are not registered automatically by pipeworks
minetest.register_abm({
  nodenames = { "mt_future:hydroponic_substrate_empty" },
  interval = 1,
  chance = 1,
  action = function(pos, node, active_object_count, active_object_count_wider)
    pipeworks.check_for_inflows(pos,node)
  end
})

minetest.register_abm({
  nodenames = { "mt_future:hydroponic_substrate_loaded" },
  interval = 1,
  chance = 1,
  action = function(pos, node, active_object_count, active_object_count_wider)
    pipeworks.check_sources(pos,node)
  end
})
