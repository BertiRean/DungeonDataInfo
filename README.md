# DungeonDataInfo
WoW Addon for get useful info about npcs in dungeons and raids.

Basic addon that get the hp values and the difficulty of the dungeon/raid where they are used when you see the tooltip of Npcs in game.

You will get the data in this format

["645,2"] = {
		[39698] = "(39698,2,300480)",
}

Legend:
- "645,2" value correspond to "MapId, Difficulty" table where all npcs from instances are stored.
- [39698] = "(39698,2,300480)" correspond to "Entry or Id from Npc, Difficulty Value, Max Health Value".

This data is stored in SavedVariables file of your account id:

Example:
  D:\World of Warcraft\_retail_\WTF\Account\#AccountId\SavedVariables\DungeonDataInfo.lua
