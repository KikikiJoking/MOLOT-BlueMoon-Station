/* BLUEMOON EDIT - CODE OVERRIDDEN IN 'modular_bluemoon\code\modules\vending\magivend.dm'
/obj/machinery/vending/magivend
	name = "\improper MagiVend"
	desc = "A magic vending machine."
	icon_state = "MagiVend"
	product_slogans = "Накладывайте заклинания правильным способом с помощью MagiVend!;Станьте своим собственным Гудини! Используйте MagiVend!;FJKLFJSD;AJKFLBJAKL;1234 LOONIES;LOL!;>MFW;KOS!!!;GET DAT FUKKEN DISK;HONK!;EI NATH;Destroy the station!;Admin conspiracies since forever!;Space-time bending hardware!"
	vend_reply = "Have an enchanted evening!"
	products = list(/obj/item/clothing/head/wizard = 1,
					/obj/item/clothing/suit/wizrobe = 1,
					/obj/item/clothing/head/wizard/red = 1,
					/obj/item/clothing/suit/wizrobe/red = 1,
					/obj/item/clothing/head/wizard/yellow = 1,
					/obj/item/clothing/suit/wizrobe/yellow = 1,
					/obj/item/clothing/shoes/sandal/magic = 1,
					/obj/item/staff = 2)
	contraband = list(/obj/item/reagent_containers/glass/bottle/wizarditis = 1) //No one can get to the machine to hack it anyways; for the lulz - Microwave
	armor = list(MELEE = 100, BULLET = 100, LASER = 100, ENERGY = 100, BOMB = 0, BIO = 0, RAD = 0, FIRE = 100, ACID = 50, MAGIC = 100)
	resistance_flags = FIRE_PROOF
	default_price = 0 //Just in case, since it's primary use is storage.
	extra_price = PRICE_ABOVE_EXPENSIVE
	payment_department = ACCOUNT_SRV
	light_mask = "magivend-light-mask"
*/
