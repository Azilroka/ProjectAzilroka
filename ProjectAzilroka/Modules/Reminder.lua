local PA, ACL, ACH = unpack(_G.ProjectAzilroka)
local AR = PA:NewModule('AuraReminder', 'AceEvent-3.0', 'AceTimer-3.0')
_G.AuraReminder, PA.AuraReminder = AR, AR

AR.Title, AR.Description, AR.Authors, AR.isEnabled = 'Aura Reminder', ACL['Reminder for Buffs / Debuffs'], 'Azilroka', false

local _G = _G
local next, tonumber, tostring, select, format, strmatch, tinsert, wipe = next, tonumber, tostring, select, format, strmatch, tinsert, wipe

local GetSpellCooldown = PA.GetSpellCooldown
local GetSpellInfo = PA.GetSpellInfo
local IsSpellKnownOrOverridesKnown = IsSpellKnownOrOverridesKnown
local IsUsableSpell = C_Spell.IsSpellUsable
local IsInInstance = IsInInstance
local UnitAffectingCombat = UnitAffectingCombat
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitLevel = UnitLevel
local UnitInVehicle = UnitInVehicle
local GetInventoryItemID = GetInventoryItemID
local GetWeaponEnchantInfo = GetWeaponEnchantInfo
local GetInventoryItemTexture = GetInventoryItemTexture
local PlaySoundFile = PlaySoundFile
local GetSpecialization = GetSpecialization
local GetSpecializationRole = GetSpecializationRole
local GetSpecializationInfo = GetSpecializationInfo
local GetItemInfoInstant = GetItemInfoInstant

local MAX_PLAYER_LEVEL = MAX_PLAYER_LEVEL

local UIParent, CreateFrame = UIParent, CreateFrame

AR.CreatedReminders = {}

local selectedFilter, selectedGroup, filters, spellList, filterTypeList, DefaultFilters = nil, PA.MyClass, {}, {}, {}

do
	local function SpellIDPredicate(spellIDToFind, casterToFind, _, _, _, _, _, _, _, caster, _, _, spellID)
		return (casterToFind and caster == casterToFind and spellIDToFind == spellID) or (spellIDToFind == spellID)
	end

	function AR:FindAuraBySpellID(spellID, unit, filter, caster)
		return _G.AuraUtil.FindAura(SpellIDPredicate, unit, filter, spellID, caster)
	end
end

function AR:FindPlayerAura(db, checkPersonal, filter)
	if db then
		for spellID, value in next, db do
			if value == true then
				return AR:FindAuraBySpellID(spellID, 'player', filter, checkPersonal and 'player')
			end
		end
	end
end

function AR:IsSpellOnCooldown(id)
	local cooldownInfo = GetSpellCooldown(id)
	if coolInfo.startTime > 0 and cooldownInfo.duration > 1.5 then
		return true
	end
end

function AR:IsSpellUsable(id)
	local isUsable = IsUsableSpell(id)
	if isUsable then
		return true
	end
end

function AR:UpdateColors(frame, id)
	local isUsable, notEnoughMana = IsUsableSpell(id)
	if isUsable then
		frame.icon:SetVertexColor(1, 1, 1)
	elseif notEnoughMana then
		frame.icon:SetVertexColor(.5, .5, 1)
	else
		frame.icon:SetVertexColor(.4, .4, .4)
	end
end

function AR:HasOffHandWeapon(itemID)
	if not itemID then return end
	local itemEquipLoc = select(4, GetItemInfoInstant(itemID))
	return (itemEquipLoc == "INVTYPE_WEAPON" or itemEquipLoc == "INVTYPE_2HWEAPON" or itemEquipLoc == "INVTYPE_WEAPONOFFHAND")
end

function AR:FilterCheck(db, isReverse)
	local _, instanceType = IsInInstance()
	local roleCheck, treeCheck, combatCheck, instanceCheck, PVPCheck = true, true, true, true, true

	if PA.Retail then
		local spec = GetSpecialization()

		if db.role and (db.role ~= 'ANY' and db.role ~= GetSpecializationRole(spec)) then
			roleCheck = false
		end

		if not isReverse and db.tree and (db.tree ~= 'ANY' and db.tree ~= spec) then
			treeCheck = false
		end

		if isReverse and db.talentTreeException and db.talentTreeException == spec then
			treeCheck = false
		end
	end

	if db.combat and not UnitAffectingCombat('player') then
		combatCheck = false
	end

	if db.instance and (instanceType ~= 'party' and instanceType ~= 'raid') then
		instanceCheck = false
	end

	if db.pvp and (instanceType ~= 'arena' and instanceType ~= 'pvp') then
		PVPCheck = false
	end

	if (isReverse or roleCheck and treeCheck) and combatCheck and instanceCheck and PVPCheck then
		return true
	else
		return false
	end
end

function AR:Reminder_Update()
	if UnitIsDeadOrGhost('player') or (not PA.Classic and UnitInVehicle('player')) then return end

	for _, button in next, AR.CreatedReminders do
		button:Hide()
		button:SetAlpha(1)
	end

	local Position = 1
	for _, filter in next, {PA.MyClass, 'Global'} do
		if AR.db.Filters then
			for _, db in next, AR.db.Filters[filter] do
				if db.enable and (not db.level or db.level and UnitLevel('player') > db.level) then
					local Button = AR.CreatedReminders[Position]
					if (not Button) or (Button:IsVisible()) then
						Button = AR:CreateReminder(Position)
						Position = Position + 1
					end

					AR:SetIconPosition(Button, db)

					local filterCheck, reverseCheck = AR:FilterCheck(db), AR:FilterCheck(db, true)

					if db.filterType == 'COOLDOWN' and db.cooldownSpellID and filterCheck then
						local start, duration = GetSpellCooldown(db.cooldownSpellID)
						if (duration and duration > 1.5) then
							Button.cooldown:SetCooldown(start, duration)
						end

						Button.cooldown:SetShown((duration and duration > 0))
						Button.icon:SetTexture(select(3, GetSpellInfo(db.cooldownSpellID)))
						Button:SetShown((duration and duration == 0) or db.onCooldown)

						AR:UpdateColors(Button, db.cooldownSpellID)

						if (duration and duration > 1.5) and filterCheck and db.onCooldown then
							Button:SetAlpha(db.cooldownAlpha or .5)
						end
					elseif (db.filterType == 'WEAPON' or (db.filterType == 'SPELL' and db.spellGroup)) and filterCheck then
						if db.filterType == 'SPELL' then
							local hasBuff, hasDebuff = AR:FindPlayerAura(db.spellGroup, db.personal), AR:FindPlayerAura(db.spellGroup, nil, 'HARMFUL')
							local negate = AR:FindPlayerAura(db.negateGroup, db.personal)
							local skip = false
							if not (negate or hasBuff or hasDebuff) then
								for buff, value in next, db.spellGroup do
									if value then
										local usable = IsUsableSpell(buff)
										if db.strictFilter then
											usable = usable and IsSpellKnownOrOverridesKnown(buff)
											skip = not usable
										end
										if usable and AR:IsSpellOnCooldown(buff) then
											break
										end

										if usable or not db.strictFilter then
											Button.icon:SetTexture(select(3, GetSpellInfo(buff)))
											AR:UpdateColors(Button, buff)
											break
										end
									end
								end

								Button:SetShown(not skip and (((not hasBuff) and (not hasDebuff)) and not db.reverseCheck) or (reverseCheck and db.reverseCheck and ((hasBuff or hasDebuff) or ((not hasBuff) and (not hasDebuff)))))
							end
						end

						if db.filterType == 'WEAPON' then
							local hasOffhandWeapon = AR:HasOffHandWeapon(GetInventoryItemID('player', 17))
							local hasMainHandEnchant, _, _, hasOffHandEnchant = GetWeaponEnchantInfo()

							if (not hasMainHandEnchant) then
								Button.icon:SetTexture(GetInventoryItemTexture('player', 16))
							elseif (hasOffhandWeapon and not hasOffHandEnchant) then
								Button.icon:SetTexture(GetInventoryItemTexture('player', 17))
							end

							Button:SetShown(not (hasMainHandEnchant or hasOffHandEnchant))
							Button.icon:SetVertexColor(1, 1, 1)
						end

						if Button:IsShown() and not db.disableSound then
							AR:PlaySoundFile()
						end
					end
				end
			end
		end
	end
end

function AR:ResetSoundPlayback()
	AR.IsPlaying = false
end

function AR:PlaySoundFile()
	if AR.IsPlaying then return end

	AR.IsPlaying = true

	PlaySoundFile(PA.Libs.LSM:Fetch('sound', AR.db.Sound))

	AR:ScheduleTimer('ResetSoundPlayback', 10)
end

function AR:SetIconPosition(button, db)
	if not (button or db) then return end

	local xOffset = db.xOffset or 0
	local yOffset = db.yOffset or 200
	local size = db.size or 40

	button:ClearAllPoints()
	button:SetPoint('CENTER', UIParent, 'CENTER', xOffset, yOffset)
	button:SetSize(size, size)
end

function AR:CreateReminder(index)
	local frame = CreateFrame('Frame', 'AuraReminder'..index, UIParent)
	frame:Hide()
	frame:SetClampedToScreen(true)
	frame.icon = frame:CreateTexture(nil, 'OVERLAY')
	frame.icon:SetTexCoord(PA:TexCoords())
	frame.cooldown = CreateFrame('Cooldown', nil, frame, 'CooldownFrameTemplate')
	frame.cooldown:SetAllPoints(frame.icon)

	PA:SetTemplate(frame)
	PA:SetInside(frame.icon)

	tinsert(AR.CreatedReminders, frame)
	return frame
end

function AR:UpdateFilterGroup(group)
	for option, optionTable in next, PA.Options.args.AuraReminder.args.filterGroup.args[group].args do
		if strmatch(option, "^AR") then
			optionTable.hidden = true
		end
	end

	if AR.db.Filters[selectedGroup][selectedFilter] and AR.db.Filters[selectedGroup][selectedFilter][group] then
		local i = 1
		for spell in next, AR.db.Filters[selectedGroup][selectedFilter][group] do
			if spell and GetSpellInfo(spell) then
				local name = format('AR%s', i + 2)
				local optionName = PA.Options.args.AuraReminder.args.filterGroup.args[group].args[name]
				if not optionName then
					PA.Options.args.AuraReminder.args.filterGroup.args[group].args[name] = { type = 'toggle', width = 'double' }
					optionName = PA.Options.args.AuraReminder.args.filterGroup.args[group].args[name]
				end

				optionName.name = function() return format('%s (%s)', GetSpellInfo(spell), spell) end
				optionName.get = function() return spell and AR.db.Filters[selectedGroup][selectedFilter][group][spell] end
				optionName.set = function(_, value) AR.db.Filters[selectedGroup][selectedFilter][group][spell] = value end
				optionName.hidden = false

				i = i + 1
			end
		end
	end
end

function AR:CleanDB()
	-- Cleanup DB
	for _, filter in next, {PA.MyClass, 'Global'} do
		if AR.db.Filters and AR.db.Filters[filter] then
			for _, db in next, AR.db.Filters[filter] do
				if db.role == 'ANY' then db.role = nil end
				if db.tree == 'ANY' then db.tree = nil end
				if db.talentTreeException == 'NONE' then db.talentTreeException = nil end
				if (db.level and db.level == 0) then db.level = nil end
				if not db.combat then db.combat = nil end
				if not db.instance then db.instance = nil end
				if not db.pvp then db.pvp = nil end
				if not db.onCooldown then db.onCooldown = nil end
				if not db.disableSound then db.disableSound = nil end
			end
		end
	end
end

local addGroupTemplate = { name = '', template = ''}

function AR:GetOptions()
	local AuraReminder = ACH:Group(AR.Title, nil, nil, 'tree', function(info) return AR.db[info[#info]] end, function(info, value) AR.db[info[#info]] = value end)
	PA.Options.args.AuraReminder = AuraReminder

	AuraReminder.args.Description = ACH:Description(AR.Description, 0)
	AuraReminder.args.Enable = ACH:Toggle(ACL['Enable'], nil, 1, nil, nil, nil, nil, function(info, value) AR.db[info[#info]] = value if (not AR.isEnabled) then AR:Initialize() else _G.StaticPopup_Show('PROJECTAZILROKA_RL') end end)
	AuraReminder.args.Sound = ACH:SharedMediaSound(ACL['Sound'], ACL['Sound that will play when you have a warning icon displayed.'], 2)
	AuraReminder.args.selectGroup = ACH:Select(ACL['Select Group'], nil, 3, { Class = 'Class', Global = 'Global'}, nil, nil, function() return selectedGroup == 'Global' and selectedGroup or 'Class' end, function(_, value) selectedGroup = value == 'Class' and PA.MyClass or value end)
	AuraReminder.args.selectFilter = ACH:Select(ACL['Select Filter'], nil, 4, function() wipe(filters) for filter in next, AR.db.Filters[selectedGroup] do filters[filter] = filter end if not next(filters) then filters[''] = ACL['None'] end return filters end, nil, nil, function() return selectedFilter ~= '' and selectedFilter or '' end, function(_, value) selectedFilter = value ~= '' and value or nil AR:UpdateFilterGroup('spellGroup') AR:UpdateFilterGroup('negateGroup') end)

	AuraReminder.args.filterControl = ACH:Group(ACL['Filter Control'], nil, 5)
	AuraReminder.args.filterControl.inline = true
	AuraReminder.args.filterControl.args.addFilter = ACH:Input(ACL['New Filter Name'], nil, 1, nil, nil, function() return addGroupTemplate.name end, function(_, value) if AR.db.Filters[selectedGroup][value] then return end addGroupTemplate.name = value end)
	AuraReminder.args.filterControl.args.addFilterTemplate = ACH:Select(ACL['New Filter Type'], nil, 2, function() wipe(filterTypeList) filterTypeList.SPELL = ACL['Spell'] if selectedGroup ~= 'Global' then filterTypeList.WEAPON = ACL['Weapon'] filterTypeList.COOLDOWN = ACL['Cooldown'] end return filterTypeList end, nil, nil, function() return addGroupTemplate.template end, function(_, value) if AR.db.Filters[selectedGroup][value] then return end addGroupTemplate.template = value end)
	AuraReminder.args.filterControl.args.addFilterButton = ACH:Execute(ACL['Add Filter'], nil, 3, function() AR.db.Filters[selectedGroup][addGroupTemplate.name] = { enable = true, size = 50, filterType = addGroupTemplate.template } if addGroupTemplate.template == 'COOLDOWN' then AR.db.Filters[selectedGroup][addGroupTemplate.name].cooldownAlpha = .5 else AR.db.Filters[selectedGroup][addGroupTemplate.name].spellGroup, AR.db.Filters[selectedGroup][addGroupTemplate.name].negateGroup = {}, {} end selectedFilter = addGroupTemplate.name addGroupTemplate.name, addGroupTemplate.template = '', '' end, nil, nil, nil, nil, nil, nil, function() return addGroupTemplate.name == '' or addGroupTemplate.template == '' end)
	AuraReminder.args.filterControl.args.deleteGroup = ACH:Select(ACL['Remove Filter'], nil, 5, function() wipe(filters) for filter in next, AR.db.Filters[selectedGroup] do filters[filter] = filter end if not next(filters) then filters[''] = ACL['None'] end return filters end, function(_, value) return ACL['Remove Filter']..' - '..value end, nil, function() return '' end, function(_, value) selectedFilter = nil if DefaultFilters[selectedGroup][value] then AR.db.Filters[selectedGroup][value].enable = false else AR.db.Filters[selectedGroup][value] = nil end end)

	AuraReminder.args.filterGroup = ACH:Group(function() return selectedFilter end, nil, 8, nil, function(info) return AR.db.Filters[selectedGroup][selectedFilter][info[#info]] end, function(info, value) AR.db.Filters[selectedGroup][selectedFilter][info[#info]] = value end, nil, function() return not selectedFilter end)
	AuraReminder.args.filterGroup.inline = true
	AuraReminder.args.filterGroup.args.enable = ACH:Toggle(ACL['Enable'], nil, 1)
	AuraReminder.args.filterGroup.args.filterType = ACH:Select(ACL['Filter Type'], ACL['Change this if you want the Reminder module to check for weapon enchants, setting this will cause it to ignore any spells listed.'], 2, function() wipe(filterTypeList) filterTypeList.SPELL = ACL['Spell'] if selectedGroup ~= 'Global' then filterTypeList.WEAPON, filterTypeList.COOLDOWN = ACL['Weapon'], ACL['Cooldown'] end return filterTypeList end)
	AuraReminder.args.filterGroup.args.xOffset = ACH:Range(ACL['X Offset'], nil, 3, { min = -(PA.ScreenWidth / 2), max = (PA.ScreenWidth / 2), step = 1 })
	AuraReminder.args.filterGroup.args.yOffset = ACH:Range(ACL['Y Offset'], nil, 4, { min = -(PA.ScreenHeight / 2), max = (PA.ScreenHeight / 2), step = 1 })
	AuraReminder.args.filterGroup.args.size = ACH:Range(ACL['Size'], nil, 5, { min = 8, max = 128, step = 1 })
	AuraReminder.args.filterGroup.args.conditions = ACH:MultiSelect(ACL['Conditions'], nil, 10, { instance = ACL['Inside Raid/Party'], pvp = ACL['Inside BG/Arena'], combat = ACL['Combat'] }, nil, nil, function(_, key) return AR.db.Filters[selectedGroup][selectedFilter][key] end, function(_, key, value) AR.db.Filters[selectedGroup][selectedFilter][key] = value end)

	AuraReminder.args.filterGroup.args.filterConditions = ACH:Group(ACL['Filter Conditions'], nil, 11)
	AuraReminder.args.filterGroup.args.filterConditions.inline = true
	AuraReminder.args.filterGroup.args.filterConditions.args.level = ACH:Range(ACL['Level Requirement'], ACL['Level requirement for the icon to be able to display. 0 for disabled.'], 4, { min = 0, max = MAX_PLAYER_LEVEL, step = 1 })
	AuraReminder.args.filterGroup.args.filterConditions.args.personal = ACH:Toggle(ACL['Personal Buffs'], ACL['Only check if the buff is coming from you.'], 5, nil, nil, nil, nil, nil, nil, function() return AR.db.Filters[selectedGroup][selectedFilter].filterType ~= 'SPELL' end)
	AuraReminder.args.filterGroup.args.filterConditions.args.reverseCheck = ACH:Toggle(ACL['Reverse Check'], ACL['Instead of hiding the frame when you have the buff, show the frame when you have the buff.'], 6, nil, nil, nil, nil, nil, nil, function() return AR.db.Filters[selectedGroup][selectedFilter].filterType ~= 'SPELL' end)
	AuraReminder.args.filterGroup.args.filterConditions.args.strictFilter = ACH:Toggle(ACL['Strict Filter'], ACL['This ensures you can only see spells that you actually know. You may want to uncheck this option if you are trying to monitor a spell that is not directly clickable out of your spellbook.'], 7, nil, nil, nil, nil, nil, nil, function() return AR.db.Filters[selectedGroup][selectedFilter].filterType == 'COOLDOWN' end)
	AuraReminder.args.filterGroup.args.filterConditions.args.disableSound = ACH:Toggle(ACL['Disable Sound'], nil, 8, nil, nil, nil, nil, nil, nil, function() return AR.db.Filters[selectedGroup][selectedFilter].filterType == 'COOLDOWN' end)

	AuraReminder.args.filterGroup.args.cooldownConditions = ACH:Group(ACL['Cooldown Conditions'], nil, 12, nil, nil, nil, nil, function() return AR.db.Filters[selectedGroup][selectedFilter].filterType ~= 'COOLDOWN' or selectedGroup == 'Global' end)
	AuraReminder.args.filterGroup.args.cooldownConditions.inline = true
	AuraReminder.args.filterGroup.args.cooldownConditions.args.description = ACH:Description(function() local spellID = AR.db.Filters[selectedGroup][selectedFilter].cooldownSpellID if not spellID or spellID == '' then return end return format('%s (%s)', GetSpellInfo(spellID), spellID) end, 0, 'medium', nil, nil, nil, nil, nil, function() return AR.db.Filters[selectedGroup][selectedFilter].cooldownSpellID == '' end)
	AuraReminder.args.filterGroup.args.cooldownConditions.args.cooldownSpellID = ACH:Input(ACL['Spell ID'], nil, 1, nil, nil, function(info) return tostring(AR.db.Filters[selectedGroup][selectedFilter][info[#info]] or '') end, function(info, value) value = tonumber(value) if not value then return end AR.db.Filters[selectedGroup][selectedFilter][info[#info]] = value end)
	AuraReminder.args.filterGroup.args.cooldownConditions.args.onCooldown = ACH:Toggle(ACL['Show On Cooldown'], nil, 2)
	AuraReminder.args.filterGroup.args.cooldownConditions.args.cooldownAlpha = ACH:Range(ACL['Cooldown Alpha'], nil, 3, { min = 0, max = 1, step = .1 }, nil, nil, nil, nil, function() return not AR.db.Filters[selectedGroup][selectedFilter].onCooldown end)

	local function AddSpellSet(info, value) value = tonumber(value) if not value then return end AR.db.Filters[selectedGroup][selectedFilter][info[#info-1]] = AR.db.Filters[selectedGroup][selectedFilter][info[#info-1]] or {} AR.db.Filters[selectedGroup][selectedFilter][info[#info-1]][value] = true AR:UpdateFilterGroup(info[#info-1]) end
	local function RemoveFilterSet(info, value) AR.db.Filters[selectedGroup][selectedFilter][info[#info-1]][value] = nil AR:UpdateFilterGroup(info[#info-1]) end
	local function RemoveFilterValues(info) wipe(spellList) if AR.db.Filters[selectedGroup][selectedFilter][info[#info-1]] then for spellID in next, AR.db.Filters[selectedGroup][selectedFilter][info[#info-1]] do local name = GetSpellInfo(spellID) spellList[spellID] = name and format('%s (%s)', name, spellID) or spellID end end return spellList end

	AuraReminder.args.filterGroup.args.spellGroup = ACH:Group(ACL['Spells'], nil, 13, nil, function() AR:UpdateFilterGroup('spellGroup') return '' end, nil, nil, function() return AR.db.Filters[selectedGroup][selectedFilter].filterType ~= 'SPELL' end)
	AuraReminder.args.filterGroup.args.spellGroup.inline = true
	AuraReminder.args.filterGroup.args.spellGroup.args.AddSpell = ACH:Input(ACL['New ID'], nil, 0, nil, nil, nil, AddSpellSet)
	AuraReminder.args.filterGroup.args.spellGroup.args.RemoveSpell = ACH:Select(ACL['Remove ID'], nil, 1, RemoveFilterValues, nil, nil, function() return '' end, RemoveFilterSet)
	AuraReminder.args.filterGroup.args.spellGroup.args.spacer = ACH:Spacer(2)

	AuraReminder.args.filterGroup.args.negateGroup = ACH:Group(ACL['Negate Spells'], nil, 14, nil, function() AR:UpdateFilterGroup('negateGroup') return '' end, nil, nil, function() return AR.db.Filters[selectedGroup][selectedFilter].filterType ~= 'SPELL' end)
	AuraReminder.args.filterGroup.args.negateGroup.inline = true
	AuraReminder.args.filterGroup.args.negateGroup.args.AddSpell = ACH:Input(ACL['New ID'], nil, 0, nil, nil, nil, AddSpellSet)
	AuraReminder.args.filterGroup.args.negateGroup.args.RemoveSpell = ACH:Select(ACL['Remove ID'], nil, 1, RemoveFilterValues, nil, nil, function() return '' end, RemoveFilterSet)
	AuraReminder.args.filterGroup.args.negateGroup.args.spacer = ACH:Spacer(2)

	PA.Options.args.AuraReminder.args.AuthorHeader = ACH:Header(ACL['Authors:'], -2)
	PA.Options.args.AuraReminder.args.Authors = ACH:Description(AR.Authors, -1, 'large')

	if PA.Retail then
		local optionGroup = PA.Options.args.AuraReminder.args.filterGroup.args.filterConditions.args
		local Specializations, _ = { ['ANY'] = ACL['Any'] }
		for i = 1, 4 do _, Specializations[tostring(i)] = GetSpecializationInfo(i) end

		optionGroup.role = ACH:Select(ACL['Role'], ACL['You must be a certain role for the icon to appear.'], 1, { TANK = ACL['Tank'], DAMAGER = ACL['Damage'], HEALER = ACL['Healer'], ANY = ACL['Any'] }, nil, nil, function(info) return AR.db.Filters[selectedGroup][selectedFilter][info[#info]] or 'ANY' end, nil, nil, function() return selectedGroup == 'Global' end)
		optionGroup.tree = ACH:Select(ACL['Talent Tree'], ACL['You must be using a certain talent tree for the icon to show.'], 2, Specializations, nil, nil, function() return tostring(AR.db.Filters[PA.MyClass][selectedFilter].tree or 'ANY') end, function(_, value) if value == 'ANY' then AR.db.Filters[PA.MyClass][selectedFilter].tree = 'ANY' else AR.db.Filters[PA.MyClass][selectedFilter].tree = tonumber(value) end end, nil, function() return selectedGroup == 'Global' or AR.db.Filters[PA.MyClass][selectedFilter].reverseCheck end)
		optionGroup.talentTreeException = ACH:Select(ACL['Tree Exception'], ACL['Set a talent tree to not follow the reverse check.'], 2, CopyTable(Specializations), nil, nil, function() return tostring(AR.db.Filters[PA.MyClass][selectedFilter]['talentTreeException'] or 'NONE') end, function(_, value) if value == 'NONE' then AR.db.Filters[PA.MyClass][selectedFilter].talentTreeException = nil else AR.db.Filters[PA.MyClass][selectedFilter]['talentTreeException'] = tonumber(value) end end, nil, function() return selectedGroup == 'Global' or not AR.db.Filters[PA.MyClass][selectedFilter].reverseCheck end)
		optionGroup.talentTreeException.values.NONE = ACL['None']
	end
end

function AR:BuildProfile()
	PA.Defaults.profile.AuraReminder = {
		Enable = true,
		Sound = 'Warning',
		Filters = { Global = {} },
	}

	for k in next, LOCALIZED_CLASS_NAMES_MALE do PA.Defaults.profile.AuraReminder.Filters[k] = {} end

	DefaultFilters = CopyTable(PA.Defaults.profile.AuraReminder.Filters)
end

function AR:UpdateSettings()
	AR.db = PA.db.AuraReminder
end

function AR:Initialize()
	if AR.db.Enable ~= true then
		return
	end

	AR.isEnabled = true

	AR:ScheduleRepeatingTimer('Reminder_Update', .5)

	AR:CleanDB()
	AR:RegisterEvent("PLAYER_LOGOUT", 'CleanDB')
end
