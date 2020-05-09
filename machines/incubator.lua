--[[
  Incubator
  Omikhleia 2020.
  MIT-lisenced.
--]]

local incubator_demand = 1600 -- Energy expensive: 1 MV hydro without upgrade.
local incubator_time = 300 -- Slow: ~5mn (300 iterations of the technic run, whatever it is).
local incubator_tube_velocity = 1

local S = function(machine_name, status, pos)
  local meta = minetest.env:get_meta(pos)
  return machine_name.." "..status.." (owned by "..meta:get_string("owner")..")"
end

local is_a_mob = function(stack)
  -- TODO: might not be a perfect check...
  -- For now supports mob_redo
  if minetest.get_modpath("mobs") then
    local nodef = minetest.registered_craftitems[stack:get_name()]
    if nodef ~= nil and nodef.groups ~= nil and nodef.groups.spawn_egg then
      return true
    end
  end
  return false
end

-- Item container code adapted from the itemframes mod.
-- https://gitlab.com/VanessaE/homedecor_modpack/tree/master/itemframes
local tmp = {}

minetest.register_entity("mt_future:item", {
  hp_max = 1,
  visual = "wielditem",
  visual_size = {x=.33,y=.33},
  collisionbox = {0,0,0,0,0,0},
  physical = false,
  textures = {"air"},
  on_activate = function(self, staticdata)
    if tmp.nodename ~= nil and tmp.texture ~= nil then
      self.nodename = tmp.nodename
      tmp.nodename = nil
      self.texture = tmp.texture
      tmp.texture = nil
    else
      if staticdata ~= nil and staticdata ~= "" then
        local data = staticdata:split(';')
        if data and data[1] and data[2] then
          self.nodename = data[1]
          self.texture = data[2]
        end
      end
    end
    if self.texture ~= nil then
      self.object:set_properties({textures={self.texture}})
    end
    self.object:set_properties({automatic_rotate=1})
  end,
  get_staticdata = function(self)
    if self.nodename ~= nil and self.texture ~= nil then
      return self.nodename .. ';' .. self.texture
    end
    return ""
  end,
})

local remove_item = function(pos, node)
  local objs = minetest.env:get_objects_inside_radius(pos, .5)
  if objs then
    for _, obj in ipairs(objs) do
      if obj and obj:get_luaentity() and obj:get_luaentity().name == "mt_future:item" then
        obj:remove()
      end
    end
  end
end

local update_item = function(pos, node)
  remove_item(pos, node)
  local meta = minetest.env:get_meta(pos)
  if meta:get_string("item") ~= "" then
    tmp.nodename = node.name
    tmp.texture = ItemStack(meta:get_string("item")):get_name()
    minetest.add_entity(pos,"mt_future:item")
    minetest.swap_node(pos, { name = "mt_future:incubator", param2 = 50})
  end
end

local drop_item = function(pos, node)
  local meta = minetest.env:get_meta(pos)
  if meta:get_string("item") ~= "" then
    minetest.env:add_item({x=pos.x,y=pos.y+1,z=pos.z}, meta:get_string("item"))
    meta:set_string("item","")
  end
  remove_item(pos, node)
  minetest.swap_node(pos, { name = "mt_future:incubator", param2 = 10})
end

minetest.register_node("mt_future:incubator", {
  description = "Incubator",
  
  tiles = {"default_obsidian_glass.png^pipeworks_tube_connection_metallic.png"},
  special_tiles = {{
      name = "default_water_source_animated.png",
      animation = {
        type = "vertical_frames",
        aspect_w = 16,
        aspect_h = 16,
        length = 2.0,
      }
    }
  },
  use_texture_alpha = true,
  sunlight_propagates = true,
  drawtype = "glasslike_framed",
  paramtype = "light",
  paramtype2 = "glasslikeliquidlevel",
  place_param2 = 10,
  sounds = default.node_sound_glass_defaults(),
  
  groups = {
    cracky = 3,
    oddly_breakable_by_hand = 3,
    tubedevice = 1,
    tubedevice_receiver = 1,
    technic_machine = 1,
    technic_mv = 1
  },
  
  tube = {
    -- No input, output only
    connect_sides = {left = 1, right = 1, front = 1, back = 1, top = 1}
  },

  connects_to = {"group:technic_mv_cable"},
  connect_sides = {"bottom"},
  
  on_construct = function(pos)
    local meta = minetest.get_meta(pos)
    meta:set_int("MV_EU_input", 0)
    meta:set_int("MV_EU_demand", 0)
  end,
  
  after_place_node = function(pos, placer, itemstack)
    local meta = minetest.env:get_meta(pos)
    meta:set_string("owner", placer:get_player_name())
    meta:set_string("infotext", "Incubator (owned by "..placer:get_player_name()..")")
  end,
  
  on_rightclick = function(pos, node, clicker, itemstack)
    if not itemstack then return end
    local meta = minetest.env:get_meta(pos)

    if clicker:get_player_name() == meta:get_string("owner") then
      drop_item(pos, node)
      local s = itemstack:take_item()
      meta:set_string("item", s:to_string())
      update_item(pos, node)
    end
    return itemstack
  end,
  
  on_punch = function(pos,node,puncher)
    local meta = minetest.env:get_meta(pos)
    if puncher:get_player_name() == meta:get_string("owner") then
      drop_item(pos, node)
    end
  end,
  
  can_dig = function(pos,player)
    local meta = minetest.env:get_meta(pos)
    return player:get_player_name() == meta:get_string("owner")
  end,
  
  technic_run = function(pos, node)
    local meta     = minetest.get_meta(pos)
    local eu_input = meta:get_int("MV_EU_input")

    -- Setup machine metadata if it does not exist.
    if not eu_input then
      meta:set_int("MV_EU_demand", incubator_demand)
      meta:set_int("MV_EU_input", 0)
      meta:set_int("incubation_time", incubator_time)
      return
    end
   
    if meta:get_string("item") ~= "" then
      if (eu_input < incubator_demand) then
        meta:set_string("infotext", S("Incubator", "Unpowered", pos))
        meta:set_int("incubation_time", incubator_time)
      else
        local stack = ItemStack(meta:get_string("item"))
        if is_a_mob(stack) then
          local time = meta:get_int("incubation_time")
          meta:set_string("infotext", S("Incubator", 
                          "Active "..math.floor(100 *time / incubator_time).."%", pos))
          meta:set_int("MV_EU_demand", incubator_demand)
          meta:set_int("incubation_time", time - 1)
          
          if (time <= 0) then
            -- Cloning to tube
            technic.tube_inject_item(pos, pos, vector.new(incubator_tube_velocity, 0, incubator_tube_velocity), 
                                     meta:get_string("item"))
            meta:set_int("incubation_time", incubator_time)
          end
        else
          meta:set_string("infotext", S("Incubator", "Inactive", pos))
          meta:set_int("incubation_time", incubator_time)
        end
      end
      meta:set_int("MV_EU_demand", incubator_demand)
    else
      meta:set_string("infotext", S("Incubator", "Idle", pos))
      meta:set_int("MV_EU_demand", 0)
    end    
  end
})

-- automatically restore entities lost from frames/pedestals
-- due to /clearobjects or similar
minetest.register_abm({
  nodenames = { "mt_future:incubator" },
  interval = 15,
  chance = 1,
  action = function(pos, node, active_object_count, active_object_count_wider)
    if #minetest.get_objects_inside_radius(pos, 0.5) > 0 then return end
    update_item(pos, node)
  end
})

technic.register_machine("MV", "mt_future:incubator", technic.receiver)
