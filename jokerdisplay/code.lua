-- JokerDisplay definitions for items/code.lua.
return function(jd)
	local defs = JokerDisplay.Definitions

	-- Values that are just shown as they are, like Hologram.
	defs.j_cry_cut = jd.stat("xmult", "Xmult")
	defs.j_cry_python = jd.stat("xmult", "Xmult")

	-- Copy/Paste: like Hallucination, its chance.
	defs.j_cry_copypaste = jd.chance(function(card)
		return SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "Copy/Paste")
	end)
end
