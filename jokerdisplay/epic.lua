-- JokerDisplay definitions for items/epic.lua.
return function(jd)
	local defs = JokerDisplay.Definitions

	-- Values that are just shown as they are, like Hologram.
	defs.j_cry_m = jd.stat("xmult", "x_mult")
	defs.j_cry_starfruit = { text = jd.bonus_text("emult", "emult", "card.ability") }

	-- End-of-round money, like Cloud 9.
	defs.j_cry_number_blocks = jd.round_money(jd.dollar_bonus)
	defs.j_cry_goldjoker = jd.round_money(jd.dollar_bonus)

	-- Chances, like Hallucination.
	defs.j_cry_boredom = jd.chance(function(card)
		return SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "Boredom")
	end)
	defs.j_cry_bonusjoker = jd.chance(function(card)
		return SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "Bonus Joker")
	end)
	defs.j_cry_multjoker = jd.chance(function(card)
		return SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "Mult Joker")
	end)

	-- Supercell: +Chips, +Mult, X Chips and X Mult (only the X ones in the Modest gameset).
	local supercell_xchips = jd.bonus_text("xchips", "x_chips")[1]
	local supercell_xmult = jd.bonus_text("xmult", "x_mult")[1]
	defs.j_cry_supercell = {
		text = {
			{ text = "+", colour = G.C.CHIPS },
			{ ref_table = "card.joker_display_values", ref_value = "chips", colour = G.C.CHIPS, retrigger_type = "mult" },
			{ text = " +", colour = G.C.MULT },
			{ ref_table = "card.joker_display_values", ref_value = "mult", colour = G.C.MULT, retrigger_type = "mult" },
			{ text = " " },
			supercell_xchips,
			{ text = " " },
			supercell_xmult,
		},
		calc_function = function(card)
			local values = card.ability.extra
			local active = to_big(values.stat2) > to_big(1)
			local plus = active and Card.get_gameset(card) ~= "modest"
			card.joker_display_values.chips = plus and values.stat1 or 0
			card.joker_display_values.mult = plus and values.stat1 or 0
			card.joker_display_values.x_chips = active and values.stat2 or 1
			card.joker_display_values.x_mult = active and values.stat2 or 1
		end,
	}

	-- Old Membership Card: +Chips for every so many members of the Cryptid Discord.
	defs.j_cry_membershipcardtwo = {
		text = jd.bonus_text("chips", "chips"),
		text_config = { colour = G.C.CHIPS },
		calc_function = function(card)
			-- The member count is read from a web response, so it can be a string.
			local members = tonumber(Cryptid.member_count) or 0
			card.joker_display_values.chips = to_big(card.ability.extra.chips)
				* math.floor(members / card.ability.immutable.chips_mod)
		end,
	}

	-- Googol Play Card: like Gros Michel. X Mult with a chance.
	local googol_play = jd.add_odds(jd.stat("xmult", "Xmult"))
	googol_play.calc_function = function(card)
		card.joker_display_values.odds =
			jd.odds_text(SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "Googol Play Card"))
	end
	defs.j_cry_googol_play = googol_play

	-- Canvas: retriggers each Joker to its left once per non-Common Joker to its right
	-- (shown on those Jokers' numbers, like Chad).
	defs.j_cry_canvas = {
		retrigger_joker_function = function(retriggered, canvas)
			local area = canvas.area
			if not area or retriggered.area ~= area or not canvas.rank or not retriggered.rank then
				return 0
			end
			if retriggered.rank >= canvas.rank then
				return 0
			end
			local modest = Card.get_gameset(canvas) == "modest"
			local count = 0
			for i, other in ipairs(area.cards) do
				if
					canvas.rank < i
					and other.is_rarity
					and not other:is_rarity(1)
					and (not modest or not other:is_rarity("cry_candy"))
				then
					count = count + 1
				end
			end
			return modest and math.min(2, count) or count
		end,
	}

	-- Error: like Invisible Joker, but the number of rounds is hidden.
	defs.j_cry_error = {
		reminder_text = {
			{ text = "(" },
			{ ref_table = "card.joker_display_values", ref_value = "active_text" },
			{ text = ")" },
		},
		calc_function = function(card)
			card.joker_display_values.is_active = card.ability.extra.active and true or false
			card.joker_display_values.active_text =
				localize("jdis_" .. (card.joker_display_values.is_active and "active" or "inactive"))
		end,
		style_function = jd.style_active,
	}

	-- Circus: X Mult for each Joker of a rarity above Common, shown on those Jokers (like Baseball
	-- Card).
	defs.j_cry_circus = {
		mod_function = function(other, circus)
			if other == circus or other.ability.set ~= "Joker" then
				return {}
			end
			local map = circus.ability.immutable and circus.ability.immutable.rarity_map
			local key = map and map[other.config.center.rarity]
			local x_mult = key and circus.ability.extra[key]
			if not x_mult or to_big(x_mult) <= to_big(1) then
				return {}
			end
			return { x_mult = x_mult ^ JokerDisplay.calculate_joker_triggers(circus) }
		end,
	}

	-- Caramel: like Triboulet. X Mult for every scoring card.
	defs.j_cry_caramel = {
		text = jd.bonus_text("xmult", "x_mult"),
		calc_function = function(card)
			local count = jd.count_scoring(function()
				return true
			end)
			card.joker_display_values.x_mult = card.ability.extra.x_mult ^ count
		end,
	}

	-- Spectrogram: retriggers the rightmost Joker once per scoring Echo Card (shown on that
	-- Joker's numbers, like Chad).
	defs.j_cry_spectrogram = {
		retrigger_joker_function = function(retriggered, spectrogram)
			if not G.jokers or retriggered ~= G.jokers.cards[#G.jokers.cards] or retriggered == spectrogram then
				return 0
			end
			local _, _, scoring_hand = JokerDisplay.evaluate_hand()
			local count = 0
			for _, scoring_card in pairs(scoring_hand or {}) do
				if scoring_card.config.center_key == "m_cry_echo" and not scoring_card.debuff then
					count = count + 1
				end
			end
			return count
		end,
	}

	-- Jimbo-tron 9000: ^Mult for each Joker (the plain one) you have.
	defs.j_cry_jtron = {
		text = jd.bonus_text("emult", "e_mult"),
		calc_function = function(card)
			card.joker_display_values.e_mult = 1 + to_big(card.ability.extra.bonus) * #SMODS.find_card("j_joker")
		end,
	}

	-- Clockwork Joker: its X Mult, times X Mult for each Steel Card held in hand (like Baron), and
	-- the Steel retriggers. Its four counters tick when a hand is played, so before that the
	-- display looks one tick ahead.
	local function clockwork_ticked(card, counter, limit)
		local state = card.ability.immutable
		local value = state.counters[counter]
		if next(G.play.cards) then
			return value
		end
		return value + 1 >= state.limits[limit] and 0 or value + 1
	end
	local function is_steel(playing_card)
		return SMODS.has_enhancement(playing_card, "m_steel")
	end
	defs.j_cry_clockwork = {
		text = jd.bonus_text("xmult", "x_mult"),
		calc_function = function(card)
			local values = card.ability.extra
			local x_mult, steel = values.xmult, values.steelenhc
			if not next(G.play.cards) then
				if clockwork_ticked(card, "c2", "l2") == 0 then
					x_mult = x_mult + values.xmult_mod
				end
				if clockwork_ticked(card, "c4", "l4") == 0 then
					steel = steel + values.steel_mod
				end
			end
			if to_big(steel) ~= to_big(1) then
				x_mult = x_mult * steel ^ jd.count_held(is_steel)
			end
			card.joker_display_values.x_mult = x_mult
		end,
		retrigger_function = function(playing_card, _, held_in_hand, joker_card)
			if not held_in_hand or not is_steel(playing_card) or clockwork_ticked(joker_card, "c1", "l1") ~= 0 then
				return 0
			end
			return JokerDisplay.calculate_joker_triggers(joker_card)
		end,
	}

	-- Demicolon: whether the Joker to its right can be force-triggered (like Blueprint's reminder).
	defs.j_cry_demicolon = {
		reminder_text = {
			{ text = "(" },
			{ ref_table = "card.joker_display_values", ref_value = "compatible" },
			{ text = ")" },
		},
		calc_function = function(card)
			local right
			for i = 1, #G.jokers.cards do
				if G.jokers.cards[i] == card then
					right = G.jokers.cards[i + 1]
				end
			end
			local compatible = Cryptid.demicolonGetTriggerable(right)[1]
			card.joker_display_values.is_active = compatible
			card.joker_display_values.compatible = localize(compatible and "k_compatible" or "k_incompatible")
		end,
		style_function = jd.style_active,
	}

	-- Sundial: like Red Bloon's countdown. Hands left until selling it makes the effect permanent.
	defs.j_cry_sundial = {
		reminder_text = {
			{ text = "(" },
			{ ref_table = "card.joker_display_values", ref_value = "countdown" },
			{ text = ")" },
		},
		calc_function = function(card)
			local left = card.ability.extra.handleft
			card.joker_display_values.is_active = to_big(left) < to_big(1)
			card.joker_display_values.countdown = jd.countdown_text(left)
		end,
		style_function = jd.style_active,
	}
end
