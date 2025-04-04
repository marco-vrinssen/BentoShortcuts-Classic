-- DEFINE CONSTANTS
local regionNames = {'us', 'kr', 'eu', 'tw', 'cn'}
local region = regionNames[GetCurrentRegion()]


-- CREATE TARGET MACRO
local function createTargetMacro(msg)
    local macroName = "FIND"
    local macroBody
    local targetName

    if msg and msg ~= "" then
        targetName = msg
        macroBody = "/cleartarget\n/target " .. msg
    else
        targetName = UnitName("target")
        if targetName then
            macroBody = "/cleartarget\n/target " .. targetName
        else
            print("No target selected and no name provided.")
            return
        end
    end

    macroBody = macroBody .. "\n/run if UnitExists(\"target\") and not UnitIsDead(\"target\") and GetRaidTargetIndex(\"target\") == nil then SetRaidTarget(\"target\",8) end"

    local macroIndex = GetMacroIndexByName(macroName)
    if macroIndex > 0 then
        EditMacro(macroIndex, macroName, "Ability_Hunter_SniperShot", macroBody)
    else
        CreateMacro(macroName, "Ability_Hunter_SniperShot", macroBody, nil)
    end

    print(YELLOW_CHAT_LUA .. "FIND:" .. "|r" .. " " .. targetName .. ".")
end

SLASH_TARGETMACRO1 = "/find"
SlashCmdList["TARGETMACRO"] = createTargetMacro


-- ADD TARGET TO EXISTING MACRO
local function addToTargetMacro(msg)
    local macroName = "FIND"
    local macroIndex = GetMacroIndexByName(macroName)
    local macroBody = macroIndex > 0 and GetMacroBody(macroName) or ""
    local targetName

    if msg and msg ~= "" then
        targetName = msg
    else
        targetName = UnitName("target")
        if not targetName then
            print("No target selected and no name provided.")
            return
        end
    end

    local existingTargets = {}
    for target in macroBody:gmatch("/target ([^\n]+)") do
        table.insert(existingTargets, target)
    end

    for _, target in ipairs(existingTargets) do
        if target == targetName then
            print(targetName .. " is already in the target list.")
            return
        end
    end

    if #existingTargets >= 3 then
        print("Cannot add more than 3 targets.")
        return
    end

    if macroBody == "" or not macroBody:find("/cleartarget") then
        macroBody = "/cleartarget\n/target " .. targetName
    else
        macroBody = macroBody:gsub("\n/run .+", "") .. "\n/target " .. targetName
    end

    macroBody = macroBody .. "\n/run if UnitExists(\"target\") and not UnitIsDead(\"target\") and GetRaidTargetIndex(\"target\") == nil then SetRaidTarget(\"target\",8) end"

    if macroIndex > 0 then
        EditMacro(macroIndex, macroName, "Ability_Hunter_SniperShot", macroBody)
    else
        CreateMacro(macroName, "Ability_Hunter_SniperShot", macroBody, nil)
    end

    local newTargetsStr = table.concat(existingTargets, ", ") .. ", " .. targetName
    print(YELLOW_CHAT_LUA .. "FIND:" .. "|r" .. " " .. newTargetsStr .. ".")
end

SLASH_TARGETMACROADD1 = "/find+"
SlashCmdList["TARGETMACROADD"] = addToTargetMacro


-- ASSIST PLAYER
local function assistPlayer(targetName)
    if not targetName then
        targetName = UnitName("target")
        if not targetName then
            print("Please provide a NAME after the command ")
            return false
        end
    end

    local macroName = "ASSIST"
    local macroBody = "/assist " .. targetName

    local macroIndex = GetMacroIndexByName(macroName)
    if macroIndex > 0 then
        EditMacro(macroIndex, macroName, "Ability_DualWield", macroBody)
    else
        CreateMacro(macroName, "Ability_DualWield", macroBody, nil)
    end

    print(YELLOW_CHAT_LUA .. "ASSIST macro updated to" .. "|r" .. " " .. targetName .. ".")
    return true
end


-- FIX SERVER NAME
local function fixServerName(server)
    if server == nil or server == "" then
        return
    end
    local auServer
    if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and server:sub(-3):lower() == "-au" then
        auServer = true
        server = server:sub(1, -4)
    end
    server = server:gsub("'(%u)", function(c) return c:lower() end):gsub("'", ""):gsub("%u", "-%1"):gsub("^[-%s]+", ""):gsub("[^%w%s%-]", ""):gsub("%s", "-"):lower():gsub("%-+", "-")
    server = server:gsub("([a-zA-Z])of%-", "%1-of-")
    if auServer == true then
        server = server .. "-au"
    end
    return server
end


-- GENERATE URL
local function generateURL(type, name, server)
    local url
    if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
        if type == "armory" then
            url = "https://www.classic-armory.org/character/"..region.."/vanilla/"..server.."/"..name
        end
    elseif WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
        if type == "armory" then
            url = "https://worldofwarcraft.blizzard.com/character/"..region.."/"..server.."/"..name
        end
    end
    return url
end


-- SHOW POPUP LINK
local function popupLink(argType, argName, argServer)
    local type = argType
    local name = argName and argName:lower()
    local server = fixServerName(argServer)

    local url = generateURL(type, name, server)
    if not url then return end
    StaticPopupDialogs["PopupLinkDialog"] = {
        text = "Armory Link",
        button1 = "Close",
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        hasEditBox = true,
        OnShow = function(self, data)
            self.editBox:SetText(data.url)
            self.editBox:HighlightText()
            self.editBox:SetFocus()
            self.editBox:SetScript("OnKeyDown", function(_, key)
                local isMac = IsMacClient()
                if key == "ESCAPE" then
                    self:Hide()
                elseif (isMac and IsMetaKeyDown() or IsControlKeyDown()) and key == "C" then
                    self:Hide()
                end
            end)
        end,
    }
    StaticPopup_Show("PopupLinkDialog", "", "", {url = url})
end


-- MODIFY RIGHT-CLICK MENU
local function modifyMenu(menuType, isPlayer)
    Menu.ModifyMenu(menuType, function(owner, rootDescription, contextData)
        local playerName = contextData.name
        local server = contextData.server or GetNormalizedRealmName()

        if rootDescription.HasTitle and not rootDescription:HasTitle("Targeting") then
            rootDescription:CreateDivider()
            rootDescription:CreateTitle("Targeting")
            rootDescription:CreateButton("Assist", function()
                assistPlayer(playerName)
            end)
            rootDescription:CreateButton("Find", function()
                createTargetMacro(playerName)
            end)
            rootDescription:CreateButton("Find Also", function()
                addToTargetMacro(playerName)
            end)
        end

        if rootDescription.HasTitle and not rootDescription:HasTitle("Player Links") then
            rootDescription:CreateDivider()
            rootDescription:CreateTitle("Player Links")
            rootDescription:CreateButton("Armory Link", function()
                popupLink("armory", playerName, server)
            end)
        end
    end)
end


-- APPLY MENU MODIFICATIONS
local chatTypes = {
    "SELF", "PLAYER", "PARTY", "RAID", "RAID_PLAYER", "ENEMY_PLAYER",
    "FOCUS", "FRIEND", "GUILD", "GUILD_OFFLINE", "ARENAENEMY",
    "BN_FRIEND", "CHAT_ROSTER", "COMMUNITIES_GUILD_MEMBER", "COMMUNITIES_WOW_MEMBER"
}

for _, value in ipairs(chatTypes) do
    modifyMenu("MENU_UNIT_"..value, true)
end

local unitTypes = {
    "SELF", "PLAYER", "PARTY", "RAID", "RAID_PLAYER", "ENEMY_PLAYER",
    "FOCUS", "FRIEND", "GUILD", "GUILD_OFFLINE", "ARENAENEMY",
    "BN_FRIEND", "CHAT_ROSTER", "COMMUNITIES_GUILD_MEMBER", "COMMUNITIES_WOW_MEMBER",
    "NPC", "UNIT", "TARGET"
}

for _, value in ipairs(unitTypes) do
    modifyMenu("MENU_UNIT_"..value, value == "PLAYER")
end