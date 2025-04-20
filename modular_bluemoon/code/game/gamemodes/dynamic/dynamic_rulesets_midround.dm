// Warhammer Pirates ruleset
/datum/dynamic_ruleset/midround/warhammer_pirate
	name = "Warhammer Pirates"
	antag_flag = "Warhammer Pirates"
	required_type = /mob/dead/observer
	enemy_roles = list("Blueshield", "Peacekeeper", "Brig Physician", "Security Officer", "Warden", "Detective", "Head of Security","Bridge Officer", "Captain") //BLUEMOON CHANGE
	required_enemies = list(0,0,0,0,0,5,4,3,3,3) //BLUEMOON CHANGES
	required_candidates = 0
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD) // BLUEMOON ADD
	weight = 6 //BLUEMOON CHANGES
	cost = 15
	requirements = list(101,101,101,101,101,40,30,20,10,10) //BLUEMOON CHANGES
	repeatable = TRUE

/datum/dynamic_ruleset/midround/warhammer_pirate/acceptable(population=0, threat=0)
	if (!SSmapping.empty_space)
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/warhammer_pirate/execute()
	send_pirate_threat()
	return ..()
