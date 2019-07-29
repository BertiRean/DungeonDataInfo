import re
import sys

spell_or_npc_names = {}
spells_by_map = { }

def computeDiffTime(timers):

	diffs = []
	size = len(timers)

	if size == 0:
		return []

	if size < 2:
		return [timers[0]]

	for idx in range(1, size):
		diff = int(timers[idx]) - int(timers[idx - 1])

		if diff != 1:
			diffs.append(diff)


	if len(diffs) < 1:
		return []

	return [min(diffs), max(diffs)]

def addSpellTimerInfo(npcEntry, npcCurrMap, spellTimerInfo):

	timerInfo = spellTimerInfo.split(',')

	spellId = timerInfo[0]
	firstCastDt = timerInfo[1]

	if spellId not in spells_by_map[npcCurrMap][npcEntry]:
		spells_by_map[npcCurrMap][npcEntry][spellId] = { "startTimer" : [], "repeatTimers" : [ [] ] }
	
	spells_by_map[npcCurrMap][npcEntry][spellId]["startTimer"].append(int(firstCastDt))
	spells_by_map[npcCurrMap][npcEntry][spellId]["repeatTimers"].append([timerInfo[2:]])
	pass

def get_timers_by_entry(npcEntry):

	hasData = False

	for mapInfo, npcs in spells_by_map.items():

		if npcEntry in npcs:
			hasData = True

			getTimers(npcEntry, npcs[npcEntry])

			return

	if not hasData:
		print("Npc not founded in database")

	pass


def get_trash_data_by_map(mapId):

	if mapId not in spells_by_map:
		print("Map Not found in Database\n")
		return

	filename = "Spell_Casted_In_MapId_" + str(mapId) + ".sql"

	file = open(filename, "a+")

	for mapInfo, npcs in spells_by_map.items():
		for npcId, spells in npcs.items():
			queries = generate_queries(npcId, spells)

			for query in queries:
				file.write(query)

		pass
	pass

	file.close()

	print("Data Writed to ", filename)


def getTimers(npcId, spells_casted):
	
	print("\nNpc Name: ", spell_or_npc_names[npcId], "\n")

	for spellId, timers in spells_casted.items():

		print("Spell:", spell_or_npc_names[spellId], "ID: ", spellId)

		print("Start Timers:\n", timers["startTimer"], "\n")

		print("Repeated Timers:")

		for repeatTimers in timers["repeatTimers"]:
			for repeatTimer in repeatTimers:
				print(repeatTimer, "\nDiff Times: ", computeDiffTime(repeatTimer), "\n")

	pass


def generate_queries(npcEntry, spells_casted):

	queries = []

	idx = 0

	deleteQuery = "DELETE FROM `combat_ai_events` where `entry` = " + npcEntry + ';\n'
	insertQuery = ("INSERT INTO `combat_ai_events` (`entry`, `id`, `start_min`, `start_max`," +
					"`repeat_min`, `repeat_max`, `repeat_fail`, `spell_id`, `event_check`," +
					"`event_flags`, `attack_dist`, `difficulty_mask`, `comment`) VALUES\n")

	queries.append(deleteQuery)
	queries.append(insertQuery)

	npcName = spell_or_npc_names[npcEntry]

	for spellId, timers in spells_casted.items():

		spellName = spell_or_npc_names[spellId]

		minStart = str(min(timers["startTimer"]))
		maxStart = str(max(timers["startTimer"]))

		query = ( "(" + npcEntry + ', ' + str(idx) + ', ' + minStart + ', ' + maxStart + ', ' +
					'repeatMin' + ', ' + "repeatMax" + ', ' + '1000' + ', ' + spellId + ', ' +
					'eventCheck' + ', ' + "eventFlags" + ', ' + "attack_dist" + ', ' + '0' + ', ' + 
					npcName + " - " + spellName + ")\n" )

		queries.append(query)

		idx += 1
	pass

	queryCreatureTemplate = ("\n\nUPDATE `creature_template` SET\n" + 
							"`AIName` = \"LegionCombatAI\",\n" +
							"`ScriptName` = \"\"\n" +
							"WHERE `entry` = " + npcEntry + ";\n\n")

	queries.append(queryCreatureTemplate)

	return queries	


def load_database(inFile):

	if inFile == "":
		return

	file = open(inFile, "r")

	readNames = False
	hasTimers = False
	isReadingNpc = False

	spellPattern = re.compile('\((.*)\)')
	npcPattern = re.compile('\[(\d+)\]')
	mapHashPattern = re.compile('\[\"(.*)\,')
	namePattern = re.compile('\"(.*)\"')

	npcEntry = ""
	curr_mapHash = ""

	for line in file:

		if not readNames and re.search("NpcOrSpellNames", line):
			readNames = True
			hasTimers = False
			continue

		if readNames:
			npcOrSpellId = npcPattern.search(line)
			npcOrSpellName = namePattern.search(line)

			if npcOrSpellId and npcOrSpellName:
				spell_or_npc_names[npcOrSpellId.group(1)] = npcOrSpellName.group(1)

			continue

		if not hasTimers and not readNames and re.search("DungeonSpellTimers", line):
			hasTimers = True
			continue

		if hasTimers:

			if not isReadingNpc:
				isMapHash = mapHashPattern.search(line)

				if isMapHash:
					curr_mapHash = isMapHash.group(1)
					print(curr_mapHash, type(curr_mapHash))
					spells_by_map[curr_mapHash] = {}

			if isReadingNpc:

				spell = spellPattern.search(line)

				if not spell:
					isReadingNpc = False
					continue
					#getTimers(npcEntry)
				else:
					addSpellTimerInfo(npcEntry, curr_mapHash, spell.group(1))

			result = npcPattern.search(line)
			
			if not isReadingNpc and result:
				isReadingNpc = True
				npcEntry = result.group(1)
				npcs = spells_by_map[curr_mapHash]
				npcs[npcEntry] = {}

	file.close()

pass

load_database(sys.argv[1])
print("type exit or Exit to finish the program")

while True:
	print("Introduce the mode of consult: \n - 1 for generate scripts by map id\n - 2 for consult with npcId\n")
	mode = input()

	if mode == "exit" or mode == "Exit":
		print("Thanks for using")
		exit()
	elif int(mode) == 1:
		inp = input("Introduce Map Id: ")
		get_trash_data_by_map(inp)
	elif int(mode) == 2:
		inp = input("Introduce Npc Entry: ")
		get_timers_by_entry(inp)
	else:
		print("Invalid option please introduce a number between 1 and 2")
