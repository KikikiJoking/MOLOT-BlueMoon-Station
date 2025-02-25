/datum/tgs_chat_command/ban
	name = "ban"
	help_text = "Usage: ban (add ckey (comment)|remove ckey (comment)"
	admin_only = TRUE

/datum/tgs_chat_command/ban/Run(datum/tgs_chat_user/sender, params)
	var/datum/admins/our_solution
	our_solution = new (forced_holder = TRUE)

	if(!params)
		return "Использование: !ban add <ckey> <reason> | !ban remove <ckey>"

	var/list/paramslist = splittext(params, " ")

	var/target_ckey = ckey(paramslist[1])
	message_admins("PERMABAN: Попытка заблокировать '[target_ckey]' от [sender.friendly_name]")

	switch(paramslist[1])
		if("add")
			var/comment = "Перманентная блокировка."
			if(length(paramslist) > 2)
				var/pos = findtext(params, paramslist[2]) + length(paramslist[2]) + 1
				comment = copytext(params, pos)
			our_solution.DB_ban_record(BANTYPE_PERMA, target_ckey, reason = comment)
		else
			our_solution.DB_ban_unban_by_id(target_ckey)
