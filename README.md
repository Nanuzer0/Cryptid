# Cryptid (Nanuzer0's version)

This is my personal version of the [Cryptid](https://github.com/SpectralPack/Cryptid) mod for Balatro. For now it's mostly small fixes and quality-of-life tweaks on top of upstream Cryptid.

It needs the same mods as upstream Cryptid: [Steamodded](https://github.com/Steamodded/smods/releases/latest) and [Amulet](https://github.com/frostice482/amulet/releases/latest).

## Fixes

- **Crashes**
  - No crash at 0 hand size when the None hand is unlocked, and selling a hand-size Joker (like Stuntman) at 0 hand size no longer ends the run.
  - Invalid ACE code shows "Nope!" instead of crashing the game.
  - Fixed several undefined variables that could crash the game.
  - Code that runs before Cryptid has fully loaded no longer assumes it has.
- **://CRASH**
  - Saves the run reliably before crashing, including when used inside a booster pack.
- **Cards and decks**
  - Negative playing cards no longer stop you from drawing cards in the next blind.
  - Monopoly Money no longer makes vouchers count as two purchases (e.g. for Cursor).
  - ://SEED's Rigged sticker now works on shop and booster pack cards.
  - The Deck of Equilibrium's pool no longer includes locked items.
  - Pointer no longer lets you spawn Exotics after visiting a playing card submenu.
  - Shattering Jokers now trigger "Joker destroyed" effects and can be prevented, like in Steamodded.
- **Gamesets and menus**
  - Gameset values (rarity, cost, effects) apply properly and switch back when you change gamesets, without needing a restart.
  - Disabled items look debuffed again in the collection.
  - Disabled challenges are greyed out reliably.
  - Antimatter deck descriptions can no longer get stuck on other decks.
- **Restored after Steamodded updates** (these had silently stopped working)
  - Banana Jokers can go extinct at the end of the round again.
  - Sixth Sense can't destroy an Eternal 6.
  - Shiny tags use their shiny art.
  - ://CRASH glitches the screen again.
  - Oversaturated cards have their shine.
  - The ascension power text clears after a hand is scored.
  - After using a Planet, the selected hand (or None) is shown again.
  - Jimbo is a Jolly Joker with Cryptid's colours.
  - Cross-mod content loads its art and sounds from its own mod.
  - Card descriptions format big bonus values safely, and early xChips/xMult effects can't crash.

## Changes and additions

- **Monopoly Money** takes all your money when sold.
- **Baneful Pack**: can't be skipped, and it has 2 cards.
- **The Decision** no longer fastens Jokers.
- **Antimatter Deck**: "Select all" and "Deselect all" buttons on the deck select page.
- **Simple ://CRASH** setting: every crash except ACE becomes an instant quit, with the same odds as before.
- **End Run** button on the Continue tab, so you can delete a saved run and change gameset settings.
- **Gameset picker**: a green tick marks the current option.
- **Additions page**: each item shows the gameset it's in.

## To do

- Rewrite the Chocolate Die events, with Ghost kept.
- Rewrite the Antimatter Sleeve (CardSleeves support).
- Rewrite the JokerDisplay support.
- Improve how the End Run button looks.
- Translations for the new settings and buttons, which are English only for now.
