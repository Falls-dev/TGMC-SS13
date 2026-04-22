/// Global list of all available xeno mutations (initialized on first use)
GLOBAL_LIST_EMPTY(xeno_mutations)

/// Global variable for accessing mutation menu. Does not need to be unique to each xeno as ui_data pulls relevant information based on context.
GLOBAL_DATUM(mutation_menu, /datum/mutation_menu)
