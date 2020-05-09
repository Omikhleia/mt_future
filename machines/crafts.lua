minetest.register_craft({
  output = 'mt_future:incubator',
  recipe = {
    {'bucket:bucket_water',    'default:obsidian_glass', 'bucket:bucket_water'},
    {'pipeworks:tube_1',       'technic:mv_transformer', 'pipeworks:tube_1'},
    {'technic:machine_casing', 'technic:mv_cable',       'technic:stainless_steel_ingot'},
  }
})
