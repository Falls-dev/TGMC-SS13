ADMIN_VERB(player_panel, R_ADMIN, "Player Panel", "View the player panel", ADMIN_CATEGORY_MAIN)
	var/dat = {"
		<script type='text/javascript'>
			var openRow;

			function updateSearch() {
				var filter = document.getElementById('player-filter').value.toLowerCase();
				var rows = document.getElementById('player-rows').rows;
				for (var i = 0; i < rows.length; i++) {
					var search = rows\[i\].getElementsByClassName('filter_data')\[0\];
					rows\[i\].style.display = search.textContent.toLowerCase().indexOf(filter) === -1 ? 'none' : '';
				}
			}

			function showDetails(row) {
				if (row === openRow) {
					return;
				}
				if (openRow && openRow.getAttribute('data-locked') !== 'true') {
					openRow.getElementsByClassName('player-details')\[0\].style.display = 'none';
				}
				row.getElementsByClassName('player-details')\[0\].style.display = '';
				openRow = row;
			}

			function toggleDetails(row) {
				var locked = row.getAttribute('data-locked') === 'true';
				row.setAttribute('data-locked', locked ? 'false' : 'true');
				row.getElementsByClassName('lock-notice')\[0\].style.display = locked ? 'none' : '';
				showDetails(row);
			}
		</script>
		<p align='center'>Hover over a line to see more information. Click to keep it open.</p>
		<p align='center'><label for='player-filter'>Search</label>
			<input type='text' id='player-filter' oninput='updateSearch()' autofocus style='width:300px;'>
		</p>
		<table width='650' align='center' cellspacing='0' cellpadding='5'>
			<tbody id='player-rows'>
	"}
	var/ref = "[REF(user.holder)];[HrefToken()]"
	var/i = 1
	for(var/mob/M in sortmobs())
		if(!M.ckey || !M.client)
			continue

		var/color = "#494949"
		if(i % 2 == 0)
			color = "#595959"

		var/M_job = ""

		if(isliving(M))
			if(iscarbon(M)) //Carbon stuff
				if(ishuman(M))
					var/mob/living/carbon/human/H = M
					if(H.job)
						M_job = H.job.title
				else if(ismonkey(M))
					M_job = "Monkey"
				else if(isxeno(M))
					if(M.client?.prefs?.xeno_name && M.client.prefs.xeno_name != "Undefined")
						M_job = "Xenomorph - [M.client.prefs.xeno_name]"
					else
						M_job = "Xenomorph"
				else
					M_job = "Carbon-based"

			else if(issilicon(M)) //silicon
				if(isAI(M))
					M_job = "AI"
				else
					M_job = "Silicon"

			else if(isanimal(M)) //simple animals
				if(iscorgi(M))
					M_job = "Corgi"
				else
					M_job = "Animal"

			else
				M_job = "Living"

		else if(istype(M,/mob/new_player))
			M_job = "New player"

		else if(isobserver(M))
			M_job = "Ghost"

		M_job = html_encode(M_job)
		var/M_name = html_encode(M.name)
		var/M_rname = html_encode(M.real_name)
		var/M_key = html_encode(M.key)
		var/M_cid = html_encode(M.computer_id)
		var/M_ip = html_encode(M.ip_address)

		var/previous_names = ""
		var/datum/player_details/P = GLOB.player_details[M.ckey]
		if(P)
			previous_names = P.played_names.Join(", ")
		previous_names = html_encode(previous_names)

		dat += {"
			<tr onmouseover='showDetails(this)'>
				<td align='center' bgcolor='[color]'>
					<span class='lock-notice' style='display:none;color:#bc3c3c'>Locked</span>
					<a href='#' onclick='toggleDetails(this.parentNode.parentNode); return false'>
						[M_name] - [M_rname] - [M_key] ([M_job])
					</a>
					<span hidden class='filter_data'>[M_name] [M_rname] [M_key] [M_job] [M_cid] [M_ip] [previous_names]</span>
					<div class='player-details' style='display:none'>
						<table><tr><td align='left'>
							<font size='2'>[M_job] - [M_name]<br>Real name: [M_rname]<br>[M_key] ([M_ip], [M_cid])<br>Old names: [previous_names]</font>
						</td><td align='center'>
							<a href='byond://?src=[ref];playerpanel=[REF(M)]'>PP</a> -
							<a href='byond://?_src_=vars;[HrefToken()];vars=[REF(M)]'>VV</a> -
							<a href='byond://?priv_msg=[M.ckey]'>PM</a> -
							<a href='byond://?src=[ref];subtlemessage=[REF(M)]'>SM</a> -
							<a href='byond://?src=[ref];observejump=[REF(M)]'>JMP</a> -
							<a href='byond://?src=[ref];observefollow=[REF(M)]'>FLW</a> -
							<a href='byond://?src=[ref];individuallog=[REF(M)]'>LOGS</a>
						</td></tr></table>
					</div>
				</td>
			</tr>
		"}
		i++

	dat += "</tbody></table>"

	log_admin("[key_name(usr)] opened the global player panel.")

	var/datum/browser/browser = new(usr, "players", "<div align='center'>Player Panel</div>", 700, 500)
	browser.set_content(dat)
	browser.open()

ADMIN_VERB(player_panel_extended, R_ADMIN, "Player Panel Extended", "View the extended player panel", ADMIN_CATEGORY_MAIN)
	var/ref = "[REF(user.holder)];[HrefToken()]"
	var/dat = "<table border=0 cellspacing=5><B><tr><th>Key</th><th>Name</th><th>Type</th><th>PP</th><th>CID</th><th>IP</th><th>JMP</th><th>FLW</th><th>Notes</th></tr></B>"

	for(var/mob/M in sortmobs())
		if(!M.ckey)
			continue

		dat += "<tr><td>[html_encode(M.key || "No Key")]</td>"
		dat += "<td><a href='byond://?priv_msg=[M.ckey]'>[html_encode(M.name)]</a></td>"
		if(isAI(M))
			dat += "<td>AI</td>"
		else if(ishuman(M))
			dat += "<td>[html_encode(M.real_name)]</td>"
		else if(istype(M, /mob/new_player))
			dat += "<td>New Player</td>"
		else if(isobserver(M))
			dat += "<td>Ghost</td>"
		else if(ismonkey(M))
			dat += "<td>Monkey</td>"
		else if(isxeno(M))
			if(M.client?.prefs?.xeno_name && M.client.prefs.xeno_name != "Undefined")
				dat += "<td>alien - [html_encode(M.client.prefs.xeno_name)]</td>"
			else
				dat += "<td>alien</td>"
		else
			dat += "<td>Unknown</td>"


		dat += {"<td align=center><a href='byond://?src=[ref];playerpanel=[REF(M)]'>PP</a></td>
		<td>[html_encode(M.computer_id)]</td>
		<td>[html_encode(M.ip_address)]</td>
		<td><a href='byond://?src=[ref];observejump=[REF(M)]'>JMP</a></td>
		<td><a href='byond://?src=[ref];observefollow=[REF(M)]'>FLW</a></td>
		<td><a href='byond://?src=[ref];showmessageckey=[M.ckey]'>Notes</a></td>
		"}


	dat += "</table>"

	log_admin("[key_name(user)] opened the extended player panel.")


	var/datum/browser/browser = new(user.mob, "players", "<div align='center'>Player Panel Extended</div>", 800, 600)
	browser.add_head_content(HTML_TEXT_CONTENT_POLICY)
	browser.set_content(dat)
	browser.open()

ADMIN_VERB_ONLY_CONTEXT_MENU(show_player_panel, R_ADMIN, "Show Player Panel", mob/M in world)
	if(!istype(M))
		return

	if(!M.mob_panel)
		M.create_player_panel()
	M.mob_panel.ui_interact(user.mob)
	log_admin("[key_name(user)] opened the player panel of [key_name(M)].")
	return

/// Legacy HTML player panel (kept for reference; TGUI panel is used by show_player_panel).
/proc/show_player_panel_html(mob/M, client/admin_client)
	var/ref = "[REF(admin_client.holder)];[HrefToken()]"
	var/body

	body += "<b>[html_encode(M.name)]</b>"

	if(M.client)
		body += " played by <b>[M.client]</b> "
		body += " <a href='byond://?src=[ref];editrights=[(GLOB.admin_datums[M.client.ckey] || GLOB.deadmins[M.client.ckey]) ? "rank" : "add"];key=[M.key];close=1'>[M.client.holder ? M.client.holder.rank : "Player"]</a>"

	if(isnewplayer(M))
		body += " <b>Hasn't Entered Game</b> "
	else
		body += " | <a href='byond://?src=[ref];revive=[REF(M)]'>Heal</a> | <a href='byond://?src=[ref];sleep=[REF(M)]'>Sleep</a>"

	body += {"
		<br><br>
		<a href='byond://?priv_msg=[M.ckey]'>PM</a> -
		<a href='byond://?src=[ref];subtlemessage=[REF(M)]'>SM</a> -
		<a href='byond://?_src_=vars;[HrefToken()];vars=[REF(M)]'>VV</a> -
		<a href='byond://?src=[ref];spawncookie=[REF(M)]'>SC</a> -
		<a href='byond://?src=[ref];spawnfortunecookie=[REF(M)]'>SFC</a> -
		<a href='byond://?src=[ref];observejump=[REF(M)]'>JMP</a> -
		<a href='byond://?src=[ref];observefollow=[REF(M)]'>FLW</a> -
		<a href='byond://?src=[ref];individuallog=[REF(M)]'>LOGS</a></b><br>
		<b>Mob Type:</b> [M.type]<br>
		<b>Mob Location:</b> [AREACOORD(M.loc)]<br>"}

	if(isliving(M))
		var/mob/living/L = M
		body += "<b>Mob Faction:</b> [L.faction]<br>"
		if(L.job)
			body += "<b>Mob Role:</b> [L.job.title]<br>"

	body += "<b>CID:</b> [M.computer_id] | <b>IP:</b> [M.ip_address]<br>"
	if(M.client)
		body += "<br>\[<b>First Seen:</b> [M.client.player_join_date]\]\[<b>Byond account registered on:</b> [M.client.account_join_date]\]"
		if(M.client.related_accounts_cid || M.client.related_accounts_ip)
			//if(M.client.related_accounts_cid != "Requires database" && M.client.related_accounts_ip != "Requires database")
			body += "<br><b><font color=red>Player has related accounts</font></b> "
		body += "\[ <a href='byond://?_src_=holder;[HrefToken()];showrelatedacc=cid;client=[REF(M.client)]'>CID related accounts</a> | "
		body += "<a href='byond://?_src_=holder;[HrefToken()];showrelatedacc=ip;client=[REF(M.client)]'>IP related accounts</a> \]<br>"

	body += "<b>CentCom Galactic Ban DB: </b> "
	if(CONFIG_GET(string/centcom_ban_db))
		body += "<a href='byond://?_src_=holder;[HrefToken()];centcomlookup=[M?.ckey]'>Search for ([M?.ckey])</a>"
	else
		body += "<i>Disabled</i>"

	body += "<br><br>"
	if(M.client)
		body += "<a href='byond://?src=[ref];playtime=[REF(M)]'>Playtime</a> | "
		body += "<a href='byond://?src=[ref];kick=[REF(M)]'>Kick</a> | "
		body += "<a href='byond://?src=[ref];newbankey=[M.key];newbanip=[M.client.address];newbancid=[M.client.computer_id]'>Ban</a> | "
	else
		body += "<a href='byond://?src=[ref];newbankey=[M.key]'>Ban</a> | "

	body += "<a href='byond://?src=[ref];showmessageckey=[M.ckey]'>Notes</a> | "
	body += "<a href='byond://?src=[ref];cryo=[REF(M)]'>Cryo</a>"

	if(M.client)
		body += "| <a href='byond://?src=[ref];lobby=[REF(M)]'> Send back to Lobby</a>"

	body += "<br>"

	if(M.client?.prefs)
		var/muted = M.client.prefs.muted
		body += {"<br><b>Mute: </b>
			<a href='byond://?src=[ref];mute=[REF(M)];mute_type=[MUTE_IC]'><font color='[(muted & MUTE_IC) ? "#ff5e5e" : "white"]'>IC</font></a> |
			<a href='byond://?src=[ref];mute=[REF(M)];mute_type=[MUTE_OOC]'><font color='[(muted & MUTE_OOC) ? "#ff5e5e" : "white"]'>OOC</font></a> |
			<a href='byond://?src=[ref];mute=[REF(M)];mute_type=[MUTE_LOOC]'><font color='[(muted & MUTE_LOOC) ? "#ff5e5e" : "white"]'>LOOC</font></a> |
			<a href='byond://?src=[ref];mute=[REF(M)];mute_type=[MUTE_PRAY]'><font color='[(muted & MUTE_PRAY) ? "#ff5e5e" : "white"]'>PRAY</font></a> |
			<a href='byond://?src=[ref];mute=[REF(M)];mute_type=[MUTE_ADMINHELP]'><font color='[(muted & MUTE_ADMINHELP) ? "#ff5e5e" : "white"]'>ADMINHELP</font></a> |
			<a href='byond://?src=[ref];mute=[REF(M)];mute_type=[MUTE_DEADCHAT]'><font color='[(muted & MUTE_DEADCHAT) ? "#ff5e5e" : "white"]'>DEADCHAT</font></a> |
			(<a href='byond://?src=[ref];mute=[REF(M)];mute_type=[MUTE_ALL]'><font color='[(muted & MUTE_ALL) ? "#ff5e5e" : "white"]'>ALL</font></a>)
		"}

	body += {"
		<br><br>
		<a href='byond://?src=[ref];jumpto=[REF(M)]'>Jump To</a> |
		<a href='byond://?src=[ref];getmob=[REF(M)]'>Get Mob</a> |
		<a href='byond://?src=[ref];sendmob=[REF(M)]'>Send Mob</a>
		<br>
	"}

	body += {"<br>
		<b>Transformation:</b>
		<br> Special:
		<a href='byond://?src=[ref];transform=observer;mob=[REF(M)]'>Observer</a> |
		<a href='byond://?src=[ref];transform=ai;mob=[REF(M)]'>AI</a> |
		<a href='byond://?src=[ref];transform=sectoid;mob=[REF(M)]'>Sectoid</a> |
		<a href='byond://?src=[ref];transform=SKELETON;mob=[REF(M)]'>SKELETON</a> |
		<a href='byond://?src=[ref];transform=yautja;mob=[REF(M)]'>Yautja</a>
		<br> Humanoid:
		<a href='byond://?src=[ref];transform=human;mob=[REF(M)]'>Human</a> |
		<a href='byond://?src=[ref];transform=synthetic;mob=[REF(M)]'>Synthetic</a> |
		<a href='byond://?src=[ref];transform=engineer_synth;mob=[REF(M)]'>Engineer_Synth</a> |
		<a href='byond://?src=[ref];transform=medical_synth;mob=[REF(M)]'>Medical_Synth</a> |
		<a href='byond://?src=[ref];transform=vatborn;mob=[REF(M)]'>Vatborn</a> |
		<a href='byond://?src=[ref];transform=vatgrown;mob=[REF(M)]'>Vatgrown</a> |
		<a href='byond://?src=[ref];transform=prototype_supersoldier;mob=[REF(M)]'>Prototype Supersoldier</a> |
		<a href='byond://?src=[ref];transform=combat_robot;mob=[REF(M)]'>Combat_Robot</a> |
		<a href='byond://?src=[ref];transform=monkey;mob=[REF(M)]'>Monkey</a> |
		<a href='byond://?src=[ref];transform=moth;mob=[REF(M)]'>Moth</a> |
		<a href='byond://?src=[ref];transform=zombie;mob=[REF(M)]'>Zombie</a> |
		<a href='byond://?src=[ref];transform=hellhound;mob=[REF(M)]'>Hellhound</a>
		<br> Alien Tier 0:
		<a href='byond://?src=[ref];transform=larva;mob=[REF(M)]'>Larva</a> |
		<a href='byond://?src=[ref];transform=predalien_larva;mob=[REF(M)]'>Predalien Larva</a> |
		<a href='byond://?src=[ref];transform=facehugger;mob=[REF(M)]'>Facehugger</a>
		<br> Alien Tier 1:
		<a href='byond://?src=[ref];transform=runner;mob=[REF(M)]'>Runner</a> |
		<a href='byond://?src=[ref];transform=drone;mob=[REF(M)]'>Drone</a> |
		<a href='byond://?src=[ref];transform=sentinel;mob=[REF(M)]'>Sentinel</a> |
		<a href='byond://?src=[ref];transform=defender;mob=[REF(M)]'>Defender</a>
		<br> Alien Tier 2:
		<a href='byond://?src=[ref];transform=hunter;mob=[REF(M)]'>Hunter</a> |
		<a href='byond://?src=[ref];transform=panther;mob=[REF(M)]'>Panther</a> |
		<a href='byond://?src=[ref];transform=bull;mob=[REF(M)]'>Bull</a> |
		<a href='byond://?src=[ref];transform=warrior;mob=[REF(M)]'>Warrior</a> |
		<a href='byond://?src=[ref];transform=spitter;mob=[REF(M)]'>Spitter</a> |
		<a href='byond://?src=[ref];transform=hivelord;mob=[REF(M)]'>Hivelord</a> |
		<a href='byond://?src=[ref];transform=carrier;mob=[REF(M)]'>Carrier</a>
		<br> Alien Tier 3:
		<a href='byond://?src=[ref];transform=ravager;mob=[REF(M)]'>Ravager</a> |
		<a href='byond://?src=[ref];transform=praetorian;mob=[REF(M)]'>Praetorian</a> |
		<a href='byond://?src=[ref];transform=boiler;mob=[REF(M)]'>Boiler</a> |
		<a href='byond://?src=[ref];transform=defiler;mob=[REF(M)]'>Defiler</a> |
		<a href='byond://?src=[ref];transform=crusher;mob=[REF(M)]'>Crusher</a> |
		<a href='byond://?src=[ref];transform=gorger;mob=[REF(M)]'>Gorger</a> |
		<a href='byond://?src=[ref];transform=warlock;mob=[REF(M)]'>Warlock</a> |
		<a href='byond://?src=[ref];transform=widow;mob=[REF(M)]'>Widow</a> |
		<a href='byond://?src=[ref];transform=behemoth;mob=[REF(M)]'>Behemoth</a> |
		<a href='byond://?src=[ref];transform=chimera;mob=[REF(M)]'>Chimera</a>
		<br> Alien Tier 4:
		<a href='byond://?src=[ref];transform=queen;mob=[REF(M)]'>Queen</a> |
		<a href='byond://?src=[ref];transform=shrike;mob=[REF(M)]'>Shrike</a> |
		<a href='byond://?src=[ref];transform=hivemind;mob=[REF(M)]'>Hivemind</a> |
		<a href='byond://?src=[ref];transform=king;mob=[REF(M)]'>King</a> |
		<a href='byond://?src=[ref];transform=predalien;mob=[REF(M)]'>Predalien</a>
		<br>
	"}

	if(!isnewplayer(M))
		body += "<br><br>"
		body += "<b>Other actions:</b>"
		body += "<br>"
		body += "<a href='byond://?src=[ref];thunderdome=[REF(M)]'>Thunderdome</a> | "
		body += "<a href='byond://?src=[ref];gib=[REF(M)]'>Gib</a>"

		if(isliving(M))
			body += "<br>"
			body += "<a href='byond://?src=[ref];checkcontents=[REF(M)]'>Check Contents</a> | "
			body += "<a href='byond://?src=[ref];offer=[REF(M)]'>Offer Mob</a> | "
			body += "<a href='byond://?src=[ref];give=[REF(M)]'>Give Mob</a>"

			if(ishuman(M))
				body += "<br>"
				body += "<a href='byond://?src=[ref];rankequip=[REF(M)]'>Rank and Equipment</a> | "
				body += "<a href='byond://?src=[ref];editappearance=[REF(M)]'>Edit Appearance</a> | "
				body += "<a href='byond://?src=[ref];randomname=[REF(M)]'>Randomize Name</a>"

	log_admin("[key_name(admin_client)] opened the legacy HTML player panel of [key_name(M)].")

	var/datum/browser/browser = new(admin_client.mob, "player_panel_[REF(M)]", "<div align='center'>Player Panel [html_encode(key_name(M))]</div>", 575, 555)
	browser.add_head_content(HTML_TEXT_CONTENT_POLICY)
	browser.set_content(body)
	browser.open()
