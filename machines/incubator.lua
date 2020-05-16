--[[
  Incubator
  Omikhleia 2020.
  MIT-lisenced.
--]]

local incubator_demand = 1800 -- Energy expensive: 1 MV hydro without upgrade.
local incubator_depleted_demand = 180
local incubator_time = 6 -- Slow: nb iterations of the technic run (whatever it is, approx. 1s).
local incubator_max_nutrients_level = 180 -- e.g. approx 3 incub. time.
local incubator_tube_velocity = 1

local S = function(machine_name, status, pos)
  local meta = minetest.get_meta(pos)
  local nutrients_level = meta:get_int("nutrients_level")
  return machine_name
         ..(status ~= "" and " "..status or "")
         .." (owner "..meta:get_string("owner")..")"
         ..(nutrients_level > 0 and "\nNutrients level "..meta:get_int("nutrients_level") or "")
end

local is_a_mob = function(stack)
  -- TODO: might not be a perfect check...
  -- For now supports mob_redo compatible mods
  if minetest.get_modpath("mobs") then
    local nodef = minetest.registered_craftitems[stack:get_name()]
    if nodef ~= nil and nodef.groups ~= nil and nodef.groups.spawn_egg then
      return true
    end
  end
  return false
end

local check_failure = function(outitem)
  -- returns: 0 success, 1 failure, -1 critical failure
  -- The longer the string, the higher the risk (e.g. itemstring with lots of metadata)
  -- Experimentally, "mob_xxx:name" is 12..25, tamed and rune-protected bunny is 1225
  -- Let's say e.g. around 20% failure rate in the first case, 50% in the second
  local failure_percent = 16 * math.log10(#outitem)
  local critical_percent = 2 * math.log10(#outitem)
  local r = math.random(1, 100)
  if r <= failure_percent then
    return r < critical_percent and -1 or 1
  end
  return 0
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

    if self.texture ~= nil and self.nodename ~= nil then
      local entity_pos = vector.round(self.object:get_pos())
      local objs = minetest.get_objects_inside_radius(entity_pos, 0.5)
      for _, obj in ipairs(objs) do
        if obj ~= self.object and
           obj:get_luaentity() and
           obj:get_luaentity().name == "mt_future:item" and
           obj:get_luaentity().nodename == self.nodename and
           obj:get_properties() and
           obj:get_properties().textures and
           obj:get_properties().textures[1] == self.texture then
          minetest.log("action","[mt_future] Removing extra " ..
            self.texture .. " found in " .. self.nodename .. " at " ..
            minetest.pos_to_string(entity_pos))
          self.object:remove()
          break
        end
      end
    end
  end,
  get_staticdata = function(self)
    if self.nodename ~= nil and self.texture ~= nil then
      return self.nodename .. ';' .. self.texture
    end
    return ""
  end,
})

local remove_item = function(pos, node)
  local objs = minetest.get_objects_inside_radius(pos, .5)
  if objs then
    for _, obj in ipairs(objs) do
      if obj and obj:get_luaentity() and obj:get_luaentity().name == "mt_future:item" then
        obj:remove()
      end
    end
  end
  minetest.swap_node(pos, { name = node.name, param2 = 10})
end

local update_item = function(pos, node)
  remove_item(pos, node)
  local meta = minetest.get_meta(pos)
  if meta:get_string("item") ~= "" then
    tmp.nodename = node.name
    tmp.texture = ItemStack(meta:get_string("item")):get_name()
    minetest.add_entity(pos,"mt_future:item")
    minetest.swap_node(pos, { name = node.name, param2 = 50})
  end
end

local drop_item = function(pos, node)
  local meta = minetest.get_meta(pos)
  if meta:get_string("item") ~= "" then
    minetest.add_item({x=pos.x,y=pos.y+1,z=pos.z}, meta:get_string("item"))
    meta:set_string("item","")
  end
  remove_item(pos, node)
end

-- Common methods

local incubator_on_construct = function(pos)
  local meta = minetest.get_meta(pos)
  meta:set_int("MV_EU_input", 0)
  meta:set_int("MV_EU_demand", 0)
end

local incubator_on_rightclick = function(pos, node, clicker, itemstack)
  if not itemstack then return end
  local meta = minetest.get_meta(pos)

  local name = clicker and clicker:get_player_name()
  if name == meta:get_string("owner")
     or minetest.check_player_privs(name, "protection_bypass") then
    if itemstack:get_name() == "mt_future:nutrients" then
      -- refilling
      local n = math.min(itemstack:get_count(), incubator_max_nutrients_level - meta:get_int("nutrients_level"))
      itemstack:take_item(n)
      meta:set_int("nutrients_level", meta:get_int("nutrients_level") + n)
      if node.name == "mt_future:incubator_depleted" then
        minetest.swap_node(pos, { name = "mt_future:incubator", param2 = node.param2})
        meta:set_string("infotext", S("Incubator", "", pos))
        meta:set_int("MV_EU_input", 0)
        meta:set_int("MV_EU_demand", 0)
      end
    else
      -- switching contents
      drop_item(pos, node)
      local s = itemstack:take_item()
      meta:set_string("item", s:to_string())
      update_item(pos, node)
    end
  end
  return itemstack
end

local incubator_on_punch = function(pos, node,  puncher)
  local meta = minetest.get_meta(pos)

  local name = puncher and puncher:get_player_name()
  if name == meta:get_string("owner")
     or minetest.check_player_privs(name, "protection_bypass") then
    drop_item(pos, node)
  end
end

local incubator_can_dig = function(pos, player)
  if not player then return end

  local name = player and player:get_player_name()
  local meta = minetest.get_meta(pos)
  return name == meta:get_string("owner") or
      minetest.check_player_privs(name, "protection_bypass")
end

local incubator_on_destruct = function(pos)
  local meta = minetest.get_meta(pos)
  local node = minetest.get_node(pos)
  if meta:get_string("item") ~= "" then
    drop_item(pos, node)
  end
end

-- Nodes

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
    incubator_on_construct(pos)
    local meta = minetest.get_meta(pos)
    meta:set_int("nutrients_level", incubator_max_nutrients_level)
  end,
  after_place_node = function(pos, placer, itemstack)
    local meta = minetest.get_meta(pos)
    meta:set_string("owner", placer:get_player_name())
    meta:set_string("infotext", S("Incubator", "", pos))
    pipeworks.after_place(pos, placer, itemstack)
  end,
  on_rightclick = incubator_on_rightclick,
  on_punch = incubator_on_punch,
  can_dig = incubator_can_dig,
  on_destruct = incubator_on_destruct,

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

    -- Machine logic
    if meta:get_string("item") ~= "" then
      if eu_input < meta:get_int("MV_EU_demand") then
        meta:set_string("infotext", S("Incubator", "Unpowered", pos))
        meta:set_int("incubation_time", incubator_time)
      else
        local stack = ItemStack(meta:get_string("item"))
        if is_a_mob(stack) then
          -- Handle depletion
          local nlevel = meta:get_int("nutrients_level")
          if nlevel <= 0 then
              minetest.swap_node(pos, { name = "mt_future:incubator_depleted", param2 = node.param2})
              meta:set_int("MV_EU_demand", incubator_depleted_demand)
              meta:set_string("infotext", S("Depleted incubator", "Active", pos))
              return
          end
          meta:set_int("nutrients_level", nlevel - 1)
          -- Handle cloning
          local itime = meta:get_int("incubation_time")
          local progress = 100 - math.floor(100 * itime / incubator_time)
          meta:set_string("infotext", S("Incubator", 
                          "Active "..progress.."%", pos))
          meta:set_int("MV_EU_demand", incubator_demand)
          meta:set_int("incubation_time", itime - 1)
          if itime <= 0 then
            local outitem = meta:get_string("item")
            local fail = check_failure(outitem)
            if fail == -1 then
              -- Critical fail, item lost
              meta:set_string("item", "mt_future:embryo")
              update_item(pos, node)
            elseif fail == 1 then
              -- Normal fail, cloning failed experiment
              outitem = "mt_future:embryo"
              technic.tube_inject_item(pos, pos, vector.new(incubator_tube_velocity, 0, incubator_tube_velocity),
                                       outitem)
            else
              -- Success, cloning item
              technic.tube_inject_item(pos, pos, vector.new(incubator_tube_velocity, 0, incubator_tube_velocity),
                                       outitem)
            end
            meta:set_int("incubation_time", incubator_time)
            meta:set_int("MV_EU_demand", incubator_demand)
          end
        else
          meta:set_string("infotext", S("Incubator", "Inactive", pos))
          meta:set_int("MV_EU_demand", incubator_depleted_demand)
          meta:set_int("incubation_time", incubator_time)
        end
      end
    else
      meta:set_string("infotext", S("Incubator", "Idle", pos))
      meta:set_int("MV_EU_demand", 0)
    end
  end
})

minetest.register_node("mt_future:incubator_depleted", {
  description = "Depleted incubator",
  tiles = {"default_obsidian_glass.png^pipeworks_tube_connection_metallic.png"},
  special_tiles = {{
      name = "mt_future_soup_source_animated.png",
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
    technic_machine = 1,
    technic_mv = 1,
    not_in_creative_inventory = 1
  },

  tube = {
    -- No input, output only
    connect_sides = {left = 1, right = 1, front = 1, back = 1, top = 1}
  },

  connects_to = {"group:technic_mv_cable"},
  connect_sides = {"bottom"},

  on_construct = incubator_on_construct,
  after_place_node = function(pos, placer, itemstack)
    local meta = minetest.get_meta(pos)
    meta:set_string("owner", placer:get_player_name())
    meta:set_string("infotext", S("Depleted incubator", "", pos))
    pipeworks.after_place(pos, placer, itemstack)
  end,
  on_rightclick = incubator_on_rightclick,
  on_punch = incubator_on_punch,
  can_dig = incubator_can_dig,
  on_destruct = incubator_on_destruct,

  technic_run = function(pos, node)
    local meta     = minetest.get_meta(pos)
    local eu_input = meta:get_int("MV_EU_input")

    -- Setup machine metadata if it does not exist.
    if not eu_input then
      meta:set_int("MV_EU_demand", incubator_depleted_demand)
      meta:set_int("MV_EU_input", 0)
      return
    end

    -- Machine logic
    if meta:get_string("item") ~= "" then
      if eu_input < meta:get_int("MV_EU_demand") then
        meta:set_string("infotext", S("Depleted incubator", "Unpowered", pos))
      else
        local stack = ItemStack(meta:get_string("item"))
        if is_a_mob(stack) then
          meta:set_string("infotext", S("Depleted incubator", "Active", pos))
          meta:set_int("MV_EU_demand", incubator_depleted_demand)
        else
          meta:set_string("infotext", S("Depleted incubator", "Inactive", pos))
          meta:set_int("MV_EU_demand", 0)
        end
      end
    else
      meta:set_string("infotext", S("Depleted incubator", "Idle", pos))
      meta:set_int("MV_EU_demand", 0)
    end
  end
})

technic.register_machine("MV", "mt_future:incubator", technic.receiver)
technic.register_machine("MV", "mt_future:incubator_depleted", technic.receiver)

-- automatically restore entities lost
-- due to /clearobjects or similar
minetest.register_lbm({
  label = "Maintain mt_future incubator entities",
  name = "mt_future:maintain_entities",
  nodenames = {"mt_future:incubator", "mt_future:incubator_depleted"},
  run_at_every_load = true,
  action = function(pos, node)
    minetest.after(0,
      function(pos, node)
        local meta = minetest.get_meta(pos)
        local itemstring = meta:get_string("item")
        if itemstring ~= "" then
          local entity_pos = pos
          local objs = minetest.get_objects_inside_radius(entity_pos, 0.5)
          if #objs == 0 then
            minetest.log("action","[mt_future] Replacing missing " ..
              itemstring .. " in " .. node.name .. " at " ..
              minetest.pos_to_string(pos))
            update_item(pos, node)
          end
        end
      end,
    pos, node)
  end
})
