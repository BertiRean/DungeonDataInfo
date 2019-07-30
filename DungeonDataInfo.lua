DungeonDataInfoData = {}
DungeonSpellTimers = {}
NpcOrSpellNames = {}

local InstanceMapInfo = {}
local NpcHealthInfo = {}
local NpcSpells = { }
local readSpells = false
local readHealth = false;

local NpcInfo = { entry = 0, guids = {} }
NpcInfo.__index = NpcInfo

local function storeSpells()
	for mapInfo, npcTable in pairs(NpcSpells) do

		print(table.concat(npcTable, ","))

		for npcId, npcInfo in pairs(npcTable) do

			local npcSpellTimers = npcInfo:computeTimers()

			if DungeonSpellTimers[mapInfo] == nil then
				DungeonSpellTimers[mapInfo] = {}
			end

			if DungeonSpellTimers[mapInfo][npcId] == nil then
				DungeonSpellTimers[mapInfo][npcId] = {}
			end

			if #npcSpellTimers > 0 then
				for idx, timerStr in pairs(npcSpellTimers) do
					table.insert(DungeonSpellTimers[mapInfo][npcId], timerStr)
				end
			end

		end
	end
end

local function getTableSize(t)
	local count = 0
    for _, __ in pairs(t) do
        count = count + 1
    end
    return count
end

local function clearTable(t)
	
	if t == nil then
		return
	end

	for k,v in pairs(t) do
		t[k] = nil
	end

end

function NpcInfo:new(o, idNpc, guidSpawnId, startCombatTime)
	local o = o or {}
	setmetatable(o, NpcInfo)
	o.entry = idNpc
	o.guids = {}
	o.guids[guidSpawnId] = { startDt = startCombatTime, spells = {} }
	return o
end

function NpcInfo:addSpellCasted(guidSpawnId, spellId, time)

	if self.guids[guidSpawnId].spells[spellId] == nil then
		self.guids[guidSpawnId].spells[spellId] = {}
	end

	local n = #self.guids[guidSpawnId].spells[spellId]

	local dt = difftime(time, self.guids[guidSpawnId].startDt)

	if n < 5 then
		table.insert(self.guids[guidSpawnId].spells[spellId], dt)
	end

end

function NpcInfo:computeTimers()

	local timerData = {}

	for guidHash, guidInfo in pairs(self.guids) do

		for spellId, spellTimers in pairs(guidInfo.spells) do

			local timerStr = "(" .. tostring(spellId) .. "," .. table.concat(spellTimers, ",") .. ")"
			table.insert(timerData, timerStr)
		end
	end

	for guidHash, guidInfo in pairs(self.guids) do
		clearTable(guidInfo.spells)
	end

	return timerData

end

function NpcInfo:getStartCombatTime(guidSpawnId)
	return self.guids[guidSpawnId].startDt;
end

function NpcInfo:hasGuid(guidSpawnId)
	return self.guids[guidSpawnId] ~= nil
end

function NpcInfo:addGuid(guidSpawnId, startCombatTime)
	self.guids[guidSpawnId] = { startDt = startCombatTime, spells = {}}
end

function NpcInfo:getGuidsSize()
    return getTableSize(self.guids)
end


GameTooltip:HookScript("OnTooltipSetUnit", function(self)

  local instanceHash	= select(8, GetInstanceInfo()) .. "," .. select(3, GetInstanceInfo())
  local instanceType 	= select(2, GetInstanceInfo())

  if not readHealth then
  	return
  end

  if instanceType == "party" or instanceType == "raid" then
  	
  	local unit = select(2, self:GetUnit())

  	if unit then

  		local guid = UnitGUID(unit) or ""
    	local id = tonumber(guid:match("-(%d+)-%x+$"), 10)
    
    	if id and guid:match("%a+") ~= "Player" then

    		if NpcHealthInfo[id] == nil then
	    		local health = UnitHealthMax(unit)
	    		local level = UnitLevel(unit)
	    		local difficultyID = select(3, GetInstanceInfo())

	    		NpcHealthInfo[id] = "(" .. tostring(id) .. "," .. tostring(difficultyID) .. "," .. tostring(health) .. ")"
	    		InstanceMapInfo[instanceHash] = NpcHealthInfo
	    	end
	    end
	  end
  end

end)

local function isInstantSpell(spellId)
	
	local spellInfo = GetSpellInfo(spellId)

	if spellInfo then
		return spellInfo["castTime"] == nil
	end
	return false
end

local function getEnterCombatTime(self, event, ... )

	local eventInfo = {CombatLogGetCurrentEventInfo()}
	local guid = eventInfo[4]
	
	if readSpells then
		if eventInfo[2] ~= "UNIT_DIED" and guid:match("%a+") ~= "Player" then

			local mapHash = select(8, GetInstanceInfo()) .. "," .. select(1, GetInstanceInfo())
			local npcEntry = tonumber(guid:match("-(%d+)-%x+$"), 10)
			local guidHash = string.sub(guid, -10)
			local time = eventInfo[1]
			local eventType = eventInfo[2]

			if npcEntry == nil then
				return
			end

			if NpcSpells[mapHash] == nil then
				NpcSpells[mapHash] = { }
			end


			if NpcSpells[mapHash][npcEntry] == nil then
				NpcSpells[mapHash][npcEntry] = NpcInfo:new(nil, npcEntry, guidHash, time)
				NpcOrSpellNames[npcEntry] = eventInfo[5]
			else
				if not NpcSpells[mapHash][npcEntry]:hasGuid(guidHash) and NpcSpells[mapHash][npcEntry]:getGuidsSize() < 3 then
					NpcOrSpellNames[npcEntry] = eventInfo[5]
					NpcSpells[mapHash][npcEntry]:addGuid(guidHash, time)
				end

				if NpcSpells[mapHash][npcEntry]:hasGuid(guidHash) then
					if eventType == "SPELL_CAST_START" then 
						NpcOrSpellNames[eventInfo[12]] = eventInfo[13]
						NpcSpells[mapHash][npcEntry]:addSpellCasted(guidHash, eventInfo[12], time)
					elseif eventType == "SPELL_CAST_SUCCESS" then
						if isInstantSpell(eventInfo[12]) then
							NpcOrSpellNames[eventInfo[12]] = eventInfo[13]
							NpcSpells[mapHash][npcEntry]:addSpellCasted(guidHash, eventInfo[12], time)
						end
					end
				end
			end
		end
	end
end

SLASH_DUNGEONDATA1 = "/dungeonData"
SlashCmdList["DUNGEONDATA"] = function(msg)
	if msg == "storeSpellTimers" then
		storeSpells()
		print("Spell Timers Stored")
	
	elseif msg == "storeHealthValues" then
		local itr = next(InstanceMapInfo)

		if itr then
			for MapId in pairs(InstanceMapInfo) do
				DungeonDataInfoData[MapId] = InstanceMapInfo[MapId]
			end
			print("Health Values Stored")
		end
	elseif msg == "readSpells" then
		if readSpells then
			readSpells = false
			print("Read Spells Off")
		else
			readSpells = true
			print("Read Spells On")
		end
	elseif msg == "readHealth" then
		if readHealth then
			readHealth = false
			print("Read Health Values Off")
		else
			readHealth = true
			print("Read Health Values On")
		end
	elseif msg == "clearMemory" then
		clearTable(NpcSpells)
		clearTable(InstanceMapInfo)
		print("Memory Cleaned")
	else
		print("Invalid Dungeon Data Command")
	end
end

local logoutFrame = CreateFrame("Frame", "logoutFrame")
local combatFrame = CreateFrame("Frame", "combatFrame")
combatFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
combatFrame:SetScript("OnEvent", getEnterCombatTime)

logoutFrame:RegisterEvent("PLAYER_LOGOUT")
logoutFrame:SetScript("OnEvent", function (self, event, ... )
	
	storeSpells()
	print("Spell Timers Stored")

	local itr = next(InstanceMapInfo)

	if itr then
		for MapId in pairs(InstanceMapInfo) do
			DungeonDataInfoData[MapId] = InstanceMapInfo[MapId]
		end
	end
end)
