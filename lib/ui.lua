-- ui.lua - Code used for new UI elements/changes in Cryptid

-- Add/modify Steamodded Draw Steps to work with Cryptid

-- Edition Decks

--gets sprite key to use for the given type
local function get_edeck_sprite_key(run_setup, type)
	local sprite = nil
	if run_setup then
		local r = ({
			edition = "ed",
			enhancement = "enh",
			sticker = "sk",
			suit = "st",
			seal = "sl",
		})[type]
		sprite = Cryptid.safe_get(SMODS.RunSelect, "Setup", "choices", "cry_edeck_" .. r)
			or Cryptid.safe_get(G.PROFILES, G.SETTINGS.profile, "last_choices", "cry_edeck_" .. r)
	else
		sprite = G.GAME["cry_selected_" .. type]
	end
	return sprite or "default"
end

SMODS.DrawStep({
	key = "back_edition",
	order = 5,
	func = function(self)
		if self.params.sleeve_card or self.ability.set == "Sleeve" then
			return
		end
		local in_run_setup = not not (
			self.ability.set == "Back"
			or self.params.viewed_back
			or self.params.run_select_selection_choice
			or self.params.run_select_preview_card
			or (self.area and (self.area.config.run_select or self.area.config.run_select_deck_preview))
		)
		local back = (self.ability.set == "Back" and self.config.center)
			or (self.params.viewed_back == true and G.GAME.viewed_back and G.GAME.viewed_back.effect.center)
			or (self.playing_card and not in_run_setup and G.GAME.selected_back_key)
		if not self.cry_antimatter_locked and back and (back.unlocked or not in_run_setup) then
			if back.key == "b_cry_antimatter" then
				self.children.back:draw_shader("negative", nil, self.ARGS.send_to_shader, true)
				self.children.back:draw_shader("negative_shine", nil, self.ARGS.send_to_shader, true)
			end
			if back.key == "b_cry_e_deck" then
				local ed = get_edeck_sprite_key(in_run_setup, "edition")
				Cryptid.update_edeck_sprite(self, "edition", ed)
				if ed == "e_negative" then
					self.children.back:draw_shader("negative", nil, self.ARGS.send_to_shader, true)
					self.children.back:draw_shader("negative_shine", nil, self.ARGS.send_to_shader, true)
				elseif ed ~= "default" and ed ~= "random" then
					local shader = G.SHADERS[ed:sub(3)] and ed:sub(3)
						or Cryptid.safe_get(G.P_CENTERS, ed, "shader")
						or nil
					if shader then --because shader can be `false`
						self.children.back:draw_shader(shader, nil, self.ARGS.send_to_shader, true)
					end
				end
			end
			if back.key == "b_cry_et_deck" then
				local enh = get_edeck_sprite_key(in_run_setup, "enhancement")
				Cryptid.update_edeck_sprite(self, "enhancement", enh)
			end
			if back.key == "b_cry_sk_deck" then
				local sk = get_edeck_sprite_key(in_run_setup, "sticker")
				Cryptid.update_edeck_sprite(self, "sticker", sk)
				if sk == "all" then
					for key, sticker in pairs(SMODS.Stickers) do
						if type(sticker.draw) == "function" then
							sticker:draw(self)
						elseif G.shared_stickers[key] then
							G.shared_stickers[key].role.draw_major = self
							G.shared_stickers[key]:draw_shader("dissolve", nil, nil, true, self.children.center)
							G.shared_stickers[key]:draw_shader(
								"voucher",
								nil,
								self.ARGS.send_to_shader,
								true,
								self.children.center
							)
						end
					end
				elseif sk ~= "default" and sk ~= "random" and SMODS.Stickers[sk] then
					if type(SMODS.Stickers[sk].draw) == "function" then
						SMODS.Stickers[sk]:draw(self)
					else
						G.shared_stickers[sk].role.draw_major = self
						G.shared_stickers[sk]:draw_shader("dissolve", nil, nil, true, self.children.center)
						G.shared_stickers[sk]:draw_shader(
							"voucher",
							nil,
							self.ARGS.send_to_shader,
							true,
							self.children.center
						)
					end
				end
			end
			if back.key == "b_cry_st_deck" then
				local st = get_edeck_sprite_key(in_run_setup, "suit")
				Cryptid.update_edeck_sprite(self, "suit", st)
			end
			if back.key == "b_cry_sl_deck" then
				local sl = get_edeck_sprite_key(in_run_setup, "seal")
				Cryptid.update_edeck_sprite(self, "seal", sl)
				if G.shared_seals[sl] then
					G.shared_seals[sl].role.draw_major = self
					G.shared_seals[sl]:draw_shader("dissolve", nil, nil, true, self.children.center)
					if sl == "Gold" then --figure out handling shader `draw` funcs later
						G.shared_seals[sl]:draw_shader(
							"voucher",
							nil,
							self.ARGS.send_to_shader,
							true,
							self.children.center
						)
					end
				end
			end
		end
	end,
	conditions = { vortex = false, facing = "back" },
})

if SMODS.DrawSteps and SMODS.DrawSteps.seal then
	local orig_seal_draw = SMODS.DrawSteps.seal.func
	SMODS.DrawSteps.seal.func = function(self, layer)
		if self.seal == "random" or not G.shared_seals[self.seal] then
			local seal = G.P_SEALS[self.seal]
			if seal and type(seal.draw) == "function" then
				seal:draw(self, layer)
			end
			return
		end
		return orig_seal_draw(self, layer)
	end
end

local update_alert_ref = Card.update_alert
function Card:update_alert()
	if self.seal and not G.P_SEALS[self.seal] then
		return
	end
	return update_alert_ref(self)
end

-- Third Layer
SMODS.DrawStep({
	key = "floating_sprite2",
	order = 59,
	func = function(self)
		if self.ability.name == "cry-Gateway" and (self.config.center.discovered or self.bypass_discovery_center) then
			local scale_mod2 = 0.07 -- + 0.02*math.cos(1.8*G.TIMERS.REAL) + 0.00*math.cos((G.TIMERS.REAL - math.floor(G.TIMERS.REAL))*math.pi*14)*(1 - (G.TIMERS.REAL - math.floor(G.TIMERS.REAL)))^3
			local rotate_mod2 = 0 --0.05*math.cos(1.219*G.TIMERS.REAL) + 0.00*math.cos((G.TIMERS.REAL)*math.pi*5)*(1 - (G.TIMERS.REAL - math.floor(G.TIMERS.REAL)))^2
			self.children.floating_sprite2:draw_shader(
				"dissolve",
				0,
				nil,
				nil,
				self.children.center,
				scale_mod2,
				rotate_mod2,
				nil,
				0.1 --[[ + 0.03*math.cos(1.8*G.TIMERS.REAL)--]],
				nil,
				0.6
			)
			self.children.floating_sprite2:draw_shader(
				"dissolve",
				nil,
				nil,
				nil,
				self.children.center,
				scale_mod2,
				rotate_mod2
			)

			local scale_mod = 0.05
				+ 0.05 * math.sin(1.8 * G.TIMERS.REAL)
				+ 0.07
					* math.sin((G.TIMERS.REAL - math.floor(G.TIMERS.REAL)) * math.pi * 14)
					* (1 - (G.TIMERS.REAL - math.floor(G.TIMERS.REAL))) ^ 3
			local rotate_mod = 0.1 * math.sin(1.219 * G.TIMERS.REAL)
				+ 0.07
					* math.sin(G.TIMERS.REAL * math.pi * 5)
					* (1 - (G.TIMERS.REAL - math.floor(G.TIMERS.REAL))) ^ 2

			self.children.floating_sprite.role.draw_major = self
			self.children.floating_sprite:draw_shader(
				"dissolve",
				0,
				nil,
				nil,
				self.children.center,
				scale_mod,
				rotate_mod,
				nil,
				0.1 + 0.03 * math.sin(1.8 * G.TIMERS.REAL),
				nil,
				0.6
			)
			self.children.floating_sprite:draw_shader(
				"dissolve",
				nil,
				nil,
				nil,
				self.children.center,
				scale_mod,
				rotate_mod
			)
		end
		if
			self.config.center.soul_pos
			and self.config.center.soul_pos.extra
			and (self.config.center.discovered or self.bypass_discovery_center)
		then
			local scale_mod = 0.07 -- + 0.02*math.cos(1.8*G.TIMERS.REAL) + 0.00*math.cos((G.TIMERS.REAL - math.floor(G.TIMERS.REAL))*math.pi*14)*(1 - (G.TIMERS.REAL - math.floor(G.TIMERS.REAL)))^3
			local rotate_mod = 0 --0.05*math.cos(1.219*G.TIMERS.REAL) + 0.00*math.cos((G.TIMERS.REAL)*math.pi*5)*(1 - (G.TIMERS.REAL - math.floor(G.TIMERS.REAL)))^2
			if self.children.floating_sprite2 then
				self.children.floating_sprite2:draw_shader(
					"dissolve",
					0,
					nil,
					nil,
					self.children.center,
					scale_mod,
					rotate_mod,
					nil,
					0.1 --[[ + 0.03*math.cos(1.8*G.TIMERS.REAL)--]],
					nil,
					0.6
				)
				self.children.floating_sprite2:draw_shader(
					"dissolve",
					nil,
					nil,
					nil,
					self.children.center,
					scale_mod,
					rotate_mod
				)
			else
				local center = self.config.center
				if center and center.soul_pos and center.soul_pos.extra then
					self.children.floating_sprite2 = Sprite(
						self.T.x,
						self.T.y,
						self.T.w,
						self.T.h,
						G.ASSET_ATLAS[center.atlas or center.set],
						center.soul_pos.extra
					)
					self.children.floating_sprite2.role.draw_major = self
					self.children.floating_sprite2.states.hover.can = false
					self.children.floating_sprite2.states.click.can = false
				end
			end
		end
	end,
	conditions = { vortex = false, facing = "front" },
})
SMODS.draw_ignore_keys.floating_sprite2 = true

-- CCD Drawstep
local interceptorSprite = nil
SMODS.DrawStep({
	key = "ccd_interceptor",
	order = -5,
	func = function(self)
		local card_type = self.ability.set or "None"
		if card_type ~= "Default" and card_type ~= "Enhanced" and self.playing_card and self.facing == "front" then
			interceptorSprite = interceptorSprite
				or Sprite(0, 0, G.CARD_W, G.CARD_H, G.ASSET_ATLAS["cry_misc"], { x = 3, y = 1 })
			interceptorSprite.role.draw_major = self
			interceptorSprite:draw_shader("dissolve", nil, nil, nil, self.children.center)
		end
	end,
})

--Banished cards drawstep (thank you bandisplay :pray:)
SMODS.DrawStep({
	key = "banished_card",
	order = 69,
	func = function(card, layer)
		if
			not G.GAME.USING_POINTER
			and card.area
			and card.area.config.collection
			and G.GAME.cry_banished_keys[card.config.center_key]
		then
			card.children.center:draw_shader("debuff", nil, card.ARGS.send_to_shader)
		end
		if
			Cryptid.safe_get(card, "params", "run_select_selection_choice", 2) == "cry_antimatter"
			and not SMODS.RunSelect.Setup.choices.cry_antimatter[card.config.center_key]
			and not card.cry_antimatter_locked
		then
			card.children.back:draw_shader("debuff", nil, card.ARGS.send_to_shader, true)
		end
	end,
})

--Quartz Stake - Draw Pinned sticker
SMODS.DrawStep({
	key = "pinned_draw",
	order = 41,
	func = function(card, layer)
		if card.pinned and G.shared_stickers.pinned then
			G.shared_stickers.pinned.role.draw_major = card
			G.shared_stickers["pinned"]:draw_shader("dissolve", nil, nil, nil, card.children.center)
			G.shared_stickers["pinned"]:draw_shader("voucher", nil, card.ARGS.send_to_shader, nil, card.children.center)
		end
	end,
	conditions = { vortex = false, facing = "front" },
})

-- Make hover UI collidable - so we can detect collision and display tooltips
local m = Card.move
function Card:move(dt)
	m(self, dt)
	if self.children.h_popup then
		self.children.h_popup.states.collide.can = true
		if not self:force_popup() and not self.states.hover.is then
			self.children.h_popup:remove()
			self.children.h_popup = nil
		end
	end
end

function Card:get_banned_force_popup_areas()
	return { G.pack_cards }
end
-- This defines when we should show a card's description even when it's not hovered
function Card:force_popup()
	-- Must be selected
	if self.highlighted then
		-- Remove all popups in the pause menu (collection excluded)
		if G.SETTINGS.paused and not self.area.config.collection then
			return false
		end
		-- Playing cards
		if
			self.config.center.set == "Default"
			or self.config.center.set == "Base"
			or self.config.center.set == "Enhanced"
		then
			return false
		end
		-- Incantation mod compat
		if SMODS.Mods["incantation"] and self.area == G.consumeables then
			return false
		end
		-- Other areas where it doesn't work well
		for i, v in ipairs(self:get_banned_force_popup_areas()) do
			if self.area == v then
				return false
			end
		end
		return true
	end
end

-- Hacky hook to make cards selectable in the collection
-- Unfortunately this doesn't play nicely with gameset UI
local cainit = CardArea.init
function CardArea:init(X, Y, W, H, config)
	if config and config.collection then
		config.highlight_limit = config.card_limit
	end
	return cainit(self, X, Y, W, H, config)
end

-- Allow highlighting in the collection
local cach = CardArea.can_highlight
function CardArea:can_highlight(card)
	if self.config.collection then
		return true
	end
	return cach(self, card)
end

-- Prevent hover UI from being redrawn
local ch = Card.hover
function Card:hover()
	if self.children.h_popup then
		return
	end
	if not self.cry_antimatter_card then
		return ch(self)
	end
	-- Antimatter deck select: while this popup is built, deck descriptions use their
	-- "_antimatter" variants (see the localize and grab_tooltips hooks below). Clear the flag
	-- even if building the popup errors, or every later deck description would use them.
	Cryptid.in_antimatter_hover = self
	local ok, err = pcall(ch, self)
	Cryptid.in_antimatter_hover = nil
	if not ok then
		error(err, 0)
	end
end

local loc_ref = localize
function localize(args, misc_cat)
	if Cryptid.in_antimatter_hover and type(args) == "table" and args.type == "descriptions" and args.set == "Back" then
		if G.localization.descriptions.Back[args.key .. "_antimatter"] then
			args.key = args.key .. "_antimatter"
		end
	end
	return loc_ref(args, misc_cat)
end

if SMODS.RunSelect and SMODS.RunSelect.Functions and SMODS.RunSelect.Functions.grab_tooltips then
	local orig_grab_tooltips = SMODS.RunSelect.Functions.grab_tooltips
	function SMODS.RunSelect.Functions.grab_tooltips(set, key)
		if Cryptid.in_antimatter_hover and set == "Back" and G.localization.descriptions.Back[key .. "_antimatter"] then
			key = key .. "_antimatter"
		end
		return orig_grab_tooltips(set, key)
	end
end

local G_UIDEF_use_and_sell_buttons_ref = G.UIDEF.use_and_sell_buttons
function G.UIDEF.use_and_sell_buttons(card)
	local button_nodes = G_UIDEF_use_and_sell_buttons_ref(card)
	-- Remove sell button from cursed jokers
	if
		card.area
		and card.area.config.type == "joker"
		and card.config
		and card.config.center
		and card.config.center.rarity == "cry_cursed"
		and card.ability.name ~= "cry-Monopoly"
	then
		table.remove(button_nodes.nodes[1].nodes, 1)
	end
	if card.config and card.config.center and card.config.center.key == "c_cry_potion" then
		table.remove(button_nodes.nodes[1].nodes, 1)
	end
	-- i love buttercup
	if
		card.area
		and card.area.config.type == "joker"
		and card.config
		and card.config.center
		and card.ability.name == "cry-Buttercup"
	then
		local use = {
			n = G.UIT.C,
			config = { align = "cr" },
			nodes = {
				{
					n = G.UIT.C,
					config = {
						ref_table = card,
						align = "cr",
						maxw = 1.25,
						padding = 0.1,
						r = 0.05,
						hover = true,
						shadow = true,
						colour = G.C.UI.BACKGROUND_INACTIVE,
						one_press = true,
						button = "store",
						func = "can_store_card",
					},
					nodes = {
						{ n = G.UIT.B, config = { w = 0.1, h = 0.3 } },
						{
							n = G.UIT.T,
							config = {
								text = localize("b_store"),
								colour = G.C.UI.TEXT_LIGHT,
								scale = 0.3,
								shadow = true,
							},
						},
					},
				},
			},
		}
		local target_node = button_nodes.nodes[1]
		if not card.added_to_deck then
			use.nodes[1].nodes = { use.nodes[1].nodes[2] }
			if card.ability.consumeable then
				target_node = button_nodes
			end
		end
		target_node.nodes = target_node.nodes or {}
		table.insert(target_node.nodes, { n = G.UIT.R, config = { align = "cl" }, nodes = {
			use,
		} })
		return button_nodes
	end
	return button_nodes
end
-- "End Run" button on the main menu's Continue tab. It deletes the saved run, so things that
-- are locked during a run (like gameset settings) can be changed without playing it out.
-- Works like vanilla's Delete Profile: the first click shows a warning, the second confirms.
local run_setup_option_ref = G.UIDEF.run_setup_option
function G.UIDEF.run_setup_option(_type)
	local t = run_setup_option_ref(_type)
	if _type ~= "Continue" or not G.SAVED_GAME or G.STAGE ~= G.STAGES.MAIN_MENU then
		return t
	end
	-- a row below the Play button, the same width so the two buttons stack neatly,
	-- with the confirmation text under it like vanilla's Delete Profile warning
	t.nodes[#t.nodes + 1] = {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.05 },
		nodes = {
			{
				n = G.UIT.C,
				config = {
					align = "cm",
					minw = 5,
					minh = 0.6,
					padding = 0.15,
					r = 0.1,
					hover = true,
					shadow = true,
					colour = G.C.RED,
					button = "cry_end_saved_run",
					func = "cry_can_end_saved_run",
					focus_args = { nav = "wide" },
				},
				nodes = {
					{
						n = G.UIT.T,
						config = { text = localize("cry_end_run"), scale = 0.5, colour = G.C.UI.TEXT_LIGHT },
					},
				},
			},
		},
	}
	t.nodes[#t.nodes + 1] = {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.05 },
		nodes = {
			{
				n = G.UIT.T,
				config = {
					id = "cry_end_run_warning",
					text = localize("ph_click_confirm"),
					scale = 0.35,
					colour = G.C.CLEAR,
				},
			},
		},
	}
	return t
end

G.FUNCS.cry_can_end_saved_run = function(e)
	if e.config.disable_button then
		e.config.colour = G.C.UI.BACKGROUND_INACTIVE
		e.config.button = nil
	else
		e.config.colour = G.C.RED
		e.config.button = "cry_end_saved_run"
	end
end

G.FUNCS.cry_end_saved_run = function(e)
	local warning_text = e.UIBox and e.UIBox:get_UIE_by_ID("cry_end_run_warning")
	if not warning_text then
		return
	end
	if warning_text.config.colour ~= G.C.WHITE then
		-- first click: show the warning, and ignore clicks briefly so a double click doesn't confirm
		warning_text:juice_up()
		warning_text.config.colour = G.C.WHITE
		warning_text.config.shadow = true
		e.config.disable_button = true
		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.06,
			blockable = false,
			blocking = false,
			func = function()
				play_sound("tarot2", 0.76, 0.4)
				return true
			end,
		}))
		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.35,
			blockable = false,
			blocking = false,
			func = function()
				e.config.disable_button = nil
				return true
			end,
		}))
		play_sound("tarot2", 1, 0.4)
		return
	end
	-- second click: same streak handling as vanilla when a new run replaces an unfinished one
	local saved = G.SAVED_GAME
	if saved and saved.GAME and not saved.GAME.won then
		local high_scores = G.PROFILES[G.SETTINGS.profile].high_scores
		if high_scores and high_scores.current_streak then
			high_scores.current_streak.amt = 0
		end
		G:save_settings()
	end
	remove_save()
	play_sound("crumple1", 0.8, 1)
	-- reopen the Play menu, which no longer has a run to continue
	G.E_MANAGER:add_event(Event({
		blockable = false,
		blocking = false,
		func = function()
			G.FUNCS.setup_run({ config = {} })
			return true
		end,
	}))
end
