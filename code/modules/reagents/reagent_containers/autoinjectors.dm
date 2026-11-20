/obj/item/reagent_containers/hypospray/autoinjector
	name = "generic autoinjector"
	desc = "An autoinjector containing... table salt? <i>\"For any client assistance, please contact the coderbus\" is written on the back.</i>"
	icon = 'icons/obj/items/syringe.dmi'
	icon_state = "autoinjector-13"
	worn_icon_state = "hypo"
	w_class = WEIGHT_CLASS_TINY
	skilllock = 0
	reagent_flags = DRAWABLE
	amount_per_transfer_from_this = 15
	volume = 45
	possible_transfer_amounts = list(1, 3, 5, 10, 15, 20, 30, 45)
	list_reagents = list(/datum/reagent/consumable/sodiumchloride = 45)
	greyscale_config = /datum/greyscale_config/autoinjector_13
	///For keeping the initial name of the autoinjector, and not setting back to general autoinjector
	var/base_name
	/// Цвет наконечника
	var/tip_color = "#3ad1f0"
	/// Цвет средней части
	var/mid_color = "#ffffff"
	/// Цвет нижней части и кнопки
	var/down_color = "#F1A344"

/obj/item/reagent_containers/hypospray/autoinjector/Initialize(mapload)
	greyscale_colors = "[tip_color][mid_color][down_color]"
	base_icon_state = icon_state
	base_name = name
	return ..() // some incomprehensible power of shitcode makes penals first update icon_state and only then set base_icon_state, works fine for simple autoinjectors tho

/obj/item/reagent_containers/hypospray/autoinjector/update_icon_state()
	. = ..()
	if(!(reagents?.total_volume) && is_drawable())
		icon_state = "[base_icon_state]X"
		name = "expended [base_name]"
		DISABLE_BITFIELD(reagents.reagent_flags, DRAWABLE)
	else if(reagents?.total_volume && !CHECK_BITFIELD(reagents.reagent_flags, DRAWABLE)) // refilling it somehow
		icon_state = base_icon_state
		name = base_name
		ENABLE_BITFIELD(reagents.reagent_flags, DRAWABLE)

/obj/item/reagent_containers/hypospray/autoinjector/examine(mob/user)
	. = ..()
	. += "" // for some weird reason, without this lower lines get in line with item's size line
	if(length(reagents.reagent_list))
		. += span_notice("It is currently loaded.")
	else
		. += span_notice("It is spent.")
	. += span_warning("<b>Use</b> to inject into yourself. <b>Unique Action</b> to configure injection amount.")

/obj/item/reagent_containers/hypospray/autoinjector/fillable
	desc = "An autoinjector loaded with... something, consult the doctor who gave this to you."
	amount_per_transfer_from_this = 45
	list_reagents = null

/obj/item/reagent_containers/hypospray/autoinjector/tricordrazine
	name = "tricordrazine autoinjector"
	desc = "An autoinjector loaded with 3 doses of tricordrazine, a weak general use medicine for treating damage."
	tip_color = "#E38B1A"
	list_reagents = list(/datum/reagent/medicine/tricordrazine = 45)
	description_overlay = "Ti"

/obj/item/reagent_containers/hypospray/autoinjector/combat
	name = "combat autoinjector"
	desc = "An autoinjector loaded with 3 doses of healing and painkilling chemicals. Intended for use in active combat."
	tip_color = "#FFB27B"
	down_color = "#FFB27B"
	amount_per_transfer_from_this = 15
	list_reagents = list(
		/datum/reagent/medicine/bicaridine = 15,
		/datum/reagent/medicine/kelotane = 15,
		/datum/reagent/medicine/tricordrazine = 7.5,
		/datum/reagent/medicine/tramadol = 7.5,
	)
	description_overlay = "Cb"

/obj/item/reagent_containers/hypospray/autoinjector/combat_advanced
	name = "advanced combat autoinjector"
	desc = "An autoinjector loaded with 3 doses of advanced healing and painkilling chemicals. Intended for use in active combat."
	tip_color = "#FF7F7F"
	down_color = "#FF7F7F"
	amount_per_transfer_from_this = 15
	list_reagents = list(
		/datum/reagent/medicine/meralyne = 15,
		/datum/reagent/medicine/dermaline = 15,
		/datum/reagent/medicine/oxycodone = 15,
	)
	description_overlay = "Ca"

/obj/item/reagent_containers/hypospray/autoinjector/quickclot
	name = "quick-clot autoinjector"
	desc = "An autoinjector loaded with 3 doses of quick-clot, a chemical designed to pause all bleeding. Renew doses as needed."
	tip_color = "#a70a72"
	list_reagents = list(/datum/reagent/medicine/quickclot = 45)
	description_overlay = "Qk"

/obj/item/reagent_containers/hypospray/autoinjector/quickclotplus
	name = "quick-clot plus autoinjector"
	desc = "An autoinjector loaded with 3 uses of quick-clot plus, a chemical designed to remove internal bleeding. Use with antitoxin. !DO NOT USE IN ACTIVE COMBAT!"
	tip_color = "#e6119f"
	amount_per_transfer_from_this = 5
	volume = 15
	list_reagents = list(/datum/reagent/medicine/quickclotplus = 15)
	description_overlay = "Qk+"

/obj/item/reagent_containers/hypospray/autoinjector/dexalinplus
	name = "dexalin plus autoinjector"
	desc = "An autoinjector loaded with 3 uses of dexalin plus, designed to immediately oxygenate the entire body."
	tip_color = "#3b79db"
	amount_per_transfer_from_this = 1
	volume = 3
	list_reagents = list(/datum/reagent/medicine/dexalinplus = 3)
	description_overlay = "Dx+"

/obj/item/reagent_containers/hypospray/autoinjector/sleeptoxin
	name = "anesthetic autoinjector"
	desc = "An autoinjector loaded with 10 units of sleeping agent. Good to quickly pacify someone, for surgery of course."
	tip_color = "#f0e8f3"
	amount_per_transfer_from_this = 10
	volume = 10
	list_reagents = list(
		/datum/reagent/toxin/sleeptoxin = 8,
		/datum/reagent/toxin/chloralhydrate = 2,
	)

/obj/item/reagent_containers/hypospray/autoinjector/dylovene
	name = "dylovene autoinjector"
	desc = "An auto-injector loaded with 3 doses of dylovene, an anti-toxin agent useful in cases of poisoning, overdoses and toxin build-up."
	tip_color = "#17b611"
	list_reagents = list(/datum/reagent/medicine/dylovene = 45)
	description_overlay = "Dy"
	amount_per_transfer_from_this = 3

/obj/item/reagent_containers/hypospray/autoinjector/tramadol
	name = "tramadol autoinjector"
	desc = "An auto-injector loaded with 3 doses of tramadol, an effective painkiller for normal wounds."
	tip_color = "#8438b1"
	list_reagents = list(/datum/reagent/medicine/tramadol = 45)
	description_overlay = "Ta"

/obj/item/reagent_containers/hypospray/autoinjector/oxycodone
	name = "oxycodone autoinjector"
	desc = "An auto-injector loaded with 2 doses of oxycodone, a powerful pankiller intended for life-threatening situations."
	tip_color = "#272524"
	down_color = "#3b3532"
	volume = 20
	amount_per_transfer_from_this = 10
	list_reagents = list(/datum/reagent/medicine/oxycodone = 20)
	description_overlay = "Ox"

/obj/item/reagent_containers/hypospray/autoinjector/kelotane
	name = "kelotane autoinjector"
	desc = "An auto-injector loaded with 3 doses of kelotane, a common burn medicine."
	tip_color = "#ebb513"
	list_reagents = list(/datum/reagent/medicine/kelotane = 45)
	description_overlay = "Ke"

/obj/item/reagent_containers/hypospray/autoinjector/bicaridine
	name = "bicaridine autoinjector"
	desc = "An auto-injector loaded with 3 doses of bicaridine, a common brute and circulatory damage medicine."
	tip_color = "#DA0000"
	list_reagents = list(/datum/reagent/medicine/bicaridine = 45)
	description_overlay = "Bi"

/obj/item/reagent_containers/hypospray/autoinjector/inaprovaline
	name = "inaprovaline autoinjector"
	desc = "An auto-injector loaded with 3 doses of inaprovaline, an emergency stabilization medicine for patients in critical condition."
	tip_color = "#b67af1"
	amount_per_transfer_from_this = 15
	list_reagents = list(/datum/reagent/medicine/inaprovaline = 45)
	description_overlay = "In"

/obj/item/reagent_containers/hypospray/autoinjector/dexalin
	name = "dexalin autoinjector"
	desc = "An auto-injector loaded with 3 doses of dexalin, a medicine that oxygenates the body helping those with respiratory issues or low blood."
	tip_color = "#3b79db"
	volume = 15
	amount_per_transfer_from_this = 5
	list_reagents = list(/datum/reagent/medicine/dexalin = 15)
	description_overlay = "Dx"

/obj/item/reagent_containers/hypospray/autoinjector/spaceacillin
	name = "spaceacillin autoinjector"
	desc = "An auto-injector loaded with 9 doses of spaceacillin, an antibiotic medicine that helps combat infection and fight necrosis."
	tip_color = "#19d6b0"
	amount_per_transfer_from_this = 5
	list_reagents = list(/datum/reagent/medicine/spaceacillin = 45)
	description_overlay = "Sp"

/obj/item/reagent_containers/hypospray/autoinjector/alkysine
	name = "alkysine autoinjector"
	desc = "An auto-injector loaded with 9 doses of alkysine, long-living medicine for fixing brain and ear damage."
	tip_color = "#409EB1"
	amount_per_transfer_from_this = 5
	list_reagents = list(/datum/reagent/medicine/alkysine = 45)
	description_overlay = "Al"

/obj/item/reagent_containers/hypospray/autoinjector/imidazoline
	name = "imidazoline autoinjector"
	desc = "An auto-injector loaded with 6 doses of imidazoline, medicine for fixing eyesight."
	tip_color = "#3ac98d"
	amount_per_transfer_from_this = 7.5
	list_reagents = list(/datum/reagent/medicine/imidazoline = 45)
	description_overlay = "Im"

/obj/item/reagent_containers/hypospray/autoinjector/hypervene
	name = "hypervene autoinjector"
	desc = "An auto-injector loaded with 15 uses of hypervene, an emergency medicine that rapidly purges chems. Causes pain and vomiting."
	tip_color = "#3dff02"
	down_color = "#4ccc25"
	amount_per_transfer_from_this = 3
	list_reagents = list(/datum/reagent/hypervene = 45)
	description_overlay = "Hy"

/obj/item/reagent_containers/hypospray/autoinjector/virilyth //not accessible during normal play, only for valhalla
	name = "virilyth autoinjector"
	desc = "A large auto-injector freshly loaded with virilynth."
	amount_per_transfer_from_this = 10
	volume = 50
	list_reagents = list(
		/datum/reagent/virilyth = 50,
	)

/obj/item/reagent_containers/hypospray/autoinjector/rezadone //not accessible during normal play, only for valhalla
	name = "rezadone autoinjector"
	desc = "A large auto-injector freshly loaded with rezadone."
	amount_per_transfer_from_this = 10
	volume = 50
	list_reagents = list(
		/datum/reagent/medicine/rezadone = 50,
	)

/obj/item/reagent_containers/hypospray/autoinjector/synaptizine
	name = "synaptizine autoinjector"
	desc = "An auto-injector freshly loaded with a safe-to-use synaptizine mix."
	tip_color = "#7300EF"
	down_color = "#6d19c7"
	amount_per_transfer_from_this = 3
	volume = 18
	list_reagents = list(
		/datum/reagent/medicine/synaptizine = 6,
		/datum/reagent/medicine/hyronalin = 12,
	)
	description_overlay = "Sy"

/obj/item/reagent_containers/hypospray/autoinjector/synaptizine_expired
	name = "expired synaptizine autoinjector"
	desc = "An auto-injector said to be loaded with a safe-to-use synaptizine mix, 3 months past it's expiration date."
	tip_color = "#548175"
	amount_per_transfer_from_this = 2
	volume = 6
	list_reagents = list(
		/datum/reagent/medicine/synaptizine = 3,
		/datum/reagent/medicine/hyronalin = 3,
	)
	description_overlay = "Sy-"

/obj/item/reagent_containers/hypospray/autoinjector/neuraline
	name = "neuraline autoinjector"
	desc = "An auto-injector loaded with 3 doses of neuraline, an extremely powerful stimulant. !DO NOT USE MORE THAN ONCE AT A TIME!"
	tip_color = "#f10687"
	down_color = "#df067d"
	amount_per_transfer_from_this = 4
	volume = 12
	list_reagents = list(/datum/reagent/medicine/neuraline = 12)
	description_overlay = "Ne"

/obj/item/reagent_containers/hypospray/autoinjector/peridaxon
	name = "Peridaxon autoinjector"
	desc = "An auto-injector loaded with 3 doses of Peridaxon, a chemical that removes the consequences from organs !DO NOT USE MORE THAN ONCE AT A TIME!"
	amount_per_transfer_from_this = 5
	volume = 15
	tip_color = "#6c5ce7"
	list_reagents = list(/datum/reagent/medicine/peridaxon = 15)
	description_overlay = "Pe"

/obj/item/reagent_containers/hypospray/autoinjector/peridaxon_plus
	name = "peridaxon Plus autoinjector"
	desc = "An auto-injector loaded with 3 doses of Peridaxon Plus, a chemical that heals organs while causing a buildup of toxins. Use with antitoxin. !DO NOT USE IN ACTIVE COMBAT!"
	amount_per_transfer_from_this = 3
	volume = 9
	list_reagents = list(
		/datum/reagent/medicine/peridaxon_plus = 3,
		/datum/reagent/medicine/hyronalin = 6,
	)
	description_overlay = "Pe+"

/obj/item/reagent_containers/hypospray/autoinjector/antitox_mix
	name = "Anti-toxin mix 4"
	desc = "An auto-injector loaded a cocktail of chemicals intended for rapid treatment of severe toxin damage. Do not use without proper medical supervision."
	tip_color = "#00b894"
	amount_per_transfer_from_this = 15
	list_reagents = list(
		/datum/reagent/medicine/hyronalin = 7.5,
		/datum/reagent/medicine/dylovene = 7.5,
		/datum/reagent/medicine/tricordrazine = 7.5,
		/datum/reagent/medicine/arithrazine = 7.5,
	)
	description_overlay = "Tx4"

/obj/item/reagent_containers/hypospray/autoinjector/russian_red
	name = "emergency autoinjector"
	desc = "An autoinjector loaded with 3 doses of Russian Red. Restores a significant amount of stamina and heals a large amount of damage, but causes slight permanent damage."
	tip_color = "#ff2600"
	down_color = "#eb3d08"
	amount_per_transfer_from_this = 10
	list_reagents = list(
		/datum/reagent/medicine/russian_red = 30,
	)
	description_overlay = "Rr"
	free_refills = FALSE

/obj/item/reagent_containers/hypospray/autoinjector/polyhexanide
	name = "polyhexanide autoinjector"
	desc = "An auto-injector loaded with a dose of Polyhexanide, a sterilizer for internal surgical use."
	tip_color = "#55efc4"
	amount_per_transfer_from_this = 5
	volume = 20
	list_reagents = list(/datum/reagent/medicine/polyhexanide = 20)

/obj/item/reagent_containers/hypospray/autoinjector/isotonic
	name = "isotonic solution autoinjector"
	desc = "An auto-injector loaded with 3 doses of isotonic solution, formulated to quickly recover fluid volume after blood loss or trauma."
	tip_color = "#8fb5db"
	amount_per_transfer_from_this = 15
	list_reagents = list(
		/datum/reagent/medicine/saline_glucose = 45,
	)
	description_overlay = "Is"

/obj/item/reagent_containers/hypospray/autoinjector/roulettium
	name = "roulettium autoinjector"
	desc = "An auto-injector loaded with one shot of roulettium, an extremely powerful panacea. !THIS HAS A CHANCE OF UNRECOVERABLE DEATH!"
	amount_per_transfer_from_this = 1
	volume = 1
	list_reagents = list(/datum/reagent/medicine/roulettium = 1)

/obj/item/reagent_containers/hypospray/autoinjector/elite //only deathsquad should be able to get this
	name = "elite autoinjector"
	desc = "An elite auto-injector loaded with a strong and versatile combination of chemicals, healing most types of damage. Issued almost excusively to the infamous Nanotrasen deathsquads"
	volume = 37.5
	amount_per_transfer_from_this = 12.4
	list_reagents = list(
		/datum/reagent/medicine/russian_red = 30,
		/datum/reagent/medicine/rezadone = 7.2,
	)

/obj/item/reagent_containers/hypospray/autoinjector/medicalnanites
	name = "nanomachines autoinjector"
	desc = "An auto-injector loaded with medical nanites. A potent new method of healing that that reproduces using a subject's blood and has a brief but potentially dangerous activation period! Beware of Neurotoxin!"
	tip_color = "#1b4e4e"
	amount_per_transfer_from_this = 1
	volume = 1
	list_reagents = list(/datum/reagent/medicalnanites = 1)
	free_refills = FALSE
	description_overlay = "Na"

/obj/item/reagent_containers/hypospray/autoinjector/sulfasalazine
	name = "sulfasalazine autoinjector"
	desc = "An auto-injector loaded with sulfasalazine, an agent that restores itself at the expense of other reagents and purge them, but has a great healing effect. WARNING: It embeds itself into the deepest tissues of the body, making it impossible to remove from the user after administration"
	amount_per_transfer_from_this = 1
	volume = 1
	tip_color = "#71c208"
	reagent_flags = NONE
	list_reagents = list(/datum/reagent/medicine/sulfasalazine = 1)
	free_refills = FALSE
	description_overlay = "Su"

/obj/item/reagent_containers/hypospray/autoinjector/sulfasalazine/afterattack(atom/A, mob/living/user)
	if(!ishuman(A))
		balloon_alert(user, "Can only inject humans.")
		return
	. = ..()
	update_icon()

/obj/item/reagent_containers/hypospray/autoinjector/sulfasalazine/is_drawable()
	return FALSE

/obj/item/reagent_containers/hypospray/autoinjector/sulfasalazine/update_icon_state()
	if(!reagents?.total_volume)
		icon_state = "[base_icon_state]X"
	else
		icon_state = base_icon_state

/obj/item/reagent_containers/hypospray/autoinjector/pain //made for debugging
	name = "liquid pain autoinjector"
	desc = "An auto-injector loaded with liquid pain. Ow."
	amount_per_transfer_from_this = 20
	volume = 100
	list_reagents = list(/datum/reagent/toxin/pain = 100)

/obj/item/reagent_containers/hypospray/autoinjector/spacedrugs //CL goodie
	name = "space drugs autoinjector"
	desc = "An auto-injector loaded with sweet, sweet space drugs... Hard to get as a marine."
	amount_per_transfer_from_this = 25
	volume = 25
	list_reagents = list(/datum/reagent/space_drugs = 25)

/obj/item/reagent_containers/hypospray/autoinjector/mindbreaker //made for debugging
	name = "mindbreaker toxin autoinjector"
	desc = "An auto-injector loaded with the hardest, deadliest drug around. May cure PTSD. May cause it."
	amount_per_transfer_from_this = 30
	volume = 30
	list_reagents = list(/datum/reagent/toxin/mindbreaker = 30)

/obj/item/reagent_containers/hypospray/autoinjector/yautja
	name = "unusual crystal"
	desc = "A strange glowing crystal with a spike at one end."
	icon = 'icons/obj/hunter/pred_gear.dmi'
	icon_state = "crystal"
	worn_icon_state = ""
	amount_per_transfer_from_this = REAGENTS_OVERDOSE
	volume = REAGENTS_OVERDOSE
	list_reagents = list(/datum/reagent/thwei = REAGENTS_OVERDOSE)

/obj/item/reagent_containers/hypospray/autoinjector/yautja/attack(mob/M, mob/user)
	if(HAS_TRAIT(user, TRAIT_YAUTJA_TECH))
		..()
	else
		to_chat(user, span_danger("You have no idea where to inject [src]."))

/obj/item/reagent_containers/hypospray/autoinjector/yautja/interact(mob/user)
	return

/obj/item/reagent_containers/hypospray/autoinjector/regrow
	name = "Re-Grow autoinjector"
	desc = "An auto-injector loaded with Re-Grow - able to rapidly regrow missing limbs."
	tip_color = "#00cec9"
	mid_color = "#55efc4"
	amount_per_transfer_from_this = 5
	list_reagents = list(
		/datum/reagent/medicine/regrow = 30,
	)
	description_overlay = "Grw"
