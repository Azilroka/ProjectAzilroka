local PA = _G.ProjectAzilroka
if PA.ElvUI then return end

local MAJOR, MINOR = "LibElvUIPlugin-1.0", 27
local lib, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

--Cache global variables
--Lua functions
local pairs, tonumber, strmatch, strsub = pairs, tonumber, strmatch, strsub
local format, strsplit, strlen, gsub, ceil = format, strsplit, strlen, gsub, ceil
--WoW API / Variables
local CreateFrame = CreateFrame
local IsInGroup, IsInRaid = IsInGroup, IsInRaid
local GetAddOnMetadata = GetAddOnMetadata
local C_Timer = C_Timer
local RegisterAddonMessagePrefix = C_ChatInfo.RegisterAddonMessagePrefix
local SendAddonMessage = C_ChatInfo.SendAddonMessage
local GetNumGroupMembers = GetNumGroupMembers
local LE_PARTY_CATEGORY_HOME = LE_PARTY_CATEGORY_HOME
local LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE

lib.plugins = {}
lib.index = 0
lib.groupSize = 0
lib.prefix = "ElvUIPluginVC"

-- MULTI Language Support (Default Language: English)
local MSG_OUTDATED = "Your version of %s is out of date (latest is version %s). You can download the latest version from http://www.tukui.org"
local HDR_CONFIG = "Plugins"
local HDR_INFORMATION = "LibElvUIPlugin-1.0.%d - Plugins Loaded [Green - Current | Red - Out of Date]"
local INFO_BY = "by"
local INFO_VERSION = "Version:"
local INFO_NEW = "Newest:"
local LIBRARY = "Library"

if GetLocale() == "deDE" then -- German Translation
	MSG_OUTDATED = "Deine Version von %s ist veraltet (akutelle Version ist %s). Du kannst die aktuelle Version von http://www.tukui.org herunterrladen."
	HDR_CONFIG = "Plugins"
	HDR_INFORMATION = "LibElvUIPlugin-1.0.%d - Plugins geladen (Grün bedeutet du hast die aktuelle Version, Rot bedeutet es ist veraltet)"
	INFO_BY = "von"
	INFO_VERSION = "Version:"
	INFO_NEW = "Neuste:"
	LIBRARY = "Bibliothek"
end

if GetLocale() == "ruRU" then -- Russian Translations
	MSG_OUTDATED = "Ваша версия %s устарела (последняя версия %s). Вы можете скачать последнюю версию на http://www.tukui.org"
	HDR_CONFIG = "Плагины"
	HDR_INFORMATION = "LibElvUIPlugin-1.0.%d - загруженные плагины (зеленый означает, что у вас последняя версия, красный - устаревшая)"
	INFO_BY = "от"
	INFO_VERSION = "Версия:"
	INFO_NEW = "Последняя:"
	LIBRARY = "Библиотека"
end

local Options = {
	order = -10,
	type = "group",
	name = HDR_CONFIG,
	inline = false,
	args = {
		pluginheader = {
			order = 1,
			type = "header",
			name = format(HDR_INFORMATION, MINOR),
		},
		plugins = {
			order = 2,
			type = "description",
		},
	}
}

local function RGBToHex(r, g, b)
	r = r <= 1 and r >= 0 and r or 0
	g = g <= 1 and g >= 0 and g or 0
	b = b <= 1 and b >= 0 and b or 0

	return format('|cff%02x%02x%02x', r*255, g*255, b*255)
end

function lib:RegisterPlugin(name, callback, isLib)
    local plugin = {
		name = name,
		callback = callback,
		version = name == MAJOR and MINOR or GetAddOnMetadata(name, 'Version')
	}

	if isLib then
		plugin.isLib = true
		plugin.version = 1
	end

	lib.plugins[name] = plugin

	if not lib.registeredPrefix then
		C_ChatInfo.RegisterAddonMessagePrefix(lib.prefix)
		lib.VCFrame:RegisterEvent('CHAT_MSG_ADDON')
		lib.VCFrame:RegisterEvent('GROUP_ROSTER_UPDATE')
		lib.VCFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
		lib.registeredPrefix = true
	end

	callback()

	Options.args.plugins.name = lib:GeneratePluginList()

	return plugin
end

function lib:GenerateVersionCheckMessage()
	local list = ''
	for _, plugin in pairs(lib.plugins) do
		if plugin.name ~= MAJOR then
			list = list..plugin.name..'='..plugin.version..';'
		end
	end
	return list
end

function lib:GetPluginOptions()
	_G.Enhanced_Config.Options.args.plugins = Options
end

function lib:VersionCheck(event, prefix, message, channel, sender)
	if (event == 'CHAT_MSG_ADDON' and prefix == lib.prefix) and (sender and message and not strmatch(message, '^%s-$')) then
		if not lib.myName then lib.myName = PA.MyName..'-'..gsub(PA.MyRealm,'[%s%-]','') end
		if sender == lib.myName then return end

		if not self["pluginRecievedOutOfDateMessage"] then
			local name, version, plugin, Pname, Pver, ver
			for _, p in pairs({strsplit(";",message)}) do
				if not strmatch(p, '^%s-$') then
					name, version = strmatch(p, '([%w_]+)=([%d%p]+)')
					plugin = name and lib.plugins[name]

					if version and plugin and plugin.version and (plugin.version ~= 'BETA') then
						Pver, ver = tonumber(plugin.version), tonumber(version)
						if (ver and Pver) and (ver > Pver) then
							plugin.old, plugin.newversion = true, ver
							Pname = GetAddOnMetadata(plugin.name, 'Title')
							print(format(MSG_OUTDATED,Pname,plugin.newversion))
							self["pluginRecievedOutOfDateMessage"] = true
						end
					end
				end
			end
		end
	elseif event == 'GROUP_ROSTER_UPDATE' then
		local num = GetNumGroupMembers()
		if num ~= lib.groupSize then
			if num > 1 and num > lib.groupSize then
				lib:DelayedSendVersionCheck()
			end
			lib.groupSize = num
		end
	elseif event == 'PLAYER_ENTERING_WORLD' then
		lib:DelayedSendVersionCheck(15)
	end
end

function lib:GeneratePluginList()
	local list = ""
	local author, Pname, color
	for _, plugin in pairs(lib.plugins) do
		if plugin.name ~= MAJOR then
			author = GetAddOnMetadata(plugin.name, "Author")
			Pname = GetAddOnMetadata(plugin.name, "Title") or plugin.name
			color = plugin.old and RGBToHex(1,0,0) or RGBToHex(0,1,0)
			list = list..Pname
			if author then list = list..' '..INFO_BY..' '..author end
			list = list..color..(plugin.isLib and ' '..LIBRARY or ' - '..INFO_VERSION..' '..plugin.version)
			if plugin.old then list = list..INFO_NEW..plugin.newversion..')' end
			list = list..'|r\n'
		end
	end
	return list
end

function lib:SendPluginVersionCheck(message)
	if (not message) or strmatch(message, '^%s-$') then
		return
	end

	local ChatType, Channel
	if IsInRaid() then
		ChatType = (not IsInRaid(LE_PARTY_CATEGORY_HOME) and IsInRaid(LE_PARTY_CATEGORY_INSTANCE)) and 'INSTANCE_CHAT' or 'RAID'
	elseif IsInGroup() then
		ChatType = (not IsInGroup(LE_PARTY_CATEGORY_HOME) and IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) and 'INSTANCE_CHAT' or 'PARTY'
	elseif IsInGuild() then
		ChatType = 'GUILD'
	end

	if not ChatType then
		return
	end

	local delay, maxChar, msgLength = 0, 250, strlen(message)
	if msgLength > maxChar then
		local splitMessage
		for _ = 1, ceil(msgLength/maxChar) do
			splitMessage = strmatch(strsub(message, 1, maxChar), '.+;')
			if splitMessage then -- incase the string is over 250 but doesnt contain `;`
				message = gsub(message, "^"..gsub(splitMessage, '([%(%)%.%%%+%-%*%?%[%^%$])','%%%1'), "")
				C_Timer.After(delay, function() SendAddonMessage(lib.prefix, splitMessage, ChatType, Channel) end)
				delay = delay + 1
				C_Timer.After(delay, lib.ClearSendMessageTimer) -- keep this after `delay = delay + 1`
			end
		end
	else
		SendAddonMessage(lib.prefix, message, ChatType, Channel)
	end
end

local function SendPluginVersionCheck()
	lib:SendPluginVersionCheck(lib:GenerateVersionCheckMessage())
end

function lib:DelayedSendVersionCheck(delay)
	if not lib.SendMessageTimer then
		lib.SendMessageTimer = C_Timer.After(delay or 10, SendPluginVersionCheck)
	end
end

lib.VCFrame = CreateFrame('Frame')
lib.VCFrame:SetScript('OnEvent', lib.VersionCheck)

lib:RegisterPlugin(MAJOR, lib.GetPluginOptions)
