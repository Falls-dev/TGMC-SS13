//#define LOWMEMORYMODE //uncomment this to load centcom and runtime station and thats it.

#include "map_files\generic\Admin_Level.dmm"

#ifndef LOWMEMORYMODE
	#ifdef ALL_MAPS
		#include "map_files\BigRed_v2\BigRed_v2.dmm"
		#include "map_files\Ice_Colony_v2\Ice_Colony_v2.dmm"
		#include "map_files\LV624\LV624.dmm"
		#include "map_files\Prison_Station_FOP\Prison_Station_FOP.dmm"
		#include "map_files\Vapor_Processing\Vapor_Processing.dmm"
		#include "map_files\icy_caves\icy_caves.dmm"
		#include "map_files\Research_Outpost\Research_Outpost.dmm"
		#include "map_files\Barrenquilla_Mining\Barrenquilla_Mining_Facility.dmm"
		#include "map_files\Magmoor_Digsite_IV\Magmoor_Digsite_IV.dmm"
		#include "map_files\kutjevo\kutjevo.dmm"
		#include "map_files\Orion_Military_Outpost\orionoutpost.dmm"
		#include "map_files\gelida_iv\gelida_iv.dmm"
		#include "map_files\deltastation\deltastation.dmm"
		#include "map_files\desparity\desparity.dmm"
		#include "map_files\Lawanka_Outpost\LawankaOutpost.dmm"
		#include "map_files\slumbridge\slumbridge.dmm"
		#include "map_files\Talos\TGS_Talos.dmm"
		#ifdef CIBUILDING
			#include "templates.dm"
		#endif
	#endif
#endif

#ifdef CAMPAIGN_MAP_AUDIT
#include "campaign_missions\modularmaps\jungle_outpost\joutpostwtower1.dmm"
#include "campaign_missions\modularmaps\jungle_outpost\joutpostwtower2.dmm"
#include "campaign_missions\modularmaps\jungle_outpost\joutpostwtower3.dmm"
#include "campaign_missions\modularmaps\jungle_outpost\joutpostwtower4.dmm"
#include "campaign_missions\modularmaps\jungle_outpost\joutpostscrates1.dmm"
#include "campaign_missions\modularmaps\jungle_outpost\joutpostscrates2.dmm"
#include "campaign_missions\modularmaps\jungle_outpost\joutpostscrates3.dmm"
#include "campaign_missions\modularmaps\jungle_outpost\joutpostscrates4.dmm"
#include "campaign_missions\modularmaps\jungle_outpost\joutposthydro1.dmm"
#include "campaign_missions\modularmaps\jungle_outpost\joutposthydro2.dmm"
#include "campaign_missions\modularmaps\jungle_outpost\joutposthydro3.dmm"
#include "campaign_missions\modularmaps\jungle_outpost\joutpostmedbay1.dmm"
#include "campaign_missions\modularmaps\jungle_outpost\joutpostmedbay2.dmm"
#include "campaign_missions\modularmaps\jungle_outpost\joutpostmedbay3.dmm"
#include "campaign_missions\modularmaps\jungle_outpost\joutpostengi1.dmm"
#include "campaign_missions\modularmaps\jungle_outpost\joutpostengi2.dmm"
#include "campaign_missions\modularmaps\jungle_outpost\joutpostengi3.dmm"
#include "campaign_missions\map_files\BigRed_v2\BigRed_v2.dmm"
#include "campaign_missions\map_files\Campaign maps\jungle_outpost\jungle_outpost.dmm"
#include "campaign_missions\map_files\Campaign maps\nt_base\nt_base.dmm"
#include "campaign_missions\map_files\Campaign maps\orion_2\orionoutpost_2.dmm"
#include "campaign_missions\map_files\Campaign maps\patricks_rest\patricks_rest.dmm"
#include "campaign_missions\map_files\Campaign maps\som_base\sombase.dmm"
#include "campaign_missions\map_files\Campaign maps\som_raid_base\som_raiding_base.dmm"
#include "campaign_missions\map_files\Campaign maps\tgmc_airfield\tgmc_airfield.dmm"
#include "campaign_missions\map_files\Campaign maps\tgmc_raid_base\tgmc_raiding_base.dmm"
#include "campaign_missions\map_files\desparity\desparity.dmm"
#include "campaign_missions\map_files\Fort_Phobos\Fort_Phobos.dmm"
#include "campaign_missions\map_files\icy_caves\icy_caves.dmm"
#include "campaign_missions\map_files\Iteron\Iteron.dmm"
#include "campaign_missions\map_files\Lawanka_Outpost\LawankaOutpost.dmm"
#include "campaign_missions\map_files\Orion_Military_Outpost\orionoutpost.dmm"
#endif

#ifdef CAMPAIGN_MAP_AUDIT
#include "templates\capsule_1.dmm"
#endif
