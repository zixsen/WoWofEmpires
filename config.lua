local ADDON_NAME, WoWofEmpires = ...
WoWofEmpires = WoWofEmpires or {}
WoWofEmpires.Config = WoWofEmpires.Config or {}

local Config = WoWofEmpires.Config

Config.soundFolder = "Interface\\AddOns\\WoWofEmpires\\sound\\"
Config.textureFolder = "Interface\\AddOns\\WoWofEmpires\\texture\\"

Config.IntToSound = {
    [1] = "Yes.ogg",
    [2] = "No.ogg",
    [3] = "Food,_please.ogg",
    [4] = "Wood,_please.ogg",
    [5] = "Gold,_please.ogg",
    [6] = "Stone,_please.ogg",
    [7] = "Ahh.ogg",
    [8] = "All_hail.ogg",
    [9] = "Oooh.ogg",
    [10] = "Back_to_age_one.ogg",
    [11] = "Herb_laugh.ogg",
    [12] = "Being_rushed.ogg",
    [13] = "Blame_your_isp.ogg",
    [14] = "Start_the_game.ogg",
    [15] = "Don't_point_that_thing.ogg",
    [16] = "Enemy_sighted.ogg",
    [17] = "It_is_good.ogg",
    [18] = "I_need_a_monk.ogg",
    [19] = "Long_time_no_siege.ogg",
    [20] = "My_granny.ogg",
    [21] = "Nice_town_i'll_take_it.ogg",
    [22] = "Quit_touchin.ogg",
    [23] = "Raiding_party.ogg",
    [24] = "Dadgum.ogg",
    [25] = "Smite_me.ogg",
    [26] = "The_wonder.ogg",
    [27] = "You_play_two_hours.ogg",
    [28] = "You_should_see_the_other_guy.ogg",
    [29] = "Roggan.ogg",
    [30] = "Wololo.ogg",
    [31] = "Attack_an_enemy_now.ogg",
    [36] = "Wait_for_my_signal_to_attack.ogg",
    [42] = "What_age_are_you_in.ogg",
    [105] = "Resign.ogg",
}

WoWofEmpires.Config.StringToSound = {
    ["ohnono"] = "Oh-no-no-no.mp3",
    ["damn"] = "goddamnboah.mp3",
    ["bruh"] = "bruh.mp3",
    ["yeboi"] = "heheyeahboy.ogg",
    ["anton"] = "anton.mp3",
    ["zzz"] = "zzz.ogg",
    ["gay"] = "hah-gay.mp3",
    ["huuu"] = "huuuuuuu.mp3",
    ["fake news"] = "fake-news-great.mp3",
    ["fast"] = "im-fast-as-fuck-boii-2.mp3",
    ["snoop"] = "snoop dogg.mp3",
    ["wow"] = "wow.ogg",
    ["hype"] = "Zulp Hype.ogg",
    ["bitconnect"] = "Bitconnect.ogg",
    ["hehehey"] = "heheheey.ogg",
    ["nonono"] = "mmhmmhnonono.ogg",
    ["wassawassa"] = "wasa-wasa-wasa-wassup.ogg",
    ["whaat"] = "whaaat.ogg",
    ["whatsup"] = "wowwowWhatsUp.ogg",
    ["run"] = "run.ogg",
    ["whyrun"] = "Why are you running.ogg",
    ["maths"] = "Quick maths.ogg",
    ["skrra"] = "Skrra.ogg",
    ["stats"] = "Check the statistacs.ogg",
    ["profamity"] = "Watch yo profamity.ogg",
    ["durudu"] = "Durudu.ogg",
}

WoWofEmpires.Config.TEH_SQUAD = {
    ["Addons"] = true,
    ["Krasslig"] = true,
    ["Moffegreven"] = true,
    ["Koettpangmos"] = true,
    ["Enticed"] = true,
    ["Doodoodoo"] = true,
    ["Barre"] = true,
    ["Bength"] = true,
}

WoWofEmpires.Config.chatEvents = {
    "CHAT_MSG_YELL",
    "CHAT_MSG_SAY",
    "CHAT_MSG_PARTY",
    "CHAT_MSG_WHISPER",
    "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_GUILD",
    "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_EMOTE"
}
