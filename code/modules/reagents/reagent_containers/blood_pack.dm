/obj/item/reagent_containers/blood
	name = "BloodPack"
	desc = "Contains blood used for transfusion."
	icon = 'icons/obj/items/bloodpack.dmi'
	icon_state = "bloodpack"
	volume = 200
	reagent_flags = AMOUNT_ESTIMEE
	var/blood_type

/obj/item/reagent_containers/blood/Initialize(mapload)
	. = ..()
	if(blood_type)
		name = "BloodPack [blood_type]"
		reagents.add_reagent(/datum/reagent/blood, 200, list("donor"=null,"blood_DNA"=null,"blood_type"=blood_type))
	update_appearance()

/obj/item/reagent_containers/blood/update_overlays()
	. = ..()
	if(!reagents || !reagents.total_volume || !volume)
		return
	var/percent = (reagents.total_volume / volume) * 100
	var/fill_state
	switch(percent)
		if(0 to 25)
			fill_state = "25"
		if(26 to 50)
			fill_state = "50"
		if(51 to 75)
			fill_state = "75"
		if(76 to INFINITY)
			fill_state = "100"
	if(!fill_state)
		return
	var/has_blood = FALSE
	for(var/datum/reagent/current in reagents.reagent_list)
		if(istype(current, /datum/reagent/blood))
			has_blood = TRUE
			break
	var/state_name
	if(has_blood)
		state_name = "bloodpack-blood[fill_state]"
	else
		state_name = "bloodpack[fill_state]"
	var/mutable_appearance/filling = mutable_appearance(icon, state_name)
	if(!has_blood)
		filling.color = mix_color_from_reagents(reagents.reagent_list)
	. += filling

/obj/item/reagent_containers/blood/APlus
	blood_type = "A+"

/obj/item/reagent_containers/blood/AMinus
	blood_type = "A-"

/obj/item/reagent_containers/blood/BPlus
	blood_type = "B+"

/obj/item/reagent_containers/blood/BMinus
	blood_type = "B-"

/obj/item/reagent_containers/blood/OPlus
	blood_type = "O+"

/obj/item/reagent_containers/blood/OMinus
	blood_type = "O-"

/obj/item/reagent_containers/blood/empty
	name = "Empty BloodPack"
	desc = "Seems pretty useless... Maybe if there were a way to fill it?"
