/datum/antagonist/warhammer_pirate
	name = "Warhammer Pirates"
	job_rank = ROLE_TRAITOR
	roundend_category = "Warhammer Pirates"
	antagpanel_category = "Warhammer Pirates"
	threat = 5
	show_to_ghosts = TRUE
	var/datum/team/warhammer_pirate/crew

/datum/antagonist/warhammer_pirate/greet()
	SEND_SOUND(owner.current, sound('sound/ambience/antag/pirate.ogg'))
	to_chat(owner, "<span class='boldannounce'>Вы - Космопират!</span>")
	to_chat(owner, "<B>Станция в край охуела, надо её уебать.</B>")
	owner.announce_objectives()

/datum/antagonist/warhammer_pirate/get_team()
	return crew

/datum/antagonist/warhammer_pirate/create_team(datum/team/warhammer_pirate/new_team)
	if(!new_team)
		for(var/datum/antagonist/warhammer_pirate/P in GLOB.antagonists)
			if(!P.owner)
				continue
			if(P.crew)
				crew = P.crew
				return
		if(!new_team)
			crew = new /datum/team/warhammer_pirate
			return
	if(!istype(new_team))
		stack_trace("Wrong team type passed to [type] initialization.")
	crew = new_team

/datum/antagonist/warhammer_pirate/on_gain()
	if(crew)
		objectives |= crew.objectives
	. = ..()

/datum/team/warhammer_pirate
	name = "Warhammer pirates crew"
