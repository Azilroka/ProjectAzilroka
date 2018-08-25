local PA = _G.ProjectAzilroka
local type = type

function PA:TukuiOptions()
	local OptionsTable = {
		type = 'group',
		name = '|cffff8000Tukui Config|r',
		order = 215,
		childGroups = 'tab',
		args = {
			main = {
				order = 0,
				type = 'group',
				name = 'Tukui Options',
				args = {
					Account = {
						order = 0,
						type = 'toggle',
						name = Tukui[3].Others.GlobalSettings,
						get = function() return TukuiConfigPerAccount end,
						set = function(_, value) TukuiConfigPerAccount = value end,
					},
				},
			},
		},
	}

	local MyRealm = PA.MyRealm
	local MyName = PA.MyName
	local SavedVars
	local Locale = PA.Locale

	if (not TukuiConfig[Locale]) then
		Locale = "enUS"
	end

	if (TukuiConfigPerAccount) then
		SavedVars = TukuiConfigShared.Account
	else
		SavedVars = TukuiConfigShared[MyRealm][MyName]
	end

	local FontTable = tInvert(Tukui[1].FontTable)

	local GroupIndex, OptionIndex = 1
	for Group in PA:PairsByKeys(Tukui[2]) do
		if not TukuiConfig.Filter[Group] then
			OptionsTable.args.main.args[Group] = {
				order = GroupIndex,
				type = 'group',
				name = (type(TukuiConfig[Locale][Group]) == 'string' and TukuiConfig[Locale][Group]) or tostring(Group),
				args = {},
				get = function(info) return SavedVars[Group] and SavedVars[Group][info[#info]] or Tukui[2][Group][info[#info]] end,
				set = function(info, value) TukuiConfig:SetOption(Group, info[#info], value) end,
			}

			GroupIndex = GroupIndex + 1
			OptionIndex = 1

			for Option, Value in PA:PairsByKeys(Tukui[2][Group]) do
				OptionsTable.args.main.args[Group].args[Option] = { order = OptionIndex, name = tostring(Option) }

				if TukuiConfig[Locale][Group] and type(TukuiConfig[Locale][Group][Option]) == "table" then
					OptionsTable.args.main.args[Group].args[Option].name = TukuiConfig[Locale][Group][Option].Name
					OptionsTable.args.main.args[Group].args[Option].desc = TukuiConfig[Locale][Group][Option].Desc
				end
				if (type(Value) == "boolean") then -- Button
					OptionsTable.args.main.args[Group].args[Option].type = 'toggle'
				elseif (type(Value) == "number") then -- EditBox
					OptionsTable.args.main.args[Group].args[Option].type = 'input'
					OptionsTable.args.main.args[Group].args[Option].get = function(info) return tostring(SavedVars[Group] and SavedVars[Group][info[#info]] or Tukui[2][Group][info[#info]]) end
					OptionsTable.args.main.args[Group].args[Option].width = 'normal'
				elseif (type(Value) == "table") then -- Color Picker / Custom DropDown
					if Value.Options then
						OptionsTable.args.main.args[Group].args[Option].type = 'select'
						OptionsTable.args.main.args[Group].args[Option].get = function(info) return SavedVars[Group] and SavedVars[Group][info[#info]] and SavedVars[Group][info[#info]]['Value'] or Tukui[2][Group][info[#info]]['Value'] end
						OptionsTable.args.main.args[Group].args[Option].set = function(info, value) Value['Value'] = value TukuiConfig:SetOption(Group, info[#info], Value) end
						OptionsTable.args.main.args[Group].args[Option].values = Value['Options']
					else
						OptionsTable.args.main.args[Group].args[Option].type = 'color'
						OptionsTable.args.main.args[Group].args[Option].get = function(info) return unpack(SavedVars[Group] and SavedVars[Group][info[#info]] or Tukui[2][Group][info[#info]]) end
						OptionsTable.args.main.args[Group].args[Option].set = function(info, r, g, b, a) TukuiConfig:SetOption(Group, info[#info], { r, g, b, a}) end
					end
				elseif (type(Value) == "string") then -- DropDown / EditBox
					OptionsTable.args.main.args[Group].args[Option].type = 'select'
					if strfind(strlower(Option), "font") then
						OptionsTable.args.main.args[Group].args[Option].values = FontTable
						OptionsTable.args.main.args[Group].args[Option].get = function(info) return Tukui[1].FontTable[SavedVars[Group] and SavedVars[Group][info[#info]] or Tukui[2][Group][info[#info]]] end
						OptionsTable.args.main.args[Group].args[Option].set = function(info, value) TukuiConfig:SetOption(Group, info[#info], FontTable[value])	end
					elseif strfind(strlower(Option), "texture") then
						OptionsTable.args.main.args[Group].args[Option].values = Tukui[1].TextureTable
						OptionsTable.args.main.args[Group].args[Option].dialogControl = 'LSM30_Statusbar'
					end
				end
				OptionIndex = OptionIndex + 1
			end
		end
	end

	_G.Enhanced_Config.Options.args.TukuiOptions = OptionsTable
end