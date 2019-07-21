DungeonDataInfoData = {}
InstanceMapInfo = {}
NpcDataInfo = {}

GameTooltip:HookScript("OnTooltipSetUnit", function(self)

  local instanceHash	= select(8, GetInstanceInfo()) .. "," .. select(3, GetInstanceInfo())
  local instanceType 	= select(2, GetInstanceInfo())

  if instanceType == "party" or instanceType == "raid" then
  	
  	local unit = select(2, self:GetUnit())

  	if unit then

  		local guid = UnitGUID(unit) or ""
    	local id = tonumber(guid:match("-(%d+)-%x+$"), 10)
    
    	if id and guid:match("%a+") ~= "Player" then

    		if NpcDataInfo[id] == nil then
	    		local health = UnitHealthMax(unit)
	    		local level = UnitLevel(unit)
	    		local difficultyID = select(3, GetInstanceInfo())

	    		NpcDataInfo[id] = "(" .. tostring(id) .. "," .. tostring(difficultyID) .. "," .. tostring(health) .. ")"
	    		InstanceMapInfo[instanceHash] = NpcDataInfo
	    	end
	    end
	  end

  else
  	local itr = next(InstanceMapInfo)

  	if itr then
  		for MapId in pairs(InstanceMapInfo) do
  				DungeonDataInfoData[MapId] = InstanceMapInfo[MapId]
			end
  	end

  end

end)


