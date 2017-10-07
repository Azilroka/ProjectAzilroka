local AddOnName, Engine = ...
local AddOn = CreateFrame('Frame')

Engine[1] = AddOn

AddOn.Title = GetAddOnMetadata(AddOnName, "Title")
AddOn.Version = GetAddOnMetadata(AddOnName, "Version")
AddOn.MyRealm = GetRealmName()

--[[
BNET_CLIENT_APP
BNET_CLIENT_WOW
BNET_CLIENT_SC2
BNET_CLIENT_D3
BNET_CLIENT_WTCG
BNET_CLIENT_HEROES
BNET_CLIENT_OVERWATCH
BNET_CLIENT_SC
BNET_CLIENT_DESTINY2
]]

AddOn.GameIcons = {
	Default = {
		Alliance = BNet_GetClientTexture(BNET_CLIENT_WOW ),
		Horde = BNet_GetClientTexture(BNET_CLIENT_WOW ),
		Neutral = BNet_GetClientTexture(BNET_CLIENT_WOW ),
		D3 = BNet_GetClientTexture(BNET_CLIENT_D3),
		WTCG = BNet_GetClientTexture(BNET_CLIENT_WTCG),
		S1 = BNet_GetClientTexture(BNET_CLIENT_SC),
		S2 = BNet_GetClientTexture(BNET_CLIENT_SC2),
		App = BNet_GetClientTexture(BNET_CLIENT_APP),
		BSAp = App,
		Hero = BNet_GetClientTexture(BNET_CLIENT_HEROES),
		Pro = BNet_GetClientTexture(BNET_CLIENT_OVERWATCH),
		DST2 = BNet_GetClientTexture(BNET_CLIENT_DESTINY2),
	},
	BlizzardChat = {
		Alliance = "Interface\\ChatFrame\\UI-ChatIcon-WoW",
		Horde = "Interface\\ChatFrame\\UI-ChatIcon-WoW",
		Neutral = "Interface\\ChatFrame\\UI-ChatIcon-WoW",
		D3 = "Interface\\ChatFrame\\UI-ChatIcon-D3",
		WTCG = "Interface\\ChatFrame\\UI-ChatIcon-WTCG",
		S1 = "Interface\\ChatFrame\\UI-ChatIcon-SC",
		S2 = "Interface\\ChatFrame\\UI-ChatIcon-SC2",
		App = "Interface\\ChatFrame\\UI-ChatIcon-Battlenet",
		BSAp = App,
		Hero = "Interface\\ChatFrame\\UI-ChatIcon-HotS",
		Pro = "Interface\\ChatFrame\\UI-ChatIcon-Overwatch",
		DST2 = "Interface\\ChatFrame\\UI-ChatIcon-Destiny2",
	},
	Flat = {
		Alliance = "Interface\\AddOns\\"..AddOnName.."\\Textures\\GameIcons\\Flat\\Alliance",
		Horde = "Interface\\AddOns\\"..AddOnName.."\\Textures\\GameIcons\\Flat\\Horde",
		Neutral = "Interface\\AddOns\\"..AddOnName.."\\Textures\\GameIcons\\Flat\\Neutral",
		D3 = "Interface\\AddOns\\"..AddOnName.."\\Textures\\GameIcons\\Flat\\D3",
		WTCG = "Interface\\AddOns\\"..AddOnName.."\\Textures\\GameIcons\\Flat\\Hearthstone",
		S1 = "Interface\\ChatFrame\\UI-ChatIcon-SC",
		S2 = "Interface\\AddOns\\"..AddOnName.."\\Textures\\GameIcons\\Flat\\SC2",
		App = "Interface\\AddOns\\"..AddOnName.."\\Textures\\GameIcons\\Flat\\BattleNet",
		BSAp = App,
		Hero = "Interface\\AddOns\\"..AddOnName.."\\Textures\\GameIcons\\Flat\\Heroes",
		Pro = "Interface\\AddOns\\"..AddOnName.."\\Textures\\GameIcons\\Flat\\Overwatch",
		DST2 = "Interface\\ChatFrame\\UI-ChatIcon-Destiny2",
	},
	Gloss = {
		Alliance = "Interface\\AddOns\\"..AddOnName.."\\Textures\\GameIcons\\Gloss\\Alliance",
		Horde = "Interface\\AddOns\\"..AddOnName.."\\Textures\\GameIcons\\Gloss\\Horde",
		Neutral = "Interface\\AddOns\\"..AddOnName.."\\Textures\\GameIcons\\Gloss\\Neutral",
		D3 = "Interface\\AddOns\\"..AddOnName.."\\Textures\\GameIcons\\Gloss\\D3",
		WTCG = "Interface\\AddOns\\"..AddOnName.."\\Textures\\GameIcons\\Gloss\\Hearthstone",
		S1 = "Interface\\ChatFrame\\UI-ChatIcon-SC",
		S2 = "Interface\\AddOns\\"..AddOnName.."\\Textures\\GameIcons\\Gloss\\SC2",
		App = "Interface\\AddOns\\"..AddOnName.."\\Textures\\GameIcons\\Gloss\\BattleNet",
		BSAp = App,
		Hero = "Interface\\AddOns\\"..AddOnName.."\\Textures\\GameIcons\\Gloss\\Heroes",
		Pro = "Interface\\AddOns\\"..AddOnName.."\\Textures\\GameIcons\\Gloss\\Overwatch",
		DST2 = "Interface\\ChatFrame\\UI-ChatIcon-Destiny2",
	},
}

AddOn.StatusIcons = {
	Default = {
		Online = FRIENDS_TEXTURE_ONLINE,
		Offline = FRIENDS_TEXTURE_OFFLINE,
		DND = FRIENDS_TEXTURE_DND,
		AFK = FRIENDS_TEXTURE_AFK,
	},
	Square = {
		Online = "Interface\\AddOns\\"..AddOnName.."\\Textures\\StatusIcons\\Square\\Online",
		Offline = "Interface\\AddOns\\"..AddOnName.."\\Textures\\StatusIcons\\Square\\Offline",
		DND = "Interface\\AddOns\\"..AddOnName.."\\Textures\\StatusIcons\\Square\\DND",
		AFK = "Interface\\AddOns\\"..AddOnName.."\\Textures\\StatusIcons\\Square\\AFK",
	},
	D3 = {
		Online = "Interface\\AddOns\\"..AddOnName.."\\Textures\\StatusIcons\\D3\\Online",
		Offline = "Interface\\AddOns\\"..AddOnName.."\\Textures\\StatusIcons\\D3\\Offline",
		DND = "Interface\\AddOns\\"..AddOnName.."\\Textures\\StatusIcons\\D3\\DND",
		AFK = "Interface\\AddOns\\"..AddOnName.."\\Textures\\StatusIcons\\D3\\AFK",
	},
}

AddOn:RegisterEvent("PLAYER_LOGIN")
AddOn:SetScript("OnEvent", function(self)
	EP = LibStub("LibElvUIPlugin-1.0", true)
	if EP then
		EP:RegisterPlugin(AddOnName, self.GetOptions)
	else
		self:GetOptions()
	end

	self:Basic()
end)