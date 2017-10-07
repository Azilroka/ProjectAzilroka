local AddOnTitle = select(2, GetAddOnInfo(select(1,...)))

local function Commands()
	print(AddOnTitle.." Commands")
	print("/enable <AddOnName> - Enable an AddOn")
	print("/disable <AddOnName> - Disable an AddOn")
	print("/base [Tukui | AsphyxiaUI | DuffedUI | ElvUI] - Enables 'DevToolkit', [Base], [Config], [Skins] - EG: Tukui, Tukui_ConfigUI, Tukui_Skins.")
	print("/rl or /reloadui - Reloads the User Interface")
	print("/rc - Does a Ready Check")
	print("/leaveparty or /lp - Leaves current group/raid")
end

SLASH_RELOADUI1, SLASH_RELOADUI2 = "/rl", "/reloadui"
SlashCmdList['RELOADUI'] = ReloadUI

SLASH_RCSLASH1 = "/rc"
SlashCmdList['RCSLASH'] = DoReadyCheck

SLASH_LEAVEPARTY1, SLASH_LEAVEPARTY2 = '/leaveparty', '/lp'
SlashCmdList['LEAVEPARTY'] = LeaveParty

SLASH_COMMANDS1 = '/commands'
SlashCmdList['COMMANDS'] = Commands
