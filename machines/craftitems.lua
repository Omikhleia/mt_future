
-- Incubator nutrients and failure.

minetest.register_craftitem("mt_future:embryo", {
  description = "Failed cloning experiment", -- "Indistinct animal embryo" was perhaps a bit trashy :)
  inventory_image = "mt_future_embryo.png", -- actually a piglet :)
  on_use = minetest.item_eat(-2),
  groups = {food_meat_raw = 1, flammable = 2},
})

minetest.register_craftitem("mt_future:nutrients", {
  description = "Indistinct nutrients",
  inventory_image = "mt_future_nutrients.png",
  on_use = minetest.item_eat(-1),
  groups = {food_meat_raw = 1, flammable = 2},
})

-- Soylent crackers. Colorful, but not very nutritive.
-- N.B. Soylent Color (with caps) might be a trademark, hence the naming.

minetest.register_craftitem("mt_future:soylent_green", {
  description = "Green soylent cracker",
  inventory_image = "mt_future_soylent_green.png",
  on_use = minetest.item_eat(1),
  groups = {food_meat_raw = 1, flammable = 3},
})

minetest.register_craftitem("mt_future:soylent_red", {
  description = "Red soylent cracker",
  inventory_image = "mt_future_soylent_red.png",
  on_use = minetest.item_eat(1),
  groups = {food_meat_raw = 1, flammable = 3},
})

minetest.register_craftitem("mt_future:soylent_blue", {
  description = "Blue soylent cracker",
  inventory_image = "mt_future_soylent_blue.png",
  on_use = minetest.item_eat(1),
  groups = {food_meat_raw = 1, flammable = 3},
})

minetest.register_craftitem("mt_future:soylent_yellow", {
  description = "Yellow soylent cracker",
  inventory_image = "mt_future_soylent_yellow.png",
  on_use = minetest.item_eat(1),
  groups = {food_meat_raw = 1, flammable = 3},
})

