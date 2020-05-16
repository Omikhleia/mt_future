minetest.register_craft({
  output = 'mt_future:incubator',
  recipe = {
    {'bucket:bucket_water',    'default:obsidian_glass', 'bucket:bucket_water'},
    {'pipeworks:tube_1',       'technic:mv_transformer', 'pipeworks:tube_1'},
    {'technic:machine_casing', 'technic:mv_cable',       'technic:stainless_steel_ingot'}
  }
})

minetest.register_craft( {
  output = "mt_future:hydroponic_substrate_empty",
  recipe = {
    {'',           'wool:white',               ''},
    {'',           'pipeworks:pipe_1_empty',   ''},
    {'group:sand', 'pipeworks:storage_tank_0', 'group:sand'}
  }
})

local soylent_colors = {
  "red",
  "green",
  "blue",
  "yellow"
}

for _, color in ipairs(soylent_colors) do
  minetest.register_craft({
    type = "shapeless",
    output = "mt_future:soylent_"..color.." 11",
    recipe = {
      "dye:"..color,
      "mt_future:nutrients"
    },
  })
  minetest.register_craft({
    type = "fuel",
    recipe = "mt_future:soylent_"..color,
    burntime = 1,
  })
end

technic.register_extractor_recipe({input = {"mt_future:embryo"}, output = "mt_future:nutrients 3"})

minetest.register_craft( {
  type = "shapeless",
  output = "mt_future:nutrients 10",
  recipe = {'farming:salt', 'bucket:bucket_water', 'default:dirt'}
})

