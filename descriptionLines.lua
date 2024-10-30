local types = include("diject.quest_guider.types")

return {
    [types.requirementType.CustomActor] = { str = "Talk to #objectName#", priority = -1000 },
    [types.requirementType.Item] = { str = "\"#varName#\" item count is #operator# #value# for #objectName#", },
    [types.requirementType.CustomDisposition] = { str = "Disposition of the actor is #operator# #value#", priority = -1001 },
    [types.requirementType.PreviousDialogChoice] = { str = "#value# dialogue option is selected", priority = -1001 },
    [types.requirementType.CustomPCFaction] = { str = "The player in #valueName# faction", },
    [types.requirementType.Dead] = { str = "#varName#'s death count is #operator# #value#", },
    [types.requirementType.CustomActorCell] = { str = "Find the actor in #valueName#", priority = -1000 },
    [types.requirementType.NotActorID] = { str = "The actor is#negNotContr# #varName#", priority = -1001 },
    [types.requirementType.CustomPCRank] = { str = "#rankName# rank for #varName#", },
    [types.requirementType.CustomActorGender] = { str = "Someone's gender is #operator# @value == 0 and \"male\" or \"female\"@", priority = -1001 },
    [types.requirementType.PlayerLevel] = { str = "Player level is #operator# #value#", },
    [types.requirementType.CustomActorFaction] = { str = "The NPC in #valueName# faction", priority = -1001 },
    [types.requirementType.NotActorRace] = { str = "Race of #objectName# is#negNotContr# #variable#", priority = -1001 },
    [types.requirementType.Journal] = { str = "Stage of \"#varQuestName#\" quest is #operator# #value#", },
    [types.requirementType.CustomLocal] = { str = "Local variable @variable@ for #objectName# is #operator# #value#", },
    [types.requirementType.CustomCurrentAIPackage] = { str = "AI action in action", },
    [types.requirementType.CustomGlobal] = { str = "Global variable @variable@ is #operator# #value#", },
    [types.requirementType.CustomDistance] = { str = "Distance to #varName# is #operator# #value#", },
    [types.requirementType.CustomActorClass] = { str = "The NPC's class is #operator# #classVal#", priority = -1001 },
    [types.requirementType.NPCSameFactionAsPlayer] = { str = "#objectName# faction is#notContr# equal player's faction", },
    [types.requirementType.NPCTalkedToPlayer] = { str = "#objectName# talked to the player @value == 0 and \"before\" or \"\"@", },
    [types.requirementType.CustomSkill] = { str = "#skillName# of #objectName# is #operator# #value#", },
    [types.requirementType.PlayerGender] = { str = "Player gender is #operator# @value == 0 and \"male\" or \"female\"@", },
    [types.requirementType.CustomAIPackageDone] = { str = "AI action of #objectName# is#notContr# done", },
    [types.requirementType.NPCSameGenderAsPlayer] = { str = "#objectName# has#notContr# same gender as the player", },
    [types.requirementType.CustomAttribute] = { str = "#attributeName# of #objectName# is #operator# #value#", },
    [types.requirementType.PlayerReputation] = { str = "Player's reputation is #operator# #value#", },
    [types.requirementType.RankRequirement] = { str = "#rankName# rank for #varName# of #objectName#", },
    [types.requirementType.PlayerIsVampire] = { str = "The player is#notContr# a vampire", },
    [types.requirementType.NPCIsAlarmed] = { str = "#objectName# is#notContr# alarmed", },
    [types.requirementType.NPCAttacked] = { str = "#objectName# is#notContr# attacked", },
    [types.requirementType.PlayerIsDetected] = { str = "The player is#notContr# detected", },
    [types.requirementType.CustomPCSleep] = { str = "The player is#notContr# asleep", },
    [types.requirementType.PlayerBlightDisease] = { str = "The player is#notContr# sick with a blight disease", },
    [types.requirementType.CustomDisabled] = { str = "Disabled state of the object is #operator# @value==1 and \"true\" or \"false\"@", priority = -1001 },
    [types.requirementType.CustomOnPCAdd] = { str = "The item was#notContr# added", priority = -1001 },
    [types.requirementType.NPCReputation] = { str = "Reputation of #objectName# is #operator# #value#", },
    [types.requirementType.PlayerClothingModifier] = { str = "The value of items equipped on #objectName# is #operator# #value#", },
    [types.requirementType.PlayerHealth] = { str = "Health of #objectName# is #operator# #value#", },
    [types.requirementType.CustomBlightDisease] = { str = "The actor is#notContr# sick with a blight disease", priority = -1001},
    [types.requirementType.NPCSameRaceAsPlayer] = { str = "The NPC has#notContr# the same rase as the player", priority = -1001},
    [types.requirementType.CustomWeaponDrawn] = { str = "Weapon of #objectName# is#notContr# drawn"},
    [types.requirementType.CustomNotLocal] = { str = "The object has#negNotContr# attached \"#variable#\" script", priority = -1001 },
    [types.requirementType.PlayerRankMinusNPCRank] = { str = "The difference in rank between the actor and #objectName# is #operator# #value#", priority = -1001 },
    [types.requirementType.CustomScale] = { str = "Scale of the object is #operator# #value#", priority = -1001 },
    [types.requirementType.PlayerCorprus] = { str = "The player has#notContr# corprus", },
    [types.requirementType.CustomCellChanged] = { str = "After the player has#notContr# changed location", priority = -1001 },
    [types.requirementType.PlayerExpelledFromNPCFaction] = { str = "The player has been expelled from the NPC's faction", priority = -1001 },
    [types.requirementType.NPCHello] = { str = "The actor's \"hello\" stat is #operator# #value#", priority = -1001 },
    [types.requirementType.NPCAlarm] = { str = "The actor's \"alarm\" stat is #operator# #value#", priority = -1001 },
    [types.requirementType.NPCFlee] = { str = "The actor's \"flee\" stat is #operator# #value#", priority = -1001 },
    [types.requirementType.CustomOnActivate] = { str = "You do#notContr# activate the object", priority = -1001 },
    [types.requirementType.CustomOnMurder] = { str = "You did#notContr# kill the actor and you were seen", priority = -1001 },
    [types.requirementType.CustomOnKnockout] = { str = "@objectObj~=nil and (objectObj.name or \"\") or \"The actor\"@ is#notContr# knocked out", priority = -1001 },
    [types.requirementType.NotActorFaction] = { str = "The NPC's faction is#negNotContr# #operator# #varName#", priority = -1001 },
    [types.requirementType.CustomRace] = { str = "Race of #objectName# is#notContr# @variableObj and (variableObj.name or variable) or variable@", priority = -1001 },
    [types.requirementType.CustomPos] = { str = "#variable# position of the object is #operator# #value#", priority = -1001 },
    [types.requirementType.CustomInterior] = { str = "The player is#notContr# in an interior cell", priority = -1001 },
    [types.requirementType.CustomSpell] = { str = "@objectObj and objectObj.name or \"The actor\"@ has#notContr# \"#varName#\" spell", priority = -1001 },
    [types.requirementType.CustomLocked] = { str = "The object is#notContr# locked", priority = -1001 },
    [types.requirementType.CustomScriptRunning] = { str = "\"#variable#\" script is#notContr# running", },
    [types.requirementType.CustomGameHour] = { str = "Time of day is #operator# #value#", },
    [types.requirementType.CustomWeaponType] = { str = "A weapon with the type of #weaponType# is#notContr# used by #objectName#", priority = -1001 },
    [types.requirementType.PlayerCommonDisease] = { str = "The player is#notContr# sick with a common disease", },
    [types.requirementType.CustomHasSoulgem] = { str = "The player has #operator# #value# soulgame@value>1 and \"s\" or \"\"@ containing soul of #varName#", },
    [types.requirementType.CustomStandingPC] = { str = "Someone is#notContr# standing on #objectName# (#object#)", },
    [types.requirementType.CustomEffect] = { str = "#magicEffect# effect is#notContr# affecting @objectObj and objectObj.name or \"the actor\"@", priority = -1001 },
    [types.requirementType.CustomLineOfSight] = { str = "The object is#notContr# in line-of-sight to #varName#", priority = -1001 },
    [types.requirementType.NPCLevel] = { str = "Level of #objectName# is #operator# #value#", priority = -1001 },
    [types.requirementType.CustomOnDeath] = { str = "@objectObj and objectObj.name or \"The actor\"@ is#notContr# killed", priority = -1001 },
    [types.requirementType.CustomOnPCHitMe] = { str = "The actor is#notContr# alarmed by a crime", priority = -1001 },
    [types.requirementType.CustomTarget] = { str = "#varName# is#notContr# in focus for @objectObj and objectObj.name or \"the actor\"@", priority = -1001 },
    [types.requirementType.NotActorClass] = { str = "The NPC's class is#notContr# #classVar#", priority = -1001 },
    [types.requirementType.CustomCommonDisease] = { str = "@objectObj and objectObj.name or \"The actor\"@ is#notContr# sick with a common disease", priority = -1001 },
    [types.requirementType.PlayerCrimeLevel] = { str = "The current crime level of the player is #operator# #value#", },
    [types.requirementType.CustomOnPCEquip] = { str = "The player equipped an item with \"@script@\" script", },
    [types.requirementType.CustomPCCell] = { str = "The player is#notContr# in #varName#", },
    [types.requirementType.CustomSayDone] = { str = "@objectObj and objectObj.name or \"The actor\"@ is#negNotContr# saying anything", priority = -1001 },
    [types.requirementType.NotActorCell] = { str = "@objectObj and objectObj.name or \"The actor\"@ is#negNotContr# in #varName#", },
    [types.requirementType.CustomHasItemEquipped] = { str = "@objectObj and objectObj.name or \"The actor\"@ has#notContr# #varName# item equipped", priority = -1001 },
    [types.requirementType.CustomHealth] = { str = "Health of @objectObj and objectObj.name or \"the actor\"@ is #operator# #value#", priority = -1001 },
    [types.requirementType.CustomSoundPlaying] = { str = "\"#variable#\" sound is#notContr# playing", },
    [types.requirementType.CustomScript] = { str = "\"#variable#\" script", },
    [types.requirementType.CustomDay] = { str = "The date is #operator# #value#", },
    [types.requirementType.CustomMonth] = { str = "The month is #operator# #value#", },
    [types.requirementType.CustomYear] = { str = "The year is #operator# #value#", },
    [types.requirementType.CustomMenuMode] = { str = "The game is#notContr# in menu mode", },
    [types.requirementType.CustomRandom] = { str = "Random number is #operator# #value#", },
    [types.requirementType.CustomAngle] = { str = "#variable# angle of #objectName# (\"#object#\") is #operator# #value#", },
    [types.requirementType.CustomVampClan] = { str = "Player's vanpire clan is #operator# #vampClanVal#", },
    [types.requirementType.Weather] = { str = "Weather is #operator# #weatherIdVal#", },
    [types.requirementType.CustomSpellReadied] = { str = "A spell is#notContr# readied for @objectObj and objectObj.name or \"the actor\"@", },
    [types.requirementType.CustomPCWerewolf] = { str = "The player is#notContr# werewolf", },
    [types.requirementType.PlayerWerewolfKills] = { str = "The player werewolf kill count is #operator# #value#", },
    [types.requirementType.CustomWindSpeed] = { str = "Wind speed is #operator# #value#", },
    [types.requirementType.CustomPCSneaking] = { str = "The player is#notContr# sneaking", },
    [types.requirementType.PlayerHealthPercent] = { str = "The player's health fraction is #operator# #value#", },
    [types.requirementType.NPCHealthPercent] = { str = " @objectObj and objectObj.name or \"The actor\"@'s health fraction is #operator# #value#", },
}