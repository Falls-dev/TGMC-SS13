// RU TGMC EDIT ADDITION BEGIN (mutations_revamp)

// ===== SIGNALS =====
#define COMSIG_XENOMORPH_SUNDER_CHANGE "xenomorph_sunder_change" // (old, new)

// ===== HUD =====
#define ENHANCEMENT_HUD "xeno_enhancement_hud" // indicates if xeno has any enhancement mutation
#define ui_alienbiomassdisplay "EAST-1:45,10:13"

// ===== MOVESPEED =====
#define MOVESPEED_ID_ENHANCED_CELERITY_BUFF "UPGRADE_CHAMBER_ENHANCED_CELERITY_BUFF"

// ===== CARAPACE MUTATIONS =====
#define STATUS_EFFECT_CARAPACE /datum/status_effect/carapace
#define STATUS_EFFECT_CARAPACE_TWO /datum/status_effect/carapace/tier2
#define STATUS_EFFECT_CARAPACE_THREE /datum/status_effect/carapace/tier3

// ===== REGENERATION MUTATIONS =====
#define STATUS_EFFECT_REGENERATION /datum/status_effect/regeneration
#define STATUS_EFFECT_REGENERATION_TWO /datum/status_effect/regeneration/tier2

// ===== VAMPIRISM MUTATIONS =====
#define STATUS_EFFECT_VAMPIRISM /datum/status_effect/vampirism
#define STATUS_EFFECT_VAMPIRISM_TWO /datum/status_effect/vampirism/tier2

// ===== CELERITY MUTATION =====
#define STATUS_EFFECT_CELERITY /datum/status_effect/celerity

// ===== IONIZE MUTATIONS =====
#define STATUS_EFFECT_IONIZE /datum/status_effect/ionize
#define STATUS_EFFECT_IONIZE_TWO /datum/status_effect/ionize/tier2

// ===== CRUSH MUTATION =====
#define STATUS_EFFECT_CRUSH /datum/status_effect/crush

// ===== GUN SKILL STATUS EFFECTS (existing, just ensuring they're available) =====
#define STATUS_EFFECT_GUN_SKILL_ACCURACY_BUFF /datum/status_effect/stacking/gun_skill/accuracy/buff
#define STATUS_EFFECT_GUN_SKILL_SCATTER_BUFF /datum/status_effect/stacking/gun_skill/scatter/buff

// ===== XENO STATUS EFFECTS =====
#define STATUS_EFFECT_XENO_ESSENCE_LINK /datum/status_effect/stacking/essence_link
#define STATUS_EFFECT_XENO_ESSENCE_LINK_REVENGE /datum/status_effect/essence_link_revenge
#define STATUS_EFFECT_XENO_SALVE_REGEN /datum/status_effect/salve_regen
#define STATUS_EFFECT_XENO_ENHANCEMENT /datum/status_effect/drone_enhancement
#define STATUS_EFFECT_XENO_REJUVENATE /datum/status_effect/xeno_rejuvenate

// ===== TRAITS =====
#define MUTATION_TRAIT "mutation_trait"

// ===== HEAL MACRO =====
/// Heals a xeno, respecting different types of damage
#define HEAL_XENO_DAMAGE(xeno, amount, passive) do { \
	var/fire_loss = xeno.get_fire_loss(); \
	if(fire_loss) { \
		var/fire_heal = min(fire_loss, amount); \
		amount -= fire_heal;\
		xeno.adjust_fire_loss(-fire_heal, TRUE, passive); \
	} \
	var/brute_loss = xeno.get_brute_loss(); \
	if(brute_loss) { \
		var/brute_heal = min(brute_loss, amount); \
		amount -= brute_heal; \
		xeno.adjust_brute_loss(-brute_heal, TRUE, passive); \
	} \
} while(FALSE)

// RU TGMC EDIT ADDITION END
