-- Changes to base JokerDisplay's own definitions for vanilla Jokers.
return function(jd)
	local defs = JokerDisplay.Definitions

	-- Jokers that check for the first or last hand or discard of the round: show them the way
	-- Panopticon and Labyrinth make them work (see jd.as_played).
	-- Delayed Gratification is left out: it checks discards_used at the end of the round,
	-- which Labyrinth doesn't change.
	for _, key in ipairs({ "j_acrobat", "j_dusk", "j_dna", "j_sixth_sense", "j_trading", "j_burnt" }) do
		local def = defs[key]
		if def then
			for _, field in ipairs({ "calc_function", "retrigger_function" }) do
				if def[field] then
					def[field] = jd.as_played(def[field])
				end
			end
		end
	end
end
