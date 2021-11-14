
local IsInGuild = IsInGuild
local IsInInstance = IsInInstance
local SendAddonMessage = SendAddonMessage
local GetNumPartyMembers = GetNumPartyMembers
local GetNumRaidMembers = GetNumRaidMembers
local CreateFrame = CreateFrame

local myname = UnitName("player")
versionIE = GetAddOnMetadata("InspectEquip", "Version")

local spamt = 0
local timeneedtospam = 180
do
    local SendMessageWaitingIE
    local SendRecieveGroupSizeIE = 0
    function SendMessage_IE()
        if GetNumRaidMembers() > 1 then
            local _, instanceType = IsInInstance()
            if instanceType == "pvp" then
                SendAddonMessage("IEVC", versionIE, "BATTLEGROUND")
            else
                SendAddonMessage("IEVC", versionIE, "RAID")
            end
        elseif GetNumPartyMembers() > 0 then
            SendAddonMessage("IEVC", versionIE, "PARTY")
        elseif IsInGuild() then
            SendAddonMessage("IEVC", versionIE, "GUILD")
        end
        SendMessageWaitingIE = nil
    end
    
    local function SendRecieve_IE(_, event, prefix, message, _, sender)
        if event == "CHAT_MSG_ADDON" then
            -- print(argtime)
            if prefix ~= "IEVC" then return end
            if not sender or sender == myname then return end

            local ver = tonumber(versionIE)
            message = tonumber(message)

            local  timenow = time()
            if message and (message > ver) then 
                if timenow - spamt >= timeneedtospam then              
                    print("|cff1784d1".."InspectEquip".."|r".." (".."|cffff0000"..ver.."|r"..") устарел. Вы можете загрузить последнюю версию (".."|cff00ff00"..message.."|r"..") из ".."|cffffcc00".."https://github.com/fxpw/InspectEquip-Sirus".."|r")
                    -- spamt = time()
                    spamt = time()
                end
            end
        end
   

        if event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
            local numRaid = GetNumRaidMembers()
            local num = numRaid > 0 and numRaid or (GetNumPartyMembers() + 1)
            if num ~= SendRecieveGroupSizeIE then
                if num > 1 and num > SendRecieveGroupSizeIE then
                    if not SendMessageWaitingIE then
                        SendMessage_IE()
                        -- SendMessageWaitingBB = E:Delay(10,SendMessage_BB )
                    end
                end
                SendRecieveGroupSizeIE = num
            end
        elseif event == "PLAYER_ENTERING_WORLD" then          
                    if not SendMessageWaitingIE then
                        SendMessage_IE()                       
                        -- SendMessageWaitingBB = E:Delay(10, SendMessage_BB)
                    end
                
            end
    end
           
    local f = CreateFrame("Frame")
    f:RegisterEvent("CHAT_MSG_ADDON")
    f:RegisterEvent("RAID_ROSTER_UPDATE")
    f:RegisterEvent("PARTY_MEMBERS_CHANGED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", SendRecieve_IE)
end