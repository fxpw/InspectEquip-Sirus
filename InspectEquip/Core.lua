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

local bdcount
local jewh

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
  self.UpdateInspectTimer = C_Timer:NewTicker(0.002, function()
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
					local gemts1 = (tonumber(gem1) or 0)
					-- local perehod1 = numFilledSockets1
					-- local unsocet1 =  perehod1

					local gemts2 = (tonumber(gem2) or 0)
					-- local perehod2 = numFilledSockets2
					-- local unsocet2 =  perehod2

					local gemts3 = (tonumber(gem3) or 0)
					-- local perehod3 = numFilledSockets3
					-- local unsocet3 =  perehod3

					local gemts4 = (tonumber(gem4) or 0)
					-- local perehod4 = numFilledSockets4
					-- local unsocet4 =  perehod4


					-- gem1= (tonumber(gem1) or 0)


			---------------------------------------------------------------------сокеты
			if items[src] == nil then
				items[src] = {count = 0}
			end
			cat = items[src]
			if subsrc then
				-- subcategory
				if lootTable == L["Heroic"] then
					subsrc = subsrc .. " (" .. lootTable .. ")"
				end
				if cat[subsrc] == nil then
					cat[subsrc] = {count = 0, hasItems = true}
				end
				cat.count = cat.count + 1
				local subcat = cat[subsrc]
				subcat.count = subcat.count + 1
				subcat[subcat.count] = {
					link = itemLink,
					lootTable = lootTable,
					boss = boss,
					cost = cost,
					slot = slot,
					enchant = enchantId,
					gemts1 = gemts1,
					gemts2 = gemts2,
					gemts3 = gemts3,
					gemts4 = gemts4,
					kolvo = kolvo
				}
				-- print( itemLink, lootTable, boss, cost, slot,enchantId)
			else
				-- no subcategory
				cat.hasItems = true
				cat.count = cat.count + 1
				cat[cat.count] = {link = itemLink,
				lootTable = lootTable,
				boss = boss,
				cost = cost,
				slot = slot,
				enchant = enchantId,
				gemts1 = gemts1,
				gemts2 = gemts2,
				gemts3 = gemts3,
				gemts4 = gemts4,
				kolvo=kolvo
			}
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
	bdcount = 0
	jewh = 0
	self:AddCats(items, "")
	if calciv and iCount > 0 then
		local avgLvl = iLevelSum / iCount
		if bdcount == 0 and jewh >=1 then
			AVGIL:SetText(L["Avg. Item Level"] .. ": " .. string.format("%.2f", avgLvl) .."|cffFF7110 ЮВх|r: ".. jewh )
			AVGIL:Show()
		elseif bdcount >= 1 and jewh == 0 then
			AVGIL:SetText(L["Avg. Item Level"] .. ": " .. string.format("%.2f", avgLvl) .."|cffFF7110 ЧБ|r: " .. bdcount )
			AVGIL:Show()
		else
			AVGIL:SetText(L["Avg. Item Level"] .. ": " .. string.format("%.2f", avgLvl) .."|cffFF7110 ЧБ|r: " .. bdcount .."|cffFF7110 ЮВх|r: ".. jewh )
			AVGIL:Show()
		end
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
----------------------------------------провер очки

local socetsbk = { ------------- сокеты с ювы 1 тир
	[3734] = true,   -- 58 спд
	[9022] = true,   --  42 спд
	[3745] = true,   --   50 рпб
	[3739] = true,   --   50 хасты
	[3742] = true,   --   50 хит
	[3293] = true,   --   75 вын
	[3732] = true,  --    50 силы
	[3738] = true,  --    крита силы
	[3297] = true,  --    ап 100
	[3733] = true,  --    50 лвк
}
local socetsiscl = {  ----------- исключения
	[6070] = true,
	[6054] = true,
	[6090] = true,
	[6057] = true,
}

local enchantidscmn = { ----------- айди чарок с проверкой на слот
	[3817] = true, ----------голова мбб
	[4176] = true, ----------хант крит
	[7018] = true, ----------перчи лвк
	[9010] = true, ----------плечи мдд
	[7011] = true, ----------+15 грудь
	[3756] = true, ----------запы ап кожевка
	[7022] = true, ----------перчи ап +66
	[9001] = true, ----------ноги бк мили
	[3368] = true, ----------пушка дк сила
	[7015] = true, ----------ступни +18
	[3730] = true, ----------плащ ап портняга
	[9003] = true, ----------спд дух бк ноги
	[7014] = true, ----------выносливость увеличение скорости ботинки бк
	[3838] = true, ----------пелчи спд крит начерталка
	[7033] = true, ----------перчи спд бк
	[3820] = true, ----------голова спд крит
	[7021] = true, ----------перчи спд
	[7043] = true, ----------121 спд посох
	[3722] = true, ----------светлотканная портняга
	[9013] = true, ----------плечи спд
	[7039] = true, ----------спд бк одноруч
	[7032] = true, ----------75 апа бк
	[7000] = true, ----------хаста плащ
	[3604] = true, ----------инжа перчи
	[3606] = true, ----------инжа боты
	[9004] = true, ----------спд вын ноги бк
	[7006] = true, ----------лвк бк
	[3815] = true, ----------тайная голова
	[9012] = true, ----------плечи танк
	[7005] = true, ----------плащ танк
	[3297] = true, ----------275 хп грудь
	[3757] = true, ----------150 вын запы
	[7020] = true, ----------кисти  танк
	[9000] = true, ----------танк ноги
	[7012] = true, ----------танк боты
	[3835] = true, ----------плечи ап начерталка
	[3758] = true, ----------запы спд кожевка
	[3761] = true, ----------запы сопрот темной
	[3760] = true, ----------запы сопрот льду
	[3762] = true, ----------запы сопрот природе
	[3605] = true, ----------инжа спина крит
	[2673] = true, ----------мангуст
	[3847] = true, ----------дк танк чарка
	[3763] = true, ----------запы аркан
	[3818] = true, ----------танк вын деф
	[3812] = true, ----------танк лед деф
	[7013] = true, ----------дд 48 ап
	[7008] = true, ----------33 защиты грудь
	[3869] = true, ----------отведение удара
	[7034] = true, ----------запы вын
	[3883] = true, ----------руна нерубского дк
	[3852] = true, ----------плечи пвп танковские???????????
	[3728] = true, ----------плащ хил портняга
	[3813] = true, ----------голова природа
	[3816] = true, ----------огонь танк голова
	[3819] = true, ----------хил голова
	[3830] = true, ----------хил плечи наложка
	[3860] = true, ----------перчи инжа броня
	[3790] = true, ---------- черная магия
	[9011] = true, ----------спд мп5
	[3859] = true, ----------плащ инжа
	[3370] = true, ----------танк дк чарка ледяного жара
  ----------------ty hayse
	[3252]= true, -- 8 ко всем статам
	[7028]= true, -- 15 ко всем вида сопрота
	[3814]= true, -- 25 к сопрту от тёмной магии  30 к выносливости
	[3811]= true, -- 20 к рейтингу уклонения и 15 к рейтингу защиты
	[983 ]= true, -- 16 к ловкости
	[3829]= true, -- 35 к ап
	[3828]= true, -- 85 к ап
	[2998]= true, -- 7 ко всем вида сопрота
	[3822]= true, -- 55 к выносливости и 22 к ловкости
	[3842]= true, -- 30 к выносливости и 25 к устойчивости
	[3850]= true, -- 40 к выносливости
	[1099]= true, -- 22 к ловкости
	[3731]= true, -- Титановая цепь для оружия
	[1147]= true, -- 18 к духу
	[2326]= true, -- 23 к спд
	[3719]= true, -- 50 к спд и 20 к духу
	[3831]= true, -- 23 к хосте
	[3246]= true, -- 28 к спд!
	[3845]= true, -- 50 к ап
	[2666]= true, -- 30 к инте
	[3810]= true, -- 24 к спд и 15 к рейтингу криит удара
	[3823]= true, --
	[3328]= true, -- 75 к ап и 22 к рейтингу криит удара
	[1603]= true, -- 44 к ап
	[1597]= true, -- 32 к ап
	[3808]= true, -- 40 к ап и 15 к рейтингу криит удара
	[3232]= true, -- 15 к выносливости и 8% кскорости движения
	[3824]= true, -- 24 к ап
	[1900]= true, -- рыцарь
	[1606]= true, -- 50 к ап
	[2332]= true, -- 30 к спд
	[1128]= true, -- 25 к инте
	[3832]= true, -- 10 ко всем статам
	[3721]= true, -- 50 к спд и 30 к выносливости

	[2647]= true, -- 12 к силе
	[3330]= true, -- 18 к выносливости
	[3836]= true, -- 105 к спд и 12 мп5
	[3855]= true, -- 69 к спд
	[3834]= true, -- 63 к спд
	[3853]= true, -- 40 к устойчивости и 28 к выносливости
	[3607]= true, -- 40 к рейтингу скороси дальнего боя
	[3854]= true, -- 81 к спд
	[3243]= true, -- 35 к проникающей спосоности заклинаний
	[1119]= true, -- 16 к инте
	[3003]= true, -- 35 к ап и 16 к меткости
	[1600]= true, -- 36 к ап
	[3234]= true, -- 20 к меткости
	[3837]= true, -- 90 к уклонению и 23 к защите
	[7030]= true, -- 20 к мастерству
	[7003]= true, -- 15 к духу и 4% снижение угрозы
	[3872]= true, -- 50 к спд и 20 к духу
	[3826]= true, -- 12 к меткости и 12 к рейтингу криит удара
	[3873]= true, -- 50 к спд и 30 к выносливости
	[3369]= true, -- Руна оплавленного ледника
	[3608]= true, -- 40 к рейтингу крит удара в дальнем бою
	[3718]= true, -- 35 к спд и 12 к духу

}
local enchantidsnch = { ----------- айди чарок без проверки на слот
	[3789] = true, ----------берса пушка
	[7042] = true, ----------пушка ап бк
	[3849] = true, ----------титановая обшивка
	[7007] = true, ----------титановая обшивка
	[7023] = true, ----------щит 30 рейта блока
	[7041] = true, ----------пушка метк криит
	[7024] = true, ----------щит вын
	[4176] = true, ----------хант крит
  	[3368] = true, -- Руна павшего рыцаря
}
local enchantidsring = { --------- кольца
	[3839] = true, ----------
	[3840] = true, ----------
	[3791] = true, ----------
}
local enchantidslefthand = { ----------- айди чарок левой руки
	[7027] = true, ----------на левую руку щит 37 инты
}
local enchantidspvp = { ----------- айди чарок пвп
	[3603] = true,----------------перчи урон пвп
	[7004] = true,----------------пенетра
	[4217] = true,----------------калчедановая цепь на оружие
	[3796] = true,----------------плечи пвп ап
	[7009] = true,----------------грудь 30 реса
	[3795] = true,----------------голова ап рес
	[3793] = true,----------------пречи ап рес
	[3878] = true,----------------голова удар пвп инжа
	[3245] = true,----------------грудь рес
	[3601] = true,----------------пояс пвп
	[3797] = true,----------------голова спд пвп
	[3794] = true,----------------плечи спд пвп
	[9002] = true,----------------грудь спд пвп
}
local enchantidstolgorod = {
	[10124] = true,  -- дар искателя
	[10119] = true,-- дар травника
	[10120] = true, -- дар рудокопа
}
function IE:AddItems(tab, padding,event,unit)
	for i = 1, tab.count do
		local item = tab[i]
		local suffix = ""
		-------------------------------------------------проверка сокетов----------------------------------------------------------

		if InspectEquipConfig.soketc and InspectEquipConfig.soketcpokaz   then ------------- плказывать ли сокеты
			local suffixsoc = {}

			if item.kolvo >= 1 then
				for s = 1,item.kolvo do
					if item["gemts"..s] == 0 then
						suffixsoc[s] = "|cffff0000  Нет |r"
					elseif item["gemts"..s] == socetsbk["gemts"..s] then
						suffixsoc[s] = " ЮВод "
					elseif item["gemts"..s] == socetsiscl["gemts"..s] then
						suffixsoc[s] = "|cff1293f4  ЛК |r"
					elseif (item["gemts"..s] > 0 ) and (item["gemts"..s] < 4000) then
						suffixsoc[s] = "|cff1293f4  ЛК |r"
					elseif (item["gemts"..s] > 4000) and (item["gemts"..s] < 8000) then
						suffixsoc[s] = " БК "
					elseif (item["gemts"..s] > 8000) and (item["gemts"..s] < 8026) then
						suffixsoc[s] = "|cffc000ff метаБК |r"
					elseif (item["gemts"..s] > 8025) and (item["gemts"..s] < 9000) then
						suffixsoc[s] = "|cffFF7110 ЧБ |r"
						bdcount = bdcount + 1
					elseif (item["gemts"..s] > 9000) and (item["gemts"..s] < 10000) then
						suffixsoc[s] = "|cffc000ff БКп |r"
					elseif (item["gemts"..s] > 10000) then
						suffixsoc[s] = "|cffFF7110 ЮВх |r"
						jewh = jewh + 1
					end
				end
			end
			for st = 1,#suffixsoc do
				if item["gemts"..st] == 0 then
					item["gemts"..st] = " "
				end
			end
			for sst = 1,#suffixsoc do
				if suffixsoc[sst] then
						suffix = suffix.."  "..suffixsoc[sst]
				end
			end

		elseif InspectEquipConfig.soketc and not InspectEquipConfig.soketcpokaz   then            ------------------ не показывать сокеты когда стоят
			local suffixsoc = {}

			if item.kolvo >= 1 then
				for s = 1,item.kolvo do
					if item["gemts"..s] == 0 then
						suffixsoc[s] = "|cffff0000  Нет |r"
					elseif item["gemts"..s] == socetsbk["gemts"..s] then
						suffixsoc[s] = " "
					elseif item["gemts"..s] == socetsiscl["gemts"..s] then
						suffixsoc[s] = " "
					elseif (item["gemts"..s] > 0 ) and (item["gemts"..s] < 4000) then
						suffixsoc[s] = " "
					elseif (item["gemts"..s] > 4000) and (item["gemts"..s] < 8000) then
						suffixsoc[s] = " "
					elseif (item["gemts"..s] > 8000) and (item["gemts"..s] < 8026) then
						suffixsoc[s] = " "
					elseif (item["gemts"..s] > 8025) and (item["gemts"..s] < 9000) then
						suffixsoc[s] = " "
						bdcount = bdcount + 1
					elseif (item["gemts"..s] > 9000) and (item["gemts"..s] < 10000) then
						suffixsoc[s] = " "
					elseif (item["gemts"..s] > 10000) then
						suffixsoc[s] = " "
						jewh = jewh + 1
					end
				end
			end

			for st = 1,#suffixsoc do
				if item["gemts"..st] == 0 then
					item["gemts"..st] = " "
				end
			end

				for sst = 1,#suffixsoc do
			if suffixsoc[sst] then
					suffix = suffix.."  "..suffixsoc[sst]
			end
				end
		end
		-------------------------------------------------проверка чарок----------------------------------------------------------


		if  InspectEquipConfig.checkEnchants and  InspectEquipConfig.checkEnchantspokaz then
			if (item.enchant == 0) and not noEnchantWarningSlots[item.slot] then ---- сразу с 0 проверка где не должно
				suffix = "|cffff0000- Нет чарки|r"..suffix
			elseif (item.enchant == 0)  then ---- не показывать где не должно х2
				suffix = suffix
			elseif  enchantidscmn[item.enchant] and not noEnchantWarningSlots[item.slot] then
				suffix = " - Есть чарка"..suffix
			elseif  enchantidsnch[item.enchant] then
				suffix = " - Есть чарка"..suffix
			elseif  enchantidsring[item.enchant] and ( kolca[item.slot]) then
				suffix = " - Есть чарка"..suffix
			elseif enchantidslefthand[item.enchant] and ( lefthand[item.slot]) then
				suffix = " - Есть чарка"..suffix
			elseif enchantidspvp[item.enchant] then
				suffix = " - Есть чарка"..suffix
			elseif enchantidstolgorod[item.enchant] then
				suffix = " - Есть чарка"..suffix
			elseif InspectEquipConfig.bug  then   --- если нету в базе
				suffix = "|cffff0000- Нет в базе пиши репорт|r ---> "..item.enchant.." <--   "..suffix
			elseif (item.enchant >= 1)  then ---- не бк чарка
				suffix = "|cffff0000- Не бк чарка|r"..suffix
			end

		elseif   InspectEquipConfig.checkEnchants and not  InspectEquipConfig.checkEnchantspokaz then --------- если стоит не показывать

			if (item.enchant == 0) and not noEnchantWarningSlots[item.slot] then ---- сразу с 0 проверка где не должно
				suffix = "|cffff0000- Нет чарки|r"..suffix
			elseif (item.enchant == 0)  then ---- не показывать где не должно х2
				suffix = suffix
			elseif  enchantidscmn[item.enchant] and not noEnchantWarningSlots[item.slot] then
				suffix = suffix
			elseif  enchantidsnch[item.enchant] then
				suffix = suffix
			elseif  enchantidsring[item.enchant] and ( kolca[item.slot]) then
				suffix = suffix
			elseif enchantidslefthand[item.enchant] and ( lefthand[item.slot]) then
				suffix = suffix
			elseif enchantidspvp[item.enchant] then
				suffix = suffix
			elseif enchantidstolgorod[item.enchant] then
				suffix = suffix
			elseif InspectEquipConfig.bug  then   --- если нету в базе
				suffix = "|cffff0000- Нет в базе пиши репорт|r ---> "..item.enchant.." <--   "..suffix
			elseif (item.enchant >= 1)  then ---- не бк чарка
				suffix = "|cffff0000- Не бк чарка|r"..suffix
			end
		end
		------------------------------------------------------------------------------------------------------------------------ для разрабов
		if  InspectEquipConfig.razrab then --- для разрабов
			suffix = "|cffff0000 чарка айди ---> "..item.enchant.."      сокеты айди  ---> |r" ..item.gemts1.."   "..item.gemts2.."   "..item.gemts3.."   "..item.gemts4.."   "..item.kolvo
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
  ["s9"] = L["Season 9"], ["s10"] = L["Season 10"],["s11"] = L["Season 11"]
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
