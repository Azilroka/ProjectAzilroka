local AddOnTitle = GetAddOnMetadata(select(1, ...), 'Title')

local DisabledString = '|cFFFF0000Disabled|r'
local EnabledString = '|cFF00FF00Enabled|r'
local AlreadyString = "%s: '%s' is already '%s'."
local ErrorString = "%s: |cFFFFFF00Error|r '%s' not found."
local MissingString = '%s: Missing AddOn Name!. %s <AddOnName>'
local MyName = UnitName('player')

local function EnableAddon(AddOnName)
	local _, Title, _, _, Reason = GetAddOnInfo(AddOnName)
	if AddOnName == '' then
		print(format(MissingString, AddOnTitle, '/enable'))
	elseif Reason ~= 'MISSING' then
		if GetAddOnEnableState(MyName, AddOnName) > 0 then
			print(format(AlreadyString, AddOnTitle, Title, EnabledString))
		else
			EnableAddOn(AddOnName) 
			print(format("%s: %s '%s'", AddOnTitle, EnabledString, Title))
		end
	else
		print(format(ErrorString, AddOnTitle, AddOnName))
	end
end

local function DisableAddon(AddOnName)
	local _, Title, _, _, Reason = GetAddOnInfo(AddOnName)
	if AddOnName == '' then
		print(format(MissingString, AddOnTitle, '/disable'))
	elseif Reason ~= 'MISSING' then
		if GetAddOnEnableState(MyName, AddOnName) > 0 then
			DisableAddOn(AddOnName)
			print(format("%s: %s '%s'", AddOnTitle, DisabledString, Title))
		else
			print(format(AlreadyString, AddOnTitle, Title, DisabledString))
		end
	else
		print(format(ErrorString, AddOnTitle, AddOnName))
	end
end

local function BaseAddon(AddOnName)
	local _, Title, _, _, Reason = GetAddOnInfo(AddOnName)
	local AddOnName = strlower(AddOnName)
	if AddOnName == '' then
		print(format(MissingString, AddOnTitle, '/base'))
	elseif Reason ~= 'MISSING' then
		DisableAllAddOns()
		print(AddOnTitle..': Disabled All AddOns')
		print('|cffCC0000~~~~~~~~~~~~~~~~~~~~~~~~~~~~~')
		EnableAddon('DevToolkit')
		EnableAddon('AddOnSkins')
		if AddOnName == 'elvui' then
			EnableAddon('ElvUI')
			EnableAddon('ElvUI_Config')
		elseif AddOnName == 'tukui' then
			EnableAddon('Tukui')
			EnableAddon('Enhanced_Config')
			EnableAddon('Tukui_Config')
		elseif AddOnName == 'asphyxiaui' then
			EnableAddon('AsphyxiaUI')
			EnableAddon('AsphyxiaUI_Config')
			EnableAddon('Enhanced_Config')
		else
			EnableAddon(AddOnName)
		end
		print('|cffCC0000~~~~~~~~~~~~~~~~~~~~~~~~~~~~~')
	else
		print(format(ErrorString, AddOnTitle, AddOnName))
	end
end

SLASH_BASEADDON1 = '/base'
SlashCmdList['BASEADDON'] = BaseAddon

if SlashCmdList['ENABLE_ADDON'] and SlashCmdList['DISABLE_ADDON'] then
	SlashCmdList['ENABLE_ADDON'] = EnableAddon
	SlashCmdList['DISABLE_ADDON'] = DisableAddon
else
	SLASH_ENABLEADDON1 = '/enable'
	SlashCmdList['ENABLEADDON'] = EnableAddon
	SLASH_DISABLEADDON1 = '/disable'
	SlashCmdList['DISABLEADDON'] = DisableAddon
end