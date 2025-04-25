//bolter
/obj/item/gun/ballistic/automatic/pistol/bolter_pistol
	name = "Garm Pattern Service Bolt Pistol"
	desc = "The human sized bolter pistol, designed for usage by the Commissars of the Officio Prefectus, It also found itself in usage by officers of Astra Militarum, Rogue Traders as well Inquisitorial agents, Thus, it is relatively common and easily found across the Galaxy."
	icon = 'modular_bluemoon/icons/obj/guns/projectile.dmi'
	icon_state = "bpistol"
	item_state = "bpistol"
	force = 10
	inaccuracy_modifier = -0.4
	fire_delay = 4.1
	mag_type = /obj/item/ammo_box/magazine/bolt_pistol_magazine
	fire_sound = 'sound/effects/explosion1.ogg'
	slot_flags = ITEM_SLOT_BELT|ITEM_SLOT_POCKETS|ITEM_SLOT_SUITSTORE

/obj/item/gun/ballistic/automatic/pistol/bolter_pistol/update_icon()
	..()
	if(mag_type)
		icon_state = "bpistol-10"
	else
		icon_state = "bpistol-10-e"

//magaz
/obj/item/ammo_box/magazine/bolt_pistol_magazine
	name = "Boltpistol Magazine"
	icon_state = "ersatz"
	caliber = ".75"
	ammo_type = /obj/item/ammo_casing/boltpistol
	max_ammo = 10
	multiple_sprites = 1

/obj/item/ammo_casing/boltpistol
	desc = "A .75 bolt pistol casing."
	caliber = ".75"
	projectile_type = /obj/item/projectile/bullet/bpistol

/obj/item/projectile/bullet/bpistol
	damage = 48
