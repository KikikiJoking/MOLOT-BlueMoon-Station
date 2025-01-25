/datum/reagent/consumable/sterilizatoranion
	name = "Sterilizatoranion"
	description = "When a cat does not want to live without bells, and it is dangerous to take him to the veterinarian."
	taste_description = "something like someone now have no balls"
	color = "#7dea68"
	nutriment_factor = 0.5 * REAGENTS_METABOLISM

/datum/reagent/consumable/sterilizatoranion/on_mob_add(mob/living/carbon/M, mob/living/partner)
	player.sterilazation += 1
	if player.sterilazation == 3
		writePlayer("")

	client.prefs.fertility
