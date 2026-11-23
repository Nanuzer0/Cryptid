-- JokerDisplay definitions for items/m.lua.
return function(jd)
	local defs = JokerDisplay.Definitions

	-- Values that are just shown as they are, like Hologram.
	defs.j_cry_foodm = jd.stat("mult", "mult")
	defs.j_cry_longboi = jd.stat("xmult", "monster")

	-- End-of-round money, like Cloud 9.
	defs.j_cry_mneon = jd.round_money(jd.dollar_bonus)

	-- Chances, like Hallucination.
	defs.j_cry_notebook = jd.chance(function(card)
		return SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "Notebook")
	end)
	defs.j_cry_scrabble = jd.chance(function(card)
		return SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "Scrabble Tile")
	end)

	-- Once per round, like DNA: Active! until they've triggered this round.
	local function spawn_ready(card)
		return card.ability.extra.spawn
	end
	defs.j_cry_jollysus = jd.status(spawn_ready)
	defs.j_cry_sacrifice = jd.status(spawn_ready)

	-- Jokers that react to a poker hand: just the hand, like The Duo's reminder.
	local function hand_only()
		return {
			reminder_text = jd.hand_reminder(),
			calc_function = function(card)
				card.joker_display_values.localized_text = jd.hand_name(card.ability.extra.type)
			end,
		}
	end
	defs.j_cry_bubblem = hand_only() -- turns into a Foil Jolly Joker when played
	defs.j_cry_reverse = hand_only() -- fills the Joker slots with Jolly Jokers when discarded
	defs.j_cry_smallestm = hand_only() -- gives a Double M Tag when played

	-- Huge: like The Duo. X Mult once its hand has been played this round.
	local biggestm_text, biggestm_config = jd.bonus_text("xmult", "x_mult")
	defs.j_cry_biggestm = {
		text = biggestm_text,
		text_config = biggestm_config,
		reminder_text = jd.hand_reminder(),
		calc_function = function(card)
			local values = card.ability.extra
			local name = JokerDisplay.evaluate_hand()
			local active = values.check or jd.scored_hand_name(name) == values.type
			card.joker_display_values.x_mult = active and values.x_mult or 1
			card.joker_display_values.localized_text = jd.hand_name(values.type)
		end,
	}

	-- M Stack: like Hanging Chad, but for every scoring card.
	defs.j_cry_mstack = {
		retrigger_function = function(playing_card, scoring_hand, held_in_hand, joker_card)
			if held_in_hand or not JokerDisplay.in_scoring(playing_card, scoring_hand) then
				return 0
			end
			local values = joker_card.ability
			return math.min(values.extra.retriggers, values.immutable.max_retriggers)
				* JokerDisplay.calculate_joker_triggers(joker_card)
		end,
	}

	-- Loopy: retriggers every other Joker (shown on their numbers, like Chad).
	defs.j_cry_loopy = {
		retrigger_joker_function = function(retriggered, loopy)
			if retriggered == loopy then
				return 0
			end
			return math.min(loopy.ability.extra.retrigger, loopy.ability.immutable.limit)
		end,
	}

	-- Bonk: like Baseball Card. +Chips on every Joker (itself too), more on Jolly Jokers. The
	-- reminder is the hand that scales it.
	defs.j_cry_bonk = {
		reminder_text = jd.hand_reminder(),
		calc_function = function(card)
			card.joker_display_values.localized_text = jd.hand_name(card.ability.extra.type)
		end,
		mod_function = function(other, bonk)
			if other.ability.set ~= "Joker" then
				return {}
			end
			local values = bonk.ability.extra
			local chips = other:is_jolly() and to_big(values.chips) * values.xchips or values.chips
			return { chips = chips * JokerDisplay.calculate_joker_triggers(bonk) }
		end,
	}

	-- Tredecim: like Baseball Card. ^Mult on every Jolly and M Joker (itself too).
	defs.j_cry_mprime = {
		mod_function = function(other, mprime)
			if other.ability.set ~= "Joker" then
				return {}
			end
			if not (other:is_jolly() or Cryptid.safe_get(other.config.center, "pools", "M")) then
				return {}
			end
			return { e_mult = mprime.ability.extra.mult ^ JokerDisplay.calculate_joker_triggers(mprime) }
		end,
	}
end
