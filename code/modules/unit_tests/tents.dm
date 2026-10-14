/// Load every portable tent and exercise its footprint and lifetime links.
/datum/unit_test/tents/Run()
	for(var/tent_type in subtypesof(/obj/item/folded_tent))
		var/obj/item/folded_tent/folded = allocate(tent_type)
		var/turf/origin = run_loc_floor_bottom_left
		TEST_ASSERT(folded.template, "[tent_type] has no template")
		TEST_ASSERT(folded.check_area(origin), "Empty floor should permit [tent_type]")
		var/list/footprint = folded.get_deployment_area(origin)
		TEST_ASSERT_EQUAL(length(footprint), folded.dim_x * folded.dim_y, "Wrong deployment footprint")
		var/turf/obstructed = footprint[length(footprint)]
		var/obj/structure/barricade/obstruction = allocate(/obj/structure/barricade, obstructed)
		TEST_ASSERT(!folded.check_area(origin), "Obstacle at the far corner should block deployment")
		qdel(obstruction)
		TEST_ASSERT(folded.unfold(null, origin), "[tent_type] failed to load")
		var/obj/structure/tent/deployed = locate(/obj/structure/tent) in origin
		TEST_ASSERT(deployed, "[tent_type] did not create its tent")
		TEST_ASSERT_EQUAL(length(deployed.locs), length(footprint), "Tent bounds do not match its template")
		TEST_ASSERT(!folded.check_area(origin), "A tent must block overlapping deployment")
		var/list/linked_objects = list()
		for(var/turf/tile as anything in footprint)
			TEST_ASSERT(isfloorturf(tile), "Template replaced the underlying floor")
			TEST_ASSERT(deployed in tile, "Multitile tent absent from [tile]")
			for(var/obj/structure/blocker/tent/wall in tile)
				TEST_ASSERT_EQUAL(wall.linked_tent, deployed, "Wall is not linked to its tent")
				TEST_ASSERT(!wall.projectile_hit(null), "Tent walls must allow bullets through")
				linked_objects |= wall
			for(var/atom/movable/equipment in tile)
				var/datum/component/tent_supported_object/support = equipment.GetComponent(/datum/component/tent_supported_object)
				if(!support)
					continue
				TEST_ASSERT_EQUAL(support.linked_tent, deployed, "Equipment is not linked to its tent")
				linked_objects |= equipment
				if(ismachinery(equipment))
					var/obj/machinery/machine = equipment
					TEST_ASSERT(machine.powered(), "Tent equipment needs external power")
		var/obj/effect/tent_roof/roof = deployed.roof
		qdel(deployed)
		TEST_ASSERT(QDELETED(roof), "Roof remained after tent destruction")
		for(var/datum/linked as anything in linked_objects)
			TEST_ASSERT(QDELETED(linked), "[linked.type] remained after tent destruction")
		for(var/turf/tile as anything in footprint)
			for(var/obj/object in tile)
				qdel(object)
