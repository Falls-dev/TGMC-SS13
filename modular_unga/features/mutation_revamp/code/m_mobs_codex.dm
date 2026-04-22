	if(length(purchased_mutations))
		xeno_strings += "Mutations:"
		for(var/mutation_name in purchased_mutations)
			var/datum/xeno_mutation/mutation = get_xeno_mutation_by_name(mutation_name)
			if(mutation)
				xeno_strings += "  • [mutation.name]"
	else
		xeno_strings += "Mutations: None"
