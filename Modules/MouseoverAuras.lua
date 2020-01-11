local PA = _G.ProjectAzilroka
local MA = PA:NewModule('MouseoverAuras', 'AceEvent-3.0', 'AceTimer-3.0')
PA.MA = MA

MA.Title = '|cFF16C3F2Mouseover|r|cFFFFFFFFAuras|r'
MA.Description = 'Auras for your mouseover target'
MA.Authors = 'Azilroka'

_G.MouseoverAuras = MA

local floor = floor
local tinsert = tinsert

local GetMouseFocus = GetMouseFocus
local GetCursorPosition = GetCursorPosition
local UnitAura = UnitAura
local CreateFrame = CreateFrame
local UnitIsUnit = UnitIsUnit
local UnitExists = UnitExists

local VISIBLE = 1
local HIDDEN = 0

function MA:CreateAuraIcon(index)
	local button = CreateFrame('Button', MA.Holder:GetDebugName()..'Button'..index, MA.Holder)
	button:EnableMouse(false)

	button.cd = CreateFrame('Cooldown', '$parentCooldown', button, 'CooldownFrameTemplate')
	button.cd:SetAllPoints()

	button.icon = button:CreateTexture(nil, 'ARTWORK')
	button.icon:SetAllPoints()
	button.icon:SetTexCoord(unpack(PA.TexCoords))

	button.countFrame = CreateFrame('Frame', nil, button)
	button.countFrame:SetAllPoints(button)
	button.countFrame:SetFrameLevel(button.cd:GetFrameLevel() + 1)

	button.count = button.countFrame:CreateFontString(nil, 'OVERLAY', 'NumberFontNormal')
	button.count:SetPoint('BOTTOMRIGHT', button.countFrame, 'BOTTOMRIGHT', -1, 0)

	PA:SetTemplate(button)
	PA:CreateShadow(button)
	PA:RegisterCooldown(button.cd)

	tinsert(MA.Holder, button)

	return button
end

function MA:CustomFilter(unit, button, name)
	if((MA.Holder.onlyShowPlayer and button.isPlayer) or (not MA.Holder.onlyShowPlayer and name)) then
		return true
	end
end

function MA:UpdateIcon(unit, index, offset, filter, isDebuff, visible)
	local name, texture, count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID, canApply, isBossDebuff, casterIsPlayer, nameplateShowAll, timeMod, effect1, effect2, effect3 = UnitAura(unit, index, filter)

	if name then
		local position = visible + offset + 1
		local button = MA.Holder[position]

		if (not button) then
			button = MA:CreateAuraIcon(position)
			MA.Holder.createdIcons = MA.Holder.createdIcons + 1
		end

		button.caster = caster
		button.filter = filter
		button.isDebuff = isDebuff
		button.isPlayer = caster == 'player' or caster == 'vehicle'

		local show = MA:CustomFilter(unit, button, name, texture, count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID, canApply, isBossDebuff, casterIsPlayer, nameplateShowAll,timeMod, effect1, effect2, effect3)

		if show then
			if button.cd then
				if (duration and duration > 0) then
					button.cd:SetCooldown(expiration - duration, duration)
					button.cd:Show()
				else
					button.cd:Hide()
				end
			end

			if(button.icon) then button.icon:SetTexture(texture) end
			if(button.count) then button.count:SetText(count > 1 and count) end

			button:SetSize(MA.db.Size, MA.db.Size)
			button:SetID(index)
			button:Show()

			return VISIBLE
		else
			return HIDDEN
		end
	end
end

function MA:SetPosition()
	local sizex = MA.db.Size + MA.db.Spacing
	local sizey = MA.db.Size + MA.db.Spacing
	local anchor = 'BOTTOMLEFT'
	local growthx = 1
	local growthy = 1
	local cols = floor(MA.Holder:GetWidth() / sizex + 0.5)

	for i, button in ipairs(MA.Holder) do
		if(not button) then break end
		local col = (i - 1) % cols
		local row = floor((i - 1) / cols)

		button:ClearAllPoints()
		button:SetPoint(anchor, MA.Holder, anchor, col * sizex * growthx, row * sizey * growthy)
	end
end

function MA:FilterIcons(unit, filter, limit, isDebuff, offset, dontHide)
	if (not offset) then offset = 0 end
	local index = 1
	local visible = 0
	local hidden = 0
	while (visible < limit) do
		local result = MA:UpdateIcon(unit, index, offset, filter, isDebuff, visible)
		if (not result) then
			break
		elseif (result == VISIBLE) then
			visible = visible + 1
		elseif (result == HIDDEN) then
			hidden = hidden + 1
		end

		index = index + 1
	end

	if (not dontHide) then
		for i = visible + offset + 1, #MA.Holder do
			MA.Holder[i]:Hide()
		end
	end

	return visible, hidden
end

function MA:UpdateAuras(unit)
	local numBuffs = 32
	local numDebuffs = 40
	local max = numBuffs + numDebuffs

	local visibleBuffs = MA:FilterIcons(unit, 'HELPFUL', math.min(numBuffs, max), nil, 0, true)
	local visibleDebuffs = MA:FilterIcons(unit, 'HARMFUL', math.min(numDebuffs, max - visibleBuffs), true, visibleBuffs)
	local visibleAuras = visibleBuffs + visibleDebuffs

	if(MA.Holder.createdIcons > MA.Holder.anchoredIcons) then
		MA:SetPosition()
		MA.Holder.anchoredIcons = MA.Holder.createdIcons
	end
end

function MA:Update(elapsed)
	if (not UnitExists('mouseover')) or GetMouseFocus() and (GetMouseFocus():IsForbidden() or GetMouseFocus():GetName() ~= "WorldFrame" ) then
		MA.Holder:Hide()
		return
	end

	local x, y = GetCursorPosition()
	local scale = _G.UIParent:GetEffectiveScale()

	MA.Holder:ClearAllPoints()
	MA.Holder:SetPoint("BOTTOMLEFT", _G.UIParent, "BOTTOMLEFT", x / scale, y / scale)

	MA.Holder.elapsed = MA.Holder.elapsed + elapsed

	if (MA.Holder.elapsed > .25) then
		MA:UpdateAuras('mouseover')
		MA.Holder.elapsed = 0
	end
end

function MA:UPDATE_MOUSEOVER_UNIT(event)
	if (UnitExists('mouseover')) then
		MA.Holder:Show()
		MA:UpdateAuras('mouseover')
	else
		MA.Holder:Hide()
	end
end

function MA:GetOptions()
	PA.Options.args.MouseoverAuras = {
		type = 'group',
		name = MA.Title,
		childGroups = 'tab',
		get = function(info) return MA.db[info[#info]] end,
		set = function(info, value) MA.db[info[#info]] = value MA:SetPosition() end,
		args = {
			Header = {
				order = 0,
				type = 'header',
				name = PA:Color(MA.Title),
			},
			Enable = {
				order = 1,
				type = 'toggle',
				name = PA.ACL['Enable'],
			},
			General = {
				order = 2,
				type = 'group',
				name = PA.ACL['General'],
				guiInline = true,
				args = {
					Size = {
						order = 1,
						type = 'range',
						name = PA.ACL['Size'],
						min = 24, max = 60, step = 1,
					},
					Spacing = {
						order = 2,
						type = 'range',
						name = PA.ACL['Spacing'],
						min = 0, max = 20, step = 1,
					},
				},
			},
			AuthorHeader = {
				order = -2,
				type = 'header',
				name = PA.ACL['Authors:'],
			},
			Authors = {
				order = -1,
				type = 'description',
				name = MA.Authors,
				fontSize = 'large',
			},
		},
	}
end

function MA:BuildProfile()
	PA.Defaults.profile.MouseoverAuras = {
		Enable = false,
		Size = 16,
		Spacing = 1,
		cooldown = CopyTable(PA.Defaults.profile.cooldown),
	}
end

function MA:Initialize()
	MA.db = PA.db.MouseoverAuras

	if MA.db.Enable ~= true then
		return
	end

	MA.Holder = CreateFrame('Frame', 'MouseoverAurasHolder', _G.UIParent)
	MA.Holder:SetFrameStrata('TOOLTIP')
	MA.Holder:Hide()
	MA.Holder:SetSize(120, 40)
	MA.Holder.createdIcons = 0
	MA.Holder.anchoredIcons = 0
	MA.Holder.elapsed = 0
	MA.Holder:SetScript('OnUpdate', MA.Update)

	MA:RegisterEvent('UPDATE_MOUSEOVER_UNIT')
end
