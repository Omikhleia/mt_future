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
    "mt_future_hydroponics_0.png",
    "mt_future_hydroponics_0.png",
    "mt_future_hydroponics_0.png",
    "mt_future_hydroponics_0.png"
  },
  paramtype = "light",
  paramtype2 = "facedir",
  groups = {cracky=1, pipe=1},
  pipe_connections = { front=1, back=1, right=1, left=1 },

  sounds = default.node_sound_metal_defaults(),
  after_place_node = function(pos)
    pipeworks.scan_for_pipe_objects(pos)
  end,
  after_dig_node = function(pos)
    pipeworks.scan_for_pipe_objects(pos)
  end,
  on_rotate = false
})
-- FIXME: API says not to use any longer directional_horizonal_rotate()
-- But no clear example how to do it otherwise.
pipeworks.flowables.register.directional_horizonal_rotate("mt_future:hydroponic_substrate_empty", true)

minetest.register_node("mt_future:hydroponic_substrate_loaded", {
  description = "Wet hydroponic substrate",
  tiles = {
    -- top, bottom, right, left, back, front
    "wool_white.png",
    "pipeworks_storage_tank_back.png",
    pipeworks.liquid_texture.."^mt_future_hydroponics_10.png",
    pipeworks.liquid_texture.."^mt_future_hydroponics_10.png",
    pipeworks.liquid_texture.."^mt_future_hydroponics_10.png",
    pipeworks.liquid_texture.."^mt_future_hydroponics_10.png"
  },
  paramtype = "light",
  paramtype2 = "facedir",
  groups = {cracky=1, pipe=1, soil=3, not_in_creative_inventory=1},
  pipe_connections = { front=1, back=1, right=1, left=1 },
  sounds = default.node_sound_metal_defaults(),

  after_dig_node = function(pos)
    pipeworks.scan_for_pipe_objects(pos)
  end,
  drop = "mt_future:hydroponic_substrate_empty",
  on_rotate = false
})
-- FIXME: API says not to use any longer directional_horizonal_rotate()
-- But no clear example how to do it otherwise.
pipeworks.flowables.register.directional_horizonal_rotate("mt_future:hydroponic_substrate_loaded", true)

-- ABMs are not registered automatically by pipeworks?
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
