local _, st = ...
local stAM = CreateFrame("Frame", "stAddonManager", UIParent)
st[1] = stAM -- for local usage

st.FontStringTable = {} --Store all fontstrings in here (used by stAPI)

stAM.buttonHeight = 18
stAM.buttonWidth = 22
stAM.scrollOffset = 0