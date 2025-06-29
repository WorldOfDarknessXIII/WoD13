/mob/living/carbon/human/proc/AdjustMasquerade(value, forced)
	if (!iskindred(src) && !isghoul(src) && !iscathayan(src))
		return
	var/datum/species/human/kindred/vampirism = dna.species

	if (!forced)
		if (value > 0)
			if (HAS_TRAIT(src, TRAIT_VIOLATOR))
				return
		if (istype(get_area(src), /area/vtm))
			var/area/vtm/current_area = get_area(src)
			if (current_area.zone_type != ZONE_MASQUERADE)
				return
		if (!COOLDOWN_FINISHED(src, masquerade_violation_cooldown))
			return

	COOLDOWN_START(src, masquerade_violation_cooldown, 10 SECONDS)

	if (value < 0)
		if (masquerade <= 0)
			return

		SEND_SOUND(src, sound('sound/wod13/masquerade_violation.ogg', 0, 0, 75))
		to_chat(src, span_userdanger("<b>MASQUERADE VIOLATION!</b>"))
	else if (value > 0)
		if (vampirism.enlightenment)
			AdjustHumanity(1, 10)

		for (var/mob/living/carbon/human/H in GLOB.player_list)
			H.voted_for -= dna.real_name

		if (masquerade >= 5)
			return

		SEND_SOUND(src, sound('sound/wod13/general_good.ogg', 0, 0, 75))
		to_chat(src, span_boldnicegreen("<b>MASQUERADE REINFORCED!</b>"))

	masquerade = clamp(masquerade + value, 0, 5)

	if (src in GLOB.masquerade_breakers_list)
		if (masquerade > 2)
			GLOB.masquerade_breakers_list -= src
	else if (masquerade < 3)
		GLOB.masquerade_breakers_list |= src

// TODO: [Lucia] reimplement NPCs
/*
/**
 * Finds if an NPC is facing an atom
 *
 * Arguments:
 * * A - what's being checked for if the NPC is facing it
 */
/mob/living/carbon/human/npc/proc/backinvisible(atom/A)
	switch(dir)
		if(NORTH)
			if(A.y >= y)
				return TRUE
		if(SOUTH)
			if(A.y <= y)
				return TRUE
		if(EAST)
			if(A.x >= x)
				return TRUE
		if(WEST)
			if(A.x <= x)
				return TRUE
	return FALSE

/mob/living/proc/CheckEyewitness(mob/living/source, mob/attacker, range = 0, affects_source = FALSE)
	if (source.ignores_warrant)
		return

	// Visible range is multiplied by percentage of the attacker's visibility
	var/actual_range = max(1, round(range * (attacker.alpha / 255)))

	// Will be TRUE if an NPC witnesses this
	. = FALSE

	// NPCs within 1 tile aggro if facing the source
	for (var/mob/living/carbon/human/npc/NPC in oviewers(1, source))
		if (!NPC.CheckMove())
			continue
		if(get_turf(src) == turn(NPC.dir, 180))
			continue
		NPC.Aggro(attacker, FALSE)
		. = TRUE

	// NPCs within effective range aggro if facing the source and the aggravator isn't in darkness
	for (var/mob/living/carbon/human/npc/NPC in viewers(actual_range, source))
		if (!NPC.CheckMove())
			continue

		if (affects_source && (NPC == source))
			NPC.Aggro(attacker, TRUE)
			. = TRUE

		if (NPC.pulledby)
			continue

		var/turf/attacker_turf = get_turf(attacker)
		if ((attacker_turf.get_lumcount() <= 0.25) && (get_dist(NPC, attacker) > 1))
			continue
		if (!NPC.backinvisible(attacker))
			continue
		NPC.Aggro(attacker, FALSE)
		. = TRUE

// TODO: [Lucia] reimplement respawn timers
/mob/proc/can_respawn()
	if (client?.ckey)
		if (GLOB.respawn_timers[client.ckey])
			if ((GLOB.respawn_timers[client.ckey] + 10 MINUTES) > world.time)
				return FALSE
	return TRUE

/**
 * Rolls a number of dice according to Storyteller system rules to find
 * success or number of successes.
 *
 * Rolls a number of 10-sided dice, counting them as a "success" if
 * they land on a number equal to or greater than the difficulty. Dice
 * that land on 1 subtract a success from the total, and the minimum
 * difficulty is 2. The number of successes is returned if numerical
 * is true, or the roll outcome (botch, failure, success) as a defined
 * number if false.
 *
 * Arguments:
 * * dice - number of 10-sided dice to roll.
 * * difficulty - the number that a dice must come up as to count as a success.
 * * numerical - whether the proc returns number of successes or outcome (botch, failure, success)
 */
/proc/storyteller_roll(dice = 1, difficulty = 6, numerical = FALSE)
	var/successes = 0
	var/had_one = FALSE
	var/had_success = FALSE

	if (dice < 1)
		if (numerical)
			return 0
		else
			return ROLL_FAILURE

	for (var/i in 1 to dice)
		var/roll = rand(1, 10)

		if (roll == 1)
			successes--
			if (!had_one)
				had_one = TRUE
			continue

		if (roll >= difficulty)
			successes++
			if (!had_success)
				had_success = TRUE

	if (numerical)
		return successes
	else
		if (!had_success && had_one)
			return ROLL_BOTCH
		else if (successes <= 0)
			return ROLL_FAILURE
		else
			return ROLL_SUCCESS

/proc/vampireroll(dices_num = 1, hardness = 1, atom/rollviewer)
	var/wins = 0
	var/crits = 0
	var/brokes = 0
	for(var/i in 1 to dices_num)
		var/roll = rand(1, 10)
		if(roll == 10)
			crits += 1
		if(roll == 1)
			brokes += 1
		else if(roll >= hardness)
			wins += 1
	if(crits > brokes)
		if(rollviewer)
			to_chat(rollviewer, "<b>Critical <span class='nicegreen'>hit</span>!</b>")
			return DICE_CRIT_WIN
	if(crits < brokes)
		if(rollviewer)
			to_chat(rollviewer, "<b>Critical <span class='danger'>failure</span>!</b>")
			return DICE_CRIT_FAILURE
	if(crits == brokes && !wins)
		if(rollviewer)
			to_chat(rollviewer, "<span class='danger'>Failed</span>")
			return DICE_FAILURE
	if(wins)
		switch(wins)
			if(1)
				to_chat(rollviewer, "<span class='tinynotice'>Maybe</span>")
				return DICE_WIN
			if(2)
				to_chat(rollviewer, "<span class='smallnotice'>Okay</span>")
				return DICE_WIN
			if(3)
				to_chat(rollviewer, "<span class='notice'>Good</span>")
				return DICE_WIN
			if(4)
				to_chat(rollviewer, "<span class='notice'>Lucky</span>")
				return DICE_WIN
			else
				to_chat(rollviewer, "<span class='boldnotice'>Phenomenal</span>")
				return DICE_WIN
*/

/proc/get_vamp_skin_color(value = "albino")
	switch(value)
		if("caucasian1")
			return "vamp1"
		if("caucasian2")
			return "vamp2"
		if("caucasian3")
			return "vamp3"
		if("latino")
			return "vamp4"
		if("mediterranean")
			return "vamp5"
		if("asian1")
			return "vamp6"
		if("asian2")
			return "vamp7"
		if("arab")
			return "vamp8"
		if("indian")
			return "vamp9"
		if("african1")
			return "vamp10"
		if("african2")
			return "vamp11"
		else
			return value
