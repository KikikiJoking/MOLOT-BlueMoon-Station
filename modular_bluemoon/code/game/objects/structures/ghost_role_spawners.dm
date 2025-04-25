// Антаг-датумы для разных гостролек, чтобы различать их в орбит панели
/datum/antagonist/ghost_role/inteq
	name = "InteQ Ship Crew"

/datum/antagonist/ghost_role/ghost_cafe
	name = "Ghost Cafe"
	var/area/adittonal_allowed_area

/datum/antagonist/ghost_role/tarkov
	name = "Port Tarkov"

/datum/antagonist/ghost_role/centcom_intern
	name = "Centcom Intern"

/datum/antagonist/ghost_role/ds2
	name = "DS-2 personnel"

/datum/antagonist/ghost_role/space_hotel
	name = "Space Hotel"

/datum/antagonist/ghost_role/hermit
	name = "Hermit"

/datum/antagonist/ghost_role/lavaland_syndicate
	name = "Lavaland Syndicate"

/datum/antagonist/ghost_role/traders
	name  = "Traders"

/datum/antagonist/ghost_role/black_mesa
	name  = "black mesa staff"

/datum/antagonist/ghost_role/hecu
	name  = "HECU squad"

/datum/antagonist/ghost_role/losthecu
	name  = "HECU lost grunt"


mob/living/proc/ghost_cafe_traits(switch_on = FALSE, additional_area)
	if(switch_on)
		AddElement(/datum/element/ghost_role_eligibility, free_ghosting = TRUE)
		AddElement(/datum/element/dusts_on_catatonia)
		var/list/Not_dust_area = list(/area/centcom/holding/exterior,  /area/hilbertshotel)
		if(additional_area)
			Not_dust_area += additional_area
		AddElement(/datum/element/dusts_on_leaving_area, Not_dust_area)

		ADD_TRAIT(src, TRAIT_SIXTHSENSE, GHOSTROLE_TRAIT)
		ADD_TRAIT(src, TRAIT_EXEMPT_HEALTH_EVENTS, GHOSTROLE_TRAIT)
		ADD_TRAIT(src, TRAIT_NO_MIDROUND_ANTAG, GHOSTROLE_TRAIT) //The mob can't be made into a random antag, they are still eligible for ghost roles popups.

		var/datum/action/toggle_dead_chat_mob/D = new(src)
		D.Grant(src)
		var/datum/action/disguise/disguise_action = new(src)
		disguise_action.Grant(src)

	else
		RemoveElement(/datum/element/ghost_role_eligibility, free_ghosting = TRUE)
		RemoveElement(/datum/element/dusts_on_catatonia)
		var/datum/antagonist/ghost_role/ghost_cafe/GC = mind?.has_antag_datum(/datum/antagonist/ghost_role/ghost_cafe)
		if(GC)
			RemoveElement(/datum/element/dusts_on_leaving_area, list(/area/centcom/holding/exterior,  /area/hilbertshotel, GC.adittonal_allowed_area))
		else
			RemoveElement(/datum/element/dusts_on_leaving_area, list(/area/centcom/holding/exterior,  /area/hilbertshotel))

		REMOVE_TRAIT(src, TRAIT_SIXTHSENSE, GHOSTROLE_TRAIT)
		REMOVE_TRAIT(src, TRAIT_EXEMPT_HEALTH_EVENTS, GHOSTROLE_TRAIT)
		REMOVE_TRAIT(src, TRAIT_NO_MIDROUND_ANTAG, GHOSTROLE_TRAIT)

		var/datum/action/toggle_dead_chat_mob/D = locate(/datum/action/toggle_dead_chat_mob) in actions
		if(D)
			D.Remove(src)
		var/datum/action/disguise/disguise_action = locate(/datum/action/disguise) in actions
		if(disguise_action)
			if(disguise_action.currently_disguised)
				remove_alt_appearance("ghost_cafe_disguise")
			disguise_action.Remove(src)

/obj/effect/mob_spawn/qareen/attack_ghost(mob/user, latejoinercalling)
	if(GLOB.master_mode == "Extended")
		return . = ..()
	else
		return to_chat(user, "<span class='warning'>Игра за ЕРП-антагонистов допускается лишь в Режим Extended!</span>")

/obj/effect/mob_spawn/qareen //not grief antag u little shits
	name = "Qareen - The Horny Spirit"
	desc = "An ancient tomb designed for long-term stasis. This one has the word HORNY scratched all over the surface!"
	mob_name = "Qaaren"
	mob_type = 	/mob/living/simple_animal/qareen
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_s"
	short_desc = "Вы Карен!"
	flavour_text = "Вы Карен! Дух похоти! Для общения с другими Карен используйте :q. Ваш прежде мирской дух был запитан инопланетной энергией и преобразован в qareen. Вы не являетесь ни живым, ни мёртвым, а чем-то посередине. Вы способны взаимодействовать с обоими мирами. Вы неуязвимы и невидимы для живых, но не для призраков."
	important_info = "НЕ ГРИФЕРИТЬ, ИНАЧЕ ВАС ЗАБАНЯТ!!"
	death = FALSE
	roundstart = FALSE
	random = FALSE
	uses = 1
	category = "special"

/obj/effect/mob_spawn/qareen/wendigo //not grief antag u little shits
	name = "Woman Wendigo - The Horny Creature"
	short_desc = "Вы Вендиго!"
	desc = "Вендиго. Озабоченный монстр-женщина."
	icon_state = "sleeper_clockwork"
	mob_name = "Wendigo-Woman"
	mob_type = /mob/living/carbon/wendigo
	flavour_text = "Вы Вендиго-Женщина."

/obj/effect/mob_spawn/qareen/wendigo_man //not grief antag u little shits
	name = "Man Werefox - The Horny Creature"
	short_desc = "Вы Лисоборотень!"
	desc = "Озабоченный монстр-мужчина."
	icon_state = "sleeper_clockwork"
	mob_name = "Wendigo-Man"
	mob_type = /mob/living/carbon/wendigo/man
	flavour_text = "Вы Вендиго-Мужчина."

/obj/effect/mob_spawn/qareen/wendigo_lore //not grief antag u little shits
	name = "Wendigo - The Horny Creature"
	short_desc = "Вы таинственное нечто необъятных размеров, редкие свидетели прозвали вас Вендиго!"
	desc = "Вендиго. Огромный, рогатый, четвероногий, озабоченный монстр."
	icon_state = "sleeper_clockwork"
	mob_name = "Wendigo"
	mob_type = /mob/living/simple_animal/wendigo
	flavour_text = "Вы Вендиго. Огромный, рогатый, четвероногий, озабоченный монстр."

/obj/effect/mob_spawn/human/changeling_extended //not grief antag u little shits
	name = "Changeling - The Horny Creature"
	short_desc = "Вы таинственное нечто и абсолютно идеальный организм, который питается возбуждением своих жертв!"
	desc = "Генокрад."
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_clockwork"
	mob_name = "Changeling"
	flavour_text = "Вы Генокрад."
	roundstart = FALSE
	death = FALSE
	random = TRUE
	can_load_appearance = TRUE
	loadout_enabled = TRUE
	use_outfit_name = TRUE
	outfit = /datum/outfit/job/stowaway/syndicate
	category = "special"

/obj/effect/mob_spawn/human/changeling_extended/attack_ghost(mob/user, latejoinercalling)
	if(GLOB.master_mode == "Extended")
		return . = ..()
	else
		return to_chat(user, "<span class='warning'>Игра за ЕРП-антагонистов допускается лишь в Режим Extended!</span>")

/obj/effect/mob_spawn/human/changeling_extended/special(mob/living/new_spawn)
	. = ..()
	var/mob/living/carbon/human/H = new_spawn
	H.mind.make_XenoChangeling()

//warhammer_pirate
/obj/effect/mob_spawn/human/warhammer_pirate
	name = "Space Warhammer Pirate Sleeper"
	desc = "A cryo sleeper smelling faintly of rum. The sleeper looks unstable. <i>Perhaps the pirate within can be killed with the right tools...</i>"
	job_description = "Space Pirate"
	random = TRUE
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	mob_name = "a Warhammer Pirate"
	mob_species = /datum/species/skeleton/space
	outfit = /datum/outfit/warhammer_pirate
	roundstart = FALSE
	death = FALSE
	anchored = TRUE
	density = FALSE
	show_flavour = FALSE
	short_desc = "You are a Warhammer Pirate."
	flavour_text = "Станция отказалась платить вам за крышу. Похитьте её ресурсы, обнесите хранилище на кредиты. Избегайте ненужных жертв. Не забывайте следить за своим кораблем."
	assignedrole = "Space Warhammer Pirate"
	var/rank = "Mate"
	can_load_appearance = FALSE
	category = "midround"

/obj/effect/mob_spawn/human/warhammer_pirate/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	. = ..()
	if(.)
		return
	if(user.mind.has_antag_datum(/datum/antagonist/warhammer_pirate))
		to_chat(user, "<span class='notice'>Your shipmate sails within their dreams for now. Perhaps they may wake up eventually.</span>")
	else
		to_chat(user, "<span class='notice'>If you want to kill the pirate off, something to pry open the sleeper might be the best way to do it.</span>")

/obj/effect/mob_spawn/human/warhammer_pirate/corpse
	mob_name = "Dead Warhammer Pirate"
	death = TRUE
	instant = TRUE
	random = FALSE

/obj/effect/mob_spawn/human/warhammer_pirate/corpse/Destroy()
	return ..()

/obj/effect/mob_spawn/human/warhammer_pirate/special(mob/living/new_spawn)
	new_spawn.fully_replace_character_name(new_spawn.real_name,generate_warhammer_pirate_name())
	new_spawn.mind.add_antag_datum(/datum/antagonist/warhammer_pirate)

/obj/effect/mob_spawn/human/warhammer_pirate/proc/generate_warhammer_pirate_name()
	var/beggings = strings(PIRATE_NAMES_FILE, "beginnings") // заменить
	var/endings = strings(PIRATE_NAMES_FILE, "endings")
	return "[rank] [pick(beggings)] [pick(endings)]"

/obj/effect/mob_spawn/human/warhammer_pirate/Destroy()
	new/obj/structure/showcase/machinery/oldpod/used(drop_location())
	return ..()

/obj/effect/mob_spawn/human/warhammer_pirate/gunner
	rank = "Gunner"
