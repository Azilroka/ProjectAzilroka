local PA = _G.ProjectAzilroka
local TB = PA:NewModule('TorghastBuffs', 'AceEvent-3.0')
local LSM = PA.LSM
PA.TB = TB

TB.Title = '|cFF16C3F2Torghast|r|cFFFFFFFFBuffs|r'
TB.Description = 'Torghast Buffs'
TB.Authors = 'Azilroka'
TB.isEnabled = false

_G.TorghastBuffs = TB

local _G = _G
local format = format
local select, unpack = select, unpack
local strfind = strfind
local strmatch = strmatch
local tinsert = tinsert
local RegisterStateDriver = RegisterStateDriver
local UnregisterStateDriver = UnregisterStateDriver
local GetItemQualityColor = GetItemQualityColor

local CreateFrame = CreateFrame
local UIParent = UIParent
local UnitAura = UnitAura
local CopyTable = CopyTable

local DIRECTION_TO_POINT = { DOWN_RIGHT = 'TOPLEFT', DOWN_LEFT = 'TOPRIGHT', UP_RIGHT = 'BOTTOMLEFT', UP_LEFT = 'BOTTOMRIGHT', RIGHT_DOWN = 'TOPLEFT', RIGHT_UP = 'BOTTOMLEFT', LEFT_DOWN = 'TOPRIGHT', LEFT_UP = 'BOTTOMRIGHT' }
local DIRECTION_TO_HORIZONTAL_SPACING_MULTIPLIER = { DOWN_RIGHT = 1, DOWN_LEFT = -1, UP_RIGHT = 1, UP_LEFT = -1, RIGHT_DOWN = 1, RIGHT_UP = 1, LEFT_DOWN = -1, LEFT_UP = -1 }
local DIRECTION_TO_VERTICAL_SPACING_MULTIPLIER = { DOWN_RIGHT = -1, DOWN_LEFT = -1, UP_RIGHT = 1, UP_LEFT = 1, RIGHT_DOWN = -1, RIGHT_UP = 1, LEFT_DOWN = -1, LEFT_UP = 1 }
local IS_HORIZONTAL_GROWTH = { RIGHT_DOWN = true, RIGHT_UP = true, LEFT_DOWN = true, LEFT_UP = true }
local MasqueButtonData = { Icon = nil, Highlight = nil, FloatingBG = nil, Cooldown = nil, Flash = nil, Pushed = nil, Normal = nil, Disabled = nil, Checked = nil, Border = nil, AutoCastable = nil, HotKey = nil, Count = false, Name = nil, Duration = false, AutoCast = nil }

TB.Holder = CreateFrame('Frame', 'TorghastBuffsHolder', PA.PetBattleFrameHider)
TB.Holder:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 360)

TB.Headers = {}

function TB:MasqueData(texture, highlight)
	local btnData = CopyTable(MasqueButtonData)
	btnData.Icon = texture
	btnData.Highlight = highlight
	return btnData
end

function TB:CreateIcon(button)
	button.texture = button:CreateTexture(nil, 'ARTWORK')
	PA:SetInside(button.texture)
	button.texture:SetTexCoord(unpack(PA.TexCoords))

	button.count = button:CreateFontString(nil, 'OVERLAY')

	button.highlight = button:CreateTexture(nil, 'HIGHLIGHT')
	button.highlight:SetColorTexture(1, 1, 1, .45)
	PA:SetInside(button.highlight)

	button.unit = button:GetParent().unit

	TB:UpdateIcon(button)
	button:SetScript('OnAttributeChanged', TB.OnAttributeChanged)

	if TB.MasqueGroup and TB.db.Masque then
		TB.MasqueGroup:AddButton(button, TB:MasqueData(button.texture, button.highlight))
		if button.__MSQ_BaseFrame then button.__MSQ_BaseFrame:SetFrameLevel(2) end --Lower the framelevel to fix issue with buttons created during combat
		TB.MasqueGroup:ReSkin()
	else
		PA:SetTemplate(button)
	end
end

function TB:UpdateIcon(button)
	button.count:ClearAllPoints()
	button.count:Point('BOTTOMRIGHT', TB.db.countXOffset, TB.db.countYOffset)
	button.count:FontTemplate(LSM:Fetch('font', TB.db.countFont), TB.db.countFontSize, TB.db.countFontOutline)
end

function TB:UpdateAura(button, index)
	local name, texture, count, _, _, _, _, _, _, spellID = UnitAura(button.unit, index, 'MAW')

	local atlas = _G.C_Spell.GetMawPowerBorderAtlasBySpellID(spellID)
	local colorIndex = atlas and (strfind(atlas, 'purple') and 4 or strfind(atlas, 'blue') and 3 or strfind(atlas, 'green') and 2)

	if colorIndex then
		button:SetBackdropBorderColor(GetItemQualityColor(colorIndex))
	else
		PA:SetTemplate(button)
	end

	button.count:SetText(count > 1 and count)
	button.texture:SetTexture(texture)
end


function TB:OnAttributeChanged(attribute, value)
	if attribute == 'index' then
		TB:UpdateAura(self, value)
	end
end

function TB:UpdateHeader(header)
	header:SetAttribute('consolidateDuration', -1)
	header:SetAttribute('consolidateTo', 0)
	header:SetAttribute('template', format('TorghastBuffsTemplate%d', TB.db.size))
	header:SetAttribute('sortMethod', TB.db.sortMethod)
	header:SetAttribute('sortDirection', TB.db.sortDir)
	header:SetAttribute('maxWraps', TB.db.maxWraps)
	header:SetAttribute('wrapAfter', TB.db.wrapAfter)
	header:SetAttribute('point', DIRECTION_TO_POINT[TB.db.growthDirection])

	if IS_HORIZONTAL_GROWTH[TB.db.growthDirection] then
		header:SetAttribute('minWidth', ((TB.db.wrapAfter == 1 and 0 or TB.db.horizontalSpacing) + TB.db.size) * TB.db.wrapAfter)
		header:SetAttribute('minHeight', (TB.db.verticalSpacing + TB.db.size) * TB.db.maxWraps)
		header:SetAttribute('xOffset', DIRECTION_TO_HORIZONTAL_SPACING_MULTIPLIER[TB.db.growthDirection] * (TB.db.horizontalSpacing + TB.db.size))
		header:SetAttribute('yOffset', 0)
		header:SetAttribute('wrapXOffset', 0)
		header:SetAttribute('wrapYOffset', DIRECTION_TO_VERTICAL_SPACING_MULTIPLIER[TB.db.growthDirection] * (TB.db.verticalSpacing + TB.db.size))
	else
		header:SetAttribute('minWidth', (TB.db.horizontalSpacing + TB.db.size) * TB.db.maxWraps)
		header:SetAttribute('minHeight', ((TB.db.wrapAfter == 1 and 0 or TB.db.verticalSpacing) + TB.db.size) * TB.db.wrapAfter)
		header:SetAttribute('xOffset', 0)
		header:SetAttribute('yOffset', DIRECTION_TO_VERTICAL_SPACING_MULTIPLIER[TB.db.growthDirection] * (TB.db.verticalSpacing + TB.db.size))
		header:SetAttribute('wrapXOffset', DIRECTION_TO_HORIZONTAL_SPACING_MULTIPLIER[TB.db.growthDirection] * (TB.db.horizontalSpacing + TB.db.size))
		header:SetAttribute('wrapYOffset', 0)
	end

	local index = 1
	local child = select(index, header:GetChildren())
	while child do
		child:Size(TB.db.size, TB.db.size)

		TB:UpdateIcon(child)

		-- Blizzard bug fix, icons arent being hidden when you reduce the amount of maximum buttons
		if index > (TB.db.maxWraps * TB.db.wrapAfter) and child:IsShown() then
			child:Hide()
		end

		index = index + 1
		child = select(index, header:GetChildren())
	end

	if TB.MasqueGroup and TB.db.Masque then
		TB.MasqueBuffs:ReSkin()
	end

	TB.Holder:SetSize(header:GetAttribute("minWidth") + 10, header:GetAttribute("minHeight") * 5)
end

function TB:CreateAuraHeader(unit, unitName)
	local header = CreateFrame('Frame', 'TorghastBuffs_'..unitName, TB.Holder, 'SecureAuraHeaderTemplate')
	header:SetClampedToScreen(true)
	header:SetAttribute('unit', unit)
	header:SetAttribute('filter', 'MAW')
	header.unit = unit

	header.unitName = header:CreateFontString()
	header.unitName:SetPoint('BOTTOM', header, 'TOP')

	TB:UpdateHeader(header)

	tinsert(TB.Headers, header)

	return header
end

function TB:UpdateAllHeaders()
	for _, header in pairs(TB.Headers) do
		TB:UpdateHeader(header)
	end
end

function TB:HandleVisibility()
	for _, header in pairs(TB.Headers) do
		if IsInJailersTower() then
			if header.unit == 'player' then
				RegisterStateDriver(header, 'visibility', '[petbattle] hide; show')
			else
				RegisterStateDriver(header, 'visibility', format('[@%s, exists][group] show; hide', header.unit))
			end

			header.unitName:SetFont(PA.LSM:Fetch('font', PA.LSM:GetDefault('font')), 12, 'THICKOUTLINE')

			if UnitExists(header.unit) then
				header.unitName:SetText(UnitName(header.unit))
				local color = RAID_CLASS_COLORS[select(2, UnitClass(header.unit))]
				header.unitName:SetTextColor(color.r, color.g, color.b)
			end
		else
			UnregisterStateDriver(header, 'visibility')
			header:Hide()
		end
	end
end

function TB:GetOptions()
	TB:UpdateSettings()

	local TorghastBuffs = PA.ACH:Group(TB.Title, TB.Description, nil, nil, function(info) return TB.db[info[#info]] end, function(info, value) TB.db[info[#info]] = value TB:UpdateAllHeaders() end)
	PA.Options.args.TorghastBuffs = TorghastBuffs

	TorghastBuffs.args.Description = PA.ACH:Description(TB.Description, 0)
	TorghastBuffs.args.Enable = PA.ACH:Toggle(PA.ACL['Enable'], nil, 1, nil, nil, nil, nil, function(info, value) TB.db[info[#info]] = value if (not TB.isEnabled) then TB:Initialize() else _G.StaticPopup_Show('PROJECTAZILROKA_RL') end end)

	TorghastBuffs.args.General = PA.ACH:Group(PA.ACL['General'], nil, 2)
	TorghastBuffs.args.General.inline = true

	TorghastBuffs.args.General.args.Masque = PA.ACH:Toggle(PA.ACL['Masque Support'], nil, 1)
	TorghastBuffs.args.General.args.size = PA.ACH:Range(PA.ACL["Size"], PA.ACL["Set the size of the individual auras."], 2, { min = 16, max = 60, step = 2 })
	TorghastBuffs.args.General.args.growthDirection = PA.ACH:Select(PA.ACL["Growth Direction"], PA.ACL["The direction the auras will grow and then the direction they will grow after they reach the wrap after limit."], 4, PA.GrowthDirection)
	TorghastBuffs.args.General.args.wrapAfter = PA.ACH:Range(PA.ACL["Wrap After"], PA.ACL["Begin a new row or column after this many auras."], 5, { min = 1, max = 32, step = 1 })
	TorghastBuffs.args.General.args.maxWraps = PA.ACH:Range(PA.ACL["Max Wraps"], PA.ACL["Limit the number of rows or columns."], 6, { min = 1, max = 32, step = 1 })
	TorghastBuffs.args.General.args.horizontalSpacing = PA.ACH:Range(PA.ACL["Horizontal Spacing"], nil, 7, { min = 0, max = 50, step = 1 })
	TorghastBuffs.args.General.args.verticalSpacing = PA.ACH:Range(PA.ACL["Vertical Spacing"], nil, 8, { min = 0, max = 50, step = 1 })
	TorghastBuffs.args.General.args.sortMethod = PA.ACH:Select(PA.ACL["Sort Method"], PA.ACL["Defines how the group is sorted."], 9, { INDEX = PA.ACL["Index"], NAME = PA.ACL["Name"] })
	TorghastBuffs.args.General.args.sortDir = PA.ACH:Select(PA.ACL["Sort Direction"], PA.ACL["Defines the sort order of the selected sort method."], 10, { ['+'] = PA.ACL["Ascending"], ['-'] = PA.ACL["Descending"] })

	TorghastBuffs.args.AuthorHeader = PA.ACH:Header(PA.ACL['Authors:'], -2)
	TorghastBuffs.args.Authors = PA.ACH:Description(TB.Authors, -1, 'large')
end

function TB:BuildProfile()
	PA.Defaults.profile.TorghastBuffs = {
		Enable = true,
		Masque = false,
		countFont = 'Homespun',
		countFontOutline = 'MONOCHROMEOUTLINE',
		countFontSize = 10,
		countXOffset = 0,
		countYOffset = 0,
		growthDirection = 'LEFT_DOWN',
		horizontalSpacing = 2,
		maxWraps = 5,
		size = 24,
		sortDir = '-',
		sortMethod = 'INDEX',
		verticalSpacing = 2,
		wrapAfter = 10,
	}
end

function TB:UpdateSettings()
	TB.db = PA.db.TorghastBuffs
end

function TB:Initialize()
	TB:UpdateSettings()

	if TB.db.Enable ~= true then
		return
	end

	TB.isEnabled = true

	if PA.Masque and TB.db.Masque then
		PA.Masque:Register('TorghastBuffs', function() end)
		TB.MasqueGroup = PA.Masque:Group('TorghastBuffs')
	end

	TB.Holder.PlayerBuffFrame = TB:CreateAuraHeader('player', 'Player')
	TB.Holder.PlayerBuffFrame:ClearAllPoints()
	TB.Holder.PlayerBuffFrame:SetPoint('TOPLEFT', TB.Holder, 'TOPLEFT', 0, 0)
	TB.Holder.PlayerBuffFrame:UnregisterAllEvents()
	TB.Holder.PlayerBuffFrame:RegisterUnitEvent('UNIT_AURA', 'player')

	for i = 1, 4 do
		local name = format('Party%dBuffFrame', i)
		TB.Holder[name] = TB:CreateAuraHeader('party'..i, 'Party'..i)
		TB.Holder[name]:ClearAllPoints()
		TB.Holder[name]:SetPoint('TOPLEFT', i == 1 and TB.Holder.PlayerBuffFrame or TB.Holder[format('Party%dBuffFrame', i - 1)], 'BOTTOMLEFT', 0, -25)
		TB.Holder[name]:UnregisterAllEvents()
		TB.Holder[name]:RegisterUnitEvent('UNIT_AURA', 'party'..i)
	end

	if PA.ElvUI then
		_G.ElvUI[1]:CreateMover(TB.Holder, 'TorghastBuffsMover', "Torghast Buffs", nil, nil, nil, 'ALL,GENERAL', nil, 'ProjectAzilroka,TorghastBuffs')
	end

	TB:RegisterEvent('PLAYER_ENTERING_WORLD', 'HandleVisibility')
end
