local PA = _G.ProjectAzilroka
local FL = PA:NewModule('FasterLoot', 'AceEvent-3.0')
PA.FL, _G.FasterLoot = FL, FL

FL.Title = '|cFF16C3F2Faster|r |cFFFFFFFFLoot|r'
FL.Description = 'Increases auto loot speed near instantaneous.'
FL.Authors = 'Azilroka'

local GetNumLootItems, CloseLoot, LootSlot, GetCVar, IsModifiedClick = GetNumLootItems, CloseLoot, LootSlot, GetCVar, IsModifiedClick

function FL:LOOT_READY()
	local NumLootItems = GetNumLootItems()
	if NumLootItems == 0 then
		CloseLoot()
		return
	end

	if self.isLooting then
		return
	end

	if (GetCVar('autoLootDefault') == '1' and not IsModifiedClick('AUTOLOOTTOGGLE')) then
		for i = NumLootItems, 1, -1 do
			LootSlot(i)
		end

		FL.isLooting = true

		C_Timer.After(.2, function() FL.isLooting = false end)
	end
end

function FL:BuildProfile()
	PA.Defaults.profile['FasterLoot'] = { ['Enable'] = false }

	PA.Options.args.general.args.FasterLoot = {
		type = 'toggle',
		name = FL.Title,
		desc = FL.Description,
	}
end

function FL:Initialize()
	if PA.db.FasterLoot.Enable ~= true then
		return
	end

	FL:RegisterEvent('LOOT_READY')
end
