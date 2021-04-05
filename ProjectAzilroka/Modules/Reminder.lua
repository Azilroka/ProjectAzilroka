local PA = _G.ProjectAzilroka
local AR = PA:NewModule('AuraReminder', 'AceEvent-3.0', 'AceTimer-3.0')

PA.AR = AR

AR.Title = '|cFF16C3F2Aura|r |cFFFFFFFFReminder|r'
AR.Description = 'Reminder for Buffs / Debuffs'
AR.Authors = 'Azilroka    Nihilistzsche'
AR.isEnabled = false

local _G = _G
local pairs = pairs
local ipairs = ipairs
local tonumber = tonumber
local tostring = tostring
local select = select
local format = format
local strmatch = strmatch
local unpack = unpack
local tinsert = tinsert
local wipe = wipe

local GetSpellCooldown = GetSpellCooldown
local GetSpellInfo = GetSpellInfo
local IsUsableSpell = IsUsableSpell
local IsInInstance = IsInInstance
local UnitAffectingCombat = UnitAffectingCombat
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitLevel = UnitLevel
local GetInventoryItemID = GetInventoryItemID
local GetWeaponEnchantInfo = GetWeaponEnchantInfo
local GetInventoryItemTexture = GetInventoryItemTexture
local PlaySoundFile = PlaySoundFile
local GetSpecialization = GetSpecialization
local GetSpecializationRole = GetSpecializationRole
local GetSpecializationInfo = GetSpecializationInfo
local GetItemInfoInstant = GetItemInfoInstant

local MAX_PLAYER_LEVEL = MAX_PLAYER_LEVEL

local CreateFrame = CreateFrame
local UIParent = UIParent

_G.AuraReminder = AR

AR.CreatedReminders = {}

local selectedFilter, selectedGroup, filters, spellList, filterTypeList, DefaultFilters = nil, PA.MyClass, {}, {}, {}

do
	local function SpellIDPredicate(spellIDToFind, casterToFind, _, _, _, _, _, _, _, caster, _, _, spellID)
		return (casterToFind and caster == casterToFind and spellIDToFind == spellID) or (spellIDToFind == spellID)
	end

	function AR:FindAuraBySpellID(spellID, unit, filter, caster)
		return _G.AuraUtil.FindAura(SpellIDPredicate, unit, filter, spellID, caster);
	end
end

function AR:FindPlayerAura(db, checkPersonal, filter)
	if db then
		for spellID, value in pairs(db) do
			if value == true then
				return AR:FindAuraBySpellID(spellID, 'player', filter, checkPersonal and 'player')
			end
		end
	end
end

function AR:IsSpellOnCooldown(id)
	local start, duration = GetSpellCooldown(id)
	if start > 0 and duration > 1.5 then
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
	if UnitIsDeadOrGhost('player') then return end

	for _, button in ipairs(AR.CreatedReminders) do
		button:Hide()
		button:SetAlpha(1)
	end

	local Position = 1
	for _, filter in pairs({PA.MyClass, 'Global'}) do
		if AR.db.Filters then
			for _, db in pairs(AR.db.Filters[filter]) do
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
					elseif (db.filterType == 'WEAPON' or (db.filterType == 'SPELL' and db.spellGroup and PA:CountTable(db.spellGroup) > 0)) and filterCheck then
						if db.filterType == 'SPELL' then
							local hasBuff, hasDebuff = AR:FindPlayerAura(db.spellGroup, db.personal), AR:FindPlayerAura(db.spellGroup, nil, 'HARMFUL')
							local negate = AR:FindPlayerAura(db.negateGroup, db.personal)

							if not (negate or hasBuff or hasDebuff) then
								for buff, value in pairs(db.spellGroup) do
									if value then
										local usable = IsUsableSpell(buff);
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

								Button:SetShown((((not hasBuff) and (not hasDebuff)) and not db.reverseCheck) or (reverseCheck and db.reverseCheck and ((hasBuff or hasDebuff) or ((not hasBuff) and (not hasDebuff)))))
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

	PlaySoundFile(PA.LSM:Fetch('sound', AR.db.Sound))

	AR:ScheduleTimer('ResetSoundPlayback', 10)
end

function AR:SetIconPosition(button, db)
	if not (button or db) then return end

	local xOffset = db.xOffset or 0
	local yOffset = db.yOffset or 200
	local size = db.size or 40

	button:ClearAllPoints()
	button:SetPoint('CENTER', UIParent, 'CENTER', xOffset, yOffset);
	button:SetSize(size, size)
end

function AR:CreateReminder(index)
	local frame = CreateFrame('Frame', 'AuraReminder'..index, UIParent)
	frame:Hide()
	frame:SetClampedToScreen(true)
	frame.icon = frame:CreateTexture(nil, 'OVERLAY')
	frame.icon:SetTexCoord(unpack(PA.TexCoords))
	frame.cooldown = CreateFrame('Cooldown', nil, frame, 'CooldownFrameTemplate')
	frame.cooldown:SetAllPoints(frame.icon)

	PA:SetTemplate(frame)
	PA:SetInside(frame.icon)

	tinsert(AR.CreatedReminders, frame)
	return frame
end

function AR:UpdateFilterGroup(group)
	for option, optionTable in pairs(PA.Options.args.AuraReminder.args.filterGroup.args[group].args) do
		if strmatch(option, "^AR") then
			optionTable.hidden = true
		end
	end

	if AR.db.Filters[selectedGroup][selectedFilter] and AR.db.Filters[selectedGroup][selectedFilter][group] then
		local i = 1
		for spell in pairs(AR.db.Filters[selectedGroup][selectedFilter][group]) do
			if spell and GetSpellInfo(spell) then
				local name = format('AR%s', i + 2)
				local optionName = PA.Options.args.AuraReminder.args.filterGroup.args[group].args[name]
				if not optionName then
					PA.Options.args.AuraReminder.args.filterGroup.args[group].args[name] = { type = 'toggle', width = 'double' }
					optionName = PA.Options.args.AuraReminder.args.filterGroup.args[group].args[name]
				end

				optionName.name = function() return format('%s (%s)', GetSpellInfo(spell), spell) end
				optionName.get = function(info) return spell and AR.db.Filters[selectedGroup][selectedFilter][group][spell] end
				optionName.set = function(info, value) AR.db.Filters[selectedGroup][selectedFilter][group][spell] = value end
				optionName.hidden = false

				i = i + 1
			end
		end
	end
end

function AR:CleanDB()
	-- Cleanup DB
	for _, filter in pairs({PA.MyClass, 'Global'}) do
		if AR.db.Filters and AR.db.Filters[filter] then
			for _, db in pairs(AR.db.Filters[filter]) do
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
	local AuraReminder = PA.ACH:Group(AR.Title, nil, nil, 'tree', function(info) return AR.db[info[#info]] end, function(info, value) AR.db[info[#info]] = value end)
	PA.Options.args.AuraReminder = AuraReminder

	AuraReminder.args = {
			Description = {
				order = 0,
				type = 'description',
				name = AR.Description,
			},
			Enable = {
				order = 1,
				type = 'toggle',
				name = PA.ACL['Enable'],
				set = function(info, value)
					AR.db[info[#info]] = value
					if (not AR.isEnabled) then
						AR:Initialize()
					else
						_G.StaticPopup_Show('PROJECTAZILROKA_RL')
					end
				end,
			},
			Sound = {
				order = 2,
				type = 'select', dialogControl = 'LSM30_Sound',
				name = PA.ACL['Sound'],
				desc = PA.ACL['Sound that will play when you have a warning icon displayed.'],
				values = PA.LSM:HashTable('sound'),
			},
			selectGroup = {
				order = 3,
				type = 'select',
				name = PA.ACL['Select Group'],
				get = function(info)
					if selectedGroup == 'Global' then
						return selectedGroup
					else
						return 'Class'
					end
				end,
				set = function(info, value)
					selectedFilter = nil
					if value == 'Class' then
						selectedGroup = PA.MyClass
					else
						selectedGroup = value
					end
				end,
				values = { Class = 'Class', Global = 'Global'},
			},
			selectFilter = {
				order = 4,
				type = 'select',
				name = PA.ACL['Select Filter'],
				get = function(info) return selectedFilter ~= '' and selectedFilter or '' end,
				set = function(info, value)
					selectedFilter = value ~= '' and value or nil
					AR:UpdateFilterGroup('spellGroup')
					AR:UpdateFilterGroup('negateGroup')
				end,
				values = function()
					wipe(filters)
					for filter in pairs(AR.db.Filters[selectedGroup]) do
						filters[filter] = filter
					end
					if not next(filters) then
						filters[''] = PA.ACL['None']
					end
					return filters
				end,
			},
			filterControl = {
				order = 5,
				type = 'group',
				name = PA.ACL['Filter Control'],
				inline = true,
				args = {
					addFilter = {
						order = 1,
						type = 'input',
						name = PA.ACL['New Filter Name'],
						get = function(info) return addGroupTemplate.name end,
						set = function(info, value)
							if AR.db.Filters[selectedGroup][value] then
								return
							end
							addGroupTemplate.name = value
						end,
					},
					addFilterTemplate = {
						order = 2,
						type = 'select',
						name = PA.ACL['New Filter Type'],
						get = function(info) return addGroupTemplate.template end,
						set = function(info, value)
							if AR.db.Filters[selectedGroup][value] then
								return
							end
							addGroupTemplate.template = value
						end,
						values = function()
							wipe(filterTypeList)
							filterTypeList.SPELL = PA.ACL['Spell']
							if selectedGroup ~= 'Global' then
								filterTypeList.WEAPON = PA.ACL['Weapon']
								filterTypeList.COOLDOWN = PA.ACL['Cooldown']
							end
							return filterTypeList
						end,
					},
					addFilterButton = {
						type = 'execute',
						order = 3,
						name = PA.ACL['Add Filter'],
						hidden = function(info)
							return addGroupTemplate.name == '' or addGroupTemplate.template == ''
						end,
						func = function(info)
							AR.db.Filters[selectedGroup][addGroupTemplate.name] = { enable = true, size = 50, filterType = addGroupTemplate.template }
							if addGroupTemplate.template == 'COOLDOWN' then
								AR.db.Filters[selectedGroup][addGroupTemplate.name].cooldownAlpha = .5
							elseif addGroupTemplate.template == 'WEAPON' then
							else
								AR.db.Filters[selectedGroup][addGroupTemplate.name].spellGroup = {}
								AR.db.Filters[selectedGroup][addGroupTemplate.name].negateGroup = {}
							end

							selectedFilter = addGroupTemplate.name

							addGroupTemplate.name = ''
							addGroupTemplate.template = ''
						end,
					},
					deleteGroup = {
						order = 5,
						type = 'select',
						name = PA.ACL['Remove Filter'],
						get = function(info) return '' end,
						confirm = function(info, value) return PA.ACL['Remove Filter']..' - '..value end,
						set = function(info, value)
							selectedFilter = nil
							if DefaultFilters[selectedGroup][value] then
								AR.db.Filters[selectedGroup][value].enable = false;
							else
								AR.db.Filters[selectedGroup][value] = nil;
							end
						end,
						values = function()
							wipe(filters)
							for filter in pairs(AR.db.Filters[selectedGroup]) do
								filters[filter] = filter
							end
							if not next(filters) then
								filters[''] = PA.ACL['None']
							end
							return filters
						end,
					},
				},
			},
			filterGroup = {
				order = 8,
				type = 'group',
				name = function() return selectedFilter end,
				inline = true,
				get = function(info) return AR.db.Filters[selectedGroup][selectedFilter][info[#info]] end,
				set = function(info, value) AR.db.Filters[selectedGroup][selectedFilter][info[#info]] = value end,
				hidden = function() return not selectedFilter end,
				args = {
					enable = {
						order = 1,
						type = 'toggle',
						name = PA.ACL['Enable'],
					},
					filterType = {
						order = 2,
						type = 'select',
						name = PA.ACL['Filter Type'],
						desc = PA.ACL['Change this if you want the Reminder module to check for weapon enchants, setting this will cause it to ignore any spells listed.'],
						values = function()
							wipe(filterTypeList)
							filterTypeList.SPELL = PA.ACL['Spell']
							if selectedGroup ~= 'Global' then
								filterTypeList.WEAPON = PA.ACL['Weapon']
								filterTypeList.COOLDOWN = PA.ACL['Cooldown']
							end
							return filterTypeList
						end,
					},
					xOffset = {
						order = 3,
						type = 'range',
						name = PA.ACL['X Offset'],
						min = -(PA.ScreenWidth / 2), max = (PA.ScreenWidth / 2), step = 1,
					},
					yOffset = {
						order = 4,
						type = 'range',
						name = PA.ACL['Y Offset'],
						min = -(PA.ScreenHeight / 2), max = (PA.ScreenHeight / 2), step = 1,
					},
					size = {
						order = 5,
						type = 'range',
						name = PA.ACL['Size'],
						min = 0, max = 128, step = 1,
					},
					conditions = {
						order = 10,
						type = 'multiselect',
						name = PA.ACL['Conditions'],
						get = function(_, key) return AR.db.Filters[selectedGroup][selectedFilter][key] end,
						set = function(_, key, value) AR.db.Filters[selectedGroup][selectedFilter][key] = value end,
						values = {
							instance = PA.ACL['Inside Raid/Party'],
							pvp = PA.ACL['Inside BG/Arena'],
							combat = PA.ACL['Combat'],
						},
					},
					filterConditions = {
						order = 11,
						type = 'group',
						name = PA.ACL['Filter Conditions'],
						inline = true,
						args = {
							level = {
								order = 4,
								type = 'range',
								name = PA.ACL['Level Requirement'],
								desc = PA.ACL['Level requirement for the icon to be able to display. 0 for disabled.'],
								min = 0, max = MAX_PLAYER_LEVEL, step = 1,
							},
							personal = {
								order = 5,
								type = 'toggle',
								name = PA.ACL['Personal Buffs'],
								desc = PA.ACL['Only check if the buff is coming from you.'],
								hidden = function() return AR.db.Filters[selectedGroup][selectedFilter].filterType ~= 'SPELL' end,
							},
							reverseCheck = {
								order = 6,
								type = 'toggle',
								name = PA.ACL['Reverse Check'],
								desc = PA.ACL['Instead of hiding the frame when you have the buff, show the frame when you have the buff.'],
								hidden = function() return AR.db.Filters[selectedGroup][selectedFilter].filterType ~= 'SPELL' end,
							},
							strictFilter = {
								order = 7,
								type = 'toggle',
								name = PA.ACL['Strict Filter'],
								desc = PA.ACL['This ensures you can only see spells that you actually know. You may want to uncheck this option if you are trying to monitor a spell that is not directly clickable out of your spellbook.'],
								hidden = function() return AR.db.Filters[selectedGroup][selectedFilter].filterType == 'COOLDOWN' end,
							},
							disableSound = {
								order = 8,
								type = 'toggle',
								name = PA.ACL['Disable Sound'],
								hidden = function() return AR.db.Filters[selectedGroup][selectedFilter].filterType == 'COOLDOWN' end,
							},
						},
					},
					cooldownConditions = {
						order = 12,
						type = 'group',
						name = PA.ACL['Cooldown Conditions'],
						inline = true,
						hidden = function() return AR.db.Filters[selectedGroup][selectedFilter].filterType ~= 'COOLDOWN' or selectedGroup == 'Global' end,
						args = {
							dscription = {
								order = 0,
								type = 'description',
								fontSize = 'medium',
								name = function()
									local spellID = AR.db.Filters[selectedGroup][selectedFilter].cooldownSpellID
									if not spellID or spellID == '' then return end
									return format('%s (%s)', GetSpellInfo(spellID), spellID)
								end,
								hidden = function() return AR.db.Filters[selectedGroup][selectedFilter].cooldownSpellID == '' end,
							},
							cooldownSpellID = {
								order = 1,
								type = 'input',
								name = PA.ACL['Spell ID'],
								get = function(info) return tostring(AR.db.Filters[selectedGroup][selectedFilter][info[#info]] or '') end,
								set = function(info, value)
									value = tonumber(value)
									if not value then return end

									AR.db.Filters[selectedGroup][selectedFilter][info[#info]] = value
								end,
							},
							onCooldown = {
								order = 2,
								type = 'toggle',
								name = PA.ACL['Show On Cooldown'],
							},
							cooldownAlpha = {
								order = 3,
								type = 'range',
								name = PA.ACL['Cooldown Alpha'],
								min = 0, max = 1, step = 0.1,
								hidden = function() return not AR.db.Filters[selectedGroup][selectedFilter].onCooldown end,
							},
						},
					},
					spellGroup = {
						order = 13,
						type = 'group',
						name = PA.ACL['Spells'],
						inline = true,
						get = function(info)
							AR:UpdateFilterGroup('spellGroup')
							return ''
						end,
						hidden = function() return AR.db.Filters[selectedGroup][selectedFilter].filterType ~= 'SPELL' end,
						args = {
							AddSpell = {
								order = 0,
								type = 'input',
								name = PA.ACL['New ID'],
								set = function(info, value)
									value = tonumber(value)
									if not value then return end

									AR.db.Filters[selectedGroup][selectedFilter].spellGroup = AR.db.Filters[selectedGroup][selectedFilter].spellGroup or {}
									AR.db.Filters[selectedGroup][selectedFilter].spellGroup[value] = true
									AR:UpdateFilterGroup('spellGroup')
								end,
							},
							RemoveSpell = {
								order = 1,
								type = 'select',
								name = PA.ACL['Remove ID'],
								get = function() return '' end,
								set = function(info, value)
									AR.db.Filters[selectedGroup][selectedFilter].spellGroup[value] = nil;
									AR:UpdateFilterGroup('spellGroup')
								end,
								values = function()
									wipe(spellList)
									if AR.db.Filters[selectedGroup][selectedFilter].spellGroup then
										for spellID in pairs(AR.db.Filters[selectedGroup][selectedFilter].spellGroup) do
											local name = GetSpellInfo(spellID)
											spellList[spellID] = name and format('%s (%s)', name, spellID) or spellID
										end
									end
									return spellList
								end,
							},
							spacer = PA.ACH:Spacer(2)
						},
					},
					negateGroup = {
						order = 14,
						type = 'group',
						name = PA.ACL['Negate Spells'],
						inline = true,
						get = function(info)
							AR:UpdateFilterGroup('negateGroup')
							return ''
						end,
						hidden = function() return AR.db.Filters[selectedGroup][selectedFilter].filterType ~= 'SPELL' end,
						args = {
							AddSpell = {
								order = 0,
								type = 'input',
								name = PA.ACL['New ID'],
								set = function(info, value)
									value = tonumber(value)
									if not value then return end

									AR.db.Filters[selectedGroup][selectedFilter].negateGroup = AR.db.Filters[selectedGroup][selectedFilter].negateGroup or {}
									AR.db.Filters[selectedGroup][selectedFilter].negateGroup[value] = true
									AR:UpdateFilterGroup('negateGroup')
								end,
							},
							RemoveSpell = {
								order = 1,
								type = 'select',
								name = PA.ACL['Remove ID'],
								get = function() return '' end,
								set = function(info, value)
									AR.db.Filters[selectedGroup][selectedFilter].negateGroup[value] = nil;
									AR:UpdateFilterGroup('negateGroup')
								end,
								values = function()
									wipe(spellList)
									if AR.db.Filters[selectedGroup][selectedFilter].negateGroup then
										for spellID in pairs(AR.db.Filters[selectedGroup][selectedFilter].negateGroup) do
											local name = GetSpellInfo(spellID)
											spellList[spellID] = name and format('%s (%s)', name, spellID) or spellID
										end
									end
									if not next(spellList) then
										spellList[''] = PA.ACL['None']
									end
									return spellList
								end,
							},
							spacer = PA.ACH:Spacer(2)
						},
					},
				},
			},
		}

	PA.Options.args.AuraReminder.args.AuthorHeader = PA.ACH:Header(PA.ACL['Authors:'], -2)
	PA.Options.args.AuraReminder.args.Authors = PA.ACH:Description(AR.Authors, -1, 'large')

	if PA.Retail then
		local optionGroup = PA.Options.args.AuraReminder.args.filterGroup.args.filterConditions.args

		local Specializations = { ['ANY'] = PA.ACL['Any'] }

		for i = 1, 4 do
			Specializations[tostring(i)] = select(2, GetSpecializationInfo(i))
		end

		optionGroup.role = PA.ACH:Select(PA.ACL['Role'], PA.ACL['You must be a certain role for the icon to appear.'], 1, { TANK = PA.ACL['Tank'], DAMAGER = PA.ACL['Damage'], HEALER = PA.ACL['Healer'], ANY = PA.ACL['Any'] }, nil, nil, function(info) return AR.db.Filters[selectedGroup][selectedFilter][info[#info]] or 'ANY' end, nil, nil, function() return selectedGroup == 'Global' end)
		optionGroup.tree = PA.ACH:Select(PA.ACL['Talent Tree'], PA.ACL['You must be using a certain talent tree for the icon to show.'], 2, Specializations, nil, nil, function() return tostring(AR.db.Filters[PA.MyClass][selectedFilter].tree or 'ANY') end, function(_, value) if value == 'ANY' then AR.db.Filters[PA.MyClass][selectedFilter].tree = 'ANY' else AR.db.Filters[PA.MyClass][selectedFilter].tree = tonumber(value) end end, nil, function() return selectedGroup == 'Global' or AR.db.Filters[PA.MyClass][selectedFilter].reverseCheck end)
		optionGroup.talentTreeException = PA.ACH:Select(PA.ACL['Tree Exception'], PA.ACL['Set a talent tree to not follow the reverse check.'], 2, CopyTable(Specializations), nil, nil, function() return tostring(AR.db.Filters[PA.MyClass][selectedFilter]['talentTreeException'] or 'NONE') end, function(_, value) if value == 'NONE' then AR.db.Filters[PA.MyClass][selectedFilter].talentTreeException = nil else AR.db.Filters[PA.MyClass][selectedFilter]['talentTreeException'] = tonumber(value) end; end, nil, function() return selectedGroup == 'Global' or not AR.db.Filters[PA.MyClass][selectedFilter].reverseCheck end)
		optionGroup.talentTreeException.values.NONE = PA.ACL['None']
	end
end

function AR:BuildProfile()
	PA.Defaults.profile.AuraReminder = {
		Enable = true,
		Sound = 'Warning',
		Filters = { Global = {} },
	}

	for k in pairs(LOCALIZED_CLASS_NAMES_MALE) do PA.Defaults.profile.AuraReminder.Filters[k] = {} end

	DefaultFilters = CopyTable(PA.Defaults.profile.AuraReminder.Filters)
end

function AR:Initialize()
	AR.db = PA.db.AuraReminder

	if AR.db.Enable ~= true then
		return
	end

	AR.isEnabled = true

	AR:ScheduleRepeatingTimer('Reminder_Update', .5)

	AR:CleanDB()
	AR:RegisterEvent("PLAYER_LOGOUT", 'CleanDB')
end
