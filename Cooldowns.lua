local PA = _G.ProjectAzilroka

--Lua functions
local next = next
local ipairs = ipairs
local pairs = pairs
local floor = floor
local tinsert = tinsert
local ceil = ceil
local gsub = gsub

--WoW API / Variables
local GetTime = GetTime
local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc

local ICON_SIZE = 36 --the normal size for an icon (don't change this)
local FONT_SIZE = 20 --the base font size to use at a scale of 1
local MIN_SCALE = 0.5 --the minimum scale we want to show cooldown counts at, anything below this will be hidden
local MIN_DURATION = 1.5 --the minimum duration to show cooldown text for

PA.TimeThreshold = 3

PA.TimeColors = { --aura time colors
	[0] = '|cffeeeeee', --days
	[1] = '|cffeeeeee', --hours
	[2] = '|cffeeeeee', --minutes
	[3] = '|cffeeeeee', --seconds
	[4] = '|cfffe0000', --expire (fade timer)
	[5] = '|cff909090', --mmss
	[6] = '|cff707070', --hhmm
}

PA.TimeFormats = { -- short / indicator color
	[0] = {'%dd', '%d%sd|r'},
	[1] = {'%dh', '%d%sh|r'},
	[2] = {'%dm', '%d%sm|r'},
	[3] = {'%ds', '%d%ss|r'},
	[4] = {'%.1fs', '%.1f%ss|r'},
	[5] = {'%d:%02d', '%d%s:|r%02d'}, --mmss
	[6] = {'%d:%02d', '%d%s:|r%02d'}, --hhmm
}

for _, x in pairs(PA.TimeFormats) do
	x[3] = gsub(x[1], 's$', '') -- 1 without seconds
	x[4] = gsub(x[2], '%%ss', '%%s') -- 2 without seconds
end

PA.TimeIndicatorColors = {
	[0] = '|cff00b3ff',
	[1] = '|cff00b3ff',
	[2] = '|cff00b3ff',
	[3] = '|cff00b3ff',
	[4] = '|cff00b3ff',
	[5] = '|cff00b3ff',
	[6] = '|cff00b3ff',
}

local DAY, HOUR, MINUTE = 86400, 3600, 60
local DAYISH, HOURISH, MINUTEISH = HOUR * 23.5, MINUTE * 59.5, 59.5
local HALFDAYISH, HALFHOURISH, HALFMINUTEISH = DAY/2 + 0.5, HOUR/2 + 0.5, MINUTE/2 + 0.5

function PA:GetTimeInfo(s, threshhold, hhmm, mmss)
	if s < MINUTE then
		if s >= threshhold then
			return floor(s), 3, 0.51
		else
			return s, 4, 0.051
		end
	elseif s < HOUR then
		if mmss and s < mmss then
			return s/MINUTE, 5, 0.51, s%MINUTE
		else
			local minutes = floor((s/MINUTE)+.5)
			if hhmm and s < (hhmm * MINUTE) then
				return s/HOUR, 6, minutes > 1 and (s - (minutes*MINUTE - HALFMINUTEISH)) or (s - MINUTEISH), minutes%MINUTE
			else
				return ceil(s / MINUTE), 2, minutes > 1 and (s - (minutes*MINUTE - HALFMINUTEISH)) or (s - MINUTEISH)
			end
		end
	elseif s < DAY then
		if mmss and s < mmss then
			return s/MINUTE, 5, 0.51, s%MINUTE
		elseif hhmm and s < (hhmm * MINUTE) then
			local minutes = floor((s/MINUTE)+.5)
			return s/HOUR, 6, minutes > 1 and (s - (minutes*MINUTE - HALFMINUTEISH)) or (s - MINUTEISH), minutes%MINUTE
		else
			local hours = floor((s/HOUR)+.5)
			return ceil(s / HOUR), 1, hours > 1 and (s - (hours*HOUR - HALFHOURISH)) or (s - HOURISH)
		end
	else
		local days = floor((s/DAY)+.5)
		return ceil(s / DAY), 0, days > 1 and (s - (days*DAY - HALFDAYISH)) or (s - DAYISH)
	end
end

function PA:Cooldown_TextThreshold(cd, now)
	if cd.parent and cd.parent.textThreshold and cd.endTime then
		return (cd.endTime - now) >= cd.parent.textThreshold
	end
end

function PA:Cooldown_BelowScale(cd)
	if cd.parent then
		if cd.parent.hideText then return true end
		if cd.parent.skipScale then return end
	end

	return cd.fontScale and (cd.fontScale < MIN_SCALE)
end

function PA:Cooldown_OnUpdate(elapsed)
	local forced = elapsed == -1
	if forced then
		self.nextUpdate = 0
	elseif self.nextUpdate > 0 then
		self.nextUpdate = self.nextUpdate - elapsed
		return
	end

	if not PA:Cooldown_IsEnabled(self) then
		PA:Cooldown_StopTimer(self)
	else
		local now = GetTime()
		if self.endCooldown and now >= self.endCooldown then
			PA:Cooldown_StopTimer(self)
		elseif PA:Cooldown_BelowScale(self) then
			self.text:SetText('')
			if not forced then
				self.nextUpdate = 500
			end
		elseif PA:Cooldown_TextThreshold(self, now) then
			self.text:SetText('')
			if not forced then
				self.nextUpdate = 1
			end
		elseif self.endTime then
			local value, id, nextUpdate, remainder = PA:GetTimeInfo(self.endTime - now, self.threshold, self.hhmmThreshold, self.mmssThreshold)
			if not forced then
				self.nextUpdate = nextUpdate
			end

			local style = PA.TimeFormats[id]
			if style then
				local which = (self.textColors and 2 or 1) + (self.showSeconds and 0 or 2)
				if self.textColors then
					self.text:SetFormattedText(style[which], value, self.textColors[id], remainder)
				else
					self.text:SetFormattedText(style[which], value, remainder)
				end
			end

			local color = self.timeColors[id]
			if color then
				self.text:SetTextColor(color.r, color.g, color.b)
			end
		end
	end
end

function PA:Cooldown_OnSizeChanged(cd, width, force)
	local scale = width and (floor(width + 0.5) / ICON_SIZE)

	-- dont bother updating when the fontScale is the same, unless we are passing the force arg
	if scale and (scale == cd.fontScale) and (force ~= true) then return end
	cd.fontScale = scale

	-- this is needed because of skipScale variable, we wont allow a font size under the minscale
	if cd.fontScale and (cd.fontScale < MIN_SCALE) then
		scale = MIN_SCALE
	end

	if cd.customFont then -- override font
		cd.text:SetFont(PA.LSM:Fetch('font', cd.customFont), (scale * cd.customFontSize), cd.customFontOutline)
	elseif scale then -- default, no override
		cd.text:SetFont(PA.LSM:Fetch('font', PA.LSM:GetDefault('font')), (scale * FONT_SIZE), 'OUTLINE')
	end
end

function PA:Cooldown_IsEnabled(cd)
	if cd.forceEnabled then
		return true
	elseif cd.forceDisabled then
		return false
	elseif cd.reverseToggle ~= nil then
		return cd.reverseToggle
	else
		return PA.db.Cooldown.Enable
	end
end

function PA:Cooldown_ForceUpdate(cd)
	PA.Cooldown_OnUpdate(cd, -1)
	cd:Show()
end

function PA:Cooldown_StopTimer(cd)
	cd.text:SetText('')
	cd:Hide()
end

function PA:Cooldown_Options(timer, db, parent)
	local threshold, colors, icolors, hhmm, mmss, fonts
	if parent and db.override then
		threshold = db.threshold
		icolors = db.useIndicatorColor and PA.TimeIndicatorColors[parent.CooldownOverride]
		colors = PA.TimeColors[parent.CooldownOverride]
	end

	if db.checkSeconds then
		hhmm, mmss = db.hhmmThreshold, db.mmssThreshold
	end

	timer.timeColors = colors or PA.TimeColors
	timer.threshold = threshold or PA.db.Cooldown.threshold or PA.TimeThreshold
	timer.textColors = icolors or (PA.db.Cooldown.useIndicatorColor and PA.TimeIndicatorColors)
	timer.hhmmThreshold = hhmm or (PA.db.Cooldown.checkSeconds and PA.db.Cooldown.hhmmThreshold)
	timer.mmssThreshold = mmss or (PA.db.Cooldown.checkSeconds and PA.db.Cooldown.mmssThreshold)
	timer.hideBlizzard = db.hideBlizzard or PA.db.Cooldown.hideBlizzard

	if db.reverse ~= nil then
		timer.reverseToggle = (PA.db.Cooldown.Enable and not db.reverse) or (db.reverse and not PA.db.Cooldown.Enable)
	else
		timer.reverseToggle = nil
	end

	if (db ~= PA.db.Cooldown) and db.fonts and db.fonts.enable then
		fonts = db.fonts -- custom fonts override default fonts
	elseif PA.db.Cooldown.fonts and PA.db.Cooldown.fonts.enable then
		fonts = PA.db.Cooldown.fonts -- default global font override
	end

	if fonts and fonts.enable then
		timer.customFont = fonts.font
		timer.customFontSize = fonts.fontSize
		timer.customFontOutline = fonts.fontOutline
	else
		timer.customFont = nil
		timer.customFontSize = nil
		timer.customFontOutline = nil
	end
end

function PA:CreateCooldownTimer(parent)
	local timer = CreateFrame('Frame', nil, parent)
	timer:Hide()
	timer:SetAllPoints()
	timer.parent = parent
	parent.timer = timer

	local text = timer:CreateFontString(nil, 'OVERLAY')
	text:SetPoint('CENTER', 1, 1)
	text:SetJustifyH('CENTER')
	timer.text = text

	-- can be used to modify elements created from this function
	if parent.CooldownPreHook then
		parent.CooldownPreHook(parent)
	end

	-- cooldown override settings
	local db = (parent.CooldownOverride and PA.db[parent.CooldownOverride]) or PA.db
	if db and db.Cooldown then
		PA:Cooldown_Options(timer, db.Cooldown, parent)
	end

	PA:ToggleBlizzardCooldownText(parent, timer)

	-- keep an eye on the size so we can rescale the font if needed
	self:Cooldown_OnSizeChanged(timer, parent:GetWidth())
	parent:SetScript('OnSizeChanged', function(_, width)
		self:Cooldown_OnSizeChanged(timer, width)
	end)

	-- keep this after Cooldown_OnSizeChanged
	timer:SetScript('OnUpdate', PA.Cooldown_OnUpdate)

	return timer
end

PA.RegisteredCooldowns = {}
function PA:OnSetCooldown(start, duration)
	if (not self.forceDisabled) and (start and duration) and (duration > MIN_DURATION) then
		local timer = self.timer or PA:CreateCooldownTimer(self)
		timer.start = start
		timer.duration = duration
		timer.endTime = start + duration
		timer.endCooldown = timer.endTime - 0.05
		PA:Cooldown_ForceUpdate(timer)
	elseif self.timer then
		PA:Cooldown_StopTimer(self.timer)
	end
end

function PA:RegisterCooldown(cooldown)
	if not cooldown.isHooked then
		hooksecurefunc(cooldown, 'SetCooldown', PA.OnSetCooldown)
		cooldown.isHooked = true
	end

	if not cooldown.isRegisteredCooldown then
		local module = (cooldown.CooldownOverride or 'global')
		if not PA.RegisteredCooldowns[module] then PA.RegisteredCooldowns[module] = {} end

		tinsert(PA.RegisteredCooldowns[module], cooldown)
		cooldown.isRegisteredCooldown = true
	end
end

function PA:ToggleBlizzardCooldownText(cd, timer, request)
	-- we should hide the blizzard cooldown text when ours are enabled
	if timer and cd and cd.SetHideCountdownNumbers then
		local forceHide = cd.hideText or timer.hideBlizzard
		if request then
			return forceHide or PA:Cooldown_IsEnabled(timer)
		else
			cd:SetHideCountdownNumbers(forceHide or PA:Cooldown_IsEnabled(timer))
		end
	end
end

function PA:GetCooldownColors(db)
	if not db then db = PA.db.Cooldown end -- just incase someone calls this without a first arg use the global
	local c13 = PA:RGBToHex(db.hhmmColorIndicator.r, db.hhmmColorIndicator.g, db.hhmmColorIndicator.b) -- color for timers that are soon to expire
	local c12 = PA:RGBToHex(db.mmssColorIndicator.r, db.mmssColorIndicator.g, db.mmssColorIndicator.b) -- color for timers that are soon to expire
	local c11 = PA:RGBToHex(db.expireIndicator.r, db.expireIndicator.g, db.expireIndicator.b) -- color for timers that are soon to expire
	local c10 = PA:RGBToHex(db.secondsIndicator.r, db.secondsIndicator.g, db.secondsIndicator.b) -- color for timers that have seconds remaining
	local c9 = PA:RGBToHex(db.minutesIndicator.r, db.minutesIndicator.g, db.minutesIndicator.b) -- color for timers that have minutes remaining
	local c8 = PA:RGBToHex(db.hoursIndicator.r, db.hoursIndicator.g, db.hoursIndicator.b) -- color for timers that have hours remaining
	local c7 = PA:RGBToHex(db.daysIndicator.r, db.daysIndicator.g, db.daysIndicator.b) -- color for timers that have days remaining
	local c6 = db.hhmmColor -- HH:MM color
	local c5 = db.mmssColor -- MM:SS color
	local c4 = db.expiringColor -- color for timers that are soon to expire
	local c3 = db.secondsColor -- color for timers that have seconds remaining
	local c2 = db.minutesColor -- color for timers that have minutes remaining
	local c1 = db.hoursColor -- color for timers that have hours remaining
	local c0 = db.daysColor -- color for timers that have days remaining
	return c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13
end

function PA:UpdateCooldownOverride(module)
	local cooldowns = (module and PA.RegisteredCooldowns[module])
	if (not cooldowns) or not next(cooldowns) then return end

	for _, parent in ipairs(cooldowns) do
		local db = (parent.CooldownOverride and PA.db[parent.CooldownOverride]) or PA.db
		if db and db.Cooldown then
			local timer = parent.isHooked and parent.isRegisteredCooldown and parent.timer
			local cd = timer or parent

			-- cooldown override settings
			PA:Cooldown_Options(cd, db.Cooldown, parent)

			-- update font on cooldowns
			if timer and cd then -- has a parent, these are timers from RegisterCooldown
				PA:Cooldown_OnSizeChanged(cd, parent:GetWidth(), true)

				PA:ToggleBlizzardCooldownText(parent, cd)
			elseif cd.text and cd.customFont then
				cd.text:SetFont(PA.LSM:Fetch('font', cd.customFont), cd.customFontSize, cd.customFontOutline)
			end
		end
	end
end

function PA:UpdateCooldownSettings(module)
	local db, timeColors, textColors = PA.db.Cooldown, PA.TimeColors, PA.TimeIndicatorColors

	-- update the module timecolors if the config called it but ignore 'global' and 'all':
	-- global is the main call from config, all is the core file calls
	local isModule = module and (module ~= 'global' and module ~= 'all') and PA.db[module] and PA.db[module].Cooldown
	if isModule then
		if not PA.TimeColors[module] then PA.TimeColors[module] = {} end
		if not PA.TimeIndicatorColors[module] then PA.TimeIndicatorColors[module] = {} end
		db, timeColors, textColors = PA.db[module].Cooldown, PA.TimeColors[module], PA.TimeIndicatorColors[module]
	end

	timeColors[0], timeColors[1], timeColors[2], timeColors[3], timeColors[4], timeColors[5], timeColors[6], textColors[0], textColors[1], textColors[2], textColors[3], textColors[4], textColors[5], textColors[6] = PA:GetCooldownColors(db)

	if isModule then
		PA:UpdateCooldownOverride(module)
	elseif module == 'global' then -- this is only a call from the config change
		for key in pairs(PA.RegisteredCooldowns) do
			PA:UpdateCooldownOverride(key)
		end
	end

	-- okay update the other override settings if it was one of the core file calls
	if module and (module == 'all') then
		PA:UpdateCooldownSettings('OzCooldowns')
		PA:UpdateCooldownSettings('iFilger')
	end
end

local function profile(db)
	return (db == 'global' and PA.db.Cooldown) or PA.db[db].Cooldown
end

local function group(order, db, label)
	local main = PA.ACH:Group(label, nil, order, nil, function(info) local t = (profile(db))[info[#info]] return t.r, t.g, t.b, t.a end, function(info, r, g, b) local t = (profile(db))[info[#info]] t.r, t.g, t.b = r, g, b; PA:UpdateCooldownSettings(db); end)
	PA.Options.args.Cooldown.args[db] = main

	local mainArgs = main.args
	mainArgs.reverse = PA.ACH:Toggle(PA.ACL["Reverse Toggle"], PA.ACL["Reverse Toggle will enable Cooldown Text on this module when the global setting is disabled and disable them when the global setting is enabled."], 1, nil, nil, nil, function(info) return (profile(db))[info[#info]] end, function(info, value) (profile(db))[info[#info]] = value; PA:UpdateCooldownSettings(db); end)
	mainArgs.hideBlizzard = PA.ACH:Toggle(PA.ACL["Force Hide Blizzard Text"], PA.ACL["This option will force hide Blizzard's cooldown text if it is enabled at [Interface > ActionBars > Show Numbers on Cooldown]."], 2, nil, nil, nil, function(info) return (profile(db))[info[#info]] end, function(info, value) (profile(db))[info[#info]] = value; PA:UpdateCooldownSettings(db); end, nil, function() if db == 'global' then return PA.db.Cooldown.Enable else return (PA.db.Cooldown.Enable and not profile(db).reverse) or (not PA.db.Cooldown.Enable and profile(db).reverse) end end)

	local seconds = PA.ACH:Group(PA.ACL["Text Threshold"], nil, 3, nil, function(info) return (profile(db))[info[#info]] end, function(info, value) (profile(db))[info[#info]] = value; PA:UpdateCooldownSettings(db); end, function() return not (profile(db)).checkSeconds end)
	seconds.inline = true
	seconds.args.checkSeconds = PA.ACH:Toggle(PA.ACL["Enable"], PA.ACL["This will override the global cooldown settings."], 1, nil, nil, nil, nil, nil, false)
	seconds.args.mmssThreshold = PA.ACH:Range(PA.ACL["MM:SS Threshold"], PA.ACL["Threshold (in seconds) before text is shown in the MM:SS format. Set to -1 to never change to this format."], 2, { min = -1, max = 10800, step = 1 })
	seconds.args.hhmmThreshold = PA.ACH:Range(PA.ACL["HH:MM Threshold"], PA.ACL["Threshold (in minutes) before text is shown in the HH:MM format. Set to -1 to never change to this format."], 3, { min = -1, max = 1440, step = 1 })
	mainArgs.secondsGroup = seconds

	local fonts = PA.ACH:Group(PA.ACL["Fonts"], nil, 4, nil, function(info) return (profile(db)).fonts[info[#info]] end, function(info, value) (profile(db)).fonts[info[#info]] = value; PA:UpdateCooldownSettings(db); end, function() return not (profile(db)).fonts.enable end)
	fonts.inline = true
	fonts.args.enable = PA.ACH:Toggle(PA.ACL["Enable"], PA.ACL["This will override the global cooldown settings."], 1, nil, nil, nil, nil, nil, false)
	fonts.args.font = PA.ACH:SharedMediaFont(PA.ACL["Font"], nil, 2)
	fonts.args.fontSize = PA.ACH:Range(PA.ACL["Font Size"], nil, 3, { min = 10, max = 50, step = 1 })
	fonts.args.fontOutline = PA.ACH:FontFlags(PA.ACL["Font Outline"], nil, 4)
	mainArgs.fontGroup = fonts

	local colors = PA.ACH:Group(PA.ACL["Color Override"], nil, 5, nil, nil, nil, function() return not (profile(db)).override end)
	colors.inline = true
	colors.args.override = PA.ACH:Toggle(PA.ACL["Enable"], PA.ACL["This will override the global cooldown settings."], 1, nil, nil, nil, function(info) return (profile(db))[info[#info]] end, function(info, value) (profile(db))[info[#info]] = value; PA:UpdateCooldownSettings(db); end, false)
	colors.args.threshold = PA.ACH:Range(PA.ACL["Low Threshold"], PA.ACL["Threshold before text turns red and is in decimal form. Set to -1 for it to never turn red"], 2, { min = -1, max = 20, step = 1 }, nil, function(info) return (profile(db))[info[#info]] end, function(info, value) (profile(db))[info[#info]] = value; PA:UpdateCooldownSettings(db); end)
	mainArgs.colorGroup = colors

	local tColors = PA.ACH:Group(PA.ACL["Threshold Colors"], nil, 3)
	tColors.args.expiringColor = PA.ACH:Color(PA.ACL["Expiring"], PA.ACL["Color when the text is about to expire"], 1)
	tColors.args.secondsColor = PA.ACH:Color(PA.ACL["Seconds"], PA.ACL["Color when the text is in the seconds format."], 2)
	tColors.args.minutesColor = PA.ACH:Color(PA.ACL["Minutes"], PA.ACL["Color when the text is in the minutes format."], 3)
	tColors.args.hoursColor = PA.ACH:Color(PA.ACL["Hours"], PA.ACL["Color when the text is in the hours format."], 4)
	tColors.args.daysColor = PA.ACH:Color(PA.ACL["Days"], PA.ACL["Color when the text is in the days format."], 5)
	tColors.args.mmssColor = PA.ACH:Color(PA.ACL["MM:SS"], nil, 6)
	tColors.args.hhmmColor = PA.ACH:Color(PA.ACL["HH:MM"], nil, 7)
	mainArgs.colorGroup.args.timeColors = tColors

	local iColors = PA.ACH:Group(PA.ACL["Time Indicator Colors"], nil, 4, nil, nil, nil, function() return not (profile(db)).useIndicatorColor end)
	iColors.args.useIndicatorColor = PA.ACH:Toggle(PA.ACL["Use Indicator Color"], nil, 0, nil, nil, nil, function(info) return (profile(db))[info[#info]] end, function(info, value) (profile(db))[info[#info]] = value; PA:UpdateCooldownSettings(db); end, false)
	iColors.args.expireIndicator = PA.ACH:Color(PA.ACL["Expiring"], PA.ACL["Color when the text is about to expire"], 1)
	iColors.args.secondsIndicator = PA.ACH:Color(PA.ACL["Seconds"], PA.ACL["Color when the text is in the seconds format."], 2)
	iColors.args.minutesIndicator = PA.ACH:Color(PA.ACL["Minutes"], PA.ACL["Color when the text is in the minutes format."], 3)
	iColors.args.hoursIndicator = PA.ACH:Color(PA.ACL["Hours"], PA.ACL["Color when the text is in the hours format."], 4)
	iColors.args.daysIndicator = PA.ACH:Color(PA.ACL["Days"], PA.ACL["Color when the text is in the days format."], 5)
	iColors.args.hhmmColorIndicator = PA.ACH:Color(PA.ACL["MM:SS"], nil, 6)
	iColors.args.mmssColorIndicator = PA.ACH:Color(PA.ACL["HH:MM"], nil, 7)
	mainArgs.colorGroup.args.indicatorColors = iColors

	if db == 'global' then
		mainArgs.reverse = nil
		mainArgs.colorGroup.args.override = nil
		mainArgs.colorGroup.disabled = nil
		mainArgs.colorGroup.name = PA.ACL["COLORS"]

		-- keep these two in this order
		PA.Options.args.Cooldown.args.hideBlizzard = mainArgs.hideBlizzard
		mainArgs.hideBlizzard = nil
	else
		mainArgs.reverse = nil
		mainArgs.hideBlizzard = nil
		mainArgs.fontGroup = nil
	end
end

PA.Options.args.Cooldown = PA.ACH:Group(PA.ACL["Cooldown Text"], nil, 2, 'tab', function(info) return PA.db.Cooldown[info[#info]] end, function(info, value) PA.db.Cooldown[info[#info]] = value; PA:UpdateCooldownSettings('global'); end)
PA.Options.args.Cooldown.args.intro = PA.ACH:Description(PA.ACL["COOLDOWN_DESC"], 0)
PA.Options.args.Cooldown.args.Enable = PA.ACH:Toggle(PA.ACL["Enable"], PA.ACL["Display cooldown text on anything with the cooldown spiral."], 1)

group(5,  'global',     PA.ACL["Global"])
group(6, 'OzCooldowns',  PA.ACL.OzCooldowns)
group(7, 'iFilger',  PA.ACL.iFilger)
