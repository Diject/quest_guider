local this = {}

this.weaponTypeNameById = {
    [-1] = "unarmed",
    [0] = "short blade, one handed",
    [1] = "long blade, one handed",
    [2] = "long blade, two handed",
    [3] = "blunt, one handed",
    [4] = "blunt, two handed close",
    [5] = "blunt, two handed wide",
    [6] = "spear, two handed",
    [7] = "axe, one handed",
    [8] = "axe, two handed",
    [9] = "bow",
    [10] = "crossbow",
    [11] = "thrown weapon",
    [12] = "arrow",
    [13] = "bolt",
}

this.magicEffectConsts = {
    ["seffectabsorbattribute"] = 85,
    ["seffectdrainfatigue"] = 20,
    ["seffectrestorefatigue"] = 77,
    ["seffectabsorbfatigue"] = 88,
    ["seffectdrainhealth"] = 18,
    ["seffectrestorehealth"] = 75,
    ["seffectabsorbhealth"] = 86,
    ["seffectdrainskill"] = 21,
    ["seffectrestoreskill"] = 78,
    ["seffectabsorbskill"] = 89,
    ["seffectdrainspellpoints"] = 19,
    ["seffectrestorespellpoints"] = 76,
    ["seffectabsorbspellpoints"] = 87,
    ["seffectextraspell"] = 126,
    ["seffectsanctuary"] = 42,
    ["seffectalmsiviintervention"] = 63,
    ["seffectfeather"] = 8,
    ["seffectshield"] = 3,
    ["seffectblind"] = 47,
    ["seffectfiredamage"] = 14,
    ["seffectshockdamage"] = 15,
    ["seffectboundbattleaxe"] = 123,
    ["seffectfireshield"] = 4,
    ["seffectsilence"] = 46,
    ["seffectboundboots"] = 129,
    ["seffectfortifyattackbonus"] = 117,
    ["seffectslowfall"] = 11,
    ["seffectboundcuirass"] = 127,
    ["seffectfortifyattribute"] = 79,
    ["seffectsoultrap"] = 58,
    ["seffectbounddagger"] = 120,
    ["seffectfortifyfatigue"] = 82,
    ["seffectsound"] = 48,
    ["seffectboundgloves"] = 131,
    ["seffectfortifyhealth"] = 80,
    ["seffectspellabsorption"] = 67,
    ["seffectboundhelm"] = 128,
    ["seffectfortifymagickamultiplier"] = 84,
    ["seffectstuntedmagicka"] = 136,
    ["seffectboundlongbow"] = 125,
    ["seffectfortifyskill"] = 83,
    ["seffectsummonancestralghost"] = 106,
    ["seffectboundlongsword"] = 121,
    ["seffectfortifyspellpoints"] = 81,
    ["seffectsummonbonelord"] = 110,
    ["seffectboundmace"] = 122,
    ["seffectfrenzycreature"] = 52,
    ["seffectsummoncenturionsphere"] = 134,
    ["seffectboundshield"] = 130,
    ["seffectfrenzyhumanoid"] = 51,
    ["seffectsummonclannfear"] = 103,
    ["seffectboundspear"] = 124,
    ["seffectfrostdamage"] = 16,
    ["seffectsummondaedroth"] = 104,
    ["seffectburden"] = 7,
    ["seffectfrostshield"] = 6,
    ["seffectsummondremora"] = 105,
    ["seffectcalmcreature"] = 50,
    ["seffectinvisibility"] = 39,
    ["seffectsummonflameatronach"] = 114,
    ["seffectcalmhumanoid"] = 49,
    ["seffectjump"] = 9,
    ["seffectsummonfrostatronach"] = 115,
    ["seffectchameleon"] = 40,
    ["seffectlevitate"] = 10,
    ["seffectsummongoldensaint"] = 113,
    ["seffectcharm"] = 44,
    ["seffectlight"] = 41,
    ["seffectsummongreaterbonewalker"] = 109,
    ["seffectcommandcreatures"] = 118,
    ["seffectlightningshield"] = 5,
    ["seffectsummonhunger"] = 112,
    ["seffectcommandhumanoids"] = 119,
    ["seffectlock"] = 12,
    ["seffectsummonleastbonewalker"] = 108,
    ["seffectcorpus"] = 132,
    ["seffectmark"] = 60,
    ["seffectsummonscamp"] = 102,
    ["seffectcureblightdisease"] = 70,
    ["seffectnighteye"] = 43,
    ["seffectsummonskeletalminion"] = 107,
    ["seffectcurecommondisease"] = 69,
    ["seffectopen"] = 13,
    ["seffectsummonstormatronach"] = 116,
    ["seffectcurecorprusdisease"] = 71,
    ["seffectparalyze"] = 45,
    ["seffectsummonwingedtwilight"] = 111,
    ["seffectcureparalyzation"] = 73,
    ["seffectpoison"] = 27,
    ["seffectsundamage"] = 135,
    ["seffectcurepoison"] = 72,
    ["seffectrallycreature"] = 56,
    ["seffectswiftswim"] = 1,
    ["seffectdamageattribute"] = 22,
    ["seffectrallyhumanoid"] = 55,
    ["seffecttelekinesis"] = 59,
    ["seffectdamagefatigue"] = 25,
    ["seffectrecall"] = 61,
    ["seffectturnundead"] = 101,
    ["seffectdamagehealth"] = 23,
    ["seffectreflect"] = 68,
    ["seffectvampirism"] = 133,
    ["seffectdamagemagicka"] = 24,
    ["seffectremovecurse"] = 100,
    ["seffectwaterbreathing"] = 0,
    ["seffectdamageskill"] = 26,
    ["seffectresistblightdisease"] = 95,
    ["seffectwaterwalking"] = 2,
    ["seffectdemoralizecreature"] = 54,
    ["seffectresistcommondisease"] = 94,
    ["seffectweaknesstoblightdisease"] = 33,
    ["seffectdemoralizehumanoid"] = 53,
    ["seffectresistcorprusdisease"] = 96,
    ["seffectweaknesstocommondisease"] = 32,
    ["seffectdetectanimal"] = 64,
    ["seffectresistfire"] = 90,
    ["seffectweaknesstocorprusdisease"] = 34,
    ["seffectdetectenchantment"] = 65,
    ["seffectresistfrost"] = 91,
    ["seffectweaknesstofire"] = 28,
    ["seffectdetectkey"] = 66,
    ["seffectresistmagicka"] = 93,
    ["seffectweaknesstofrost"] = 29,
    ["seffectdisintegratearmor"] = 38,
    ["seffectresistnormalweapons"] = 98,
    ["seffectweaknesstomagicka"] = 31,
    ["seffectdisintegrateweapon"] = 37,
    ["seffectresistparalysis"] = 99,
    ["seffectweaknesstonormalweapons"] = 36,
    ["seffectdispel"] = 57,
    ["seffectresistpoison"] = 97,
    ["seffectweaknesstopoison"] = 35,
    ["seffectdivineintervention"] = 62,
    ["seffectresistshock"] = 92,
    ["seffectweaknesstoshock"] = 30,
    ["seffectdrainattribute"] = 17,
    ["seffectrestoreattribute"] = 74,
}

this.vampireClan = {
    [1] = "Aundae",
    [2] = "Berne",
    [3] = "Quarra",
}

return this