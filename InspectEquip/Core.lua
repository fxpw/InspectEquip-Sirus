-- InspectEquip

InspectEquip = LibStub("AceAddon-3.0"):NewAddon("InspectEquip", "AceConsole-3.0", "AceHook-3.0", "AceTimer-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("InspectEquip")
local IF = PaperDollFrame
local IE = InspectEquip
local IS = InspectEquip_ItemSources --> ItemSources.lua
local WIN = InspectEquip_InfoWindow --> InfoWindow.xml
local TITLE = InspectEquip_InfoWindowTitle
local AVGIL = InspectEquip_InfoWindowAvgItemLevel
local exMod = nil

local slots = { "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot",
                "WristSlot", "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot",
                "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot", "MainHandSlot",
                "SecondaryHandSlot", "RangedSlot" } -- TabardSlot, ShirtSlot
local noEnchantWarningSlots = {
  ["NeckSlot"] = true, ["WaistSlot"] = true, ["Finger0Slot"] = true, ["Finger1Slot"] = true,
  ["Trinket0Slot"] = true, ["Trinket1Slot"] = true, ["RangedSlot"] = true,["SecondaryHandSlot"] = true,

}
--
    local lefthand = {
  ["SecondaryHandSlot"] = true,

}  
    local kolca = {
  ["Finger0Slot"] = true, ["Finger1Slot"] = true,
  

}  
    local pozs = {
  ["WaistSlot"] = true,
  

}  

local lines = {}
local numlines = 0
local curline = 0
local curUnit = nil
local curUnitName = nil
local curUser = nil
local cached = false

local headers = {}
local numheaders = 0

local yoffset = -40
local hooked = false
local autoHidden = false

local origInspectUnit

local tonumber = tonumber
local gmatch = string.gmatch
local tinsert = table.insert
local tsort = table.sort
local Examiner = Examiner

local _,_,_,gameToc = GetBuildInfo()
local namesInitialized = false
local tooltipTimer = nil

local valorPoints = "Valor points"
local outlandToken = "Outland war Token"

--------------------------------------------------------------------------------------

InspectEquipConfig = {}
local defaults = {
  tooltips = true,
  showUnknown = true,
  inspectWindow = true,
  charWindow = true,
  checkEnchants = false,
  listItemLevels = true,
  showAvgItemLevel = true,
   socetc = false,
   soketcpokaz = false,
   checkenchantspokaz = false,
   
   
   
   bug = false,
  razrab = false,
 
  ttR = 1.0,
  ttG = 0.75,
  ttB = 0.0,
}

local options = {
  name = "InspectEquip",
  type = "group",
  args = {
    tooltips = {
      order = 1, type = "toggle", width = "full",
      name = L["Add drop information to tooltips"],
      desc = L["Add item drop information to all item tooltips"],
      get = function() return InspectEquipConfig.tooltips end,
      set = function(_,v) InspectEquipConfig.tooltips = v; if v then IE:HookTooltips() end end,
    },
    showunknown = {
      order = 2, type = "toggle", width = "full",
      name = L["Include unknown items in overview"],
      desc = L["Show items that cannot be categorized in a seperate category"],
      get = function() return InspectEquipConfig.showUnknown end,
      set = function(_,v) InspectEquipConfig.showUnknown = v end,
    },
    inspectwindow = {
      order = 3, type = "toggle", width = "full",
      name = L["Attach to inspect window"],
      desc = L["Show the equipment list when inspecting other characters"],
      get = function() return InspectEquipConfig.inspectWindow end,
      set = function(_,v) InspectEquipConfig.inspectWindow = v end,
    },
    charwindow = {
      order = 4, type = "toggle", width = "full",
      name = L["Attach to character window"],
      desc = L["Also show the InspectEquip panel when opening the character window"],
      get = function() return InspectEquipConfig.charWindow end,
      set = function(_,v) InspectEquipConfig.charWindow = v end,
    },
   
    listitemlevels = {
      order = 5, type = "toggle", width = "full",
      name = L["Show item level in equipment list"],
      desc = L["Show the item level of each item in the equipment panel"],
      get = function() return InspectEquipConfig.listItemLevels end,
      set = function(_,v) InspectEquipConfig.listItemLevels = v end,
    },
    showavgitemlevel = {
      order = 6, type = "toggle", width = "full",
      name = L["Show average item level in equipment list"],
      desc = L["Show the average item level of all items in the equipment panel"],
      get = function() return InspectEquipConfig.showAvgItemLevel end,
      set = function(_,v) InspectEquipConfig.showAvgItemLevel = v end,
    },
	
	 checkenchants = {
      order = 7, type = "toggle", width = "full",
      name = L["Check for unenchanted items"],
      desc = L["Display a warning for unenchanted items"],
      get = function() return InspectEquipConfig.checkEnchants end,
      set = function(_,v) InspectEquipConfig.checkEnchants = v end,
    },
	 checkenchantspokaz = {
      order = 8, type = "toggle", width = "full",
      name = L["Dont hide chants when has"],
      desc = L["Dont hide chants when has2"],
      get = function() return InspectEquipConfig.checkEnchantspokaz end,
      set = function(_,v) InspectEquipConfig.checkEnchantspokaz = v end,
    },
	soketc = {
			order = 9, type = "toggle", width = "full",
			name = L["Check for missing gems"],
			desc = L["Display a warning for items with missing gems"],
			get = function() return InspectEquipConfig.soketc end,
			set = function(_,v) InspectEquipConfig.soketc = v end,
		},
		soketcpokaz = {
			order = 10, type = "toggle", width = "full",
			name = L["If Check for missing gems dont hide names of soket"],
			desc = L["If Check for missing gems dont hide names of soket2"],
			get = function() return InspectEquipConfig.soketcpokaz end,
			set = function(_,v) InspectEquipConfig.soketcpokaz = v end,
		},
	bug = {
      order = 11, type = "toggle", width = "full",
      name = L["Bug"],
      desc = L["Bug2"],
      get = function() return InspectEquipConfig.bug end,
      set = function(_,v) InspectEquipConfig.bug = v end,
    },
	razrab = {
      order = 12, type = "toggle", width = "full",
      name = L["Button for dev"],
      desc = L["Shows enchantment not in the database"],
      get = function() return InspectEquipConfig.razrab end,
      set = function(_,v) InspectEquipConfig.razrab = v end,
    },
	
    tooltipcolor = {
      order = 6, type = "color", 
      name = L["Tooltip text color"],
      get = function() return InspectEquipConfig.ttR, InspectEquipConfig.ttG, InspectEquipConfig.ttB, 1.0 end,
      set = function(_,r,g,b,a)
        InspectEquipConfig.ttR = r
        InspectEquipConfig.ttG = g
        InspectEquipConfig.ttB = b
      end,
    }
  },
}

LibStub("AceConfig-3.0"):RegisterOptionsTable("InspectEquip", options)
LibStub("AceConfigDialog-3.0"):AddToBlizOptions("InspectEquip")



-- taken from https://www.wowinterface.com/forums/showpost.php?p=319704&postcount=2
--------------------------------------------------------------------------------------
local GetNumSockets
do
	-- Generate a unique name for the tooltip:
	local tooltipName = "PhanxScanningTooltip" .. random(100000, 10000000)

	-- Create the hidden tooltip object:
	local tooltip = CreateFrame("GameTooltip", tooltipName, UIParent, "GameTooltipTemplate")
	tooltip:SetOwner(UIParent, "ANCHOR_NONE")

	-- Build a list of the tooltip's texture objects:
	local textures = {}
	for i = 1, 10 do
		textures[i] = _G[tooltipName .. "Texture" .. i]
	end

	-- Set up scanning and caching:
	local numSocketsFromLink = setmetatable({}, { __index = function(t, link)
		-- Send the link to the tooltip:
		tooltip:SetHyperlink(link)

		-- Count how many textures are shown:
		local n = 0
		for i = 1, 10 do
			if textures[i]:IsShown() then
				n = n + 1
			end
		end

		-- Cache and return the count for this link:
		t[link] = n
		return n
	end })

	-- Expose the API:
	function GetNumSockets(link)
		return link and numSocketsFromLink[link]
	end
end

function IE:OnInitialize()
  setmetatable(InspectEquipConfig, {__index = defaults})

  self:SetParent(Examiner or InspectFrame)
  WIN:Hide()
  TITLE:SetText("InspectEquip")

  if Examiner and Examiner.CreateModule then
    exMod = Examiner:CreateModule("InspectEquip")
    exMod.OnCacheLoaded = function(s, entry, unit) 
      if InspectEquipConfig.inspectWindow then
        IE:Inspect("cache", entry)
      end
    end
    exMod.OnClearInspect = function(s) WIN:Hide() end
    exMod.OnInspect = function(s, unit)
      if InspectEquipConfig.inspectWindow then
        IE:SetParent(Examiner); IE:Inspect(unit)
      end
    end
  end

  self:GetItemNames()
  self:RegisterEvent("PLAYER_ENTERING_WORLD")
  self:RegisterEvent("ADDON_LOADED")
end

function IE:OnEnable()
  origInspectUnit = origInspectUnit or InspectUnit
  InspectUnit = function(...) IE:InspectUnit(...) end 
  self:SecureHookScript(PaperDollFrame, "OnShow", "PaperDollFrame_OnShow")
  self:SecureHookScript(PaperDollFrame, "OnHide", "PaperDollFrame_OnHide")
  self:SecureHookScript(GearManagerDialog, "OnShow", "GearManagerDialog_OnShow")
  self:SecureHookScript(GearManagerDialog, "OnHide", "GearManagerDialog_OnHide")
  if OutfitterFrame then
    self:SecureHookScript(OutfitterFrame, "OnShow", "GearManagerDialog_OnShow")
    self:SecureHookScript(OutfitterFrame, "OnHide", "GearManagerDialog_OnHide")
  end
  self:RegisterEvent("UNIT_INVENTORY_CHANGED")
   
  
end

function IE:OnDisable()
  InspectUnit = origInspectUnit
  if hooked then
    hooked = false
    self:Unhook("InspectFrame_UnitChanged")
  end
  self:UnhookAll()
  self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
  self:CancelAllTimers()
  WIN:Hide()
end

local entered = false

function IE:PLAYER_ENTERING_WORLD()
  entered = true
  self:ScheduleTooltipHook()
  self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function IE:ADDON_LOADED(e, name)
  if entered then
    self:ScheduleTooltipHook()
  end
end

-- Ugly hack, but some addons override the OnTooltipSetItem handler on
-- ItemRefTooltip, breaking IE. Using this timer, IE hopefully hooks after them.
function IE:ScheduleTooltipHook()
  if InspectEquipConfig.tooltips then
    if tooltipTimer then
      self:CancelTimer(tooltipTimer, true)
    end
    tooltipTimer = self:ScheduleTimer('HookTooltips', 3)
  end
end

function IE:SetParent(frame)
  WIN:SetParent(frame)
  WIN:ClearAllPoints()
  WIN:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, 0)
end

function IE:NewLine()
  local row = CreateFrame("Frame", nil, WIN)
  row:SetHeight(12)
  row:SetWidth(200)
  row:SetPoint("TOPLEFT", WIN, "TOPLEFT", 15, yoffset)

  local txt = row:CreateFontString(nil, "ARTWORK")
  txt:SetJustifyH("LEFT")
  txt:SetFontObject(GameFontHighlightSmall)
  txt:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
  
  row.text = txt
  yoffset = yoffset - 15
  numlines = numlines + 1
  lines[numlines] = row
  
  row:EnableMouse(true)
  row:SetScript("OnEnter", IE.Line_OnEnter)
  row:SetScript("OnLeave", IE.Line_OnLeave)
  row:SetScript("OnMouseDown", IE.Line_OnClick)
end

function IE:ResetDisplay()
  for i = 1, numlines do
    lines[i].text:SetText("")
    lines[i]:Hide()
  end
  curline = 0
end

function IE:AddLine(text, link, item)
  curline = curline + 1
  if curline > numlines then
    self:NewLine()
  end
  local line = lines[curline]
  line.link = link
  line.item = item
  line.text:SetText(text)
  line:SetWidth(line.text:GetStringWidth())
  line:SetFrameLevel(WIN:GetFrameLevel() + 1)
  line:Show()
end

function IE:FullUnitName(name, realm)
  if realm and realm ~= "" then
    return name .. "-" .. realm
  else
    return name
  end
end

function IE:GetExaminerCache(unit)
  local name, realm = UnitName(unit)
  return Examiner_Cache and Examiner_Cache[self:FullUnitName(name, realm)]
end

function IE:InspectUnit(unit, ...)
  origInspectUnit(unit, ...)

  if InspectEquipConfig.inspectWindow then
    self:SetParent(Examiner or InspectFrame)
    WIN:Hide()
    if not hooked and InspectFrame_UnitChanged then
      hooked = true
      self:SecureHook("InspectFrame_UnitChanged")
    end 
	
	self:Inspect(unit)
  end
end
-- local clock = os.clock
-- function sleep(n)  -- seconds
  -- local t0 = clock()
  -- while clock() - t0 <= n do end
-- end

function IE:InspectFrame_UnitChanged()
  if InspectFrame.unit and InspectEquipConfig.inspectWindow then
	self:InspectUnit(InspectFrame.unit) 
  else
    WIN:Hide()
  end
end


function IE:PaperDollFrame_OnShow()
  if InspectEquipConfig.charWindow then  
    IE:SetParent(CharacterFrame)	
	IE:Inspect("player")
  end
-- local slotId = GetInventorySlotInfo("MainHandSlot")
--/dump local link = GetInventoryItemLink("player", 5)
--local itemId, enchantId, gem1, gem2, gem3, gem4,gem5,gem6 = strsplit(":",link)
--print (itemId, enchantId, gem1, gem2, gem3, gem4,gem5,gem6 )
--end
-- /run for i=1,GameTooltip:NumLines()do local mytext=_G["GameTooltipTextLeft"..i] local text=mytext:GetText() print(text)end

-- /dump  GetInventoryItemLink("Player", 5)

-- /dump ItemTextGetText("player", 5)
end

function IE:PaperDollFrame_OnHide()
  if WIN:GetParent() == CharacterFrame then
    WIN:Hide()
    autoHidden = false
  end
end

function IE:GearManagerDialog_OnShow()
  if WIN:GetParent() == CharacterFrame and WIN:IsShown() then
    WIN:Hide()
    autoHidden = true
  end
end

function IE:GearManagerDialog_OnHide()
  if autoHidden and WIN:GetParent() == CharacterFrame then
    WIN:Show()
    autoHidden = false
  end
end

function IE:UNIT_INVENTORY_CHANGED(event, unit)
  if (unit == "player") and (WIN:IsVisible() or autoHidden) and (WIN:GetParent() == CharacterFrame) then
    IE:Inspect("player")
  elseif(unit == "target") and (WIN:IsVisible() or autoHidden) and (WIN:GetParent() == InspectFrame) then
    IE:Inspect("target")
  end
end

function IE:Inspect(unit, entry)
  self.UpdateInspectTimer = C_Timer:NewTicker(0.001, function()
  local unitName, unitRealm
  cached = (unit == "cache")

  if (cached and (not entry)) or (not self:IsEnabled()) then
    WIN:Hide()
    return
  end

  local cacheItems = cached and entry.Items or nil

  if cached then
    unitName, unitRealm = entry.name, entry.realm
  else
    if (not unit or not UnitExists(unit)) then
      unit = "player"
    end
    unitName, unitRealm = UnitName(unit)

    if not CanInspect(unit) then
      entry = self:GetExaminerCache(unit)
      if entry then
        cached = true
        cacheItems = entry.Items
      end
    else
	 -- ClearInspectPlayer()
	 -- InspectUnit("target")
      
      -- NotifyInspect(unit)
    end
  end
  if unitRealm == "" then unitRealm = nil end
  curUnit = unit
  curUnitName = unitName
  curUser = self:FullUnitName(unitName, unitRealm)
  TITLE:SetText("InspectEquip |cFFD00000(for Sirus.su)|r:  " .. curUser .. (cached and " (Cache)" or ""))

  self:ResetDisplay()

  local items = {}
  local itemsFound = false
  local getItem
  if cached then
    getItem = function(slot)
      local istr = cacheItems[slot]
      if istr then
        local itemId = tonumber(istr:match("item:(%d+)"))
        return select(2, GetItemInfo(istr)) or ("[" .. itemId .. "]")
      else
        return nil
      end
    end
  else
    getItem = function(slot) return GetInventoryItemLink(unit, GetInventorySlotInfo(slot)) end
  end

  local calciv = InspectEquipConfig.showAvgItemLevel
  local iLevelSum, iCount = 0,0

  for _,slot in pairs(slots) do
    local itemLink = getItem(slot)
--	print (itemLink)
--	print( itemLink, lootTable, boss, cost, slot,enchantId)
    if itemLink then
      local sources = self:FindItem(itemLink, InspectEquipConfig.showUnknown)
      if sources then
        local src, subsrc, lootTable, boss, cost, setname = unpack(sources[1])
--		 print (src, subsrc, lootTable, boss, cost, setname)
        local enchantId = tonumber(itemLink:match("Hitem:%d+:(%d+):"))
        itemsFound = true
		---------------------------------------------------------------------сокеты
		
		
		-- local _, _, _, gem1, gem2, gem3, gem4 = strsplit(":", strmatch(itemLink, "|H(.-)|h"))
				-- local numFilledSockets = (tonumber(gem1) or 0) + (tonumber(gem2) or 0) + (tonumber(gem3) or 0) + (tonumber(gem4) or 0)
				local kolvo = GetNumSockets(itemLink)
				
				local _, _, _, gem1, gem2, gem3, gem4 = strsplit(":", strmatch(itemLink, "|H(.-)|h"))
				local numFilledSockets1 = (tonumber(gem1) or 0) 
				local perehod1 = numFilledSockets1
				local unsocet1 =  perehod1
				
				local numFilledSockets2 = (tonumber(gem2) or 0) 
				local perehod2 = numFilledSockets2
				local unsocet2 =  perehod2
			
				local numFilledSockets3 = (tonumber(gem3) or 0)
				local perehod3 = numFilledSockets3
				local unsocet3 =  perehod3
				
				local numFilledSockets4 = (tonumber(gem4) or 0)
				local perehod4 = numFilledSockets4
				local unsocet4 =  perehod4  
				
				
				-- gem1= (tonumber(gem1) or 0)
				
				
		---------------------------------------------------------------------сокеты
        if items[src] == nil then
          items[src] = {count = 0}
        end
        cat = items[src]
        if subsrc then
          -- subcategory
          if lootTable == L["Heroic"] then subsrc = subsrc .. " (" .. lootTable .. ")" end
          if cat[subsrc] == nil then
            cat[subsrc] = {count = 0, hasItems = true}
          end
          cat.count = cat.count + 1
          local subcat = cat[subsrc]
          subcat.count = subcat.count + 1
          subcat[subcat.count] = {link = itemLink, lootTable = lootTable, boss = boss, cost = cost, slot = slot, enchant = enchantId,  unsocet1 = unsocet1,  unsocet2 = unsocet2,  unsocet3 = unsocet3,  unsocet4 = unsocet4,kolvo=kolvo, perehod1=perehod1,perehod2=perehod2,perehod3=perehod3,perehod4=perehod4}
		  -- print( itemLink, lootTable, boss, cost, slot,enchantId)
        else
          -- no subcategory
          cat.hasItems = true
          cat.count = cat.count + 1
          cat[cat.count] = {link = itemLink, lootTable = lootTable, boss = boss, cost = cost, slot = slot, enchant = enchantId,   unsocet1 = unsocet1, unsocet2 = unsocet2,  unsocet3 = unsocet3,  unsocet4 = unsocet4,kolvo=kolvo, perehod1=perehod1,perehod2=perehod2,perehod3=perehod3,perehod4=perehod4}
		  -- print( itemLink, lootTable, boss, cost, slot,enchantId)
        end
      end
      if calciv then
        local _,_,rar,lvl = GetItemInfo(itemLink)
        if lvl then
          iLevelSum = iLevelSum + lvl
          iCount = iCount + 1
        end
      end
    end
  end

  if itemsFound then
    self:AddCats(items, "")
    if calciv and iCount > 0 then
      local avgLvl = iLevelSum / iCount
      AVGIL:SetText(L["Avg. Item Level"] .. ": " .. string.format("%.2f", avgLvl))
      AVGIL:Show()
    else
      AVGIL:Hide()
    end
    self:FixWindowSize()
    if WIN:GetParent() == CharacterFrame and (GearManagerDialog:IsVisible() or (OutfitterFrame and OutfitterFrame:IsVisible())) then
      autoHidden = true
    else
      WIN:Show()
    end
  else
    WIN:Hide()
  end
  end,5)
end

function IE:AddCats(tab, prefix)
  local t = {}
  for cat, items in pairs(tab) do
    if cat ~= "count" then
      tinsert(t, {name = cat, items = items})
    end
  end
  tsort(t, function(a,b) return a.items.count < b.items.count end)

  for i = #t, 1, -1 do
    local cat = t[i]
    self:AddLine(prefix .. cat.name .. " (" .. cat.items.count .. ")")
    if cat.items.hasItems then
      self:AddItems(cat.items, prefix .. "  ")
    else
      self:AddCats(cat.items, prefix .. "  ")
    end
  end
end
-------------------------------------------
-----------------------
--
--
--
--
--
--
--[[checkenchants =   - Есть чарка   "..
     
     InspectEquipConfig.checkEnchants
  

	soketc = ..item.enchant.."   "..item.unsocet1.."   "..item.unsocet2.."   "..item.unsocet3.."   "..item.unsocet4.."   "
		
		InspectEquipConfig.soketc 
		
		
	seid = ..item.enchant..
    
      get = function() return InspectEquipConfig.seid 
     
   
	razrab 
      InspectEquipConfig.razrab
    
    },


]]--

function IE:AddItems(tab, padding,event,unit)
  for i = 1, tab.count do
    local item = tab[i]
	local suffix = ""
	-- if InspectEquipConfig.seid  then  -------------------------------------------- айди инчантов включены ли
	-- suffix = suffix..":  "..item.enchant .."  :"
	-- end
	
	if InspectEquipConfig.soketc and InspectEquipConfig.soketcpokaz   then                              -------------------- сокеты включены ли   
	if (item.kolvo == 4 ) then                         ---------- если 4 гема          
													---------- для 1 гема
	if   (item.unsocet1 == 0) then
	item.unsocet1 = "|cffff0000  нет |r"
	------------------------------------------------------------------------------ все сокеты бк и +50
	elseif (item.unsocet1 == 3734) -- 58 спд
	or (item.unsocet1 == 9022)   --  42 спд
	or (item.unsocet1 == 3745)   --   50 рпб
	or (item.unsocet1 == 3739)   --   50 хасты
	or (item.unsocet1 == 3742)   --   50 хит
	or (item.unsocet1 == 3293)   --   75 вын
	or (item.unsocet1 == 3732)  --    50 силы
	or (item.unsocet1 == 3738)  --    крита силы
	or (item.unsocet1 == 3297)  --    ап 100
	or (item.unsocet1 == 3733)  --    50 лвк
	
	then
	item.unsocet1 = " бк "
	
	--------------------------------------        исключения                 
	
	elseif  (item.unsocet1 == 6070) or (item.unsocet1 == 6054) or (item.unsocet1 == 6090)  or  (item.unsocet1 == 6057) then
	item.unsocet1 = "|cffff0000  лк |r"
	
	elseif (item.unsocet1 < 4000) and (item.unsocet1 > 0 )   then 
	item.unsocet1 = "|cffff0000  лк |r"
	
	elseif (item.unsocet1 > 4000) then
		item.unsocet1 = " бк "	
	end
	
	--------------------------------------------- вт гем
	if   (item.unsocet2 == 0) then
	item.unsocet2 = "|cffff0000  нет |r"
	
	elseif (item.unsocet2 == 3734) -- 58 спд
	or (item.unsocet2 == 9022)   --  42 спд
	or (item.unsocet2 == 3745)   --   50 рпб
	or (item.unsocet2 == 3739)   --   50 хасты
	or (item.unsocet2 == 3742)   --   50 хит
	or (item.unsocet2 == 3293)   --   75 вын
	or (item.unsocet2 == 3732)  --    50 силы
	or (item.unsocet2 == 3738)  --    крита силы
	or (item.unsocet2 == 3297)  --    ап 100
	or (item.unsocet2 == 3733)  --    50 лвк
	then
	item.unsocet2 = " бк "              
	
	elseif  (item.unsocet2 == 6070) or (item.unsocet2 == 6054) or (item.unsocet2 == 6090)  or  (item.unsocet2 == 6057) then
	item.unsocet2 = "|cffff0000  лк |r"
	elseif (item.unsocet2 < 4000) and (item.unsocet2 > 0 )  then 
	item.unsocet2 = "|cffff0000  лк |r"
	
	elseif (item.unsocet2 > 4000) then
		item.unsocet2 = " бк "	
	end
	
	------------------------------------------- тр гем
	if   (item.unsocet3 == 0) then
	item.unsocet3 = "|cffff0000  нет |r"
	elseif (item.unsocet3 == 3734) -- 58 спд
	or (item.unsocet3 == 9022)   --  42 спд
	or (item.unsocet3 == 3745)   --   50 рпб
	or (item.unsocet3 == 3739)   --   50 хасты
	or (item.unsocet3 == 3742)   --   50 хит
	or (item.unsocet3 == 3293)   --   75 вын
	or (item.unsocet3 == 3732)  --    50 силы
	or (item.unsocet3 == 3738)  --    крита силы
	or (item.unsocet3 == 3297)  --    ап 100
	or (item.unsocet3 == 3733)  --    50 лвк
	
	
	then
	item.unsocet3 = " бк "
	
	--------------------------------------        исключения                 
	
	elseif  (item.unsocet3 == 6070) or (item.unsocet3 == 6054) or (item.unsocet3 == 6090)  or  (item.unsocet3 == 6057) then
	item.unsocet3 = "|cffff0000  лк |r"
	
	elseif (item.unsocet3 < 4000) and (item.unsocet3 > 0 )  then 
	item.unsocet3 = "|cffff0000  лк |r"
	
	elseif (item.unsocet3 > 4000) then
		item.unsocet3 = " бк "	
	end
	------------------------------------------- чт гем
	if   (item.unsocet4 == 0) then
	item.unsocet4 = "|cffff0000  нет |r"
	elseif (item.unsocet4 == 3734) -- 58 спд
	or (item.unsocet4 == 9022)   --  42 спд
	or (item.unsocet4 == 3745)   --   50 рпб
	or (item.unsocet4 == 3742)   --   50 хит
	or (item.unsocet4 == 3739)   --   50 хасты
	or (item.unsocet4 == 3293)   --   75 вын
	or (item.unsocet4 == 3732)  --    50 силы
	or (item.unsocet4 == 3738)  --    крита силы
	or (item.unsocet4 == 3297)  --    ап 100
	or (item.unsocet4 == 3733)  --    50 лвк
	
	then
	item.unsocet4 = " бк "
	
	--------------------------------------        исключения                 
	
	elseif  (item.unsocet4 == 6070) or (item.unsocet4 == 6054) or (item.unsocet4 == 6090)  or  (item.unsocet4 == 6057) then
	item.unsocet4 = "|cffff0000  лк |r"
	
	elseif (item.unsocet4 < 4000) and (item.unsocet4 > 0 )  then 
	item.unsocet4 = "|cffff0000  лк |r"
	
	elseif (item.unsocet4 > 4000) then
		item.unsocet4 = " бк "

	end
	
	
	elseif (item.kolvo == 3 ) then
	--------------------------------------------- пр гем
	
	if   (item.unsocet1 == 0) then
	item.unsocet1 = "|cffff0000  нет |r"
	elseif (item.unsocet1 == 3734) -- 58 спд
	or (item.unsocet1 == 9022)   --  42 спд
	or (item.unsocet1 == 3745)   --   50 рпб
	or (item.unsocet1 == 3742)   --   50 хит
	or (item.unsocet1 == 3739)   --   50 хасты
	or (item.unsocet1 == 3293)   --   75 вын
	or (item.unsocet1 == 3732)  --    50 силы
	or (item.unsocet1 == 3738)  --    крита силы
	or (item.unsocet1 == 3297)  --    ап 100
	or (item.unsocet1 == 3733)  --    50 лвк
	
	
	then
	item.unsocet1 = " бк "
	
	--------------------------------------        исключения                 
	
	elseif  (item.unsocet1 == 6070) or (item.unsocet1 == 6054) or (item.unsocet1 == 6090)  or  (item.unsocet1 == 6057) then
	item.unsocet1 = "|cffff0000  лк |r"
	elseif (item.unsocet1 < 4000) and (item.unsocet1 > 0 )  then 
	item.unsocet1 = "|cffff0000  лк |r"
	
	elseif (item.unsocet1 > 4000) then
		item.unsocet1 = " бк "	
	end
	--------------------------------------------- вт гем
	if   (item.unsocet2 == 0) then
	item.unsocet2 = "|cffff0000  нет |r"
	elseif (item.unsocet2 == 3734) -- 58 спд
	or (item.unsocet2 == 9022)   --  42 спд
	or (item.unsocet2 == 3745)   --   50 рпб
	or (item.unsocet2 == 3742)   --   50 хит
	or (item.unsocet2 == 3739)   --   50 хасты
	or (item.unsocet2 == 3293)   --   75 вын
	or (item.unsocet2 == 3732)  --    50 силы
	or (item.unsocet2 == 3738)  --    крита силы
	or (item.unsocet2 == 3297)  --    ап 100
	or (item.unsocet2 == 3733)  --    50 лвк
	
	then
	item.unsocet2 = " бк "
	
	--------------------------------------        исключения                 
	
	elseif  (item.unsocet2 == 6070) or  (item.unsocet2 == 6054) or(item.unsocet2 == 6090)  or  (item.unsocet2 == 6057) then
	item.unsocet2 = "|cffff0000  лк |r"
	elseif (item.unsocet2 < 4000) and (item.unsocet2 > 0 )  then 
	item.unsocet2 = "|cffff0000  лк |r"
	
	elseif (item.unsocet2 > 4000) then
		item.unsocet2 = " бк "	
	end
	
	------------------------------------------- тр гем
	if   (item.unsocet3 == 0) then
	item.unsocet3 = "|cffff0000  нет |r"
	elseif (item.unsocet3 == 3734) -- 58 спд
	or (item.unsocet3 == 9022)   --  42 спд
	or (item.unsocet3 == 3745)   --   50 рпб
	or (item.unsocet3 == 3742)   --   50 хит
	or (item.unsocet3 == 3739)   --   50 хасты
	or (item.unsocet3 == 3293)   --   75 вын
	or (item.unsocet3 == 3732)  --    50 силы
	or (item.unsocet3 == 3738)  --    крита силы
	or (item.unsocet3 == 3297)  --    ап 100
	or (item.unsocet3 == 3733)  --    50 лвк
	
	
	then
	item.unsocet3 = " бк "
	
	--------------------------------------        исключения                 
	
	elseif  (item.unsocet3 == 6070) or  (item.unsocet3 == 6054) or (item.unsocet3 == 6090)  or  (item.unsocet3 == 6057) then
	item.unsocet3 = "|cffff0000  лк |r"
	
	elseif (item.unsocet3 < 4000) and (item.unsocet3 > 0 )  then 
	item.unsocet3 = "|cffff0000  лк |r"
	
	elseif (item.unsocet3 > 4000) then
		item.unsocet3 = " бк "	
	end
	
	elseif (item.kolvo == 2 ) then
	--------------------------------------------- пр гем
	
	if   (item.unsocet1 == 0) then
	item.unsocet1 = "|cffff0000  нет |r"
	elseif (item.unsocet1 == 3734) -- 58 спд
	or (item.unsocet1 == 9022)   --  42 спд
	or (item.unsocet1 == 3745)   --   50 рпб
	or (item.unsocet1 == 3742)   --   50 хит
	or (item.unsocet1 == 3739)   --   50 хасты
	or (item.unsocet1 == 3293)   --   75 вын
	or (item.unsocet1 == 3732)  --    50 силы
	or (item.unsocet1 == 3738)  --    крита силы
	or (item.unsocet1 == 3297)  --    ап 100
	or (item.unsocet1 == 3733)  --    50 лвк
	
	
	then
	item.unsocet1 = " бк "
	
	--------------------------------------        исключения                 
	
	elseif  (item.unsocet1 == 6070) or  (item.unsocet1 == 6054) or (item.unsocet1 == 6090)  or  (item.unsocet1 == 6057) then
	item.unsocet1 = "|cffff0000  лк |r"
	elseif (item.unsocet1 < 4000) and (item.unsocet1 > 0 )  then 
	item.unsocet1 = "|cffff0000  лк |r"
	
	elseif (item.unsocet1 > 4000) then
		item.unsocet1 = " бк "	
	end
	--------------------------------------------- вт гем
	if   (item.unsocet2 == 0) then
	item.unsocet2 = "|cffff0000  нет |r"
	elseif (item.unsocet2 == 3734) -- 58 спд
	or (item.unsocet2 == 9022)   --  42 спд
	or (item.unsocet2 == 3745)   --   50 рпб
	or (item.unsocet2 == 3739)   --   50 хасты
	or (item.unsocet2 == 3742)   --   50 хит
	or (item.unsocet2 == 3293)   --   75 вын
	or (item.unsocet2 == 3732)  --    50 силы
	or (item.unsocet2 == 3738)  --    крита силы
	or (item.unsocet2 == 3297)  --    ап 100
	or (item.unsocet2 == 3733)  --    50 лвк
	
	
	then
	item.unsocet2 = " бк "
	
	--------------------------------------        исключения                 
	
	elseif  (item.unsocet2 == 6070) or (item.unsocet2 == 6054) or (item.unsocet2 == 6090)  or  (item.unsocet2 == 6057) then
	item.unsocet1 = "|cffff0000  лк |r"
	elseif (item.unsocet2 < 4000) and (item.unsocet2 > 0 )  then 
	item.unsocet2 = "|cffff0000  лк |r"
	
	elseif (item.unsocet2 > 4000) then
		item.unsocet2 = " бк "	
	end
	 elseif (item.kolvo == 1 ) then
	--------------------------------------------- пр гем
	
	if   (item.unsocet1 == 0) then
	item.unsocet1 = "|cffff0000  нет |r"
	elseif (item.unsocet1 == 3734) -- 58 спд
	or (item.unsocet1 == 9022)   --  42 спд
	or (item.unsocet1 == 3745)   --   50 рпб
	or (item.unsocet1 == 3739)   --   50 хасты
	or (item.unsocet1 == 3742)   --   50 хит
	or (item.unsocet1 == 3293)   --   75 вын
	or (item.unsocet1 == 3732)  --    50 силы
	or (item.unsocet1 == 3738)  --    крита силы
	or (item.unsocet1 == 3297)  --    ап 100
	or (item.unsocet1 == 3733)  --    50 лвк
	
	
	then
	item.unsocet1 = " бк "
	
	--------------------------------------        исключения                 
	
	elseif  (item.unsocet1 == 6070) or  (item.unsocet1 == 6054) or (item.unsocet1 == 6090)  or  (item.unsocet1 == 6057) then
	item.unsocet1 = "|cffff0000  лк |r"
	elseif (item.unsocet1 < 4000) and (item.unsocet1 > 0 )  then 
	item.unsocet1 = "|cffff0000  лк |r"
	
	elseif (item.unsocet1 > 4000) then
		item.unsocet1 = " бк "	
	end
	end
	
	if (item.unsocet4 == 0) then
	item.unsocet4 = " "
	else item.unsocet4 = item.unsocet4 
	end
	
	if (item.unsocet3 == 0) then
	item.unsocet3 = " "
	else item.unsocet3 = item.unsocet3 
	end
	
	if (item.unsocet2 == 0) then
	item.unsocet2 = " "
	else item.unsocet2 = item.unsocet2 
	end
	
	if (item.unsocet1 == 0) then
	item.unsocet1 = " "
	else item.unsocet1 = item.unsocet1 
	end
	
     suffix = suffix.."   "..item.unsocet1.."   "..item.unsocet2.."   "..item.unsocet3.."   "..item.unsocet4.."   " ------ в суффикс добавляется сокеты
	 
	
	
	
	
	elseif InspectEquipConfig.soketc and not InspectEquipConfig.soketcpokaz   then  
	                         -------------------- сокеты  включены ли    не показывать если есть бк
	if (item.kolvo == 4 ) then                         ---------- если 4 гема          
													---------- для 1 гема
	if   (item.unsocet1 == 0) then
	item.unsocet1 = "|cffff0000  нет |r"
	------------------------------------------------------------------------------ все сокеты бк и +50
	elseif (item.unsocet1 == 3734) -- 58 спд
	or (item.unsocet1 == 9022)   --  42 спд
	or (item.unsocet1 == 3745)   --   50 рпб
	or (item.unsocet1 == 3739)   --   50 хасты
	or (item.unsocet1 == 3742)   --   50 хит
	or (item.unsocet1 == 3293)   --   75 вын
	or (item.unsocet1 == 3732)  --    50 силы
	or (item.unsocet1 == 3738)  --    крита силы
	or (item.unsocet1 == 3297)  --    ап 100
	or (item.unsocet1 == 3733)  --    50 лвк
	then
	item.unsocet1 = "  "
	
	--------------------------------------        исключения                 
	
	elseif  (item.unsocet1 == 6070) or (item.unsocet1 == 6054) or (item.unsocet1 == 6090)  or  (item.unsocet1 == 6057) then
	item.unsocet1 = "|cffff0000  лк |r"
	
	elseif (item.unsocet1 < 4000) and (item.unsocet1 > 0 )   then 
	item.unsocet1 = "|cffff0000  лк |r"
	
	elseif (item.unsocet1 > 4000) then
		item.unsocet1 = "  "	
	end
	
	--------------------------------------------- вт гем
	if   (item.unsocet2 == 0) then
	item.unsocet2 = "|cffff0000  нет |r"
	
	elseif (item.unsocet2 == 3734) -- 58 спд
	or (item.unsocet2 == 9022)   --  42 спд
	or (item.unsocet2 == 3745)   --   50 рпб
	or (item.unsocet2 == 3739)   --   50 хасты
	or (item.unsocet2 == 3742)   --   50 хит
	or (item.unsocet2 == 3293)   --   75 вын
	or (item.unsocet2 == 3732)  --    50 силы
	or (item.unsocet2 == 3738)  --    крита силы
	or (item.unsocet2 == 3297)  --    ап 100
	or (item.unsocet2 == 3733)  --    50 лвк
	then
	item.unsocet2 = "  "              
	
	elseif  (item.unsocet2 == 6070) or (item.unsocet2 == 6054) or (item.unsocet2 == 6090)  or  (item.unsocet2 == 6057) then
	item.unsocet2 = "|cffff0000  лк |r"
	elseif (item.unsocet2 < 4000) and (item.unsocet2 > 0 )  then 
	item.unsocet2 = "|cffff0000  лк |r"
	
	elseif (item.unsocet2 > 4000) then
		item.unsocet2 = "  "	
	end
	
	------------------------------------------- тр гем
	if   (item.unsocet3 == 0) then
	item.unsocet3 = "|cffff0000  нет |r"
	elseif (item.unsocet3 == 3734) -- 58 спд
	or (item.unsocet3 == 9022)   --  42 спд
	or (item.unsocet3 == 3745)   --   50 рпб
	or (item.unsocet3 == 3739)   --   50 хасты
	or (item.unsocet3 == 3742)   --   50 хит
	or (item.unsocet3 == 3293)   --   75 вын
	or (item.unsocet3 == 3732)  --    50 силы
	or (item.unsocet3 == 3738)  --    крита силы
	or (item.unsocet3 == 3297)  --    ап 100
	or (item.unsocet3 == 3733)  --    50 лвк
	
	
	then
	item.unsocet3 = "  "
	
	--------------------------------------        исключения                 
	
	elseif  (item.unsocet3 == 6070) or (item.unsocet3 == 6054) or (item.unsocet3 == 6090)  or  (item.unsocet3 == 6057) then
	item.unsocet3 = "|cffff0000  лк |r"
	
	elseif (item.unsocet3 < 4000) and (item.unsocet3 > 0 )  then 
	item.unsocet3 = "|cffff0000  лк |r"
	
	elseif (item.unsocet3 > 4000) then
		item.unsocet3 = "  "	
	end
	------------------------------------------- чт гем
	if   (item.unsocet4 == 0) then
	item.unsocet4 = "|cffff0000  нет |r"
	elseif (item.unsocet4 == 3734) -- 58 спд
	or (item.unsocet4 == 9022)   --  42 спд
	or (item.unsocet4 == 3745)   --   50 рпб
	or (item.unsocet4 == 3742)   --   50 хит
	or (item.unsocet4 == 3739)   --   50 хасты
	or (item.unsocet4 == 3293)   --   75 вын
	or (item.unsocet4 == 3732)  --    50 силы
	or (item.unsocet4 == 3738)  --    крита силы
	or (item.unsocet4 == 3297)  --    ап 100
	or (item.unsocet4 == 3733)  --    50 лвк
	
	
	then
	item.unsocet4 = "  "
	
	--------------------------------------        исключения                 
	
	elseif  (item.unsocet4 == 6070) or (item.unsocet4 == 6054) or (item.unsocet4 == 6090)  or  (item.unsocet4 == 6057) then
	item.unsocet4 = "|cffff0000  лк |r"
	
	elseif (item.unsocet4 < 4000) and (item.unsocet4 > 0 )  then 
	item.unsocet4 = "|cffff0000  лк |r"
	
	elseif (item.unsocet4 > 4000) then
		item.unsocet4 = "  "

	end
	
	elseif (item.kolvo == 3 ) then
	--------------------------------------------- пр гем
	
	if   (item.unsocet1 == 0) then
	item.unsocet1 = "|cffff0000  нет |r"
	elseif (item.unsocet1 == 3734) -- 58 спд
	or (item.unsocet1 == 9022)   --  42 спд
	or (item.unsocet1 == 3745)   --   50 рпб
	or (item.unsocet1 == 3742)   --   50 хит
	or (item.unsocet1 == 3739)   --   50 хасты
	or (item.unsocet1 == 3293)   --   75 вын
	or (item.unsocet1 == 3732)  --    50 силы
	or (item.unsocet1 == 3738)  --    крита силы
	or (item.unsocet1 == 3297)  --    ап 100
	or (item.unsocet1 == 3733)  --    50 лвк
	
	
	then
	item.unsocet1 = "  "
	
	--------------------------------------        исключения                 
	
	elseif  (item.unsocet1 == 6070) or (item.unsocet1 == 6054) or (item.unsocet1 == 6090)  or  (item.unsocet1 == 6057) then
	item.unsocet1 = "|cffff0000  лк |r"
	elseif (item.unsocet1 < 4000) and (item.unsocet1 > 0 )  then 
	item.unsocet1 = "|cffff0000  лк |r"
	
	elseif (item.unsocet1 > 4000) then
		item.unsocet1 = "  "	
	end
	--------------------------------------------- вт гем
	if   (item.unsocet2 == 0) then
	item.unsocet2 = "|cffff0000  нет |r"
	elseif (item.unsocet2 == 3734) -- 58 спд
	or (item.unsocet2 == 9022)   --  42 спд
	or (item.unsocet2 == 3745)   --   50 рпб
	or (item.unsocet2 == 3742)   --   50 хит
	or (item.unsocet2 == 3739)   --   50 хасты
	or (item.unsocet2 == 3293)   --   75 вын
	or (item.unsocet2 == 3732)  --    50 силы
	or (item.unsocet2 == 3738)  --    крита силы
	or (item.unsocet2 == 3297)  --    ап 100
	or (item.unsocet2 == 3733)  --    50 лвк
	
	
	then
	item.unsocet2 = "  "
	
	--------------------------------------        исключения                 
	
	elseif  (item.unsocet2 == 6070) or (item.unsocet2 == 6054) or (item.unsocet2 == 6090)  or  (item.unsocet2 == 6057) then
	item.unsocet2 = "|cffff0000  лк |r"
	elseif (item.unsocet2 < 4000) and (item.unsocet2 > 0 )  then 
	item.unsocet2 = "|cffff0000  лк |r"
	
	elseif (item.unsocet2 > 4000) then
		item.unsocet2 = "  "	
	end
	
	------------------------------------------- тр гем
	if   (item.unsocet3 == 0) then
	item.unsocet3 = "|cffff0000  нет |r"
	elseif (item.unsocet3 == 3734) -- 58 спд
	or (item.unsocet3 == 9022)   --  42 спд
	or (item.unsocet3 == 3745)   --   50 рпб
	or (item.unsocet3 == 3742)   --   50 хит
	or (item.unsocet3 == 3739)   --   50 хасты
	or (item.unsocet3 == 3293)   --   75 вын
	or (item.unsocet3 == 3732)  --    50 силы
	or (item.unsocet3 == 3738)  --    крита силы
	or (item.unsocet3 == 3297)  --    ап 100
	or (item.unsocet3 == 3733)  --    50 лвк
	
	
	then
	item.unsocet3 = "  "
	
	--------------------------------------        исключения                 
	
	elseif  (item.unsocet3 == 6070) or (item.unsocet3 == 6054) or (item.unsocet3 == 6090)  or  (item.unsocet3 == 6057) then
	item.unsocet3 = "|cffff0000  лк |r"
	
	elseif (item.unsocet3 < 4000) and (item.unsocet3 > 0 )  then 
	item.unsocet3 = "|cffff0000  лк |r"
	
	elseif (item.unsocet3 > 4000) then
		item.unsocet3 = "  "	
	end
	
	elseif (item.kolvo == 2 ) then
	--------------------------------------------- пр гем
	
	if   (item.unsocet1 == 0) then
	item.unsocet1 = "|cffff0000  нет |r"
	elseif (item.unsocet1 == 3734) -- 58 спд
	or (item.unsocet1 == 9022)   --  42 спд
	or (item.unsocet1 == 3745)   --   50 рпб
	or (item.unsocet1 == 3742)   --   50 хит
	or (item.unsocet1 == 3739)   --   50 хасты
	or (item.unsocet1 == 3293)   --   75 вын
	or (item.unsocet1 == 3732)  --    50 силы
	or (item.unsocet1 == 3738)  --    крита силы
	or (item.unsocet1 == 3297)  --    ап 100
	or (item.unsocet1 == 3733)  --    50 лвк
	
	
	then
	item.unsocet1 = "  "
	
	--------------------------------------        исключения                 
	
	elseif  (item.unsocet1 == 6070) or (item.unsocet1 == 6054) or (item.unsocet1 == 6090)  or  (item.unsocet1 == 6057) then
	item.unsocet1 = "|cffff0000  лк |r"
	elseif (item.unsocet1 < 4000) and (item.unsocet1 > 0 )  then 
	item.unsocet1 = "|cffff0000  лк |r"
	
	elseif (item.unsocet1 > 4000) then
		item.unsocet1 = "  "	
	end
	--------------------------------------------- вт гем
	if   (item.unsocet2 == 0) then
	item.unsocet2 = "|cffff0000  нет |r"
	elseif (item.unsocet2 == 3734) -- 58 спд
	or (item.unsocet2 == 9022)   --  42 спд
	or (item.unsocet2 == 3745)   --   50 рпб
	or (item.unsocet2 == 3739)   --   50 хасты
	or (item.unsocet2 == 3742)   --   50 хит
	or (item.unsocet2 == 3293)   --   75 вын
	or (item.unsocet2 == 3732)  --    50 силы
	or (item.unsocet2 == 3738)  --    крита силы
	or (item.unsocet2 == 3297)  --    ап 100
	or (item.unsocet2 == 3733)  --    50 лвк
	
	
	then
	item.unsocet2 = "  "
	
	--------------------------------------        исключения                 
	
	elseif  (item.unsocet2 == 6070) or (item.unsocet2 == 6054) or (item.unsocet2 == 6090)  or  (item.unsocet2 == 6057) then
	item.unsocet1 = "|cffff0000  лк |r"
	elseif (item.unsocet2 < 4000) and (item.unsocet2 > 0 )  then 
	item.unsocet2 = "|cffff0000  лк |r"
	
	elseif (item.unsocet2 > 4000) then
		item.unsocet2 = "  "	
	end
	
	elseif (item.kolvo == 1 ) then
	--------------------------------------------- пр гем
	
	if   (item.unsocet1 == 0) then
	item.unsocet1 = "|cffff0000  нет |r"
	elseif (item.unsocet1 == 3734) -- 58 спд
	or (item.unsocet1 == 9022)   --  42 спд
	or (item.unsocet1 == 3745)   --   50 рпб
	or (item.unsocet1 == 3739)   --   50 хасты
	or (item.unsocet1 == 3742)   --   50 хит
	or (item.unsocet1 == 3293)   --   75 вын
	or (item.unsocet1 == 3732)  --    50 силы
	or (item.unsocet1 == 3738)  --    крита силы
	or (item.unsocet1 == 3297)  --    ап 100
	or (item.unsocet1 == 3733)  --    50 лвк
	
	
	then
	item.unsocet1 = "  "
	
	--------------------------------------        исключения                 
	
	elseif  (item.unsocet1 == 6070) or (item.unsocet1 == 6054) or (item.unsocet1 == 6090)  or  (item.unsocet1 == 6057) then
	item.unsocet1 = "|cffff0000  лк |r"
	elseif (item.unsocet1 < 4000) and (item.unsocet1 > 0 )  then 
	item.unsocet1 = "|cffff0000  лк |r"
	
	elseif (item.unsocet1 > 4000) then
		item.unsocet1 = "  "	
	end
	end
	
	if (item.unsocet4 == 0) then
	item.unsocet4 = " "
	else item.unsocet4 = item.unsocet4 
	end
	
	if (item.unsocet3 == 0) then
	item.unsocet3 = " "
	else item.unsocet3 = item.unsocet3 
	end
	
	if (item.unsocet2 == 0) then
	item.unsocet2 = " "
	else item.unsocet2 = item.unsocet2 
	end
	
	if (item.unsocet1 == 0) then
	item.unsocet1 = " "
	else item.unsocet1 = item.unsocet1 
	end
	
     suffix = suffix.."   "..item.unsocet1.."   "..item.unsocet2.."   "..item.unsocet3.."   "..item.unsocet4.."   " ------ в суффикс добавляется сокеты
	 
	 
	 
	end
	
	
	 
	 -------------------- в суффикс добавляется инчант если стоит проверка
	 	 
	 ------ чарка 
	 if  InspectEquipConfig.checkEnchants and  InspectEquipConfig.checkEnchantspokaz then                   --- если стоит показывать 
	 if   (item.enchant == 3817) and (not noEnchantWarningSlots[item.slot]) then -- голова  мдд
	 suffix = " - Есть чарка"..suffix
	 elseif   (item.enchant == 4176) then -- хант крит
	 suffix = " - Есть чарка"..suffix
	 
	  elseif   (item.enchant == 7018) then -- перчи лвк
	 suffix = " - Есть чарка"..suffix
	 elseif   (item.enchant == 9010) and (not noEnchantWarningSlots[item.slot])then -- плечи мдд
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 7011) and (not noEnchantWarningSlots[item.slot])then -- грудь +15 бк
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 3756) and (not noEnchantWarningSlots[item.slot])then --запы ап кожевка
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 7022) and (not noEnchantWarningSlots[item.slot])then --перчи ап +66
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 9001) and (not noEnchantWarningSlots[item.slot])then --ноги бк мили
	 suffix = " - Есть чарка"..suffix
	 
	  elseif   (item.enchant == 3368) and (not noEnchantWarningSlots[item.slot])then --пушка дк сила
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 7015) and (not noEnchantWarningSlots[item.slot])then --ступни +18
	suffix = " - Есть чарка"..suffix
	
	  elseif   (item.enchant == 3730) and (not noEnchantWarningSlots[item.slot])then -- плащ ап портняга
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 9003) and (not noEnchantWarningSlots[item.slot])then -- спд дух бк ноги
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 7014) and (not noEnchantWarningSlots[item.slot])then -- выносливость увеличение скорости ботинки бк
	suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 3838) and (not noEnchantWarningSlots[item.slot])then --  пелчи спд крит начерталка
	suffix = " - Есть чарка"..suffix
	 
	
	 elseif   (item.enchant == 7033) and (not noEnchantWarningSlots[item.slot])then -- перчи спд бк
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 3820) and (not noEnchantWarningSlots[item.slot])then -- голова спд крит
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 7021) and (not noEnchantWarningSlots[item.slot])then -- перчи спд
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 7043) and (not noEnchantWarningSlots[item.slot])then -- 121 спд посох
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 3722) and (not noEnchantWarningSlots[item.slot])then -- светлотканная портняга
	suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 9013) and (not noEnchantWarningSlots[item.slot])then -- плечи спд 
	 suffix = " - Есть чарка"..suffix
	
	 elseif   (item.enchant == 7039) and (not noEnchantWarningSlots[item.slot])then -- спд бк одноруч
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 7032) and (not noEnchantWarningSlots[item.slot])then -- 75 апа бк
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 7000) and (not noEnchantWarningSlots[item.slot])then -- хаста плащ
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 3604) and (not noEnchantWarningSlots[item.slot])then -- инжа перчи
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 3606) and (not noEnchantWarningSlots[item.slot])then -- инжа боты
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 3789) then  -- берса пушка
	 suffix = " - Есть чарка"..suffix
	  elseif   (item.enchant == 7042) then  -- пушка ап бк
	 suffix = " - Есть чарка"..suffix
	  elseif   (item.enchant == 3816) then  -- огонь танк голова
	 suffix = " - Есть чарка"..suffix
	 elseif   (item.enchant == 3849) then  -- титановая обшивка
	 suffix = " - Есть чарка"..suffix
	 elseif   (item.enchant == 7007) then  -- титановая обшивка
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 3819) then  -- хил голова
	 suffix = " - Есть чарка"..suffix
	 elseif   (item.enchant == 3830) then  -- хил плечи наложка
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 9004) and (not noEnchantWarningSlots[item.slot])then -- спд вын ноги бк
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 7006) and (not noEnchantWarningSlots[item.slot])then -- лвк бк
	 suffix = " - Есть чарка"..suffix
	 
	  elseif   (item.enchant == 3815) and (not noEnchantWarningSlots[item.slot])then -- тайная голова
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 9012) and (not noEnchantWarningSlots[item.slot])then -- плечи танк
	 suffix = " - Есть чарка"..suffix
	 
	  elseif   (item.enchant == 7005) and (not noEnchantWarningSlots[item.slot])then -- плащ танк 
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 3297) and (not noEnchantWarningSlots[item.slot])then -- 275 хп грудь 
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 3757) and (not noEnchantWarningSlots[item.slot])then -- 150 вын запы
	 suffix = " - Есть чарка"..suffix
	 
	  elseif   (item.enchant == 7020) and (not noEnchantWarningSlots[item.slot])then -- кисти  танк
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 9000) and (not noEnchantWarningSlots[item.slot])then -- танк ноги
	 suffix = " - Есть чарка"..suffix
	 
	  elseif   (item.enchant == 7012) and (not noEnchantWarningSlots[item.slot])then -- танк боты
	 suffix = " - Есть чарка"..suffix
	 
	  elseif   (item.enchant == 3370) and (not noEnchantWarningSlots[item.slot])then -- танк дк чарка
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 3835) and (not noEnchantWarningSlots[item.slot])then -- плечи ап начерталка
	 suffix = " - Есть чарка"..suffix
	 
	  elseif   (item.enchant == 3758) and (not noEnchantWarningSlots[item.slot])then -- запы спд кожевка
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 3761) and (not noEnchantWarningSlots[item.slot])then -- запы сопрот темной
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 3760) and (not noEnchantWarningSlots[item.slot])then -- запы сопрот льду
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 3762) and (not noEnchantWarningSlots[item.slot])then -- запы сопрот природе
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 3605) and (not noEnchantWarningSlots[item.slot])then -- инжа спина крит
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 2673) and (not noEnchantWarningSlots[item.slot])then -- мангуст
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 3847) and (not noEnchantWarningSlots[item.slot])then -- дк танк чарка
	 suffix = " - Есть чарка"..suffix
	 
	  elseif   (item.enchant == 3763) and (not noEnchantWarningSlots[item.slot])then -- запы аркан
	 suffix = " - Есть чарка"..suffix
	 
	  elseif   (item.enchant == 3818) and (not noEnchantWarningSlots[item.slot])then -- танк вын деф
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 3812) and (not noEnchantWarningSlots[item.slot])then -- танк лед деф
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 7013) and (not noEnchantWarningSlots[item.slot])then -- дд 48 ап
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 7008) and (not noEnchantWarningSlots[item.slot])then -- 33 защиты грудь
	 suffix = " - Есть чарка"..suffix
	 
	  elseif   (item.enchant == 3869) and (not noEnchantWarningSlots[item.slot])then -- отведение удара
	 suffix = " - Есть чарка"..suffix
	 
	  elseif   (item.enchant == 7034) and (not noEnchantWarningSlots[item.slot])then -- запы вын
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 3883) and (not noEnchantWarningSlots[item.slot])then -- руна нерубского дк
	 suffix = " - Есть чарка"..suffix
	 
	 elseif   (item.enchant == 3852) and (not noEnchantWarningSlots[item.slot])then -- плечи пвп танковские???????????
	 suffix = " - Есть чарка"..suffix.."|cffff0000  пвпп|r"
	 
	 elseif   (item.enchant == 3728) and (not noEnchantWarningSlots[item.slot])then -- плащ хил портняга
	  suffix = " - Есть чарка"..suffix
	  elseif   (item.enchant == 3813) and (not noEnchantWarningSlots[item.slot])then -- голова природа
	  suffix = " - Есть чарка"..suffix
	   elseif   (item.enchant == 7023) then -- щит 30 рейта блока
	  suffix = " - Есть чарка"..suffix
	   elseif   (item.enchant == 7041) then -- пушка метк криит
	  suffix = " - Есть чарка"..suffix
	   elseif   (item.enchant == 7024) then -- щит вын
	  suffix = " - Есть чарка"..suffix
	  elseif   (item.enchant == 3860) then -- перчи инжа броня
	  suffix = " - Есть чарка"..suffix
	  
	   elseif InspectEquipConfig.checkEnchants and (item.enchant == 7027) and ( lefthand[item.slot]) then    --- на левую руку щит 37 инты
      suffix = " - Есть чарка"..suffix
	  elseif InspectEquipConfig.checkEnchants and (item.enchant == 3839) and ( kolca[item.slot]) then    --- кольцо ап инчант
      suffix = " - Есть чарка"..suffix
	  elseif InspectEquipConfig.checkEnchants and (item.enchant == 3840) and ( kolca[item.slot]) then    --- кольцо спд инчант
      suffix = " - Есть чарка"..suffix
	  elseif InspectEquipConfig.checkEnchants and (item.enchant == 3791) and ( kolca[item.slot]) then    --- кольцо вын инчант
      suffix = " - Есть чарка"..suffix
	  elseif   (item.enchant == 4176) then -- пушка ханта крит
	 suffix = " - Есть чарка"..suffix
	  elseif   (item.enchant == 3790) then -- черная магия
	 suffix = " - Есть чарка"..suffix
	 elseif   (item.enchant == 9011) then -- спд мп5
	 suffix = " - Есть чарка"..suffix
	  elseif   (item.enchant == 3859) then -- плащ инжа
	 suffix = " - Есть чарка"..suffix
	 elseif   (item.enchant == 3370) then -- ледяного жара
	 suffix = " - Есть чарка"..suffix
	   -- elseif   (item.enchant == 7027) and (not noEnchantWarningSlots[item.slot])then -- щит 37 инты
	  -- suffix = " - Есть чарка"..suffix
	  
	  -- elseif   (item.enchant == ) and (not noEnchantWarningSlots[item.slot])then --
	 -- suffix = " - Есть чарка"..suffix
	 
	 ------------------------------------------------------------------------------------------------------------------------ пвп
	 elseif   (item.enchant == 3603) and (not noEnchantWarningSlots[item.slot])then -- перчи урон пвп
	 suffix = " - Есть чарка"..suffix.."|cffff0000   пвп|r"
	 
	 elseif   (item.enchant == 7004) and (not noEnchantWarningSlots[item.slot])then -- пенетра
	 suffix = " - Есть чарка"..suffix.."|cffff0000   пвп|r"
	 
	 
	  elseif   (item.enchant == 4217) and (not noEnchantWarningSlots[item.slot])then -- калчедановая цепь на оружие
	 suffix = " - Есть чарка"..suffix.."|cffff0000   пвп|r"
	 
	  elseif   (item.enchant == 3796) and (not noEnchantWarningSlots[item.slot])then -- плечи пвп ап
	 suffix = " - Есть чарка"..suffix.."|cffff0000   пвп|r"
	 
	 elseif   (item.enchant == 7009) and (not noEnchantWarningSlots[item.slot])then -- грудь 30 реса
	 suffix = " - Есть чарка"..suffix.."|cffff0000   пвп|r"
	 
	 elseif   (item.enchant == 3795) and (not noEnchantWarningSlots[item.slot])then -- голова ап рес
	 suffix = " - Есть чарка"..suffix.."|cffff0000   пвп|r"
	 
	 elseif   (item.enchant == 3793) and (not noEnchantWarningSlots[item.slot])then -- пречи ап рес
	 suffix = " - Есть чарка"..suffix.."|cffff0000   пвп|r"
	 
	 elseif   (item.enchant == 3878) and (not noEnchantWarningSlots[item.slot])then -- голова удар пвп инжа
	 suffix = " - Есть чарка"..suffix.."|cffff0000   пвп|r"
	 elseif   (item.enchant == 3245) and (not noEnchantWarningSlots[item.slot])then -- грудь рес
	 suffix = " - Есть чарка"..suffix.."|cffff0000   пвп|r"
	 elseif   (item.enchant == 3601) and ( pozs[item.slot])then -- пояс пвп 
	 suffix = " - Есть чарка"..suffix.."|cffff0000   пвп|r"
	 elseif   (item.enchant == 3797) then -- голова спд пвп
	 suffix = " - Есть чарка"..suffix.."|cffff0000   пвп|r"
	 elseif   (item.enchant == 3794) then -- плечи спд пвп
	 suffix = " - Есть чарка"..suffix.."|cffff0000   пвп|r"
	 elseif   (item.enchant == 9002) then -- грудь спд пвп
	 suffix = " - Есть чарка"..suffix.."|cffff0000   пвп|r"
	 
	 
	 ------------------------------------------------------------------------------------------------------------------------ толгород
	 elseif   (item.enchant == 10124) then -- дар искателя
	 suffix = " - Есть чарка"..suffix
	 elseif   (item.enchant == 10119) then -- дар травника
	 suffix = " - Есть чарка"..suffix
	 
	----------------------------------------------------------------------------------------------------------------------------
	  
	 
	   elseif InspectEquipConfig.checkEnchants and (item.enchant == 0) and (not noEnchantWarningSlots[item.slot]) then ---- не показывать где не должно
      suffix = "|cffff0000- Нет чарки|r"..suffix
	  elseif InspectEquipConfig.checkEnchants and InspectEquipConfig.bug and  (item.enchant == item.enchant) then   --- если нету в базе-------------------------------
      suffix = "|cffff0000- Нет в базе пиши репорт|r ---> "..item.enchant.."    "..suffix
	   elseif InspectEquipConfig.checkEnchants and (item.enchant >= 1)  then ---- не бк чарка
      suffix = "|cffff0000- Не бк чарка|r"..suffix
	   elseif InspectEquipConfig.checkEnchants and (item.enchant == 0)  then ---- не показывать где не должно х2
      suffix = suffix
	  
	  -- elseif InspectEquipConfig.checkEnchants and (item.enchant >= 1) and ( lefthand[item.slot]) then    --- на левую руку проверка наложения
      -- suffix = "|cffff0000- Нет Чарки|r  "..suffix
	 
	  
		   end
	 
	  elseif   InspectEquipConfig.checkEnchants and not  InspectEquipConfig.checkEnchantspokaz then --------- если стоит не показывать
	  if   (item.enchant == 3817) and (not noEnchantWarningSlots[item.slot]) then -- голова  мдд
	 suffix = suffix
	 elseif   (item.enchant == 4176) then -- хант крит
	 suffix = suffix
	  elseif   (item.enchant == 7018) then -- перчи лвк
	 suffix = suffix
	 
	 elseif   (item.enchant == 9010) and (not noEnchantWarningSlots[item.slot])then -- плечи мдд
	 suffix = suffix
	 
	 elseif   (item.enchant == 7011) and (not noEnchantWarningSlots[item.slot])then -- грудь +15 бк
	 suffix = suffix
	 
	 elseif   (item.enchant == 3756) and (not noEnchantWarningSlots[item.slot])then --запы ап кожевка
	 suffix = suffix
	 
	 elseif   (item.enchant == 7022) and (not noEnchantWarningSlots[item.slot])then --перчи ап +66
	 suffix = suffix
	 
	 elseif   (item.enchant == 9001) and (not noEnchantWarningSlots[item.slot])then --ноги бк мили
	 suffix = suffix
	 
	  elseif   (item.enchant == 3368) and (not noEnchantWarningSlots[item.slot])then --пушка дк сила
	 suffix = suffix
	 
	 elseif   (item.enchant == 7015) and (not noEnchantWarningSlots[item.slot])then --ступни +18
	suffix = suffix
	
	  elseif   (item.enchant == 3730) and (not noEnchantWarningSlots[item.slot])then -- плащ ап портняга
	 suffix = suffix
	 
	 elseif   (item.enchant == 9003) and (not noEnchantWarningSlots[item.slot])then -- спд дух бк ноги
	 suffix = suffix
	 
	 elseif   (item.enchant == 7014) and (not noEnchantWarningSlots[item.slot])then -- выносливость увеличение скорости ботинки бк
	suffix = suffix
	 
	 elseif   (item.enchant == 3838) and (not noEnchantWarningSlots[item.slot])then --  пелчи спд крит начерталка
	suffix = suffix
	 
	
	 elseif   (item.enchant == 7033) and (not noEnchantWarningSlots[item.slot])then -- перчи спд бк
	 suffix = suffix
	 
	 elseif   (item.enchant == 3820) and (not noEnchantWarningSlots[item.slot])then -- голова спд крит
	 suffix = suffix
	 
	 elseif   (item.enchant == 7021) and (not noEnchantWarningSlots[item.slot])then -- перчи спд
	 suffix = suffix
	 
	 elseif   (item.enchant == 7043) and (not noEnchantWarningSlots[item.slot])then -- 121 спд посох
	 suffix = suffix
	 
	 elseif   (item.enchant == 3722) and (not noEnchantWarningSlots[item.slot])then -- светлотканная портняга
	suffix = suffix
	 
	 elseif   (item.enchant == 9013) and (not noEnchantWarningSlots[item.slot])then -- плечи спд 
	 suffix = suffix
	
	 elseif   (item.enchant == 7039) and (not noEnchantWarningSlots[item.slot])then -- спд бк одноруч
	 suffix = suffix
	 
	 elseif   (item.enchant == 7032) and (not noEnchantWarningSlots[item.slot])then -- 75 апа бк
	 suffix = suffix
	 
	 elseif   (item.enchant == 7000) and (not noEnchantWarningSlots[item.slot])then -- хаста плащ
	 suffix = suffix
	 
	 elseif   (item.enchant == 3604) and (not noEnchantWarningSlots[item.slot])then -- инжа перчи
	 suffix = suffix
	 
	 elseif   (item.enchant == 3606) and (not noEnchantWarningSlots[item.slot])then -- инжа боты
	 suffix = suffix
	 
	 elseif   (item.enchant == 3789) then  -- берса пушка
	 suffix = suffix
	  elseif   (item.enchant == 7042) then  -- пушка ап бк
	 suffix = suffix
	  elseif   (item.enchant == 3816) then  -- огонь танк голова
	 suffix = suffix
	 elseif   (item.enchant == 3849) then  -- титановая обшивка
	 suffix = suffix
	 elseif   (item.enchant == 7007) then  -- титановая обшивка
	 suffix = suffix
	 
	  elseif   (item.enchant == 3819) then  -- хил голова
	 suffix = suffix
	 elseif   (item.enchant == 3830) then  -- хил плечи кожевка
	 suffix = suffix
	 
	 elseif   (item.enchant == 9004) and (not noEnchantWarningSlots[item.slot])then -- спд вын ноги бк
	 suffix = suffix
	 
	 elseif   (item.enchant == 7006) and (not noEnchantWarningSlots[item.slot])then -- лвк бк
	 suffix = suffix
	 
	  elseif   (item.enchant == 3815) and (not noEnchantWarningSlots[item.slot])then -- тайная голова
	 suffix = suffix
	 
	 elseif   (item.enchant == 9012) and (not noEnchantWarningSlots[item.slot])then -- плечи танк
	 suffix = suffix
	 
	  elseif   (item.enchant == 7005) and (not noEnchantWarningSlots[item.slot])then -- плащ танк 
	 suffix = suffix
	 
	 elseif   (item.enchant == 3297) and (not noEnchantWarningSlots[item.slot])then -- 275 хп грудь 
	 suffix = suffix
	 
	 elseif   (item.enchant == 3757) and (not noEnchantWarningSlots[item.slot])then -- 150 вын запы
	 suffix = suffix
	 
	  elseif   (item.enchant == 7020) and (not noEnchantWarningSlots[item.slot])then -- кисти  танк
	 suffix = suffix
	 
	 elseif   (item.enchant == 9000) and (not noEnchantWarningSlots[item.slot])then -- танк ноги
	 suffix = suffix
	 
	  elseif   (item.enchant == 7012) and (not noEnchantWarningSlots[item.slot])then -- танк боты
	 suffix = suffix
	 
	  elseif   (item.enchant == 3370) and (not noEnchantWarningSlots[item.slot])then -- танк дк чарка
	 suffix = suffix
	 
	 elseif   (item.enchant == 3835) and (not noEnchantWarningSlots[item.slot])then -- плечи ап начерталка
	 suffix = suffix
	 
	  elseif   (item.enchant == 3758) and (not noEnchantWarningSlots[item.slot])then -- запы спд кожевка
	 suffix = suffix
	 
	 elseif   (item.enchant == 3761) and (not noEnchantWarningSlots[item.slot])then -- запы сопрот темной
	 suffix = suffix
	 
	 elseif   (item.enchant == 3760) and (not noEnchantWarningSlots[item.slot])then -- запы сопрот льду
	 suffix = suffix
	 
	 elseif   (item.enchant == 3762) and (not noEnchantWarningSlots[item.slot])then -- запы сопрот природе
	 suffix = suffix
	 
	 elseif   (item.enchant == 3605) and (not noEnchantWarningSlots[item.slot])then -- инжа спина крит
	 suffix = suffix
	 
	 elseif   (item.enchant == 2673) and (not noEnchantWarningSlots[item.slot])then -- мангуст
	 suffix = suffix
	 
	 elseif   (item.enchant == 3847) and (not noEnchantWarningSlots[item.slot])then -- дк танк чарка
	 suffix = suffix
	 
	  elseif   (item.enchant == 3763) and (not noEnchantWarningSlots[item.slot])then -- запы аркан
	 suffix = suffix
	 
	  elseif   (item.enchant == 3818) and (not noEnchantWarningSlots[item.slot])then -- танк вын деф
	 suffix = suffix
	 
	 elseif   (item.enchant == 3812) and (not noEnchantWarningSlots[item.slot])then -- танк лед деф
	 suffix = suffix
	 
	 elseif   (item.enchant == 7013) and (not noEnchantWarningSlots[item.slot])then -- дд 48 ап
	 suffix = suffix
	 
	 elseif   (item.enchant == 7008) and (not noEnchantWarningSlots[item.slot])then -- 33 защиты грудь
	 suffix = suffix
	 
	  elseif   (item.enchant == 3869) and (not noEnchantWarningSlots[item.slot])then -- отведение удара
	 suffix = suffix
	 
	  elseif   (item.enchant == 7034) and (not noEnchantWarningSlots[item.slot])then -- запы вын
	 suffix = suffix
	 
	 elseif   (item.enchant == 3883) and (not noEnchantWarningSlots[item.slot])then -- руна нерубского дк
	 suffix = suffix
	 
	 elseif   (item.enchant == 3852) and (not noEnchantWarningSlots[item.slot])then -- плечи пвп танковские???????????
	 suffix = suffix
	 
	 elseif   (item.enchant == 3728) and (not noEnchantWarningSlots[item.slot])then -- плащ хил портняга
	  suffix = suffix
	  elseif   (item.enchant == 3813) and (not noEnchantWarningSlots[item.slot])then -- голова природа
	  suffix = suffix
	   elseif   (item.enchant == 7023) then -- щит 30 рейта блока
	  suffix = suffix
	   elseif   (item.enchant == 7041) then -- пушка метк криит
	  suffix = suffix
	   elseif   (item.enchant == 7024) then -- щит вын
	  suffix = suffix
	   elseif   (item.enchant == 3860) then -- перчи инжа броня
	  suffix = suffix
	  
	   elseif InspectEquipConfig.checkEnchants and (item.enchant == 7027) and ( lefthand[item.slot]) then    --- на левую руку щит 37 инты
      suffix = suffix
	  elseif InspectEquipConfig.checkEnchants and (item.enchant == 3839) and ( kolca[item.slot]) then    --- кольцо ап инчант
      suffix = suffix
	  elseif InspectEquipConfig.checkEnchants and (item.enchant == 3840) and ( kolca[item.slot]) then    --- кольцо спд инчант
      suffix = suffix
	  elseif InspectEquipConfig.checkEnchants and (item.enchant == 3791) and ( kolca[item.slot]) then    --- кольцо вын инчант
      suffix = suffix
	  elseif   (item.enchant == 4176) then -- пушка ханта крит
	 suffix = suffix
	  elseif   (item.enchant == 3790) then -- черная магия
	 suffix = suffix
	 elseif   (item.enchant == 9011) then -- спд мп5
	 suffix = suffix
	  elseif   (item.enchant == 3859) then -- плащ инжа
	 suffix = suffix
	 elseif   (item.enchant == 3370) then -- ледяного жара
	 suffix = suffix
	   -- elseif   (item.enchant == 7027) and (not noEnchantWarningSlots[item.slot])then -- щит 37 инты
	  -- suffix = suffix
	  
	  -- elseif   (item.enchant == ) and (not noEnchantWarningSlots[item.slot])then --
	 -- suffix = suffix
	 
	 ------------------------------------------------------------------------------------------------------------------------ пвп
	 elseif   (item.enchant == 3603) and (not noEnchantWarningSlots[item.slot])then -- перчи урон пвп
	 suffix = suffix
	 
	 elseif   (item.enchant == 7004) and (not noEnchantWarningSlots[item.slot])then -- пенетра
	 suffix = suffix
	 
	 
	  elseif   (item.enchant == 4217) and (not noEnchantWarningSlots[item.slot])then -- калчедановая цепь на оружие
	 suffix = suffix
	 
	  elseif   (item.enchant == 3796) and (not noEnchantWarningSlots[item.slot])then -- плечи пвп ап
	 suffix = suffix
	 
	 elseif   (item.enchant == 7009) and (not noEnchantWarningSlots[item.slot])then -- грудь 30 реса
	 suffix = suffix
	 
	 elseif   (item.enchant == 3795) and (not noEnchantWarningSlots[item.slot])then -- голова ап рес
	 suffix = suffix
	 
	 elseif   (item.enchant == 3793) and (not noEnchantWarningSlots[item.slot])then -- пречи ап рес
	 suffix = suffix
	 
	 elseif   (item.enchant == 3878) and (not noEnchantWarningSlots[item.slot])then -- голова удар пвп инжа
	 suffix = suffix
	 elseif   (item.enchant == 3245) and (not noEnchantWarningSlots[item.slot])then -- грудь рес
	 suffix = suffix
	 elseif   (item.enchant == 3601) and ( pozs[item.slot])then -- пояс пвп 
	 suffix = suffix
	 elseif   (item.enchant == 3797) then -- голова спд пвп
	 suffix = suffix
	 elseif   (item.enchant == 3794) then -- плечи спд пвп
	 suffix = suffix
	 elseif   (item.enchant == 9002) then -- грудь спд пвп
	 suffix = suffix
	 
	 
	 ------------------------------------------------------------------------------------------------------------------------ толгород
	 elseif   (item.enchant == 10124) then -- дар искателя
	 suffix = suffix
	 elseif   (item.enchant == 10119) then -- дар травника
	 suffix = suffix
	----------------------------------------------------------------------------------------------------------------------------
	  
	 
	   elseif InspectEquipConfig.checkEnchants and (item.enchant == 0) and (not noEnchantWarningSlots[item.slot]) then ---- не показывать где не должно
      suffix = "|cffff0000- Нет чарки|r"..suffix
	  elseif InspectEquipConfig.checkEnchants and InspectEquipConfig.bug and  (item.enchant == item.enchant) then   --- если нету в базе-------------------------------
      suffix = "|cffff0000- Нет в базе пиши репорт|r ---> "..item.enchant.."    "..suffix
	   elseif InspectEquipConfig.checkEnchants and (item.enchant >= 1)  then ---- не бк чарка
      suffix = "|cffff0000- Не бк чарка|r"..suffix
	   elseif InspectEquipConfig.checkEnchants and (item.enchant == 0)  then ---- не показывать где не должно х2
      suffix = suffix
	  
	  -- elseif InspectEquipConfig.checkEnchants and (item.enchant >= 1) and ( lefthand[item.slot]) then    --- на левую руку проверка наложения
      -- suffix = "|cffff0000- Нет Чарки|r  "..suffix
	 
	  
		   
	  
	  
	  
	 end
	
	  end
	   ------------------------------------------------------------------------------------------------------------------------ для разрабов
	if  InspectEquipConfig.razrab  and (item.enchant == item.enchant)  then --- для разрабов
      suffix = "|cffff0000 чарка айди ---> "..item.enchant.."      сокеты айди  ---> |r" ..item.perehod1.."   "..item.perehod2.."   "..item.perehod3.."   "..item.perehod4.."   "..item.kolvo
   
    
  end
	 
	 
	
    local prefix = padding
	
    if InspectEquipConfig.listItemLevels then
      local _,_,_,ilvl = GetItemInfo(item.link)
      if ilvl then
        prefix = padding .. "|cffaaaaaa[" .. ilvl .. "]|r "
      end
    end
	
	
    self:AddLine(prefix .. item.link .. suffix, item.link, item)
  end

end

local srctypes_d = { -- Instances
  ["n"] = L["Normal"], ["h"] = L["Heroic"], ["q"] = L["Quest Reward"], 
}
local srctypes_r = { -- Raids with 10 man, 25 man, 10 man heroic, 25 man heroic modes
  ["N"] = L["Heroic"], ["H"] = L["Heroic"], ["q"] = L["Quest Reward"], ["Q"] = L["Quest Reward"] 
}
local pvptypes = {
  ["m"] = L["Accessories"], ["l"] = L["Low level PvP"], ["w"] = L["World PvP"], ["s1"] = L["Season 1"],
  ["s2"] = L["Season 2"], ["s3"] = L["Season 3"], ["s4"] = L["Season 4"], ["s5"] = L["Season 5"], 
  ["s6"] = L["Season 6"], ["s7"] = L["Season 7"], ["s8"] = L["Season 8"], ["g"] = L["Lake Wintergrasp"],
  ["s9"] = L["Season 9"], ["s10"] = L["Season 10"],
}

function IE:FindItem(itemLink, includeUnknown)
  local id = tonumber(itemLink:match("item:(%d+)"))
  if not id then return nil end

  -- Returns a list of (strings localized):
  --  category name ("Raid", "PvP rewards", ...)
  --  subcategory ("Naxxramas", "Season 1", nil, ...)
  --  loot table ("Normal", "Heroic", "Quest Reward", nil, ...)
  --  boss ("Patchwerk", nil, ...)
  --  price (100, nil, ...) <- for badge rewards
  --  set (T7, nil, ...)

  local data = IS.Items[id]
  if data then
    sources = {}
    for entry in gmatch(data, "[^;]+") do
      local next_field = gmatch(entry, "[^_]+")
      local cat = next_field()

      if cat == "r" or cat == "d" then -- Raid/Dungeon: r_ZONE_SRCTYPE_BOSS
        local catname
        if cat == "r" then catname = L["Raid"] else catname = L["Instances"] end
        local zoneId = tonumber(next_field() or 0)
        local zone = IS.Zones[zoneId]
        local lootTable = next_field()
        local srctype
        if cat == "r" then 
          srctype = srctypes_r[lootTable]
          if lootTable == "n" or lootTable == "N" or lootTable == "q" then 
            zone = zone .. "-10" -- Normal 10: n | Hard mode 10: N | Quest reward 10: q
          elseif lootTable == "h" or lootTable == "H" or lootTable == "Q" then
            zone = zone .. "-25" -- Normal 25: h | Hard mode 25: H | Quest reward 25: Q
          elseif lootTable == "4" then
            zone = zone .. "-40"
          end
        else
          srctype = srctypes_d[lootTable]
        end
        local boss = IS.Bosses[tonumber(next_field() or 0)]
        local setname = next_field()
        if setname == "+" then
          setname = L["Hard mode"]
        end
        tinsert(sources, {catname, zone, srctype, boss, nil, setname})
      elseif cat == "v" then -- Valor Points: v_COST
        tinsert(sources, {L["PvE rewards"], valorPoints, nil, nil, tonumber(next_field()), next_field()})
	  elseif cat == "z" then -- Outland war Token: z_COST
        tinsert(sources, {L["PvE rewards"], outlandToken, nil, nil, tonumber(next_field()), next_field()})
      elseif cat == "t" then -- Argent Tournament: t_COST
        tinsert(sources, {L["Argent Tournament"], nil, nil, nil, tonumber(next_field())})
      elseif cat == "c" then -- Crafted: c_PROFESSION
        local prof = GetSpellInfo(tonumber(next_field() or "0"))
        tinsert(sources, {L["Crafted"], nil, nil, prof})
      elseif cat == "f" then -- Faction rewards: f
        tinsert(sources, {L["Reputation rewards"]})
      elseif cat == "e" then -- World events: e
        tinsert(sources, {L["World events"]})
      elseif cat == "m" then -- Darkmoon Cards: m
        tinsert(sources, {L["Darkmoon Faire"]})
      elseif cat == "g" then -- Vendor (Gold): g
        tinsert(sources, {L["Vendor"]})
	  elseif cat == "l" then -- Lily
        tinsert(sources, {L["Lily"]})
	  elseif cat == "tol" then -- Tol'Garod
        tinsert(sources, {L["Tol'Garod"]})
	  elseif cat == "kel" then -- Keldanas
        tinsert(sources, {L["Keldanas"]})
       elseif cat == "auс" then -- Keldanas
        tinsert(sources, {L["Auction"]})
	  elseif cat == "b" then -- Heroic TBC Instances
        tinsert(sources, {L["Heroic TBC Instances"]})
      elseif cat == "p" then -- PvP: p_PVPTYPE
        local pvptype = pvptypes[next_field()]
        tinsert(sources, {L["PvP rewards"], pvptype})
      end

    end
    if #sources > 0 then
      return sources
    end
  else
    if includeUnknown then
      local _,_,rarity,lvl = GetItemInfo(id)
      if rarity >= 2 then
        return {{L["Unknown"]}}
      end
    end
  end
  return nil
end

function IE:GetItemNames()
  valorPoints = GetItemInfo(160000) or valorPoints
  outlandToken = GetItemInfo(280512) or outlandToken
  namesInitialized = true
end

function IE:FixWindowSize()
  local maxwidth = TITLE:GetStringWidth()
  for i = 1, numlines do
    local width = lines[i].text:GetStringWidth()
    if maxwidth < width then maxwidth = width end
  end
  local height = (curline * 15) + 55
  if InspectEquipConfig.showAvgItemLevel then
    height = height + 15
  end
  WIN:SetWidth(maxwidth + 40)
  WIN:SetHeight(height)
end

function IE.Line_OnEnter(row)
  if row.link then
    GameTooltip:SetOwner(row, "ANCHOR_TOPLEFT")
    if (not cached) and (UnitName(curUnit) == curUnitName) then
      row.link = GetInventoryItemLink(curUnit, GetInventorySlotInfo(row.item.slot)) or row.link
	 
    end
	

	
    GameTooltip:SetHyperlink(row.link)
	
    if row.item and InspectEquipConfig.checkEnchants and (row.item.enchant == 0) and (not noEnchantWarningSlots[row.item.slot]) then
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine("|cffff0000" .. L["Item is not enchanted"] .. "|r")
	 
    end
	-- if row.item and InspectEquipConfig.soketc and (row.item.unsocet1 > 0) then
			-- GameTooltip:AddLine(" ")
			-- GameTooltip:AddLine("|cffff0000" .. L["Item is not socketed"] .. "|r")
		-- end
    GameTooltip:Show()

  end
end

function IE.Line_OnLeave(row)
  GameTooltip:Hide()
end

function IE.Line_OnClick(row, button)
  if row.link then
    if IsControlKeyDown() then
      DressUpItemLink(row.link)
    elseif IsShiftKeyDown() then
      ChatEdit_InsertLink(row.link)
    end
  end
end



--[[
/run local c = GetInventoryItemLink("target",GetInventorySlotInfo("MainHandSlot")) local var1, var2, var3, var4, var5, var6, itemType = GetItemInfo(c) print(var1, var2, var3, var4, var5, var6, itemType)

/run InspectUnit("target") local itemLink = GetInventoryItemLink("target", 5) print(itemLink) InspectFrame:Hide()

getItem
/run local get = strsplit(" ",GetInventoryItemLink("target", GetInventorySlotInfo("ChestSlot"))) print(get)

/run local slotId = GetInventorySlotInfo("ChestSlot")
local link = GetInventoryItemLink("target", slotId)
local itemId, enchantId, gem1, gem2, gem3, gem4 = link:match("item:(%d+):(%d+):(%d+):(%d+):(%d+):(%d+)")
print (itemId, enchantId, gem1, gem2, gem3, gem4)

]]