-- calculate.lua: modifications specifically for card calculation

-- this seems like a good spot to put the mod calc
SMODS.current_mod.calculate = function(self, context)
	if context.setting_blind and G.GAME.sundial then
		return { xblindsize = (1 - (G.GAME.sundial_amount / 100)) }
	end
	if context.ante_change and SMODS.ante_end then
		Cryptid.apply_ante_tax()
	end
	-- Banana Jokers roll to go extinct at end of round. This runs here instead of in the
	-- sticker's calculate so debuffed Jokers roll too (SMODS skips stickers on debuffed cards).
	if
		context.end_of_round
		and context.main_eval
		and not context.individual
		and not context.repetition
		and not context.retrigger_joker
		and G.jokers
	then
		for _, joker in ipairs(G.jokers.cards) do
			joker:calculate_banana()
		end
	end
end

-- deal with Rigged and Fragile when scoring a playing card
local ec = eval_card
function eval_card(card, context)
	if not card then
		card = {
			ability = {},
			can_calculate = function()
				return false
			end,
		}
	end
	-- Store old probability for later reference
	local ret, post = ec(card, context)
	return ret, post
end

--some functions to minimize the load on calculate_joker itself
function Card:cry_copy_ability()
	local orig_ability = {}
	if self.ability then
		for i, j in pairs(self.ability) do
			if Cryptid.is_big(j) then
				orig_ability[i] = to_big(j)
			elseif type(j) == "table" then
				orig_ability[i] = {}
				for i2, j2 in pairs(j) do
					orig_ability[i][i2] = j2
				end
			else
				orig_ability[i] = j
			end
		end
	end
	return orig_ability
end
local cj = Card.calculate_joker

local function is_in_evaluated_area(card)
	if not card.area then
		return false
	end
	for _, group in ipairs({ "jokers", "playing_cards" }) do
		for _, area in ipairs(SMODS.get_card_areas(group)) do
			if card.area == area then
				return true
			end
		end
	end
	return false
end

-- Runs calculate on every active event (Chocolate Die) for one pass, "pre_jokers" or "post_jokers".
-- Events see each context in both passes, so their effects must check one of the two flags.
-- An event can return flags (e.g. { remove = true } for context.destroying_card); they're
-- collected into `flags` and returned by SMODS.calculate_context.
local function calculate_events(context, pass, flags)
	if not (G.GAME and G.GAME.events) then
		return
	end
	for k, v in pairs(SMODS.Events) do
		if G.GAME.events[k] then
			context[pass] = true
			local res = v:calculate(context)
			context[pass] = nil
			if type(res) == "table" then
				for flag, value in pairs(res) do
					flags[flag] = value
				end
			end
		end
	end
end

local smcc = SMODS.calculate_context
function SMODS.calculate_context(context, return_table, no_resolve)
	local event_flags = {}
	calculate_events(context, "pre_jokers", event_flags)
	if context.using_consumeable then
		local _card = context.consumeable
		--calculate the joker effects
		local eval, post = eval_card(_card, context)
		local effects = { eval }
		for _, v in ipairs(post) do
			effects[#effects + 1] = v
		end

		if context.other_joker then
			for k, v in pairs(effects[1]) do
				v.other_card = _card
			end
		end
		if effects[1].retriggers then
			context.retrigger_joker = true
			for rt = 1, #effects[1].retriggers do
				context.retrigger_joker = effects[1].retriggers[rt].retrigger_card
				local rt_eval, rt_post = eval_card(_card, context)
				table.insert(effects, { effects[1].retriggers[rt] })
				table.insert(effects, rt_eval)
				for _, v in ipairs(rt_post) do
					effects[#effects + 1] = v
				end
			end
			context.retrigger_joker = false
		end
		if return_table then
			for _, v in ipairs(effects) do
				if v.jokers and not v.jokers.card then
					v.jokers.card = _card
				end
				return_table[#return_table + 1] = v
			end
		else
			SMODS.trigger_effects(effects, _card)
		end
	end
	local ret = smcc(context, return_table, no_resolve)
	local trigger = context.trigger_obj
	if
		(context.mod_probability or context.fix_probability)
		and type(trigger) == "table"
		and trigger.is
		and trigger:is(Card)
		and not is_in_evaluated_area(trigger)
	then
		if no_resolve then
			SMODS.no_resolve = true
		end
		local eval, post = eval_card(trigger, context)
		local effects = { eval }
		for _, v in ipairs(post) do
			effects[#effects + 1] = v
		end
		if return_table then
			for _, v in ipairs(effects) do
				return_table[#return_table + 1] = v
			end
		else
			local f = SMODS.trigger_effects(effects, trigger)
			ret = ret or {}
			for k, v in pairs(f) do
				ret[k] = v
			end
			SMODS.update_context_flags(context, f)
		end
		if no_resolve then
			SMODS.no_resolve = nil
		end
	end
	calculate_events(context, "post_jokers", event_flags)
	-- Callers that pass return_table collect effects instead of reading flags.
	if next(event_flags) and not return_table then
		ret = ret or {}
		for flag, value in pairs(event_flags) do
			ret[flag] = value
		end
	end
	return ret
end

function Card:calculate_joker(context)
	local active_side = self
	--[[
	if
		next(SMODS.find_card("j_cry_flip_side"))
		and not context.dbl_side
		and self.edition
		and self.edition.cry_double_sided
	then
		local dummy = self:get_other_side_dummy()
		if dummy then
			active_side = dummy
			if context.callback then
				local m = context.callback
				context.callback = function(card, a, b)
					m(self, a, b)
				end
				context.dbl_side = true
			end
		else
			return
		end
	end
	]]
	if not active_side or active_side.will_shatter then
		return
	end
	if not G.GAME.cry_double_scale then
		G.GAME.cry_double_scale = { double_scale = true } --doesn't really matter what's in here as long as there's something
	end
	--local orig_ability = copy_table(active_side.ability)
	local in_context_scaling = false
	local callback = context.callback
	if active_side.ability.cry_possessed then
		if
			not (
				(context.individual and not context.repetition)
				or context.joker_main
				or (context.other_joker and not context.post_trigger)
			)
		then
			return
		end
		context.callback = nil
	end
	local ret, trig = cj(active_side, context)
	if active_side.ability.cry_possessed and ret then
		if ret.mult_mod then
			ret.mult_mod = ret.mult_mod * -1
		end
		if ret.Xmult_mod then
			ret.Xmult_mod = ret.Xmult_mod ^ -1
		end
		if ret.mult then
			ret.mult = ret.mult * -1
		end
		if ret.x_mult then
			ret.x_mult = ret.x_mult ^ -1
		end
		ret.e_mult = nil
		ret.ee_mult = nil
		ret.eee_mult = nil
		ret.hyper_mult = nil
		ret.Emult_mod = nil
		ret.EEmult_mod = nil
		ret.EEEmult_mod = nil
		ret.hypermult_mod = nil
		if ret.chip_mod then
			ret.chip_mod = ret.chip_mod * -1
		end
		if ret.Xchip_mod then
			ret.Xchip_mod = ret.Xchip_mod ^ -1
		end
		if ret.chips then
			ret.chips = ret.chips * -1
		end
		if ret.x_chips then
			ret.x_chips = ret.x_chips ^ -1
		end
		ret.e_chips = nil
		ret.ee_chips = nil
		ret.eee_chips = nil
		ret.hyper_chips = nil
		ret.Echip_mod = nil
		ret.EEchip_mod = nil
		ret.EEEchip_mod = nil
		ret.hyperchip_mod = nil
		if ret.message then
			-- TODO - this is a hacky way to do this, but it works for now
			if type(ret.message) == "table" then
				ret.message = ret.message[1]
			end
			if ret.message:sub(1, 1) == "+" then
				ret.message = "-" .. ret.message:sub(2)
			elseif ret.message:sub(1, 1) == "X" then
				ret.message = "/" .. ret.message:sub(2)
			else
				ret.message = ret.message .. "?"
			end
		end
		if callback then
			callback(context.blueprint_card or self, ret, context.retrigger_joker)
		end
	end
	if not context.blueprint and (active_side.ability.set == "Joker") and not active_side.debuff then
		if ret or trig then
			in_context_scaling = true
		end
	end
	return ret, trig
end
