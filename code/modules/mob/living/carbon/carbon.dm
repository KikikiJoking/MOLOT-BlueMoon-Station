/mob/living/carbon
	blood_volume = BLOOD_VOLUME_NORMAL
	deathsound = list ('sound/voice/deathgasp1.ogg', 'sound/voice/deathgasp2.ogg')

/mob/living/carbon/Initialize(mapload)
	. = ..()
	create_reagents(1000, NONE, NO_REAGENTS_VALUE)
	update_body_parts() //to update the carbon's new bodyparts appearance
	GLOB.carbon_list += src
	blood_volume = (BLOOD_VOLUME_NORMAL * blood_ratio)
	add_movespeed_modifier(/datum/movespeed_modifier/carbon_crawling)
	register_context()

/mob/living/carbon/Destroy()
	//This must be done first, so the mob ghosts correctly before DNA etc is nulled
	. =  ..()

	QDEL_LIST(internal_organs)
	QDEL_LIST(stomach_contents)
	QDEL_LIST(bodyparts)
	hand_bodyparts = null		//Just references out bodyparts, don't need to delete twice.
	remove_from_all_data_huds()
	QDEL_NULL(dna)
	GLOB.carbon_list -= src

/mob/living/carbon/relaymove(mob/user, direction)
	if(user in src.stomach_contents)
		if(prob(40))
			if(prob(25))
				audible_message("<span class='warning'>You hear something rumbling inside [src]'s stomach...</span>", \
								"<span class='warning'>You hear something rumbling.</span>", 4,\
							    "<span class='userdanger'>Something is rumbling inside your stomach!</span>")
			var/obj/item/I = user.get_active_held_item()
			if(I && I.force)
				var/d = rand(round(I.force / 4), I.force)
				var/obj/item/bodypart/BP = get_bodypart(BODY_ZONE_CHEST)
				if(BP.receive_damage(d, 0))
					update_damage_overlays()
				visible_message("<span class='danger'>[user] attacks [src]'s stomach wall with the [I.name]!</span>", \
									"<span class='userdanger'>[user] attacks your stomach wall with the [I.name]!</span>")
				playsound(user.loc, 'sound/effects/attackblob.ogg', 50, 1)

				if(prob(src.getBruteLoss() - 50))
					for(var/atom/movable/A in stomach_contents)
						A.forceMove(drop_location())
						stomach_contents.Remove(A)
					src.gib()


/mob/living/carbon/swap_hand(held_index)
	. = ..()
	if(!.)
		var/obj/item/held_item = get_active_held_item()
		to_chat(usr, "<span class='warning'>Your other hand is too busy holding [held_item].</span>")
		return
	if(!held_index)
		held_index = (active_hand_index % held_items.len)+1
	var/oindex = active_hand_index
	active_hand_index = held_index
	if(hud_used)
		var/atom/movable/screen/inventory/hand/H
		H = hud_used.hand_slots["[oindex]"]
		if(H)
			H.update_icon()
		H = hud_used.hand_slots["[held_index]"]
		if(H)
			H.update_icon()


/mob/living/carbon/activate_hand(selhand) //l/r OR 1-held_items.len
	if(!selhand)
		selhand = (active_hand_index % held_items.len)+1

	if(istext(selhand))
		selhand = lowertext(selhand)
		if(selhand == "right" || selhand == "r")
			selhand = 2
		if(selhand == "left" || selhand == "l")
			selhand = 1

	if(selhand != active_hand_index)
		swap_hand(selhand)
	else
		mode() // Activate held item

/mob/living/carbon/attackby(obj/item/I, mob/user, params)
	if(lying && surgeries.len)
		if(user.a_intent == INTENT_HELP || user.a_intent == INTENT_DISARM)
			for(var/datum/surgery/S in surgeries)
				if(S.next_step(user,user.a_intent))
					return STOP_ATTACK_PROC_CHAIN

	if(!all_wounds || !(user.a_intent == INTENT_HELP || user == src))
		return ..()

	for(var/i in shuffle(all_wounds))
		var/datum/wound/W = i
		if(W.try_treating(I, user))
			return STOP_ATTACK_PROC_CHAIN

	return ..()

/mob/living/carbon/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	var/hurt = TRUE
	var/extra_speed = 0
	// BLUEMOON ADDITION AHEAD - для изменения урона в зависимости от наличия квирка тяжести персонажа
	var/damage = max(0, 10 + ((src.mob_weight - MOB_WEIGHT_NORMAL) * 25))
	var/combat_knockdown = max(0, 20 + ((src.mob_weight - MOB_WEIGHT_NORMAL) * 20))
	// BLUEMOON ADDITION END
	if(throwingdatum?.thrower != src)
		extra_speed = min(max(0, throwingdatum.speed - initial(throw_speed)), 3)
	if(GetComponent(/datum/component/tackler))
		return
	if(throwingdatum?.thrower && iscyborg(throwingdatum.thrower))
		var/mob/living/silicon/robot/R = throwingdatum.thrower
		if(!R.emagged)
			hurt = FALSE
	if(hit_atom.density && isturf(hit_atom))
		if(hurt)
			DefaultCombatKnockdown(combat_knockdown)
			take_bodypart_damage(damage + 5 * extra_speed, check_armor = TRUE, wound_bonus = extra_speed * 5)
	if(iscarbon(hit_atom) && hit_atom != src)
		var/mob/living/carbon/victim = hit_atom
		if(victim.movement_type & FLYING)
			return
		if(hurt)
			victim.take_bodypart_damage(damage + 5 * extra_speed, check_armor = TRUE, wound_bonus = extra_speed * 5)
			take_bodypart_damage(damage + 5 * extra_speed, check_armor = TRUE, wound_bonus = extra_speed * 5)
			victim.DefaultCombatKnockdown(combat_knockdown)
			DefaultCombatKnockdown(combat_knockdown)
			visible_message("<span class='danger'>[src] crashes into [victim][extra_speed ? " really hard" : ""], knocking them both over!</span>",\
				"<span class='userdanger'>You violently crash into [victim][extra_speed ? " extra hard" : ""]!</span>")
		playsound(src,'sound/weapons/punch1.ogg',50,1)


//Throwing stuff
/mob/living/carbon/proc/toggle_throw_mode()
	if(stat)
		return
	if(throw_mode)
		throw_mode_off()
	else
		throw_mode_on()


/mob/living/carbon/proc/throw_mode_off()
	throw_mode = FALSE
	if(client && hud_used)
		hud_used.throw_icon.icon_state = "act_throw_off"


/mob/living/carbon/proc/throw_mode_on()
	throw_mode = TRUE
	if(client && hud_used)
		hud_used.throw_icon.icon_state = "act_throw_on"

/mob/proc/throw_item(atom/target)
	SEND_SIGNAL(src, COMSIG_MOB_THROW, target)
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_CARBON_THROW_THING, src, target)
	return TRUE

/mob/living/carbon/throw_item(atom/target)
	. = ..()
	throw_mode_off()
	update_mouse_pointer()
	if(!target || !isturf(loc))
		return FALSE
	if(istype(target, /atom/movable/screen))
		return FALSE

	//CIT CHANGES - makes it impossible to throw while in stamina softcrit
	if(IS_STAMCRIT(src))
		to_chat(src, "<span class='warning'>Вы слишком устали.</span>")
		return

	var/random_turn = a_intent == INTENT_HARM
	//END OF CIT CHANGES

	var/atom/movable/thrown_thing
	var/obj/item/held_item = get_active_held_item()
	var/verb_text = pick("throw", "toss", "hurl", "chuck", "fling")
	if(prob(0.5))
		verb_text = "yeet"

	var/neckgrab_throw = FALSE
	if(!held_item)
		if(pulling && isliving(pulling) && grab_state >= GRAB_AGGRESSIVE)
			var/mob/living/throwable_mob = pulling
			if(!throwable_mob.buckled)
				thrown_thing = throwable_mob
				if(grab_state >= GRAB_NECK)
					neckgrab_throw = TRUE
				stop_pulling()
				if(HAS_TRAIT(src, TRAIT_PACIFISM))
					to_chat(src, span_notice("You gently let go of [throwable_mob]."))
					return FALSE
				if(!UseStaminaBuffer(STAM_COST_THROW_MOB * ((throwable_mob.mob_size+1)**2), TRUE))
					return FALSE
	else
		thrown_thing = held_item.on_thrown(src, target)
	if(!thrown_thing)
		return FALSE
	var/power_throw = 0
	if(isliving(thrown_thing))
		var/turf/start_T = get_turf(loc) //Get the start and target tile for the descriptors
		var/turf/end_T = get_turf(target)
		if(start_T && end_T)
			log_combat(src, thrown_thing, "thrown", addition="grab from tile in [AREACOORD(start_T)] towards tile at [AREACOORD(end_T)]")
		//BLUEMOON ADDITION AHEAD
		var/mob/living/L = thrown_thing
		switch(L.mob_weight)
			if(MOB_WEIGHT_HEAVY_SUPER)
				power_throw = -10
			if(MOB_WEIGHT_HEAVY)
				power_throw -= 2
		//BLUEMOON ADDITION END
	if(HAS_TRAIT(src, TRAIT_HULK))
		power_throw++
	if(HAS_TRAIT(src, TRAIT_DWARF))
		power_throw--
	if(HAS_TRAIT(thrown_thing, TRAIT_DWARF))
		power_throw++
	if(neckgrab_throw)
		power_throw++
	if(isitem(thrown_thing))
		var/obj/item/thrown_item = thrown_thing
		if(thrown_item.throw_verb)
			verb_text = thrown_item.throw_verb
	visible_message(span_danger("[src] [verb_text][plural_s(verb_text)] [thrown_thing][power_throw ? " really hard!" : "."]"), \
					span_danger("You [verb_text] [thrown_thing][power_throw ? " really hard!" : "."]"))
	log_message("has thrown [thrown_thing] [power_throw > 0 ? "really hard" : ""]", LOG_ATTACK)
	do_attack_animation(target, no_effect = 1)
	var/extra_throw_range = 0 // HAS_TRAIT(src, TRAIT_THROWINGARM) ? 2 : 0
	playsound(loc, 'sound/weapons/punchmiss.ogg', 50, 1, -1)
	newtonian_move(get_dir(target, src))
	thrown_thing.safe_throw_at(target, thrown_thing.throw_range + extra_throw_range, max(1,thrown_thing.throw_speed + power_throw), src, null, null, null, move_force, random_turn)

/mob/living/carbon/restrained(ignore_grab)
	. = (handcuffed || (!ignore_grab && pulledby && pulledby.grab_state >= GRAB_AGGRESSIVE))

/mob/living/carbon/proc/canBeHandcuffed()
	return FALSE

/mob/living/carbon/Topic(href, href_list)
	..()
	if(href_list["embedded_object"] && usr.canUseTopic(src, BE_CLOSE))
		var/obj/item/bodypart/L = locate(href_list["embedded_limb"]) in bodyparts
		if(!L)
			return
		var/obj/item/I = locate(href_list["embedded_object"]) in L.embedded_objects
		if(!I || I.loc != src) //no item, no limb, or item is not in limb or in the person anymore
			return
		SEND_SIGNAL(src, COMSIG_CARBON_EMBED_RIP, I, L)
		return

/mob/living/carbon/fall(forced)
	loc.handle_fall(src, forced)//it's loc so it doesn't call the mob's handle_fall which does nothing

/mob/living/carbon/is_muzzled()
	return(istype(src.wear_mask, /obj/item/clothing/mask/muzzle))

/mob/living/carbon/hallucinating()
	if(hallucination)
		return TRUE
	else
		return FALSE

/mob/living/carbon/resist_buckle()
	. = FALSE
	if(!buckled)
		return
	if(restrained())
		// too soon.
		var/buckle_cd = 600
		if(handcuffed)
			var/obj/item/restraints/O = src.get_item_by_slot(ITEM_SLOT_HANDCUFFED)
			buckle_cd = O.breakouttime
		MarkResistTime()
		visible_message("<span class='warning'>[src] пытается выбраться!</span>", \
					"<span class='notice'>Ты пытаешься выбраться... (Это займёт около [round(buckle_cd/600,1)] минут и тебе не стоит двигаться в процессе.)</span>")
		if(do_after(src, buckle_cd, src, timed_action_flags = IGNORE_HELD_ITEM | IGNORE_INCAPACITATED, extra_checks = CALLBACK(src, PROC_REF(cuff_resist_check))))
			if(!buckled)
				return
			buckled.user_unbuckle_mob(src, src)
		else
			if(src && buckled)
				to_chat(src, "<span class='warning'>Тебе не удалось выбраться!</span>")
	else
		buckled.user_unbuckle_mob(src,src)

/mob/living/carbon/resist_fire()
	fire_stacks -= 5
	DefaultCombatKnockdown(60, TRUE, TRUE)
	spin(32,2)
	visible_message("<span class='danger'>[src] падает и крутится, сбрасывая с себя пламя!</span>", \
		"<span class='notice'>Вы остановились, упали и начали крутиться!</span>")
	MarkResistTime(30)
	sleep(30)
	if(fire_stacks <= 0)
		visible_message("<span class='danger'>[src] успешно сбрасывает с себя пламя!</span>", \
			"<span class='notice'>Вы успешно потушили себя.</span>")
		ExtinguishMob()

/mob/living/carbon/resist_restraints()
	var/obj/item/I = null
	if(handcuffed)
		I = handcuffed
	else if(legcuffed)
		I = legcuffed
	if(I)
		MarkResistTime()
		cuff_resist(I)

/mob/living/carbon/proc/cuff_resist(obj/item/I, breakouttime = 600, cuff_break = 0)
	if(I.item_flags & BEING_REMOVED)
		to_chat(src, "<span class='warning'>Вы уже пытаетесь сбросить [I]!</span>")
		return
	var/allow_breakout_movement = IGNORE_INCAPACITATED
	I.item_flags |= BEING_REMOVED
	breakouttime = I.breakouttime
	if(!cuff_break)
		visible_message("<span class='warning'>[src] пытается сбросить [I]!</span>")
		to_chat(src, "<span class='notice'>Ты пытаешься сбросить [I]... (Это займёт около [DisplayTimeText(breakouttime)]. Тебе не стоит делать лишних движений.)</span>")
		if(do_after(src, breakouttime, target = src, timed_action_flags = allow_breakout_movement, extra_checks = CALLBACK(src, PROC_REF(cuff_resist_check))))
			clear_cuffs(I, cuff_break)
		else
			to_chat(src, "<span class='warning'>Тебе не удалось сбросить [I]!</span>")

	else if(cuff_break == FAST_CUFFBREAK)
		breakouttime = 50
		visible_message("<span class='warning'>[src] is trying to break [I]!</span>")
		to_chat(src, "<span class='notice'>You attempt to break [I]... (This will take around 5 seconds and you need to stand still.)</span>")
		if(do_after(src, breakouttime, target = src, timed_action_flags = allow_breakout_movement, extra_checks = CALLBACK(src, PROC_REF(cuff_resist_check))))
			clear_cuffs(I, cuff_break)
		else
			to_chat(src, "<span class='warning'>Тебе не удалось сломать [I]!</span>")

	else if(cuff_break == INSTANT_CUFFBREAK)
		clear_cuffs(I, cuff_break)

	I.item_flags &= ~BEING_REMOVED

/mob/living/carbon/proc/cuff_resist_check()
	return !incapacitated(ignore_restraints = TRUE)

/mob/living/carbon/proc/uncuff()
	if (handcuffed)
		var/obj/item/W = handcuffed
		handcuffed = null
		if (buckled && buckled.buckle_requires_restraints)
			buckled.unbuckle_mob(src)
		update_handcuffed()
		if (client)
			client.screen -= W
		if (W)
			W.forceMove(drop_location())
			W.dropped(src)
			if (W)
				W.layer = initial(W.layer)
				W.plane = initial(W.plane)
		SetNextAction(0)
	if (legcuffed)
		var/obj/item/W = legcuffed
		legcuffed = null
		update_inv_legcuffed()
		if (client)
			client.screen -= W
		if (W)
			W.forceMove(drop_location())
			W.dropped(src)
			if (W)
				W.layer = initial(W.layer)
				W.plane = initial(W.plane)
		SetNextAction(0)
	update_equipment_speed_mods() // In case cuffs ever change speed

/mob/living/carbon/proc/clear_cuffs(obj/item/I, cuff_break)
	if(!I.loc || buckled)
		return
	visible_message("<span class='danger'>[src] manages to [cuff_break ? "break" : "remove"] [I]!</span>")
	to_chat(src, "<span class='notice'>You successfully [cuff_break ? "break" : "remove"] [I].</span>")

	if(cuff_break)
		. = !((I == handcuffed) || (I == legcuffed))
		qdel(I)
		return

	else
		if(I == handcuffed)
			handcuffed.forceMove(drop_location())
			handcuffed = null
			I.dropped(src)
			if(buckled && buckled.buckle_requires_restraints)
				buckled.unbuckle_mob(src)
			update_handcuffed()
			return
		if(I == legcuffed)
			legcuffed.forceMove(drop_location())
			legcuffed = null
			I.dropped(src)
			if(istype(I, /obj/item/restraints/legcuffs))
				var/obj/item/restraints/legcuffs/lgcf = I
				lgcf.on_removed()
			update_inv_legcuffed()
			return
		else
			dropItemToGround(I)
			return

/mob/living/carbon/get_standard_pixel_y_offset(lying = 0)
	. = ..()
	if(lying)
		. -= 6

/mob/living/carbon/proc/accident(obj/item/I)
	if(!I || (I.item_flags & ABSTRACT) || HAS_TRAIT(I, TRAIT_NODROP))
		return

	//dropItemToGround(I) CIT CHANGE - makes it so the item doesn't drop if the modifier rolls above 100

	var/modifier = 50

	if(HAS_TRAIT(src, TRAIT_CLUMSY))
		modifier -= 40 //Clumsy people are more likely to hit themselves -Honk!

	if(modifier < 100)
		dropItemToGround(I)
	//END OF CIT CHANGES

	switch(rand(1,100)+modifier) //91-100=Nothing special happens
		if(-INFINITY to 0) //attack yourself
			I.attack(src,src)
		if(1 to 30) //throw it at yourself
			I.throw_impact(src)
		if(31 to 60) //Throw object in facing direction
			var/turf/target = get_turf(loc)
			var/range = rand(2,I.throw_range)
			for(var/i = 1; i < range; i++)
				var/turf/new_turf = get_step(target, dir)
				target = new_turf
				if(new_turf.density)
					break
			I.throw_at(target,I.throw_range,I.throw_speed,src)
		if(61 to 90) //throw it down to the floor
			var/turf/target = get_turf(loc)
			I.safe_throw_at(target,I.throw_range,I.throw_speed,src, force = move_force)

/mob/living/carbon/get_status_tab_items()
	. = ..()
	var/obj/item/organ/alien/plasmavessel/vessel = getorgan(/obj/item/organ/alien/plasmavessel)
	if(vessel)
		. += "Plasma Stored: [vessel.storedPlasma]/[vessel.max_plasma]"
	if(locate(/obj/item/assembly/health) in src)
		. += "Health: [health]"

/mob/living/carbon/get_proc_holders()
	. = ..()
	. += add_abilities_to_panel()

/mob/living/carbon/attack_ui(slot)
	if(!has_hand_for_held_index(active_hand_index))
		return FALSE
	return ..()

/mob/living/carbon/proc/vomit(lost_nutrition = 10, blood = FALSE, stun = TRUE, distance = 1, message = TRUE, vomit_type = VOMIT_TOXIC, harm = TRUE, force = FALSE, purge_ratio = 0.1)
	if(HAS_TRAIT(src, TRAIT_NOHUNGER) && !force)
		return TRUE

	if(nutrition < 100 && !blood && !force)
		if(message)
			visible_message("<span class='warning'>[src] dry heaves!</span>", \
							"<span class='userdanger'>You try to throw up, but there's nothing in your stomach!</span>")
		if(stun)
			DefaultCombatKnockdown(200)
		return TRUE

	if(is_mouth_covered()) //make this add a blood/vomit overlay later it'll be hilarious
		if(message)
			visible_message("<span class='danger'>[src] throws up all over [p_them()]self!</span>", \
							"<span class='userdanger'>You throw up all over yourself!</span>")
			SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "vomit", /datum/mood_event/vomitself)
		distance = 0
	else
		if(message)
			visible_message("<span class='danger'>[src] throws up!</span>", "<span class='userdanger'>You throw up!</span>")
			if(!isflyperson(src))
				SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "vomit", /datum/mood_event/vomit)

	if(stun)
		Stun(80)

	playsound(get_turf(src), 'sound/effects/splat.ogg', 50, TRUE)
	var/turf/T = get_turf(src)
	if(!blood)
		adjust_nutrition(-lost_nutrition)
		adjustToxLoss(-3)

	for(var/i=0 to distance)
		if(blood)
			if(T)
				add_splatter_floor(T)
			if(harm)
				adjustBruteLoss(3)
		else
			if(T)
				T.add_vomit_floor(src, vomit_type, purge_ratio) //toxic barf looks different || call purge when doing detoxicfication to pump more chems out of the stomach.
		T = get_step(T, dir)
		if (is_blocked_turf(T))
			break
	return TRUE

/mob/living/carbon/proc/spew_organ(power = 5, amt = 1)
	var/list/spillable_organs = list()
	for(var/A in internal_organs)
		var/obj/item/organ/O = A
		if(!(O.organ_flags & ORGAN_NO_DISMEMBERMENT))
			spillable_organs += O
	for(var/i in 1 to amt)
		if(!spillable_organs.len)
			break //Guess we're out of organs!
		var/obj/item/organ/guts = pick(spillable_organs)
		spillable_organs -= guts
		var/turf/T = get_turf(src)
		guts.Remove()
		guts.forceMove(T)
		var/atom/throw_target = get_edge_target_turf(guts, dir)
		guts.throw_at(throw_target, power, 4, src)



/mob/living/carbon/fully_replace_character_name(oldname,newname)
	..()
	if(dna)
		dna.real_name = real_name

//Updates the mob's health from bodyparts and mob damage variables
/mob/living/carbon/updatehealth()
	if(status_flags & GODMODE)
		return
	var/total_burn	= 0
	var/total_brute	= 0
	var/total_stamina = 0
	for(var/X in bodyparts)	//hardcoded to streamline things a bit
		var/obj/item/bodypart/BP = X
		total_brute	+= (BP.brute_dam * BP.body_damage_coeff)
		total_burn	+= (BP.burn_dam * BP.body_damage_coeff)
		total_stamina += (BP.stamina_dam * BP.stam_damage_coeff)
	health = round(maxHealth - getOxyLoss() - getToxLoss() - getCloneLoss() - total_burn - total_brute, DAMAGE_PRECISION)
	staminaloss = round(total_stamina, DAMAGE_PRECISION)
	update_stat()
	if(((maxHealth - total_burn) < HEALTH_THRESHOLD_DEAD*2) && stat == DEAD )
		become_husk("burn")
	med_hud_set_health()
	if(stat == SOFT_CRIT)
		add_movespeed_modifier(/datum/movespeed_modifier/carbon_softcrit)
	else
		remove_movespeed_modifier(/datum/movespeed_modifier/carbon_softcrit)

/mob/living/carbon/update_stamina()
	var/total_health = getStaminaLoss()
	if(total_health)
		if(!(combat_flags & COMBAT_FLAG_HARD_STAMCRIT) && total_health >= STAMINA_CRIT && !stat)
			to_chat(src, "<span class='notice'>Вы слишком устали, чтобы продолжать...</span>")
			set_resting(TRUE, FALSE, FALSE)
			SEND_SIGNAL(src, COMSIG_DISABLE_COMBAT_MODE)
			combat_flags |= COMBAT_FLAG_HARD_STAMCRIT
			filters += CIT_FILTER_STAMINACRIT
			update_mobility()
	if((combat_flags & COMBAT_FLAG_HARD_STAMCRIT) && total_health <= STAMINA_CRIT_REMOVAL_THRESHOLD)
		to_chat(src, "<span class='notice'>Вы больше не чувствуете себя так измотанно.</span>")
		combat_flags &= ~(COMBAT_FLAG_HARD_STAMCRIT)
		filters -= CIT_FILTER_STAMINACRIT
		update_mobility()
	UpdateStaminaBuffer()
	update_health_hud()

/mob/living/carbon/update_sight()
	if(!client)
		return
	if(stat == DEAD)
		sight = (SEE_TURFS|SEE_MOBS|SEE_OBJS)
		see_in_dark = 8
		see_invisible = SEE_INVISIBLE_OBSERVER
		return

	sight = initial(sight)
	lighting_alpha = initial(lighting_alpha)
	var/obj/item/organ/eyes/E = getorganslot(ORGAN_SLOT_EYES)
	if(!E)
		update_tint()
	else
		see_invisible = E.see_invisible
		see_in_dark = E.see_in_dark
		sight |= E.sight_flags
		if(!isnull(E.lighting_alpha))
			lighting_alpha = E.lighting_alpha
		if(HAS_TRAIT(src, TRAIT_NIGHT_VISION))
			lighting_alpha = min(LIGHTING_PLANE_ALPHA_NV_TRAIT, lighting_alpha)
			see_in_dark = max(NIGHT_VISION_DARKSIGHT_RANGE, see_in_dark)

	if(client.eye && client.eye != src)
		var/atom/A = client.eye
		if(A.update_remote_sight(src)) //returns 1 if we override all other sight updates.
			return

	if(glasses && istype(glasses, /obj/item/clothing/glasses))
		var/obj/item/clothing/glasses/G = glasses
		sight |= G.vision_flags
		see_in_dark = max(G.darkness_view, see_in_dark)
		if(G.invis_override)
			see_invisible = G.invis_override
		else
			see_invisible = min(G.invis_view, see_invisible)
		if(!isnull(G.lighting_alpha))
			lighting_alpha = min(lighting_alpha, G.lighting_alpha)
	if(head && istype(head, /obj/item/clothing/head))
		var/obj/item/clothing/head/H = head
		sight |= H.vision_flags
		see_in_dark = max(H.darkness_view, see_in_dark)

		if(!isnull(H.lighting_alpha))
			lighting_alpha = min(lighting_alpha, H.lighting_alpha)
	if(dna)
		for(var/X in dna.mutations)
			var/datum/mutation/M = X
			if(M.name == XRAY)
				sight |= (SEE_TURFS|SEE_MOBS|SEE_OBJS)
				see_in_dark = max(see_in_dark, 8)

	if(HAS_TRAIT(src, TRAIT_TRUE_NIGHT_VISION))
		lighting_alpha = min(lighting_alpha, LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE)
		see_in_dark = max(see_in_dark, 8)

	if(HAS_TRAIT(src, TRAIT_MESON_VISION))
		sight |= SEE_TURFS
		lighting_alpha = min(lighting_alpha, LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE)

	if(HAS_TRAIT(src, TRAIT_THERMAL_VISION))
		sight |= SEE_MOBS
		lighting_alpha = min(lighting_alpha, LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE)

	if(HAS_TRAIT(src, TRAIT_XRAY_VISION))
		sight |= SEE_TURFS|SEE_MOBS|SEE_OBJS
		see_in_dark = max(see_in_dark, 8)

	if(see_override)
		see_invisible = see_override
	. = ..()


//to recalculate and update the mob's total tint from tinted equipment it's wearing.
/mob/living/carbon/proc/update_tint()
	if(!GLOB.tinted_weldhelh)
		return
	tinttotal = get_total_tint()
	if(tinttotal >= TINT_BLIND)
		become_blind(EYES_COVERED)
	else if(tinttotal >= TINT_DARKENED)
		cure_blind(EYES_COVERED)
		overlay_fullscreen("tint", /atom/movable/screen/fullscreen/scaled/impaired, 2)
	else
		cure_blind(EYES_COVERED)
		clear_fullscreen("tint", 0)

/mob/living/carbon/proc/get_total_tint()
	. = 0
	if(istype(head, /obj/item/clothing/head))
		var/obj/item/clothing/head/HT = head
		. += HT.tint
	if(wear_mask)
		. += wear_mask.tint

	var/obj/item/organ/eyes/E = getorganslot(ORGAN_SLOT_EYES)
	if(E)
		. += E.tint

	else
		. += INFINITY

/mob/living/carbon/get_permeability_protection(list/target_zones = list(HANDS,CHEST,GROIN,LEGS,FEET,ARMS,HEAD))
	var/list/tally = list()
	for(var/obj/item/I in get_equipped_items())
		for(var/zone in target_zones)
			if(I.body_parts_covered & zone)
				tally["[zone]"] = max(1 - I.permeability_coefficient, target_zones["[zone]"])
	var/protection = 0
	for(var/key in tally)
		protection += tally[key]
	protection *= INVERSE(target_zones.len)
	return protection

//this handles hud updates
/mob/living/carbon/update_damage_hud()

	if(!client)
		return

	if(health <= crit_threshold)
		var/severity = 0
		switch(health)
			if(-20 to -10)
				severity = 1
			if(-30 to -20)
				severity = 2
			if(-40 to -30)
				severity = 3
			if(-50 to -40)
				severity = 4
			if(-50 to -40)
				severity = 5
			if(-60 to -50)
				severity = 6
			if(-70 to -60)
				severity = 7
			if(-90 to -70)
				severity = 8
			if(-95 to -90)
				severity = 9
			if(-INFINITY to -95)
				severity = 10
		if(!InFullCritical())
			var/visionseverity = 4
			switch(health)
				if(-8 to -4)
					visionseverity = 5
				if(-12 to -8)
					visionseverity = 6
				if(-16 to -12)
					visionseverity = 7
				if(-20 to -16)
					visionseverity = 8
				if(-24 to -20)
					visionseverity = 9
				if(-INFINITY to -24)
					visionseverity = 10
			overlay_fullscreen("critvision", /atom/movable/screen/fullscreen/scaled/crit/vision, visionseverity)
		else
			clear_fullscreen("critvision")
		overlay_fullscreen("crit", /atom/movable/screen/fullscreen/scaled/crit, severity)
	else
		clear_fullscreen("crit")
		clear_fullscreen("critvision")

	//Oxygen damage overlay
	var/windedup = getOxyLoss() + getStaminaLoss() * 0.2
	if(windedup)
		var/severity = 0
		switch(windedup)
			if(10 to 20)
				severity = 1
			if(20 to 25)
				severity = 2
			if(25 to 30)
				severity = 3
			if(30 to 35)
				severity = 4
			if(35 to 40)
				severity = 5
			if(40 to 45)
				severity = 6
			if(45 to INFINITY)
				severity = 7
		overlay_fullscreen("oxy", /atom/movable/screen/fullscreen/scaled/oxy, severity)
	else
		clear_fullscreen("oxy")

	//Fire and Brute damage overlay (BSSR)
	var/hurtdamage = getBruteLoss() + getFireLoss() + damageoverlaytemp
	if(hurtdamage)
		var/severity = 0
		switch(hurtdamage)
			if(5 to 15)
				severity = 1
			if(15 to 30)
				severity = 2
			if(30 to 45)
				severity = 3
			if(45 to 70)
				severity = 4
			if(70 to 85)
				severity = 5
			if(85 to INFINITY)
				severity = 6
		overlay_fullscreen("brute", /atom/movable/screen/fullscreen/scaled/brute, severity)
	else
		clear_fullscreen("brute")

/mob/living/carbon/update_health_hud(shown_health_amount)
	if(!client || !hud_used)
		return
	if(hud_used.healths)
		if(stat != DEAD)
			. = 1
			if(!shown_health_amount)
				shown_health_amount = health
			if(shown_health_amount >= maxHealth)
				hud_used.healths.icon_state = "health0"
			else if(shown_health_amount > maxHealth*0.8)
				hud_used.healths.icon_state = "health1"
			else if(shown_health_amount > maxHealth*0.6)
				hud_used.healths.icon_state = "health2"
			else if(shown_health_amount > maxHealth*0.4)
				hud_used.healths.icon_state = "health3"
			else if(shown_health_amount > maxHealth*0.2)
				hud_used.healths.icon_state = "health4"
			else if(shown_health_amount > 0)
				hud_used.healths.icon_state = "health5"
			else
				hud_used.healths.icon_state = "health6"
		else
			hud_used.healths.icon_state = "health7"

/mob/living/carbon/update_stat()
	if(status_flags & GODMODE)
		return
	if(stat != CONSCIOUS)
		clear_typing_indicator()
	if(stat != DEAD)
		if(health <= HEALTH_THRESHOLD_DEAD && !HAS_TRAIT(src, TRAIT_NODEATH))
			death()
			return
		if(IsUnconscious() || IsSleeping() || getOxyLoss() > 50 || (HAS_TRAIT(src, TRAIT_DEATHCOMA)) || (health <= HEALTH_THRESHOLD_FULLCRIT && !HAS_TRAIT(src, TRAIT_NOHARDCRIT)))
			set_stat(UNCONSCIOUS)
			SEND_SIGNAL(src, COMSIG_DISABLE_COMBAT_MODE)
			if(!eye_blind)
				blind_eyes(1)
		else
			if(health <= crit_threshold && !HAS_TRAIT(src, TRAIT_NOSOFTCRIT))
				set_stat(SOFT_CRIT)
				SEND_SIGNAL(src, COMSIG_DISABLE_COMBAT_MODE)
			else
				set_stat(CONSCIOUS)
			if(eye_blind <= 1)
				adjust_blindness(-1)
		update_mobility()
	update_crit_status()
	update_damage_hud()
	update_health_hud()
	update_hunger_and_thirst_hud()
	med_hud_set_status()
	..()

/mob/living/carbon/proc/update_crit_status()
	remove_filter("hardcrit")
	if(health <= crit_threshold)
		add_filter("hardcrit", 2, BM_FILTER_HARDCRIT)

//called when we get cuffed/uncuffed
/mob/living/carbon/proc/update_handcuffed()
	if(handcuffed)
		drop_all_held_items()
		stop_pulling()
		throw_alert("handcuffed", /atom/movable/screen/alert/restrained/handcuffed, new_master = src.handcuffed)
		if(HAS_TRAIT(src, "bondaged"))
			SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, QMOOD_BONDAGE, /datum/mood_event/bondage)	 //For bondage enjoyer quirk. - Gardelin0
		if(handcuffed.demoralize_criminals)
			SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "handcuffed", /datum/mood_event/handcuffed)
	else
		clear_alert("handcuffed")
		SEND_SIGNAL(src, COMSIG_CLEAR_MOOD_EVENT, "handcuffed")
		SEND_SIGNAL(src, COMSIG_CLEAR_MOOD_EVENT, QMOOD_BONDAGE, /datum/mood_event/bondage)	//For bondage enjoyer quirk. - Gardelin0
	update_action_buttons_icon() //some of our action buttons might be unusable when we're handcuffed.
	update_inv_handcuffed()
	update_hud_handcuffed()

/mob/living/carbon/proc/can_revive(ignore_timelimit = FALSE, maximum_brute_dam = MAX_REVIVE_BRUTE_DAMAGE, maximum_fire_dam = MAX_REVIVE_FIRE_DAMAGE, ignore_heart = FALSE)
	var/tlimit = DEFIB_TIME_LIMIT * 10
	var/obj/item/organ/heart = getorgan(/obj/item/organ/heart)
	if(suiciding || hellbound || HAS_TRAIT(src, TRAIT_HUSK) || AmBloodsucker(src))
		return
	if(!ignore_timelimit && (world.time - timeofdeath) > tlimit)
		return
	if((getBruteLoss() >= maximum_brute_dam) || (getFireLoss() >= maximum_fire_dam))
		return
	if(!ignore_heart && (!heart || (heart.organ_flags & ORGAN_FAILING)))
		return
	var/obj/item/organ/brain/BR = getorgan(/obj/item/organ/brain)
	if(QDELETED(BR) || BR.brain_death || (BR.organ_flags & ORGAN_FAILING) || suiciding)
		return
	return TRUE

/mob/living/carbon/fully_heal(admin_revive = FALSE)
	if(reagents)
		reagents.clear_reagents()
	var/obj/item/organ/brain/B = getorgan(/obj/item/organ/brain)
	if(B)
		B.brain_death = FALSE
	for(var/O in internal_organs)
		var/obj/item/organ/organ = O
		organ.setOrganDamage(0)
	for(var/thing in diseases)
		var/datum/disease/D = thing
		if(D.severity != DISEASE_SEVERITY_POSITIVE)
			D.cure(FALSE)
	for(var/thing in all_wounds)
		var/datum/wound/W = thing
		W.remove_wound()
	if(admin_revive)
		regenerate_limbs()
		regenerate_organs()
		handcuffed = initial(handcuffed)
		for(var/obj/item/restraints/R in contents) //actually remove cuffs from inventory
			qdel(R)
		update_handcuffed()
		if(reagents)
			for(var/addi in reagents.addiction_list)
				reagents.remove_addiction(addi)
	cure_all_traumas(TRAUMA_RESILIENCE_MAGIC)
	..()
	// heal ears after healing traits, since ears check TRAIT_DEAF trait
	// when healing.
	restoreEars()

/mob/living/carbon/can_be_revived()
	. = ..()
	if(!getorgan(/obj/item/organ/brain) && (!mind || !mind.has_antag_datum(/datum/antagonist/changeling)))
		return FALSE

/mob/living/carbon/harvest(mob/living/user)
	if(QDELETED(src))
		return
	var/organs_amt = 0
	for(var/X in internal_organs)
		var/obj/item/organ/O = X
		if(prob(50))
			organs_amt++
			O.Remove()
			O.forceMove(drop_location())
	if(organs_amt)
		to_chat(user, "<span class='notice'>You retrieve some of [src]\'s internal organs!</span>")

/mob/living/carbon/ExtinguishMob()
	for(var/X in get_equipped_items())
		var/obj/item/I = X
		var/datum/component/acid/acid = I.GetComponent(/datum/component/acid)
		if(acid)
			acid.level = 0
		I.extinguish() //extinguishes our clothes
	..()

/mob/living/carbon/fakefire(var/fire_icon = "Generic_mob_burning")
	var/mutable_appearance/new_fire_overlay = mutable_appearance('icons/mob/OnFire.dmi', fire_icon, -FIRE_LAYER)
	new_fire_overlay.appearance_flags = RESET_COLOR
	overlays_standing[FIRE_LAYER] = new_fire_overlay
	apply_overlay(FIRE_LAYER)

/mob/living/carbon/fakefireextinguish()
	remove_overlay(FIRE_LAYER)


/mob/living/carbon/proc/devour_mob(mob/living/carbon/C, devour_time = 130)
	C.visible_message("<span class='danger'>[src] is attempting to devour [C]!</span>", \
					"<span class='userdanger'>[src] is attempting to devour you!</span>")
	if(!do_mob(src, C, devour_time))
		return
	if(pulling && pulling == C && grab_state >= GRAB_AGGRESSIVE && a_intent == INTENT_GRAB)
		C.visible_message("<span class='danger'>[src] devours [C]!</span>", \
						"<span class='userdanger'>[src] devours you!</span>")
		C.forceMove(src)
		stomach_contents.Add(C)
		log_combat(src, C, "devoured")

/mob/living/carbon/proc/create_bodyparts()
	var/l_arm_index_next = -1
	var/r_arm_index_next = 0
	for(var/X in bodyparts)
		var/obj/item/bodypart/O = new X()
		O.owner = src
		bodyparts.Remove(X)
		bodyparts.Add(O)
		if(O.body_part == ARM_LEFT)
			l_arm_index_next += 2
			O.held_index = l_arm_index_next //1, 3, 5, 7...
			hand_bodyparts += O
		else if(O.body_part == ARM_RIGHT)
			r_arm_index_next += 2
			O.held_index = r_arm_index_next //2, 4, 6, 8...
			hand_bodyparts += O

/mob/living/carbon/proc/create_internal_organs()
	for(var/X in internal_organs)
		var/obj/item/organ/I = X
		I.Insert(src)

/mob/living/carbon/proc/update_disabled_bodyparts(silent = FALSE)
	for(var/B in bodyparts)
		var/obj/item/bodypart/BP = B
		BP.update_disabled(silent)

/mob/living/carbon/vv_get_dropdown()
	. = ..()
	VV_DROPDOWN_OPTION("", "---------")
	VV_DROPDOWN_OPTION(VV_HK_MAKE_AI, "Make AI")
	VV_DROPDOWN_OPTION(VV_HK_MODIFY_BODYPART, "Modify bodypart")
	VV_DROPDOWN_OPTION(VV_HK_MODIFY_ORGANS, "Modify organs")
	VV_DROPDOWN_OPTION(VV_HK_HALLUCINATION, "Hallucinate")
	VV_DROPDOWN_OPTION(VV_HK_MARTIAL_ART, "Give Martial Arts")
	VV_DROPDOWN_OPTION(VV_HK_GIVE_TRAUMA, "Give Brain Trauma")
	VV_DROPDOWN_OPTION(VV_HK_CURE_TRAUMA, "Cure Brain Traumas")

/mob/living/carbon/vv_do_topic(list/href_list)
	. = ..()
	if(href_list[VV_HK_MODIFY_BODYPART])
		if(!check_rights(R_SPAWN))
			return
		var/edit_action = input(usr, "What would you like to do?","Modify Body Part") as null|anything in list("add","remove", "augment")
		if(!edit_action)
			return
		var/list/limb_list = list()
		if(edit_action == "remove" || edit_action == "augment")
			for(var/obj/item/bodypart/B in bodyparts)
				limb_list += B.body_zone
			if(edit_action == "remove")
				limb_list -= BODY_ZONE_CHEST
		else
			limb_list = list(BODY_ZONE_HEAD, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
			for(var/obj/item/bodypart/B in bodyparts)
				limb_list -= B.body_zone
		var/result = input(usr, "Please choose which body part to [edit_action]","[capitalize(edit_action)] Body Part") as null|anything in limb_list
		if(result)
			var/obj/item/bodypart/BP = get_bodypart(result)
			switch(edit_action)
				if("remove")
					if(BP)
						BP.drop_limb()
					else
						to_chat(usr, "[src] doesn't have such bodypart.")
				if("add")
					if(BP)
						to_chat(usr, "[src] already has such bodypart.")
					else
						if(!regenerate_limb(result))
							to_chat(usr, "[src] cannot have such bodypart.")
				if("augment")
					if(ishuman(src))
						if(BP)
							BP.change_bodypart_status(BODYPART_ROBOTIC, TRUE, TRUE)
						else
							to_chat(usr, "[src] doesn't have such bodypart.")
					else
						to_chat(usr, "Only humans can be augmented.")
		admin_ticket_log("[key_name_admin(usr)] has modified the bodyparts of [src]")
	if(href_list[VV_HK_MAKE_AI])
		if(!check_rights(R_SPAWN))
			return
		if(alert("Confirm mob type change?",,"Transform","Cancel") != "Transform")
			return
		usr.client.holder.Topic("vv_override", list("makeai"=href_list[VV_HK_TARGET]))
	if(href_list[VV_HK_MODIFY_ORGANS])
		if(!check_rights(NONE))
			return
		usr.client.manipulate_organs(src)
	if(href_list[VV_HK_MARTIAL_ART])
		if(!check_rights(NONE))
			return
		usr.client.teach_martial_art(src)
	if(href_list[VV_HK_GIVE_TRAUMA])
		if(!check_rights(NONE))
			return
		var/list/traumas = subtypesof(/datum/brain_trauma)
		var/result = input(usr, "Choose the brain trauma to apply","Traumatize") as null|anything in traumas
		if(!usr)
			return
		if(QDELETED(src))
			to_chat(usr, "Mob doesn't exist anymore")
			return
		if(!result)
			return
		var/datum/brain_trauma/BT = gain_trauma(result)
		if(BT)
			log_admin("[key_name(usr)] has traumatized [key_name(src)] with [BT.name]")
			message_admins("<span class='notice'>[key_name_admin(usr)] has traumatized [key_name_admin(src)] with [BT.name].</span>")
	if(href_list[VV_HK_CURE_TRAUMA])
		if(!check_rights(NONE))
			return
		cure_all_traumas(TRAUMA_RESILIENCE_ABSOLUTE)
		log_admin("[key_name(usr)] has cured all traumas from [key_name(src)].")
		message_admins("<span class='notice'>[key_name_admin(usr)] has cured all traumas from [key_name_admin(src)].</span>")
	if(href_list[VV_HK_HALLUCINATION])
		if(!check_rights(NONE))
			return
		var/list/hallucinations = subtypesof(/datum/hallucination)
		var/result = input(usr, "Choose the hallucination to apply","Send Hallucination") as null|anything in hallucinations
		if(!usr)
			return
		if(QDELETED(src))
			to_chat(usr, "Mob doesn't exist anymore")
			return
		if(result)
			new result(src, TRUE)

/mob/living/carbon/can_resist()
	return bodyparts.len > 2 && ..()

/mob/living/carbon/proc/hypnosis_vulnerable()//unused atm, but added in case
	if(HAS_TRAIT(src, TRAIT_MINDSHIELD))
		return FALSE
	if(hallucinating())
		return TRUE
	if(IsSleeping())
		return TRUE
	if(HAS_TRAIT(src, TRAIT_DUMB))
		return TRUE
	var/datum/component/mood/mood = src.GetComponent(/datum/component/mood)
	if(mood)
		if(mood.sanity < SANITY_UNSTABLE)
			return TRUE

/mob/living/carbon/can_see_reagents()
	. = ..()
	if(.) //No need to run through all of this if it's already true.
		return
	if(isclothing(head))
		var/obj/item/clothing/H = head
		if(H.clothing_flags & SCAN_REAGENTS)
			return TRUE
	if(isclothing(wear_mask) && (wear_mask.clothing_flags & SCAN_REAGENTS))
		return TRUE
	// BLUEMOON ADDITION AHEAD making use of trait system
	else if (HAS_TRAIT(src.mind, TRAIT_REAGENT_EXPERT))
		return TRUE
	// BLUEMOON ADDITION END

/mob/living/carbon/can_hold_items()
	return TRUE

/mob/living/carbon/set_gender(ngender = NEUTER, silent = FALSE, update_icon = TRUE, forced = FALSE)
	var/bender = gender != ngender
	. = ..()
	if(!.)
		return
	if(dna && bender)
		if(ngender == MALE || ngender == FEMALE)
			dna.features["body_model"] = ngender
			if(!silent)
				var/adj = ngender == MALE ? "masculine" : "feminine"
				visible_message("<span class='boldnotice'>[src] suddenly looks more [adj]!</span>", "<span class='boldwarning'>You suddenly feel more [adj]!</span>")
		else if(ngender == NEUTER)
			dna.features["body_model"] = MALE
	if(update_icon)
		update_body()

/mob/living/carbon/check_obscured_slots()
	if(head)
		if(head.flags_inv & HIDEMASK)
			LAZYOR(., ITEM_SLOT_MASK)
		if(head.flags_inv & HIDEEYES)
			LAZYOR(., ITEM_SLOT_EYES)
		if(head.flags_inv & HIDEEARS)
			LAZYOR(., ITEM_SLOT_EARS_LEFT)
			LAZYOR(., ITEM_SLOT_EARS_RIGHT)

	if(wear_mask)
		if(wear_mask.flags_inv & HIDEEYES)
			LAZYOR(., ITEM_SLOT_EYES)

// if any of our bodyparts are bleeding
/mob/living/carbon/proc/is_bleeding()
	for(var/i in bodyparts)
		var/obj/item/bodypart/BP = i
		if(BP.get_bleed_rate())
			return TRUE

// get our total bleedrate
/mob/living/carbon/proc/get_total_bleed_rate()
	var/total_bleed_rate = 0
	for(var/i in bodyparts)
		var/obj/item/bodypart/BP = i
		total_bleed_rate += BP.get_bleed_rate()

	return total_bleed_rate

/**
  * generate_fake_scars()- for when you want to scar someone, but you don't want to hurt them first. These scars don't count for temporal scarring (hence, fake)
  *
  * If you want a specific wound scar, pass that wound type as the second arg, otherwise you can pass a list like WOUND_LIST_SLASH to generate a random cut scar.
  *
  * Arguments:
  * * num_scars- A number for how many scars you want to add
  * * forced_type- Which wound or category of wounds you want to choose from, WOUND_LIST_BLUNT, WOUND_LIST_SLASH, or WOUND_LIST_BURN (or some combination). If passed a list, picks randomly from the listed wounds. Defaults to all 3 types
  */
/mob/living/carbon/proc/generate_fake_scars(num_scars, forced_type)
	for(var/i in 1 to num_scars)
		var/datum/scar/scaries = new
		var/obj/item/bodypart/scar_part = pick(bodyparts)

		var/wound_type
		if(forced_type)
			if(islist(forced_type))
				wound_type = pick(forced_type)
			else
				wound_type = forced_type
		else
			wound_type = pick(GLOB.global_all_wound_types)

		var/datum/wound/phantom_wound = new wound_type
		scaries.generate(scar_part, phantom_wound)
		scaries.fake = TRUE
		QDEL_NULL(phantom_wound)

/**
  * get_biological_state is a helper used to see what kind of wounds we roll for. By default we just assume carbons (read:monkeys) are flesh and bone, but humans rely on their species datums
  *
  * go look at the species def for more info [/datum/species/proc/get_biological_state]
  */
/mob/living/carbon/proc/get_biological_state()
	return BIO_FLESH_BONE

/mob/living/carbon/altattackby(obj/item/W, mob/living/carbon/user, params)
	if(user.incapacitated() || !user.Adjacent(src))
		return FALSE
	if(W && user.a_intent == INTENT_HELP && W.can_give())
		user.give(src)
		return TRUE

/mob/living/carbon/verb/give_verb()
	set src in oview(1)
	set category = "IC"
	set name = "Give"

	if(usr.incapacitated() || !usr.Adjacent(src))
		return

	if(!usr.get_active_held_item()) // Let me know if this has any problems -Yota
		return
	var/obj/item/I = usr.get_active_held_item()
	var/mob/living/carbon/C = usr
	if(I.can_give())
		C.give(src)

/mob/living/carbon/proc/functional_blood()
	return blood_volume + integrating_blood
