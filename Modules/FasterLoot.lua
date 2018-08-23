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
	if (GetCVar('autoLootDefault') == '1' and not IsModifiedClick('AUTOLOOTTOGGLE')) or (GetCVar('autoLootDefault') ~= '1' and IsModifiedClick('AUTOLOOTTOGGLE')) then
		for i = NumLootItems, 1, -1 do
			LootSlot(i)
		end
		CloseLoot()
	end
end

function FL:Initialize()
	FL:RegisterEvent('LOOT_READY')
end