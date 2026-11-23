-- JokerDisplay definitions for items/exotic.lua.
return function(jd)
	local defs = JokerDisplay.Definitions

	-- Values that are just shown as they are, like Hologram. Some only score while above X1/^1;
	-- showing X1/^1 then is the same.
	local stats = {
		exponentia = { "emult", "Emult" },
		crustulum = { "chips", "chips" },
		stella_mortis = { "emult", "Emult" },
		verisimile = { "xmult", "xmult" },
		duplicare = { "xmult", "Xmult" },
	}
	for key, stat in pairs(stats) do
		defs["j_cry_" .. key] = jd.stat(stat[1], stat[2])
	end

	-- Primus: like Runner, its ^Mult and the ranks that scale it (every played card must be one).
	local primus = jd.stat("emult", "Emult")
	primus.reminder_text = { { text = "(A,2,3,5,7)" } }
	defs.j_cry_primus = primus

	-- Tenebris: end-of-round money, like Cloud 9.
	defs.j_cry_tenebris = jd.round_money(jd.dollar_bonus)

	-- Iterum: like Triboulet and Hack. Retriggers every scoring card and gives X Mult for each.
	defs.j_cry_iterum = {
		text = jd.bonus_text("xmult", "x_mult"),
		calc_function = function(card)
			local count = jd.count_scoring(function()
				return true
			end)
			card.joker_display_values.x_mult = card.ability.extra.x_mult ^ count
		end,
		retrigger_function = function(playing_card, scoring_hand, held_in_hand, joker_card)
			if held_in_hand or not JokerDisplay.in_scoring(playing_card, scoring_hand) then
				return 0
			end
			local values = joker_card.ability
			return math.min(values.immutable.max_repetitions, values.extra.repetitions)
				* JokerDisplay.calculate_joker_triggers(joker_card)
		end,
	}

	-- Redeo: like Invisible Joker. Money spent towards the next Ante reduction.
	defs.j_cry_redeo = jd.progress(function(card)
		return card.ability.extra.money_remaining, card.ability.extra.money_req
	end)

	-- Circulus Pistoris: like Acrobat. ^Chips and ^Mult (pi, or tau when Oversaturated) when the
	-- hand is played with exactly hands_remaining hands left after it (never with Panopticon).
	local circulus_text = {
		jd.bonus_text("echips", "e_chips")[1],
		{ text = " " },
		jd.bonus_text("emult", "e_mult")[1],
	}
	defs.j_cry_circulus_pistoris = {
		text = circulus_text,
		calc_function = jd.as_played(function(card)
			-- The hand being scored has already been taken off hands_left.
			local hands_left = G.GAME.current_round.hands_left - (next(G.play.cards) and 0 or 1)
			local active = to_big(hands_left) == to_big(card.ability.extra.hands_remaining)
			local pi = Cryptid.safe_get(card, "edition", "cry_oversat") and 2 * math.pi or math.pi
			card.joker_display_values.e_chips = active and pi or 1
			card.joker_display_values.e_mult = active and pi or 1
		end),
	}

	-- Facile: ^Mult if cards score no more than `check` times in the hand (retriggers count).
	defs.j_cry_facile = {
		text = jd.bonus_text("emult", "e_mult"),
		calc_function = function(card)
			local count = jd.count_scoring(function()
				return true
			end)
			local active = to_big(count) <= to_big(card.ability.extra.check)
			card.joker_display_values.e_mult = active and card.ability.extra.Emult or 1
		end,
	}

	-- Energia: like Pickle. The Tags it adds for each Tag you get.
	defs.j_cry_energia = {
		text = {
			{ ref_table = "card.joker_display_values", ref_value = "tags" },
		},
		text_config = { colour = G.C.FILTER },
		calc_function = function(card)
			local tags = math.min(card.ability.immutable.max_tags, card.ability.extra.tags)
			card.joker_display_values.tags =
				localize({ type = "variable", key = to_big(tags) == to_big(1) and "a_tag" or "a_tags", vars = { tags } })
		end,
	}

	-- Formidiulosus: ^Mult for each Candy Joker you have.
	defs.j_cry_formidiulosus = {
		text = jd.bonus_text("emult", "e_mult"),
		calc_function = function(card)
			local candies = #Cryptid.advanced_find_joker(nil, "cry_candy", nil, nil, true)
			card.joker_display_values.e_mult = 1 + card.ability.extra.Emult_mod * candies
		end,
	}
end
