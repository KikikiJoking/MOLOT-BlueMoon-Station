#define FIREALARM_COOLDOWN 67 // Chosen fairly arbitrarily, it is the length of the audio in FireAlarm.ogg. The actual track length is 7 seconds 8ms but but the audio stops at 6s 700ms

/obj/item/electronics/firealarm
	name = "fire alarm electronics"
	custom_price = PRICE_CHEAP
	desc = "A fire alarm circuit. Can handle heat levels up to 40 degrees celsius."

/obj/item/wallframe/firealarm
	name = "fire alarm frame"
	desc = "Used for building fire alarms."
	icon = 'icons/obj/monitors.dmi'
	icon_state = "fire_bitem"
	result_path = /obj/machinery/firealarm

/obj/machinery/firealarm
	name = "fire alarm"
	desc = "<i>\"Дёрните рычаг в случае чрезвычайной ситуации\"</i>. Наверняка, его допустимо тянуть и в иных случаях..."
	icon = 'icons/obj/monitors.dmi'
	icon_state = "fire0"
	plane = ABOVE_WALL_PLANE
	max_integrity = 250
	integrity_failure = 0.4
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 100, RAD = 100, FIRE = 90, ACID = 30)
	mouse_over_pointer = MOUSE_HAND_POINTER
	use_power = IDLE_POWER_USE
	idle_power_usage = 2
	active_power_usage = 6
	power_channel = ENVIRON
	resistance_flags = FIRE_PROOF

	light_power = 0
	light_range = 7
	light_color = "#ff3232"

	var/detecting = 1
	var/buildstage = 2 // 2 = complete, 1 = no wires, 0 = circuit gone
	COOLDOWN_DECLARE(last_alarm)
	var/area/myarea = null
	//Has this firealarm been triggered by its enviroment?
	var/triggered = FALSE

	var/alarm_active = FALSE
	var/wire_override = FALSE
	var/button_wire_cut = FALSE

/obj/machinery/firealarm/directional/north //Pixel offsets get overwritten on New()
	pixel_y = 28

/obj/machinery/firealarm/directional/south
	pixel_y = -28

/obj/machinery/firealarm/directional/east
	pixel_x = 28

/obj/machinery/firealarm/directional/west
	pixel_x = -28

/obj/machinery/firealarm/Initialize(mapload, dir, building)
	. = ..()
	if(dir)
		src.setDir(dir)
	if(building)
		buildstage = 0
		panel_open = TRUE
		pixel_x = (dir & 3)? 0 : (dir == 4 ? -24 : 24)
		pixel_y = (dir & 3)? (dir ==1 ? -24 : 24) : 0
	update_icon()
	myarea = get_base_area(src)
	LAZYADD(myarea.firealarms, src)

	set_wires(new /datum/wires/firealarm(src))
	register_context()

/obj/machinery/firealarm/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()

	if(isnull(held_item))
		var/area/location = get_area(src)
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, (location.fire ? "Turn off" : "Turn on"))
		return CONTEXTUAL_SCREENTIP_SET

/obj/machinery/firealarm/Destroy()
	myarea.firereset(src)
	LAZYREMOVE(myarea.firealarms, src)

	qdel(wires)
	wires = null

	return ..()

/obj/machinery/firealarm/power_change()
	..()
	update_icon()

/obj/machinery/firealarm/update_icon_state()
	if(panel_open)
		icon_state = "fire_b[buildstage]"
		return

	if(machine_stat & BROKEN)
		icon_state = "firex"
		set_light(0)
		return

	if(machine_stat & NOPOWER)
		icon_state = "firep"
		set_light(0)
		return

	else if(triggered)
		icon_state = "fire1"
		set_light(5, 0.8, COLOR_RED_LIGHT)

	icon_state = "fire0"
	set_light(2, 1, COLOR_GREEN)

/obj/machinery/firealarm/update_overlays()
	. = ..()
	SSvis_overlays.remove_vis_overlay(src, managed_vis_overlays)

	. += "fire_overlay"

	if(is_station_level(z))
		. += "fire_[GLOB.security_level]"
		. += mutable_appearance(icon, "overlay_[NUM2SECLEVEL(GLOB.security_level)]")
		. += emissive_appearance(icon, "overlay_[NUM2SECLEVEL(GLOB.security_level)]")
	else
		. += "overlay_[NUM2SECLEVEL(SEC_LEVEL_GREEN)]"
		. += mutable_appearance(icon, "overlay_[NUM2SECLEVEL(GLOB.security_level)]")
		. += emissive_appearance(icon, "overlay_[NUM2SECLEVEL(GLOB.security_level)]")

	var/area/A = src.loc
	A = A.loc

	if(obj_flags & EMAGGED)
		. += "overlay_emagged"
		. += mutable_appearance(icon, "overlay_emagged")
		. += emissive_appearance(icon, "overlay_emagged")
	else
		. += "fire_on"
		. += mutable_appearance(icon, "fire_on")
		. += emissive_appearance(icon, "fire_on")

/obj/machinery/firealarm/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Текущий уровень угрозы: <b><u>[capitalize(get_security_level())]</u></b>.</span>"

/obj/machinery/firealarm/emp_act(severity)
	. = ..()

	if (. & EMP_PROTECT_SELF)
		return

	if(prob(severity/1.8))
		alarm()

/obj/machinery/firealarm/emag_act(mob/user)
	. = ..()
	if(obj_flags & EMAGGED)
		return
	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	obj_flags |= EMAGGED
	update_icon()
	if(user)
		user.visible_message("<span class='warning'>Sparks fly out of [src]!</span>",
							"<span class='notice'>You emag [src], disabling its thermal sensors.</span>")
	playsound(src, "sparks", 50, 1)
	return TRUE

/obj/machinery/firealarm/temperature_expose(datum/gas_mixture/air, temperature, volume)
	if((temperature > T0C + 200 || temperature < BODYTEMP_COLD_DAMAGE_LIMIT) && COOLDOWN_FINISHED(src, last_alarm) && !(obj_flags & EMAGGED) && detecting && !machine_stat)
		alarm()
	..()

/obj/machinery/firealarm/proc/alarm(mob/user)
	if(!is_operational() || !COOLDOWN_FINISHED(src, last_alarm))
		return
	COOLDOWN_START(src, last_alarm, FIREALARM_COOLDOWN)
	var/area/A = get_base_area(src)
	A.firealert(src)
	playsound(loc, 'goon/sound/machinery/FireAlarm.ogg', 75)
	if(user)
		log_game("[user] triggered a fire alarm at [COORD(src)]")

	alarm_active = TRUE

/obj/machinery/firealarm/proc/reset(mob/user)
	if(!is_operational())
		return
	var/area/A = get_base_area(src)
	A.firereset()
	if(user)
		log_game("[user] reset a fire alarm at [COORD(src)]")

	alarm_active = FALSE

/obj/machinery/firealarm/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(buildstage != 2)
		return ..()
	add_fingerprint(user)
	var/area/A = get_base_area(src)
	if(wire_override || button_wire_cut)
		to_chat(user, "<span class='warning'>The fire alarm doesn't respond!</span>")
	else if(A.fire)
		reset(user)
	else
		alarm(user)

/obj/machinery/firealarm/attack_ai(mob/user)
	return attack_hand(user)

/obj/machinery/firealarm/attack_robot(mob/user)
	return attack_hand(user)

/obj/machinery/firealarm/attackby(obj/item/W, mob/user, params)
	add_fingerprint(user)

	if(W.tool_behaviour == TOOL_SCREWDRIVER && buildstage == 2)
		W.play_tool_sound(src)
		panel_open = !panel_open
		to_chat(user, "<span class='notice'>The wires have been [panel_open ? "exposed" : "unexposed"].</span>")
		update_icon()
		return

	if(panel_open)

		if(panel_open && is_wire_tool(W) && user.a_intent == INTENT_HELP)
			wires.interact(user)
			return

		if((W.tool_behaviour == TOOL_WELDER) && user.a_intent == INTENT_HELP)
			if(obj_integrity < max_integrity)
				if(!W.tool_start_check(user, amount=0))
					return

				to_chat(user, "<span class='notice'>Вы начинаете чинить [src]...</span>")
				if(W.use_tool(src, user, 40, volume=50))
					obj_integrity = max_integrity
					to_chat(user, "<span class='notice'>Вы починили [src].</span>")
			else
				to_chat(user, "<span class='warning'>[src] is already in good condition!</span>")
			return

		switch(buildstage)
			if(2)
				if(W.tool_behaviour == TOOL_WIRECUTTER && !(user.a_intent == INTENT_HELP))
					buildstage = 1
					W.play_tool_sound(src)
					new /obj/item/stack/cable_coil(user.loc, 5)
					to_chat(user, "<span class='notice'>You cut the wires from \the [src].</span>")

					alarm_active = FALSE
					wire_override = FALSE
					button_wire_cut = FALSE
					qdel(wires)
					wires = null

					update_icon()
					return
				else if(W.force) //hit and turn it on
					..()
					var/area/A = get_base_area(src)
					if(!A.fire)
						alarm()
					return
			if(1)
				if(istype(W, /obj/item/stack/cable_coil))
					if(!W.use_tool(src, user, 0, 5))
						to_chat(user, "<span class='warning'>You need more cable for this!</span>")
					else
						buildstage = 2
						to_chat(user, "<span class='notice'>You wire \the [src].</span>")

						set_wires(new /datum/wires/firealarm(src))

						update_icon()
					return

				else if(W.tool_behaviour == TOOL_CROWBAR)
					user.visible_message("[user.name] removes the electronics from [src.name].", \
										"<span class='notice'>You start prying out the circuit...</span>")
					if(W.use_tool(src, user, 20, volume=50))
						if(buildstage == 1)
							if(machine_stat & BROKEN)
								to_chat(user, "<span class='notice'>You remove the destroyed circuit.</span>")
								machine_stat &= ~BROKEN
							else
								to_chat(user, "<span class='notice'>You pry out the circuit.</span>")
								new /obj/item/electronics/firealarm(user.loc)
							buildstage = 0
							update_icon()
					return
			if(0)
				if(istype(W, /obj/item/electronics/firealarm))
					to_chat(user, "<span class='notice'>You insert the circuit.</span>")
					qdel(W)
					buildstage = 1
					update_icon()
					return

				else if(istype(W, /obj/item/electroadaptive_pseudocircuit))
					var/obj/item/electroadaptive_pseudocircuit/P = W
					if(!P.adapt_circuit(user, 15))
						return
					user.visible_message("<span class='notice'>[user] fabricates a circuit and places it into [src].</span>", \
					"<span class='notice'>You adapt a fire alarm circuit and slot it into the assembly.</span>")
					buildstage = 1
					update_icon()
					return

				else if(W.tool_behaviour == TOOL_WRENCH)
					user.visible_message("[user] removes the fire alarm assembly from the wall.", \
										 "<span class='notice'>You remove the fire alarm assembly from the wall.</span>")
					var/obj/item/wallframe/firealarm/frame = new /obj/item/wallframe/firealarm()
					frame.forceMove(user.drop_location())
					W.play_tool_sound(src)
					qdel(src)
					return
	return ..()

/obj/machinery/firealarm/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	if((buildstage == 0) && (the_rcd.upgrade & RCD_UPGRADE_SIMPLE_CIRCUITS))
		return list("mode" = RCD_UPGRADE_SIMPLE_CIRCUITS, "delay" = 20, "cost" = 1)
	return FALSE

/obj/machinery/firealarm/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	switch(passed_mode)
		if(RCD_UPGRADE_SIMPLE_CIRCUITS)
			user.visible_message("<span class='notice'>[user] fabricates a circuit and places it into [src].</span>", \
			"<span class='notice'>You adapt a fire alarm circuit and slot it into the assembly.</span>")
			buildstage = 1
			update_icon()
			return TRUE
	return FALSE

/obj/machinery/firealarm/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir)
	. = ..()
	if(.) //damage received
		if(obj_integrity > 0 && !(machine_stat & BROKEN) && buildstage != 0)
			if(prob(33))
				alarm()

/obj/machinery/firealarm/singularity_pull(S, current_size)
	if (current_size >= STAGE_FIVE) // If the singulo is strong enough to pull anchored objects, the fire alarm experiences integrity failure
		deconstruct()
	..()

/obj/machinery/firealarm/obj_break(damage_flag)
	if(!(machine_stat & BROKEN) && !(flags_1 & NODECONSTRUCT_1) && buildstage != 0) //can't break the electronics if there isn't any inside.
		LAZYREMOVE(myarea.firealarms, src)
		machine_stat |= BROKEN
		update_icon()

/obj/machinery/firealarm/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		new /obj/item/stack/sheet/metal(loc, 1)
		if(!(machine_stat & BROKEN))
			var/obj/item/I = new /obj/item/electronics/firealarm(loc)
			if(!disassembled)
				I.obj_integrity = I.max_integrity * 0.5
		new /obj/item/stack/cable_coil(loc, 3)
	qdel(src)

/obj/machinery/firealarm/proc/update_fire_light(fire)
	if(fire == !!light_power)
		return  // do nothing if we're already active
	if(fire)
		set_light(l_power = 0.8)
	else
		set_light(l_power = 0)

/*
 * Return of Party button
 */

/area
	var/party = FALSE

/obj/machinery/firealarm/partyalarm
	name = "\improper PARTY BUTTON"
	desc = "Cuban Pete is in the house!"
	var/static/party_overlay

/obj/machinery/firealarm/partyalarm/reset()
	if (machine_stat & (NOPOWER|BROKEN))
		return
	var/area/A = get_base_area(src)
	if (!A || !A.party)
		return
	A.party = FALSE
	A.cut_overlay(party_overlay)

/obj/machinery/firealarm/partyalarm/alarm()
	if (machine_stat & (NOPOWER|BROKEN))
		return
	var/area/A = get_base_area(src)
	if (!A || A.party || A.name == "Space")
		return
	A.party = TRUE
	if (!party_overlay)
		party_overlay = iconstate2appearance('icons/turf/areas.dmi', "party")
	A.add_overlay(party_overlay)
