/datum/outfit/warhammer_pirate
	name = "Space Warhammer Pirate"
	uniform = /obj/item/clothing/under/costume/pirate
	shoes = /obj/item/clothing/shoes/sneakers/brown
	suit = /obj/item/clothing/suit/pirate
	head = /obj/item/clothing/head/bandana
	glasses = /obj/item/clothing/glasses/eyepatch

/datum/outfit/warhammer_pirate/space
	name = "Space Warhammer Pirate, Space"
	suit = /obj/item/clothing/suit/space/pirate
	head = /obj/item/clothing/head/helmet/space/warhammer_pirate/bandana
	ears = /obj/item/radio/headset/pirate
	id = /obj/item/card/id/pirate

	give_space_cooler_if_synth = TRUE // BLUEMOON ADD

/datum/outfit/warhammer_pirate/space/captain
	name = "Space Warhammer Pirate, Space, Captian"
	head = /obj/item/clothing/head/helmet/space/warhammer_pirate

/datum/outfit/warhammer_pirate/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	H.faction |= "pirate"

	var/obj/item/radio/R = H.ears
	if(R)
		R.set_frequency(FREQ_PIRATE)
		R.freqlock = TRUE

	var/obj/item/card/id/W = H.wear_id
	if(W)
		W.registered_name = H.real_name
		W.update_label(H.real_name)

	var/obj/item/implant/weapons_auth/B = new
	B.implant(H)
