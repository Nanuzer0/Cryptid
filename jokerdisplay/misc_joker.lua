-- JokerDisplay definitions for items/misc_joker.lua.
return function(jd)
	local defs = JokerDisplay.Definitions

	local function extra(field)
		return function(card)
			return type(card.ability.extra) == "table" and card.ability.extra[field] or nil
		end
	end
	local extra_type = extra("type")

	-- Hand-type Jokers (Jolly Joker family). "the" (The), "undefined" and "nebulous" need the
	-- None hand itself; the WholeDeck ones need all 52 cards.
	local hand_type_jokers = {
		-- X Mult
		duos = { kind = "xmult", value = extra("Xmult"), also = { "Full House" } },
		home = { kind = "xmult", value = extra("Xmult") },
		nuts = { kind = "xmult", value = extra("Xmult") },
		quintet = { kind = "xmult", value = extra("Xmult") },
		unity = { kind = "xmult", value = extra("Xmult") },
		swarm = { kind = "xmult", value = extra("Xmult") },
		stronghold = { kind = "xmult", value = extra("Xmult") },
		wtf = { kind = "xmult", value = extra("Xmult") },
		clash = { kind = "xmult", value = extra("Xmult") },
		the = { kind = "xmult", value = extra("Xmult"), by_name = true },
		words_cant_even = { kind = "xmult", value = extra("x_mult") },
		-- ^Mult
		annihalation = { kind = "emult", value = extra("emult") },
		-- +Mult
		giggly = { kind = "mult", value = extra("t_mult") },
		nutty = { kind = "mult", value = extra("t_mult") },
		manic = { kind = "mult", value = extra("t_mult") },
		silly = { kind = "mult", value = extra("t_mult") },
		delirious = { kind = "mult", value = extra("t_mult") },
		wacky = { kind = "mult", value = extra("t_mult") },
		kooky = { kind = "mult", value = extra("t_mult") },
		bonkers = { kind = "mult", value = extra("t_mult") },
		fuckedup = { kind = "mult", value = extra("t_mult") },
		foolhardy = { kind = "mult", value = extra("t_mult") },
		undefined = { kind = "mult", value = extra("t_mult"), by_name = true },
		-- +Chips
		dubious = { kind = "chips", value = extra("t_chips") },
		shrewd = { kind = "chips", value = extra("t_chips") },
		tricksy = { kind = "chips", value = extra("t_chips") },
		foxy = { kind = "chips", value = extra("t_chips") },
		savvy = { kind = "chips", value = extra("t_chips") },
		subtle = { kind = "chips", value = extra("t_chips") },
		discreet = { kind = "chips", value = extra("t_chips") },
		adroit = { kind = "chips", value = extra("t_chips") },
		penetrating = { kind = "chips", value = extra("t_chips") },
		treacherous = { kind = "chips", value = extra("t_chips") },
		nebulous = { kind = "chips", value = extra("t_chips"), by_name = true },
		many_lost_minds = { kind = "chips", value = extra("chips") },
	}
	for key, args in pairs(hand_type_jokers) do
		args.hand = args.hand or extra_type
		defs["j_cry_" .. key] = jd.hand_type(args)
	end

	-- Filler keeps its values outside ability.extra, like vanilla's The Duo.
	defs.j_cry_filler = jd.hand_type({
		kind = "xmult",
		value = function(card)
			return card.ability.x_mult
		end,
		hand = function(card)
			return card.ability.type
		end,
	})
end
