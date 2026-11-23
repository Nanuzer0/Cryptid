-- JokerDisplay definitions for items/spooky.lua.
return function(jd)
	local defs = JokerDisplay.Definitions

	-- Candies that run out, counted down like Loyalty Card.
	local function remaining(field)
		return jd.remaining(function(card)
			return card.ability.extra[field]
		end)
	end
	defs.j_cry_wrapped = remaining("rounds") -- rounds until it turns into a Food Joker
	defs.j_cry_candy_buttons = remaining("rerolls") -- free rerolls
	defs.j_cry_brittle = remaining("rounds") -- hands it still changes a card in (despite the name)
	defs.j_cry_candy_sticks = remaining("hands") -- hands the Boss Blind stays disabled

	-- Chances, like Hallucination.
	defs.j_cry_trick_or_treat = jd.chance(function(card)
		return SMODS.get_probability_vars(card, 3, card.ability.extra.odds)
	end)
	defs.j_cry_monopoly_money = jd.chance(function(card)
		return SMODS.get_probability_vars(card, 1, card.ability.extra.odds)
	end)

	-- Candy Basket: like Pickle, the Candy Jokers it gives when sold.
	defs.j_cry_candy_basket = {
		text = {
			{ ref_table = "card.joker_display_values", ref_value = "candies" },
		},
		text_config = { colour = G.C.RARITY.cry_candy },
		calc_function = function(card)
			local candies = math.floor(math.min(card.ability.immutable.max_spawn, card.ability.extra.candies))
			card.joker_display_values.candies = localize({ type = "variable", key = "a_candy", vars = { candies } })
		end,
	}

	-- Blacklist: like Mail-In Rebate, the rank it's about. A hand with that rank played or held
	-- scores nothing.
	defs.j_cry_blacklist = {
		reminder_text = {
			{ text = "(" },
			{ ref_table = "card.joker_display_values", ref_value = "rank", colour = G.C.ORANGE },
			{ text = ")" },
		},
		calc_function = function(card)
			local id = card.ability.extra.blacklist
			local rank_key
			for key, rank in pairs(SMODS.Ranks) do
				if rank.id == id then
					rank_key = key
				end
			end
			card.joker_display_values.rank = rank_key and localize(rank_key, "ranks") or "-"
		end,
	}

	-- Rotten Egg: like Invisible Joker. Sell value of the Jokers sold so far, out of what's needed
	-- (the same "N/M" as its own messages).
	defs.j_cry_rotten_egg = jd.progress(function(card)
		local values = card.ability.extra
		return values.needed_money - values.left_money, values.needed_money
	end)

	-- Candy Cane: like Business Card. Money each time a scoring card is retriggered.
	defs.j_cry_candy_cane = {
		text = {
			{ text = "+$" },
			{ ref_table = "card.joker_display_values", ref_value = "dollars" },
		},
		text_config = { colour = G.C.GOLD },
		calc_function = function(card)
			local text, _, scoring_hand = JokerDisplay.evaluate_hand()
			local retriggers = 0
			if text ~= "Unknown" then
				for _, scoring_card in pairs(scoring_hand) do
					local triggers = JokerDisplay.calculate_card_triggers(scoring_card, scoring_hand)
					retriggers = retriggers + math.max(0, triggers - 1)
				end
			end
			card.joker_display_values.dollars = to_big(card.ability.extra.dollars) * retriggers
		end,
	}
end
