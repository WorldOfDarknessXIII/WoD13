/mob/living/carbon/human/npc/hobo
	bloodquality = BLOOD_QUALITY_LOW
	old_movement = TRUE

/mob/living/carbon/human/npc/hobo/Initialize(mapload)
	. = ..()

	if (prob(33))
		set_body_weight(SLIM_BODY_WEIGHT)

	var/datum/socialrole/assign_role = pick(/datum/socialrole/poormale, /datum/socialrole/poorfemale)
	AssignSocialRole(assign_role)
