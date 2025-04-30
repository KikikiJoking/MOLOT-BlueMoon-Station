//bolter
/obj/item/gun/ballistic/automatic/pistol/bolter_pistol
	name = "Garm Pattern Service Bolt Pistol"
	desc = "The human sized bolter pistol, designed for usage by the Commissars of the Officio Prefectus, It also found itself in usage by officers of Astra Militarum, Rogue Traders as well Inquisitorial agents, Thus, it is relatively common and easily found across the Galaxy."
	icon = 'modular_bluemoon/icons/obj/guns/projectile.dmi'
	icon_state = "bolter"
	item_state = "bolter"
	force = 10
	inaccuracy_modifier = -0.4
	fire_delay = 4.1
	mag_type = /obj/item/ammo_box/magazine/bolt_pistol_magazine
	fire_sound = 'sound/effects/explosion1.ogg'
	slot_flags = ITEM_SLOT_BELT|ITEM_SLOT_POCKETS|ITEM_SLOT_SUITSTORE

/obj/item/gun/ballistic/automatic/pistol/bolter_pistol/update_icon()
	..()
	if(magazine)
		if(magazine.ammo_count(0))
			icon_state = "bolter"
		else
			icon_state = "bolter-10"
	else
		if(chambered)
			icon_state = "bolter-e"
		else
			icon_state = "bolter-10-e"

//magaz
/obj/item/ammo_box/magazine/bolt_pistol_magazine
	name = "Boltpistol Magazine"
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = "ersatz"
	item_state = "ersatz"
	caliber = ".75"
	ammo_type = /obj/item/ammo_casing/boltpistol
	max_ammo = 10
	multiple_sprites = 1

/obj/item/ammo_box/magazine/bolt_pistol_magazine/update_icon()
	. = ..()
	if(ammo_count())
		icon_state = "[initial(icon_state)]-ammo"
	else
		icon_state = "[initial(icon_state)]"

/obj/item/ammo_casing/boltpistol
	desc = "A .75 bolt pistol casing."
	caliber = ".75"
	projectile_type = /obj/item/projectile/bullet/bpistol

/obj/item/projectile/bullet/bpistol
	damage = 48
