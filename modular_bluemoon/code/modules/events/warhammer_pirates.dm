/*
/datum/round_event_control/warhammer_pirate
	name = "Warhammer Pirates"
	typepath = /datum/round_event/warhammer_pirate
	weight = 20
	max_occurrences = 1
	min_players = 30
	earliest_start = 45 MINUTES
	dynamic_should_hijack = TRUE
	category = EVENT_CATEGORY_INVASION
	description = "The crew will either pay up, or face a pirate assault."

#define WARHAMMER_PIRATE_ROGUES "Rogues"
// #define WARHAMMER_PIRATE_SILVERSCALES "Silverscales"
// #define WARHAMMER_PIRATE_DUTCHMAN "Flying Dutchman"

/proc/send_warhammer_pirate_threat()
	var/warhammer_pirate_type = WARHAMMER_PIRATE_ROGUES //pick(WARHAMMER_PIRATE_ROGUES, WARHAMMER_PIRATE_SILVERSCALES, WARHAMMER_PIRATE_DUTCHMAN)
	var/datum/comm_message/threat_msg = new
	var/payoff = 0
	var/payoff_min = 25000 //documented this time
	var/ship_template
	var/ship_name = "Regal Aquitaine"
	var/initial_send_time = world.time
	var/response_max_time = 3 MINUTES
	switch(warhammer_pirate_type)
		if(WARHAMMER_PIRATE_ROGUES)
			ship_name = pick(strings(PIRATE_NAMES_FILE, "rogue_names"))

	priority_announce("Входящая подпространственная передача данных. Открыт защищенный канал связи на всех коммуникационных консолях.", "Предложение о Защите Сектора", SSstation.announcer.get_rand_report_sound(), has_important_message = TRUE)
	var/datum/bank_account/D = SSeconomy.get_dep_account(ACCOUNT_CAR)
	if(D)
		payoff = max(payoff_min, FLOOR(D.account_balance * 0.80, 1000))
	switch(warhammer_pirate_type)
		if(WARHAMMER_PIRATE_ROGUES)
			ship_template = /datum/map_template/shuttle/pirate/default // Заменить
			threat_msg.title = "Предложение о Защите Сектора"
			threat_msg.content = "Приветствуем вас с корабля [ship_name]. Ваш сектор нуждается в защите, заплатите нам [payoff] кредитов или на вас наверняка кто-то нападёт."
			threat_msg.possible_answers = list("Мы заплатим.","Мы заплатим, но на самом деле нет.")

	threat_msg.answer_callback = CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(pirates_answered), threat_msg, payoff, ship_name, initial_send_time, response_max_time, ship_template)
	SScommunications.send_message(threat_msg,unique = TRUE)

/proc/warhammer_pirate_answered(datum/comm_message/threat_msg, payoff, ship_name, initial_send_time, response_max_time, ship_template)
	if(world.time > initial_send_time + response_max_time)
		priority_announce("Слишком поздно умолять о пощаде!", ship_name, 'modular_bluemoon/phenyamomota/sound/announcer/pirate_nopeacedecision.ogg', "Priority")
		spawn_pirates(threat_msg, ship_template, TRUE)
		return
	if(threat_msg && threat_msg.answered == 1)
		var/datum/bank_account/D = SSeconomy.get_dep_account(ACCOUNT_CAR)
		if(D)
			if(D.adjust_money(-payoff))
				priority_announce("Спасибо за кредиты, сухопутные крысы!", ship_name, 'modular_bluemoon/phenyamomota/sound/announcer/pirate_yespeacedecision.ogg', "Priority")
			else
				priority_announce("Пытаешься нас обмануть? Ты пожалеешь об этом!", ship_name, 'modular_bluemoon/phenyamomota/sound/announcer/pirate_nopeacedecision.ogg', "Priority")
				spawn_pirates(threat_msg, ship_template, TRUE)
				return
	else
		priority_announce("Пытаешься нас обмануть? Ты пожалеешь об этом!", ship_name, 'modular_bluemoon/phenyamomota/sound/announcer/pirate_nopeacedecision.ogg', "Priority")
		spawn_pirates(threat_msg, ship_template, TRUE)

/datum/round_event_control/warhammer_pirate/preRunEvent()
	if (!SSmapping.empty_space)
		return EVENT_CANT_RUN

	return ..()

/datum/round_event/warhammer_pirate/start()
	send_pirate_threat()
/*
/proc/spawn_warhammer_pirate(datum/comm_message/threat_msg, ship_template, skip_answer_check)
	if(!skip_answer_check && threat_msg?.answered == 1)
		return

	var/list/candidates = pollGhostCandidates("Вы желаете стать космопиратом?", ROLE_TRAITOR)
	shuffle_inplace(candidates)

	var/datum/map_template/shuttle/pirate/ship = new ship_template // Заменить
	var/x = rand(TRANSITIONEDGE, world.maxx - TRANSITIONEDGE - ship.width)
	var/y = rand(TRANSITIONEDGE, world.maxy - TRANSITIONEDGE - ship.height)
	var/z = SSmapping.empty_space.z_value
	var/turf/T = locate(x,y,z)
	if(!T)
		CRASH("Warhammer pirate event found no turf to load in")

	if(!ship.load(T))
		CRASH("Loading pirate ship failed!") // как появится у них корабль, заменить на соотвесвутющий вывод о ошибке

	for(var/turf/A in ship.get_affected_turfs(T))
		for(var/obj/effect/mob_spawn/human/warhammer_pirate/spawner in A)
			if(candidates.len > 0)
				var/mob/our_candidate = candidates[1]
				spawner.create(our_candidate.ckey)
				candidates -= our_candidate
				notify_ghosts("The pirate ship has an object of interest: [our_candidate]!", source=our_candidate, action=NOTIFY_ORBIT, header="Something's Interesting!")
			else
				notify_ghosts("The pirate ship has an object of interest: [spawner]!", source=spawner, action=NOTIFY_ORBIT, header="Something's Interesting!")

	priority_announce("В секторе обнаружен вооруженный корабль.", "Отдел ССО Пакта Синих Лун", 'modular_bluemoon/phenyamomota/sound/announcer/pirate_incoming.ogg')
*/
/obj/machinery/computer/shuttle/warhammer_pirate
	name = "WarHammer shuttle console"
	shuttleId = "WarHammership"
	icon_screen = "syndishuttle"
	icon_keyboard = "syndie_key"
	light_color = LIGHT_COLOR_RED
	req_access = list(ACCESS_SYNDICATE)
	possible_destinations = "pirateship_away;pirateship_home;pirateship_custom"

/obj/machinery/computer/camera_advanced/shuttle_docker/syndicate/warhammer_pirate
	name = "Pirate Shuttle Navigation Computer"
	desc = "Used to designate a precise transit location for the pirate shuttle."
	shuttleId = "WarHammership"
	lock_override = CAMERA_LOCK_STATION
	shuttlePortId = "pirateship_custom"
	x_offset = 11
	y_offset = 1
	see_hidden = FALSE

/obj/docking_port/mobile/warhammer_pirate
	name = "WarHammer shuttle"
	shuttle_id = "WarHammership"
	rechargeTime = 3 MINUTES

/obj/machinery/suit_storage_unit/warhammer_pirate
	helmet_type = /obj/item/clothing/head/helmet/space/pirate/bandana/eva
	suit_type = /obj/item/clothing/suit/space/pirate
	mask_type = /obj/item/clothing/mask/gas/glass
	storage_type = /obj/item/tank/jetpack/oxygen/harness

/obj/machinery/suit_storage_unit/warhammer_pirate/captain
	helmet_type = /obj/item/clothing/head/helmet/space/pirate/eva
	suit_type = /obj/item/clothing/suit/space/pirate
	mask_type = /obj/item/clothing/mask/gas/glass
	storage_type = /obj/item/tank/jetpack/oxygen/harness

/obj/item/clothing/head/helmet/space/warhammer_pirate/eva
	name = "Heavy Modified EVA helmet"
	desc = "A modified helmet to allow space pirates to intimidate their customers whilst staying safe from the void. Comes with some additional protection."
	icon_state = "spacepirate"
	item_state = "space_pirate_helmet"
	armor = list(MELEE = 20, BULLET = 40, LASER = 30, ENERGY = 25, BOMB = 50, BIO = 100, RAD = 50, FIRE = 80, ACID = 80, WOUND = 20)
	strip_delay = 40
	equip_delay_other = 20
	//species_restricted = list("Vox")

/obj/item/clothing/head/helmet/space/warhammer_pirate/bandana/eva
	icon_state = "spacebandana"
	item_state = "space_bandana_helmet"

/obj/item/clothing/suit/space/warhammer_pirate/eva
	name = "Heavy Modified EVA suit"
	desc = "A modified suit to allow space pirates to board shuttles and stations while avoiding the maw of the void. Comes with additional protection and is lighter to move in."
	icon_state = "spacepirate"
	w_class = WEIGHT_CLASS_NORMAL
	allowed = list(/obj/item/gun, /obj/item/ammo_box, /obj/item/ammo_casing, /obj/item/melee/baton, /obj/item/restraints/handcuffs, /obj/item/tank/internals, /obj/item/melee/transforming/energy/sword/pirate, /obj/item/clothing/glasses/eyepatch, /obj/item/reagent_containers/food/drinks/bottle/rum)
	slowdown = 0
	armor = list(MELEE = 20, BULLET = 40, LASER = 30,ENERGY = 25, BOMB = 50, BIO = 100, RAD = 50, FIRE = 80, ACID = 80, WOUND = 20)
	strip_delay = 40
	equip_delay_other = 20
	//species_restricted = list("Vox")

//Warhammer Pirates outfit
/obj/item/clothing/head/helmet/space/warhammer_pirate
	name = "royal tricorne"
	desc = "A thick, space-proof tricorne from the royal Space Queen. It's lined with a layer of reflective kevlar."
	icon_state = "pirate"
	item_state = "pirate"
	armor = list(MELEE = 30, BULLET = 50, LASER = 30,ENERGY = 15, BOMB = 30, BIO = 30, RAD = 30, FIRE = 60, ACID = 75, WOUND = 30)
	flags_inv = HIDEHAIR
	strip_delay = 40
	equip_delay_other = 20
	flags_cover = HEADCOVERSEYES
	mutantrace_variation = NONE

/obj/item/clothing/head/helmet/space/warhammer_pirate/bandana
	name = "royal bandana"
	desc = "A space-proof bandanna crafted with reflective kevlar."
	icon_state = "bandana"
	item_state = "bandana"
	mutantrace_variation = NONE

/obj/item/clothing/suit/space/pirate
	name = "royal waistcoat "
	desc = "A royal, space-proof waistcoat. The inside of it is lined with reflective kevlar."
	icon_state = "pirate"
	item_state = "pirate"
	w_class = WEIGHT_CLASS_NORMAL
	flags_inv = 0
	allowed = list(/obj/item/gun, /obj/item/ammo_box, /obj/item/ammo_casing, /obj/item/melee/baton, /obj/item/restraints/handcuffs, /obj/item/tank/internals, /obj/item/melee/transforming/energy/sword/pirate, /obj/item/clothing/glasses/eyepatch, /obj/item/reagent_containers/food/drinks/bottle/rum)
	slowdown = 0
	armor = list(MELEE = 30, BULLET = 50, LASER = 30,ENERGY = 15, BOMB = 30, BIO = 30, RAD = 30, FIRE = 60, ACID = 75, WOUND = 30)
	strip_delay = 40
	equip_delay_other = 20
	mutantrace_variation = STYLE_DIGITIGRADE
	tail_state = ""
*/
