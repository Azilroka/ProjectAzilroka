local PA = _G.ProjectAzilroka
local type = type

function PA:TukuiOptions()
	local Options = {
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

	local MyRealm = GetRealmName()
	local MyName = UnitName("Player")
	local SavedVars
	local Locale = GetLocale()
	if (Locale == "enGB") then
		Locale = "enUS"
	end

	if (TukuiConfigPerAccount) then
		SavedVars = TukuiConfigShared.Account
	else
		SavedVars = TukuiConfigShared[MyRealm][MyName]
	end

	local GroupIndex, OptionIndex = 1
	for Group in PA:PairsByKeys(Tukui[2]) do
		if not TukuiConfig.Filter[Group] then
			Options.args.main.args[Group] = {
				order = GroupIndex,
				type = 'group',
				name = (type(TukuiConfig[Locale][Group]) == 'string' and TukuiConfig[Locale][Group]) or tostring(Group),
				args = {},
				get = function(info) return SavedVars[Group] and SavedVars[Group][info[#info]] or Tukui[2][Group][info[#info]] end,
				set = function(info, value)
					if (not SavedVars[Group]) then
						SavedVars[Group] = {}
					end

					SavedVars[Group][info[#info]] = value
				end
			}

			GroupIndex = GroupIndex + 1
			OptionIndex = 1

			for Option, Value in PA:PairsByKeys(Tukui[2][Group]) do
				Options.args.main.args[Group].args[Option] = { order = OptionIndex, name = tostring(Option) }

				if TukuiConfig[Locale][Group] and type(TukuiConfig[Locale][Group][Option]) == "table" then
					Options.args.main.args[Group].args[Option].name = TukuiConfig[Locale][Group][Option].Name
					Options.args.main.args[Group].args[Option].desc = TukuiConfig[Locale][Group][Option].Desc
				end

				if (type(Value) == "boolean") then -- Button
					Options.args.main.args[Group].args[Option].type = 'toggle'
				elseif (type(Value) == "number") then -- EditBox
					Options.args.main.args[Group].args[Option].type = 'input'
					Options.args.main.args[Group].args[Option].width = 'normal'
					Options.args.main.args[Group].args[Option].get = function(info) return tostring(SavedVars[Group] and SavedVars[Group][info[#info]] or Tukui[2][Group][info[#info]]) end
					Options.args.main.args[Group].args[Option].set = function(info, value)
						if (not SavedVars[Group]) then
							SavedVars[Group] = {}
						end

						SavedVars[Group][info[#info]] = tonumber(value)
					end
				elseif (type(Value) == "table") then -- Color Picker / Custom DropDown
					if Value.Options then
						Options.args.main.args[Group].args[Option].type = 'select'
						Options.args.main.args[Group].args[Option].values = Value.Options
					else
						Options.args.main.args[Group].args[Option].type = 'color'
						Options.args.main.args[Group].args[Option].get = function(info) return unpack(SavedVars[Group] and SavedVars[Group][info[#info]] or Tukui[2][Group][info[#info]]) end
						Options.args.main.args[Group].args[Option].set = function(info, r, g, b)
							if (not SavedVars[Group]) then
								SavedVars[Group] = {}
							end

							SavedVars[Group][info[#info]] = { r, g, b }
						end
					end
				elseif (type(Value) == "string") then -- DropDown / EditBox
					Options.args.main.args[Group].args[Option].type = 'select'
					if strfind(strlower(Option), "font") then
						Options.args.main.args[Group].args[Option].values = tInvert(Tukui[1].FontTable)
						Options.args.main.args[Group].args[Option].get = function(info)
							local Font = SavedVars[Group] and SavedVars[Group][info[#info]] or Tukui[2][Group][info[#info]]
							return Tukui[1].GetFont(Font)
						end
					elseif strfind(strlower(Option), "texture") then
						Options.args.main.args[Group].args[Option].values = tInvert(Tukui[1].TextureTable)
						Options.args.main.args[Group].args[Option].dialogControl = "LSM30_Statusbar"
						Options.args.main.args[Group].args[Option].get = function(info)
							local Texture = SavedVars[Group] and SavedVars[Group][info[#info]] or Tukui[2][Group][info[#info]]
							return Tukui[1].GetTexture(Texture)
						end
					end
				end
				OptionIndex = OptionIndex + 1
			end
		end
	end

	_G.Enhanced_Config.Options.args.TukuiOptions = Options
end