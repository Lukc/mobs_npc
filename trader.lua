
local modpath = minetest.get_modpath("mobs_npc")
local traderspath = modpath .. "/traders"

local in_trade = {}

mobs.human = {
	items = {
		--{item for sale, price, chance of appearing in trader's inventory}
		{"default:apple 10", "default:gold_ingot 2", 10},
		{"farming:bread 10", "default:gold_ingot 4", 5},
		{"default:clay 10", "default:gold_ingot 2", 12},
		{"default:brick 10", "default:gold_ingot 4", 17},
		{"default:glass 10", "default:gold_ingot 4", 17},
		{"default:obsidian 10", "default:gold_ingot 15", 50},
		{"default:diamond 1", "default:gold_ingot 5", 40},
		{"farming:wheat 10", "default:gold_ingot 2", 17},
		{"default:tree 5", "default:gold_ingot 4", 20},
		{"default:stone 10", "default:gold_ingot 8", 17},
		{"default:desert_stone 10", "default:gold_ingot 8", 27},
		{"default:sapling 1", "default:gold_ingot 1", 7},
		{"default:pick_steel 1", "default:gold_ingot 2", 7},
		{"default:sword_steel 1", "default:gold_ingot 2", 17},
		{"default:shovel_steel 1", "default:gold_ingot 1", 17},
	},
	names = {
		"Bob", "Duncan", "Bill", "Tom", "James", "Ian", "Lenny"
	}
}

-- Trader ( same as NPC but with right-click shop )

mobs:register_mob("mobs_npc:trader", {
	type = "npc",
	passive = false,
	damage = 3,
	attack_type = "dogfight",
	attacks_monsters = true,
	pathfinding = false,
	hp_min = 10,
	hp_max = 20,
	armor = 100,
	collisionbox = {-0.35,-1.0,-0.35, 0.35,0.8,0.35},
	visual = "mesh",
	mesh = "character.b3d",
	textures = {
		{"mobs_trader.png"}, -- by Frerin
	},
	makes_footstep_sound = true,
	sounds = {},
	walk_velocity = 2,
	run_velocity = 3,
	jump = false,
	drops = {},
	water_damage = 0,
	lava_damage = 4,
	light_damage = 0,
	follow = {"default:diamond"},
	view_range = 15,
	owner = "",
	order = "stand",
	fear_height = 3,
	animation = {
		speed_normal = 30,
		speed_run = 30,
		stand_start = 0,
		stand_end = 79,
		walk_start = 168,
		walk_end = 187,
		run_start = 168,
		run_end = 187,
		punch_start = 200,
		punch_end = 219,
	},
	on_rightclick = function(self, clicker)
		mobs_trader(self, clicker, nil, mobs.human)
	end,
})

-- FIXME: Move this somewhere else. 
--This code comes almost exclusively from the trader and inventory of mobf, by Sapier.
--The copyright notice below is from mobf:
-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
--
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice.
-- And of course you are NOT allow to pretend you have written it.
--
--! @file inventory.lua
--! @brief component containing mob inventory related functions
--! @copyright Sapier
--! @author Sapier
--! @date 2013-01-02
--
--! @defgroup Inventory Inventory subcomponent
--! @brief Component handling mob inventory
--! @ingroup framework_int
--! @{
--
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

function mobs.allow_move(inventory, fromList, fromIndex, toList, toindex, count, player)
	if not minetest.check_player_privs(player, {give = true}) then
		return 0
	end

	return count
end

function mobs.allow_put(inventory, listName, index, stack, player)
	if not minetest.check_player_privs(player, {give = true}) then
		return 0
	end

	return stack:get_count()
end

function mobs.allow_take(inventory, listName, index, stack, player)
	if not minetest.check_player_privs(player, {give = true}) then
		return 0
	end

	return stack:get_count()
end

local function load_inventory(entity, inventory)
	for k,v in pairs(inventory) do
		entity.trader_inventory:set_stack("goods", k, v.goods)
		entity.trader_inventory:set_stack("price", k, v.price)
	end
end

local function store_inventory(entity, id)
	local file = io.open(traderspath .. "/" .. id, "w")

	local inventory = {}

	for i = 1, 15 do
		inventory[#inventory+1] = {
			goods = entity.trader_inventory:get_stack("goods", i):to_string(),
			price = entity.trader_inventory:get_stack("price", i):to_string()
		}
	end	

	file:write(minetest.serialize(inventory))

	file:close()
end

local function add_goods(self, race)
	local n = 0

	for i = 1, 15 do
		if math.random(0, 100) > race.items[i][3] then
			self.trader_inventory:set_stack(
				"goods", n, race.items[i][1]
			)
			self.trader_inventory:set_stack(
				"price", n, race.items[i][2]
			)

			n = n + 1
		end
	end
end

-- @ignored: entity
function mobs_trader(self, clicker, entity, race)
	local player = clicker:get_player_name()

	if not self.editing then
		self.editing = {}
	end

	local editing = self.editing[clicker:get_player_name()]

	if not self.id then
		self.id = (math.random(1, 1000) * math.random(1, 10000))
			.. self.name .. (math.random(1, 1000) ^ 2)
	end

	if not self.game_name then
		self.game_name = tostring(race.names[math.random(1, #race.names)])
		self.nametag = "Trader " .. self.game_name

		self.object:set_properties({
			nametag = self.nametag,
			nametag_color = "#00FF00"
		})

	end

	local unique_entity_id = self.id
	local is_inventory = minetest.get_inventory({type = "detached", name = unique_entity_id})

	in_trade[clicker:get_player_name()] = self

	local move_put_take = {
		allow_move = mobs.allow_move,
		allow_put = mobs.allow_put,
		allow_take = mobs.allow_take,
		on_put = function(inventory, listname, index, stack, player)
			local mob = in_trade[player:get_player_name()]

			store_inventory(mob, unique_entity_id)
		end,
		on_take = function(inventory, listname, index, stack, player)
			local mob = in_trade[player:get_player_name()]

			store_inventory(mob, unique_entity_id)
		end,
		on_move = function(inventory, from_list, from_index, to_list, to_index, count, player)
			local mob = in_trade[player:get_player_name()]

			store_inventory(mob, unique_entity_id)
		end,
	}

	if is_inventory == nil then
		self.trader_inventory = minetest.create_detached_inventory(unique_entity_id, move_put_take)
		self.trader_inventory:set_size("goods", 15)
		self.trader_inventory:set_size("price", 15)
	else
		self.trader_inventory = is_inventory
	end

	local success, data = pcall(function()
		f = loadfile(traderspath .. "/" .. unique_entity_id)

		return f()
	end)

	if success then
		load_inventory(self, data)
	else
		add_goods(self, race)

		store_inventory(self, unique_entity_id)
	end

	minetest.chat_send_player(player, "<Trader " .. self.game_name
		.. "> Hello, " .. player .. ", have a look at my wares.")

	local y = 0
	local h = 6

	local privileged = minetest.check_player_privs(player, {give = true})

	if privileged then
		y = y + 1
		h = 7
	end

	local form = "size[8," .. h .. "]"
		.. "label[0," .. y + 0.2 .. ";Item:]"
		.. "label[0," .. y + 1.2 .. ";Price:]"

	if privileged then
		form = form
			.. "label[0.5,-0.4;You can edit the trader’s inventory because you have the 'give' privilege]"
			.. "button[1,0;3,1;edit;Edit trader inventory]"
	end

	for i = 1, 7 do
		local x = tostring(i)

		local stack = self.trader_inventory:get_stack("price", i)

		if not stack then
			break
		end

		form = form
			.. "list[detached:" .. unique_entity_id .. ";goods;" .. x .. "," .. y .. ";1,1;" .. tostring(i - 1) .. "]"

		if editing then
			form = form
				.. "list[detached:" .. unique_entity_id .. ";price;" .. x .. "," .. y + 1 .. ";1,1;" .. tostring(i-1) .. "]"
		else
			form = form
				.. "item_image_button[" .. x .. "," .. y + 1 .. ";1,1;"
					.. stack:get_name() .. ";price" .. tostring(i)
					.. ";\n\b\b\b\b" .. stack:get_count() .. "]"
		end
	end

	y = y + 2

	form = form
		.. "list[current_player;main;0," .. y .. ";8,4;]"

	minetest.show_formspec(player, "trade", form)
end

minetest.register_on_player_receive_fields(function(player, form, pressed)
	local playerName = player:get_player_name()

	if form == "trade" then
		if pressed.edit then
			local mob = in_trade[player:get_player_name()]

			mob.editing[player:get_player_name()] = not mob.editing[player:get_player_name()]

			return  mobs_trader(mob, player, nil, mobs.human)
		end

		local n

		for i = 1, 7 do
			if pressed["price" .. i] then
				n = i
				break
			end
		end

		if not n then
			return
		end

		local inventory = minetest.get_inventory {
			type = "detached",
			name = in_trade[player:get_player_name()].id
		}

		local goods = inventory:get_stack("goods", n)
		local price = inventory:get_stack("price", n)

		minetest.chat_send_player(
			playerName,
			("%s %s  -- %s %s"):format(
				goods:get_name(), goods:get_count(),
				price:get_name(), price:get_count()
			)
		)

		-- player inventory
		local pInventory = minetest.get_inventory {
			type = "player",
			name = playerName
		}

		local priceString = ("%s %s"):format(price:get_name(), price:get_count())
		local goodsString = ("%s %s"):format(goods:get_name(), goods:get_count())

		if not pInventory:contains_item("main", priceString) then
			minetest.chat_send_player(playerName, "Dear " .. playerName .. ", you cannot afford that item.")

			return
		end

		if not pInventory:room_for_item("main", goodsString) then
			minetest.chat_send_player(playerName, "Dear " .. playerName .. ", you have no room to hold that item.")

			return
		end

		print(goods:get_name(), goods:get_count(), price:get_name(), price:get_count())

		pInventory:add_item("main", goodsString)
		pInventory:remove_item("main", priceString)
	end
end)

mobs:register_egg("mobs_npc:trader", "Trader", "default_sandstone.png", 1)

-- compatibility
mobs:alias_mob("mobs:trader", "mobs_npc:trader")

