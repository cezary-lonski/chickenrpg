class_name ServerCmds
extends RefCounted
## Komendy czatu (/…) i konsoli serwera. Nadawca 0 = konsola serwera (prawa admina).

const PLAYER_HELP := "Komendy: /help /list /w <gracz> <tekst> /me <tekst> /pos /stats /skills /skill <slot 1-9> <id|-> /attr <statystyka> [ile] /swiat /kampania /quest /wyzwanie /arena <gracz> /wyjdz /ranking /wlasne (edytor fal: klawisz B)"
const ADMIN_HELP := "Admin: /tp /tphere /give /heal /god /creative /survival /kill /kick /ban /unban /spawn /killall /xp /setlevel /gold /say /op /deop /class /items /save /backup /stop /rozdzial <nr> /kia <ally N|pet> /boss [id] /bosses /event raid"
const ADMIN_CMDS := ["update", "tp", "tphere", "give", "heal", "god", "creative", "survival", "kill", "kick", "ban", "unban", "spawn", "killall", "xp", "setlevel", "gold",
		"say", "op", "deop", "class", "items", "save", "backup", "stop", "rozdzial", "kia", "boss", "bosses", "event", "wedrowiec"]

## Opisy komend do podpowiedzi w czacie (klient pokazuje je po wpisaniu "/", Tab uzupełnia).
const INFO := {
	"help": "/help — lista komend",
	"list": "/list — gracze online",
	"w": "/w <gracz> <tekst> — prywatna wiadomość",
	"msg": "/msg <gracz> <tekst> — prywatna wiadomość (jak /w)",
	"tell": "/tell <gracz> <tekst> — prywatna wiadomość (jak /w)",
	"me": "/me <tekst> — akcja w czacie",
	"pos": "/pos — Twoja pozycja i strefa",
	"stats": "/stats — Twoje statystyki",
	"skills": "/skills — sloty i znane umiejętności",
	"skill": "/skill <slot 1-9> <id|-> — przypisz umiejętność",
	"attr": "/attr <statystyka> [ile] — rozdaj punkty atrybutów",
	"swiat": "/swiat — idź na Pustkowie",
	"kampania": "/kampania — wróć do kampanii",
	"quest": "/quest — aktualny rozdział i cel",
	"wyzwanie": "/wyzwanie — tryb wyzwań (rycerze w rundach)",
	"arena": "/arena <gracz> — zaproś gracza na pojedynek PvP",
	"wyjdz": "/wyjdz — przerwij wyzwanie, arenę lub własne fale",
	"ranking": "/ranking — ranking wyzwań i areny",
	"wlasne": "/wlasne — uruchom własne fale (edytor: klawisz B)",
	"mapa": "/mapa — mapa świata Aktu II",
	"tp": "/tp <gracz> | <x> <y> (~ = obecna pozycja) | <gracz> <cel> — teleport [admin]",
	"tphere": "/tphere <gracz> — przenieś gracza do siebie [admin]",
	"give": "/give <gracz> <przedmiot|all> [ile] — daj przedmiot [admin]",
	"heal": "/heal [gracz] — ulecz [admin]",
	"god": "/god [gracz] — nieśmiertelność [admin]",
	"creative": "/creative [gracz] — tryb creative: niezniszczalność [admin]",
	"survival": "/survival [gracz] — tryb survival: normalnie zniszczalny [admin]",
	"kill": "/kill <gracz> — zabij gracza [admin]",
	"kick": "/kick <gracz> [powód] — wyrzuć z serwera [admin]",
	"ban": "/ban <postać> [powód] — zbanuj [admin]",
	"unban": "/unban <postać> — odbanuj [admin]",
	"spawn": "/spawn <gatunek> [ile] — przywołaj potwory [admin]",
	"killall": "/killall — zabij wszystkich wrogów w strefie [admin]",
	"xp": "/xp <gracz> <liczba> — dodaj XP [admin]",
	"setlevel": "/setlevel <gracz> <poziom> — ustaw poziom [admin]",
	"gold": "/gold <gracz> <liczba> — dodaj złoto [admin]",
	"say": "/say <tekst> — komunikat serwera [admin]",
	"op": "/op <postać> — nadaj admina [admin]",
	"deop": "/deop <postać> — odbierz admina [admin]",
	"class": "/class <gracz> <klasa> — zmień klasę [admin]",
	"items": "/items [fraza] — lista przedmiotów [admin]",
	"save": "/save — zapisz postacie [admin]",
	"backup": "/backup — kopia zapasowa danych serwera [admin]",
	"stop": "/stop — zatrzymaj serwer [admin]",
	"update": "/update — sprawdź i zainstaluj aktualizację serwera (restart) [admin]",
	"version": "/version — wersja serwera i dostępna aktualizacja",
	"rozdzial": "/rozdzial <nr> — skocz do rozdziału [admin]",
	"kia": "/kia <ally N|pet> — zabij towarzysza [admin]",
	"boss": "/boss [id] — przywołaj bossa [admin]",
	"bosses": "/bosses — lista bossów [admin]",
	"event": "/event raid|duel — wymuś wydarzenie [admin]",
	"wedrowiec": "/wedrowiec [id] — przywołaj wędrownego podróżnika obok siebie (Pustkowie) [admin]",
}

## Rodzaje argumentów komend (podpowiedzi jak w Minecrafcie): player = nick online, item = przedmiot z gry itd.
const ARGS := {
	"give": ["player", "item", "num"], "tp": ["player", "player"], "tphere": ["player"], "heal": ["player"], "god": ["player"], "creative": ["player"], "survival": ["player"],
	"kill": ["player"], "kick": ["player"], "ban": ["player"], "w": ["player"], "msg": ["player"], "tell": ["player"], "arena": ["player"], "op": ["player"], "deop": ["player"],
	"xp": ["player", "num"], "gold": ["player", "num"], "setlevel": ["player", "num"], "class": ["player", "class"],
	"spawn": ["species", "num"], "boss": ["boss"], "items": ["item"], "rozdzial": ["chapter"], "skill": ["slot", "skill"], "attr": ["attr", "num"], "event": ["ev"], "kia": ["kia"],
}

static func _commands_for(is_admin: bool) -> Array:
	var names: Array = []
	for n in INFO.keys():
		if is_admin or String(n) not in ADMIN_CMDS:
			names.append(String(n))
	names.sort()
	return names

## Kandydaci dla rodzaju argumentu: [[wartość, opis], …] pasujące do wpisanego początku.
static func _candidates(kind: String, partial: String, ctx: Dictionary) -> Array:
	var pl := partial.to_lower()
	var out: Array = []
	match kind:
		"player":
			for s in [["@s", "Ty"], ["@p", "najbliższy gracz"], ["@r", "losowy gracz"], ["@a", "wszyscy gracze"]]:
				if String(s[0]).begins_with(pl):
					out.append(s)
			for n in ctx.get("players", []):
				if String(n).to_lower().begins_with(pl):
					out.append([String(n), "gracz"])
		"item":
			if "all".begins_with(pl):
				out.append(["all", "wszystkie przedmioty (do 40 miejsc)"])
			var ids: Array = ItemDB.LIST.keys()
			ids.sort()
			for id in ids:
				var nm := String(ItemDB.LIST[id].get("name", id))
				if String(id).begins_with(pl) or nm.to_lower().contains(pl):
					out.append([String(id), nm])
		"species":
			var sp: Array = EnemyDB.LIST.keys()
			sp.sort()
			for id in sp:
				if not bool(EnemyDB.LIST[id].get("boss", false)) and String(id).begins_with(pl):
					out.append([String(id), String(EnemyDB.LIST[id].get("name", id))])
		"boss":
			for id in BossDB.BASE_LIST:
				if String(id).begins_with(pl):
					out.append([String(id), String(BossDB.BASE_LIST[id].get("name", id))])
		"class":
			for id in ClassDatabase.all():
				if String(id).begins_with(pl):
					out.append([String(id), String(ClassDatabase.get_data(id).get("title", id))])
		"skill":
			var sk: Array = ctx.get("skills", SkillDB.all())
			for id in sk:
				if String(id).begins_with(pl) or String(SkillDB.get_data(String(id)).get("name", "")).to_lower().contains(pl):
					out.append([String(id), String(SkillDB.get_data(String(id)).get("name", id))])
			if "-".begins_with(pl):
				out.append(["-", "pusty slot"])
		"slot":
			for i in range(1, 10):
				if str(i).begins_with(pl):
					out.append([str(i), "slot %d" % i])
		"attr":
			for k in GameState.ATTR_ORDER:
				if String(k).begins_with(pl):
					out.append([String(k), String(GameState.ATTRS.get(k, {}).get("name", k))])
		"chapter":
			for i in QuestDB.count():
				var cid := String(QuestDB.chapter(i).get("id", ""))
				if ZoneDB.has(cid) and str(i + 1).begins_with(partial):
					out.append([str(i + 1), "%s — %s" % [String(QuestDB.chapter(i).get("label", "")), String(QuestDB.chapter(i).get("title", ""))]])
		"ev":
			for k in ["raid", "duel"]:
				if k.begins_with(pl):
					out.append([k, "wydarzenie"])
		"kia":
			for k in ["ally", "pet"]:
				if k.begins_with(pl):
					out.append([k, "towarzysz"])
	return out

## Podpowiedzi dla wpisanego tekstu. Zwraca {"usage": składnia komendy, "options": [[wartość, opis]], "start": indeks początku
## uzupełnianego słowa}. Komendy: po "/" lista; argumenty: nicki, przedmioty, potwory… zależnie od komendy.
static func hints(typed: String, is_admin: bool, ctx: Dictionary = {}) -> Dictionary:
	var empty := {"usage": "", "options": [], "start": 0}
	if not typed.begins_with("/"):
		return empty
	var body := typed.substr(1)
	var parts := body.split(" ")
	if parts.size() == 1:
		var opts: Array = []
		for n in _commands_for(is_admin):
			if String(n).begins_with(parts[0].to_lower()):
				opts.append(["/" + n, String(INFO[n]).get_slice(" — ", 1)])
		return {"usage": "", "options": opts, "start": 0}
	var cmd := String(parts[0]).to_lower()
	if not INFO.has(cmd) or (cmd in ADMIN_CMDS and not is_admin):
		return empty
	var idx := parts.size() - 2
	var partial := String(parts[parts.size() - 1])
	var kinds: Array = ARGS.get(cmd, [])
	var options: Array = []
	if idx < kinds.size():
		options = _candidates(String(kinds[idx]), partial, ctx)
	return {"usage": String(INFO[cmd]), "options": options, "start": typed.length() - partial.length()}

func run(srv: MmoServer, id: int, line: String) -> void:
	var text := line.strip_edges()
	if text.begins_with("/"):
		text = text.substr(1)
	var parts := text.split(" ", false)
	if parts.is_empty():
		return
	var cmd := String(parts[0]).to_lower()
	var args: Array = []
	for i in range(1, parts.size()):
		args.append(String(parts[i]))
	if cmd in ADMIN_CMDS and not srv.is_admin(id):
		srv.reply(id, "Brak uprawnień (tylko admin).", "error")
		return
	# selektory jak w Minecrafcie: @s (ja), @p (najbliższy), @r (losowy), @a (wszyscy — komenda dla każdego)
	var kinds_here: Array = ARGS.get(cmd, [])
	for i in mini(args.size(), kinds_here.size()):
		if kinds_here[i] == "player" and String(args[i]).begins_with("@"):
			var sel := String(args[i]).to_lower()
			var names: Array = []
			match sel:
				"@s":
					if id != 0:
						names.append(String(srv.peers[id]["name"]))
				"@a":
					for pid in srv.peers:
						names.append(String(srv.peers[pid]["name"]))
				"@r":
					if not srv.peers.is_empty():
						var keys: Array = srv.peers.keys()
						names.append(String(srv.peers[keys[randi() % keys.size()]]["name"]))
				"@p":
					var me := srv.player_of(id)
					var best := 1.0e18
					for pid in srv.peers:
						var pn := srv.player_of(int(pid))
						if int(pid) == id or pn == null or me == null or srv.inst_of(int(pid)) != srv.inst_of(id):
							continue
						var d := pn.position.distance_to(me.position)
						if d < best:
							best = d
							names = [String(srv.peers[pid]["name"])]
			if names.is_empty():
				srv.reply(id, "Selektor %s nie znalazł gracza." % sel, "error")
				return
			for nm in names:
				var copy := args.duplicate()
				copy[i] = nm
				run(srv, id, "/" + cmd + " " + " ".join(copy))
			return
	if id != 0:
		srv.log_msg("%s: /%s" % [srv.peers[id]["name"], text])
	match cmd:
		"help", "?":
			srv.reply(id, PLAYER_HELP + ("\n" + ADMIN_HELP if srv.is_admin(id) else ""))
		"list", "who":
			var names: Array = []
			for p in srv.peers.values():
				names.append("%s (poz. %d)" % [p["name"], int(p["rec"]["level"])])
			srv.reply(id, "Online (%d/%d): %s" % [names.size(), int(srv.cfg["max_players"]), ", ".join(names)])
		"w", "msg", "tell":
			if args.size() < 2:
				srv.reply(id, "Użycie: /w <gracz> <tekst>", "error")
				return
			var to := srv.find_peer(args[0])
			if to < 0:
				srv.reply(id, "Nie ma takiego gracza.", "error")
				return
			var msg := " ".join(args.slice(1))
			var from_name := "SERWER" if id == 0 else String(srv.peers[id]["name"])
			Mmo.send_chat(to, "whisper", from_name, msg)
			if id != 0:
				Mmo.send_chat(id, "whisper", "do " + String(srv.peers[to]["name"]), msg)
		"me":
			if id != 0 and not args.is_empty():
				srv.broadcast_chat("me", String(srv.peers[id]["name"]), " ".join(args))
		"pos":
			var n := srv.player_of(id)
			if n != null:
				srv.reply(id, "Pozycja: %d, %d (strefa %s)" % [int(n.position.x), int(n.position.y), srv.inst_of(id).key])
		"stats":
			if id != 0:
				var rec: Dictionary = srv.peers[id]["rec"]
				var st := ServerChars.compute_stats(rec)
				srv.reply(id, "%s: poz. %d (%d/%d xp), złoto %d, HP %d, siła %.2f, obrona %.2f, punkty atrybutów: %d" % [
					rec["name"], int(rec["level"]), int(rec["xp"]), ServerChars.xp_needed(int(rec["level"])), int(rec["gold"]),
					int(st["max_health"]), float(st["strength"]), float(st["defense"]), int(rec.get("attr_points", 0))])
		"skills":
			if id != 0:
				var rec2: Dictionary = srv.peers[id]["rec"]
				var slots: Array = []
				for i in rec2["skills"].size():
					slots.append("%d:%s" % [i + 1, String(rec2["skills"][i]) if String(rec2["skills"][i]) != "" else "-"])
				srv.reply(id, "Sloty: " + " ".join(slots))
				srv.reply(id, "Znane: " + ", ".join(rec2["known_skills"]))
		"skill":
			if id == 0 or args.size() < 2:
				srv.reply(id, "Użycie: /skill <slot 1-9> <id|->", "error")
				return
			srv.on_inv(id, "skill", str(int(args[0]) - 1), "" if args[1] == "-" else args[1])
		"attr":
			_attr(srv, id, args)
		"tp":
			_tp(srv, id, args)
		"tphere":
			var t1 := srv.find_peer(args[0]) if args.size() > 0 else -1
			var me := srv.player_of(id)
			if t1 < 0 or me == null:
				srv.reply(id, "Użycie: /tphere <gracz> (nie z konsoli)", "error")
				return
			_bring(srv, t1, id)
		"give":
			_give(srv, id, args)
		"heal":
			var target := _target(srv, id, args, 0)
			if target < 0:
				return
			var n2 := srv.player_of(target)
			if n2 != null:
				n2.hp = n2.max_hp
				n2.energy = n2.max_energy
				srv.reply(id, "Uleczono: %s" % srv.peers[target]["name"])
		"god":
			var t2 := _target(srv, id, args, 0)
			if t2 < 0:
				return
			srv.peers[t2]["god"] = not bool(srv.peers[t2]["god"])
			srv.reply(id, "Nieśmiertelność %s: %s" % ["włączona" if srv.peers[t2]["god"] else "wyłączona", srv.peers[t2]["name"]])
		"creative", "survival":
			var t4 := _target(srv, id, args, 0)
			if t4 < 0:
				return
			var creative := cmd == "creative"
			srv.peers[t4]["god"] = creative
			srv.reply(id, "Tryb %s: %s" % ["creative (niezniszczalny)" if creative else "survival (zniszczalny)", srv.peers[t4]["name"]])
		"kill":
			if args.is_empty():
				srv.reply(id, "Użycie: /kill <gracz>", "error")
				return
			var t3 := srv.find_peer(args[0])
			if t3 < 0:
				srv.reply(id, "Nie ma takiego gracza.", "error")
				return
			var n3 := srv.player_of(t3)
			if n3 != null and n3.state != Player.S.DEAD:
				n3.invuln = 0.0
				n3._die({})
		"kick":
			if args.is_empty():
				srv.reply(id, "Użycie: /kick <gracz> [powód]", "error")
				return
			var t4 := srv.find_peer(args[0])
			if t4 < 0:
				srv.reply(id, "Nie ma takiego gracza.", "error")
				return
			srv.kick(t4, " ".join(args.slice(1)) if args.size() > 1 else "bez powodu")
		"ban":
			if args.is_empty():
				srv.reply(id, "Użycie: /ban <postać> [powód]", "error")
				return
			var key: String = ServerChars.key_of(args[0])
			var t5 := srv.find_peer(args[0])
			if t5 >= 0:
				key = ServerChars.key_of(String(srv.peers[t5]["name"]))
			if key not in srv.cfg["banned"]:
				srv.cfg["banned"].append(key)
				srv.save_config()
			srv.reply(id, "Zbanowano: %s" % key)
			if t5 >= 0:
				srv.kick(t5, "ban")
		"unban":
			if args.is_empty():
				srv.reply(id, "Użycie: /unban <postać>", "error")
				return
			srv.cfg["banned"].erase(ServerChars.key_of(args[0]))
			srv.save_config()
			srv.reply(id, "Odbanowano: %s" % args[0])
		"spawn":
			_spawn(srv, id, args)
		"kia":
			var kinst2 := srv.inst_of(id)
			if id == 0 or kinst2 == null or args.is_empty():
				srv.reply(id, "Użycie: /kia <ally N | pet>", "error")
				return
			var want := String(args[0]) if args[0] != "ally" or args.size() < 2 else "ally:%s" % args[1]
			for c in kinst2.entities.get_children():
				if c is Ally and "ally:%d" % (c as Ally).slot == want and (c as Ally).server_peer == id:
					(c as Ally)._die()
				elif c is Pet and want == "pet" and (c as Pet).server_peer == id:
					(c as Pet)._die()
		"bosses":
			var bl: Array = []
			for bid in BossDB.BASE_LIST:
				bl.append("%s (%d HP)" % [bid, int(BossDB.BASE_LIST[bid]["hp"])])
			srv.reply(id, "Bossowie: " + ", ".join(bl))
		"boss":
			var binst := srv.inst_of(id)
			var bnode := srv.player_of(id)
			if id == 0 or binst == null or bnode == null:
				srv.reply(id, "Użycie z gry: /boss [id] (lista: /bosses)", "error")
				return
			var want_boss := String(args[0]) if not args.is_empty() else srv.world_boss_for(binst)
			if not BossDB.has(want_boss):
				srv.reply(id, "Nieznany boss. /bosses", "error")
				return
			binst.spawn_world_boss(want_boss, (bnode.position + Vector2(0.0, -300.0)).clamp(Vector2(700, 700), binst.size - Vector2(700, 700)))
		"wedrowiec":
			var winst := srv.inst_of(id)
			if winst == null or winst.kind != "swiat":
				srv.reply(id, "Wędrowcy pojawiają się tylko na Pustkowiu.", "error")
				return
			var want := String(args[0]) if not args.is_empty() else ""
			if not winst.spawn_wander(id, want):
				srv.reply(id, "Nie można teraz przywołać wędrowca (rozmawia? już jest? zły id?). Id: " + ", ".join(EncounterDB.roaming()), "error")
		"event":
			var einst := srv.inst_of(id)
			if einst == null or args.is_empty():
				srv.reply(id, "Użycie: /event raid (Pustkowie) albo /event duel (rozdział, jeden gracz)", "error")
				return
			if args[0] == "raid" and einst.kind == "swiat":
				einst.start_raid()
			elif args[0] == "duel" and einst.kind == "story" and einst.peer_ids.size() == 1:
				einst._start_duel()
			else:
				srv.reply(id, "Tu się nie da (raid: Pustkowie; duel: rozdział z jednym graczem).", "error")
		"killall":
			var kinst := srv.inst_of(id)
			srv.reply(id, "Usunięto mobów: %d" % (kinst.kill_all() if kinst != null else 0))
		"wyzwanie":
			if id != 0:
				srv.start_challenge(id)
		"arena":
			if id == 0 or args.is_empty():
				srv.reply(id, "Użycie: /arena <gracz> — zaproś gracza na pojedynek PvP", "error")
				return
			srv.invite_arena(id, args[0])
		"wyjdz", "poddaj":
			if id != 0:
				srv.leave_fight(id)
		"mapa":
			if id == 0:
				return
			var mrec: Dictionary = srv.peers[id]["rec"]
			if MmoServer.act2_needs_choice(mrec):
				srv.open_map(id)
			else:
				srv.reply(id, "Mapa świata Aktu II jest dostępna między jego misjami (po Akcie I albo po wyzwoleniu wioski).")
		"wlasne":
			if id != 0:
				srv.start_custom(id)
		"ranking":
			srv.reply(id, srv.ranking_text())
		"swiat":
			_zone_switch(srv, id, "swiat")
		"kampania":
			_zone_switch(srv, id, "story")
		"quest":
			if id != 0:
				var qi := srv.inst_of(id)
				var story := MmoServer.story_of(srv.peers[id]["rec"])
				if MmoServer.act2_needs_choice(srv.peers[id]["rec"]):
					srv.reply(id, "Akt II: wybierz kolejną wioskę na mapie świata (/mapa).")
					return
				srv.reply(id, "Rozdział: %s — %s
Cel: %s" % [String(QuestDB.get_data(String(story["quest"])).get("label", "")), String(QuestDB.get_data(String(story["quest"])).get("title", "")), qi.objective() if qi != null else ""])
		"rozdzial":
			if id == 0 or args.is_empty() or not args[0].is_valid_int():
				srv.reply(id, "Użycie: /rozdzial <numer 1-%d>" % QuestDB.count(), "error")
				return
			var ci := clampi(int(args[0]) - 1, 0, QuestDB.count() - 1)
			var cq := String(QuestDB.chapter(ci).get("id", ""))
			if not ZoneDB.has(cq):
				srv.reply(id, "Ten rozdział nie ma strefy.", "error")
				return
			var rs := MmoServer.story_of(srv.peers[id]["rec"])
			rs["chapter"] = ci
			rs["quest"] = cq
			srv.peers[id]["rec"]["zone"] = "story"
			srv.chars.mark_dirty()
			srv.enter_zone(id, cq)
		"xp", "setlevel", "gold":
			_numeric(srv, id, cmd, args)
		"say":
			if args.is_empty():
				return
			srv.broadcast_chat("server", "SERWER", " ".join(args))
			srv.log_msg("[SERWER] " + " ".join(args))
		"op", "deop":
			if args.is_empty():
				srv.reply(id, "Użycie: /%s <postać>" % cmd, "error")
				return
			var k2 := ServerChars.key_of(args[0])
			if cmd == "op" and k2 not in srv.cfg["admins"]:
				srv.cfg["admins"].append(k2)
			elif cmd == "deop":
				srv.cfg["admins"].erase(k2)
			srv.save_config()
			srv.reply(id, "%s: %s" % ["Admin dodany" if cmd == "op" else "Admin usunięty", k2])
			var t6 := srv.find_peer(args[0])
			if t6 >= 0:
				srv.refresh_loadout(t6)
		"class":
			if args.size() < 2:
				srv.reply(id, "Użycie: /class <gracz> <klasa>  (klasy: %s)" % ", ".join(ClassDatabase.all()), "error")
				return
			var t7 := srv.find_peer(args[0])
			if t7 < 0 or not ClassDatabase.has(args[1]):
				srv.reply(id, "Zły gracz lub klasa.", "error")
				return
			var r7: Dictionary = srv.peers[t7]["rec"]
			r7["class"] = args[1]
			ServerChars.refresh_class(r7)
			srv.chars.mark_dirty()
			srv.refresh_loadout(t7)
			srv.reply(id, "Zmieniono klasę: %s -> %s" % [r7["name"], args[1]])
		"items":
			var filt: String = String(args[0]).to_lower() if args.size() > 0 else ""
			var ids: Array = []
			for iid in ItemDB.LIST:
				if filt == "" or String(iid).contains(filt) or String(ItemDB.LIST[iid].get("name", "")).to_lower().contains(filt):
					ids.append(String(iid))
			ids.sort()
			srv.reply(id, "Przedmioty (%d): %s" % [ids.size(), ", ".join(ids.slice(0, 60))] + (" …" if ids.size() > 60 else ""))
		"save":
			srv.chars.save_all(true)
			srv.reply(id, "Zapisano postacie.")
		"backup":
			var stamp: String = srv.chars.backup()
			if stamp == "":
				srv.reply(id, "Nie udało się utworzyć kopii zapasowej.", "error")
			else:
				srv.reply(id, "Kopia zapasowa: %s/backups/%s" % [ServerChars.dir(), stamp])
		"version":
			var up := srv.updater
			srv.reply(id, "Wersja serwera: %s%s" % [UiUpdater.current_version(), ("  (dostępna %s — /update)" % up.tag) if up != null and up.available() else ""])
		"update":
			if srv.updater == null:
				srv.reply(id, "Aktualizacje niedostępne.", "error")
			else:
				srv.reply(id, "Sprawdzam aktualizacje… (wynik w logu serwera)")
				srv.updater.check(true)
		"stop":
			srv.reply(id, "Zatrzymuję serwer…")
			srv.stop.call_deferred()
		_:
			srv.reply(id, "Nieznana komenda. /help", "error")

func _target(srv: MmoServer, id: int, args: Array, idx: int) -> int:
	if args.size() > idx:
		var t := srv.find_peer(args[idx])
		if t < 0:
			srv.reply(id, "Nie ma takiego gracza.", "error")
		return t
	if id == 0:
		srv.reply(id, "Podaj nazwę gracza.", "error")
		return -1
	return id

func _attr(srv: MmoServer, id: int, args: Array) -> void:
	if id == 0 or args.is_empty():
		srv.reply(id, "Użycie: /attr <%s> [ile]" % "|".join(GameState.ATTR_ORDER), "error")
		return
	var rec: Dictionary = srv.peers[id]["rec"]
	var key: String = String(args[0]).to_lower()
	var n := clampi(int(args[1]) if args.size() > 1 else 1, 1, 500)
	if key not in GameState.ATTR_ORDER:
		srv.reply(id, "Statystyki: " + ", ".join(GameState.ATTR_ORDER), "error")
		return
	if int(rec.get("attr_points", 0)) < n:
		srv.reply(id, "Za mało punktów (masz %d)." % int(rec.get("attr_points", 0)), "error")
		return
	rec["attr_points"] = int(rec["attr_points"]) - n
	rec["attrs"][key] = int(rec["attrs"].get(key, 0)) + n
	srv.chars.mark_dirty()
	srv.refresh_loadout(id)
	srv.reply(id, "+%d %s" % [n, key])

func _tp(srv: MmoServer, id: int, args: Array) -> void:
	var node := srv.player_of(id)
	if args.size() == 2 and _is_coord(args[0]) and _is_coord(args[1]):
		if node != null:
			var tinst := srv.inst_of(id)
			node.position = Vector2(clampf(_coord(args[0], node.position.x), 100.0, tinst.size.x - 100.0), clampf(_coord(args[1], node.position.y), 100.0, tinst.size.y - 100.0))
		return
	if args.size() == 1:
		var t := srv.find_peer(args[0])
		if t < 0 or node == null:
			srv.reply(id, "Użycie: /tp <gracz> | /tp <x> <y> | /tp <gracz> <cel>", "error")
			return
		_bring(srv, id, t)
	elif args.size() == 2:
		var a := srv.find_peer(args[0])
		var b := srv.find_peer(args[1])
		if a < 0 or b < 0:
			srv.reply(id, "Nie ma takiego gracza.", "error")
			return
		_bring(srv, a, b)
	else:
		srv.reply(id, "Użycie: /tp <gracz> | /tp <x> <y> | /tp <gracz> <cel>", "error")

## Współrzędne jak w Minecrafcie: liczba albo ~ (obecna pozycja) / ~10 (przesunięcie).
static func _is_coord(tok: String) -> bool:
	return tok.is_valid_float() or tok == "~" or (tok.begins_with("~") and tok.substr(1).is_valid_float())

static func _coord(tok: String, cur: float) -> float:
	if tok.begins_with("~"):
		return cur + (float(tok.substr(1)) if tok.length() > 1 else 0.0)
	return float(tok)

## /give <gracz> <przedmiot|all> [ile] — jak w Minecrafcie; kolejność argumentów jest dowolna
## (liczba = ilość, nazwa przedmiotu albo "all" = towar, reszta = gracz; bez gracza dostaje wywołujący).
func _give(srv: MmoServer, id: int, args: Array) -> void:
	var item := ""
	var count := 1
	var who := ""
	for a in args:
		var s := String(a)
		if s.is_valid_int() and item != "":
			count = clampi(int(s), 1, 999)
		elif item == "" and (s == "all" or ItemDB.has(s)):
			item = s
		elif who == "":
			who = s
		else:
			srv.reply(id, "Nie znam przedmiotu „%s” (lista: /items). Użycie: /give <gracz> <przedmiot|all> [ile]" % s, "error")
			return
	if item == "":
		srv.reply(id, "Użycie: /give <gracz> <przedmiot|all> [ile]  (lista: /items) — nie znam przedmiotu%s." % ((" „%s”" % who) if who != "" else ""), "error")
		return
	var tgt := id
	if who != "":
		tgt = srv.find_peer(who)
		if tgt < 0:
			srv.reply(id, "Nie ma gracza „%s” online." % who, "error")
			return
	elif id == 0:
		srv.reply(id, "Z konsoli podaj gracza: /give <gracz> <przedmiot|all> [ile]", "error")
		return
	var rec: Dictionary = srv.peers[tgt]["rec"]
	if item == "all":
		var added := 0
		for iid in ItemDB.LIST:
			if ServerChars.inv_add(rec, String(iid), 1) > 0:
				added += 1
		srv.reply(id, "Dodano %d rodzajów przedmiotów (plecak ma 40 miejsc)." % added)
	else:
		var got := ServerChars.inv_add(rec, item, count)
		if got < 1:
			srv.reply(id, "Plecak pełny.", "error")
			return
		srv.reply(id, "Dano %s x%d dla %s." % [item, got, srv.peers[tgt]["name"]])
	srv.chars.mark_dirty()
	srv.refresh_loadout(tgt)

func _spawn(srv: MmoServer, id: int, args: Array) -> void:
	if args.is_empty():
		var ids: Array = []
		for sid in EnemyDB.LIST:
			if not bool(EnemyDB.LIST[sid].get("boss", false)):
				ids.append(String(sid))
		srv.reply(id, "Użycie: /spawn <gatunek> [ile]. Gatunki: " + ", ".join(ids))
		return
	var node := srv.player_of(id)
	var sinst := srv.inst_of(id)
	if sinst == null:
		srv.reply(id, "Z konsoli nie da się (brak strefy) — użyj z gry.", "error")
		return
	var at := node.position + Vector2(160, 0) if node != null else sinst.spawn + Vector2(200, 0)
	var n := clampi(int(args[1]) if args.size() > 1 and args[1].is_valid_int() else 1, 1, 20)
	var made := 0
	for i in n:
		if sinst.spawn_mob(args[0], at + Vector2(randf_range(-60, 60), randf_range(-60, 60))) != null:
			made += 1
	srv.reply(id, "Stworzono: %d" % made if made > 0 else "Nieznany gatunek (bez bossów).", "system" if made > 0 else "error")

func _numeric(srv: MmoServer, id: int, cmd: String, args: Array) -> void:
	if args.size() < 2 or not args[1].is_valid_int():
		srv.reply(id, "Użycie: /%s <gracz> <liczba>" % cmd, "error")
		return
	var t := srv.find_peer(args[0])
	if t < 0:
		srv.reply(id, "Nie ma takiego gracza.", "error")
		return
	var rec: Dictionary = srv.peers[t]["rec"]
	var v := int(args[1])
	match cmd:
		"xp":
			var gained := ServerChars.add_xp(rec, maxi(0, v))
			if gained > 0:
				srv.broadcast_chat("system", "", "%s awansuje na poziom %d!" % [rec["name"], int(rec["level"])])
		"gold":
			rec["gold"] = clampi(int(rec["gold"]) + v, 0, 99999999)
		"setlevel":
			var target := clampi(v, 1, ServerChars.MAX_LEVEL)
			var before := int(rec["level"])
			rec["level"] = target
			rec["xp"] = 0
			rec["attr_points"] = maxi(0, int(rec.get("attr_points", 0)) + (target - before) * GameState.ATTR_POINTS_PER_LEVEL)
	srv.chars.mark_dirty()
	srv.refresh_loadout(t)
	srv.reply(id, "OK: %s %s %d" % [rec["name"], cmd, v])

## Przenosi gracza `who` do strefy gracza `target` (jeśli są w różnych instancjach) i ustawia obok niego.
func _bring(srv: MmoServer, who: int, target: int) -> void:
	var tn := srv.player_of(target)
	if tn == null or not srv.peers.has(who):
		return
	var tinst := srv.inst_of(target)
	if srv.inst_of(who) != tinst:
		srv.enter_zone(who, tinst.key)
	var wn := srv.player_of(who)
	if wn != null:
		wn.position = tn.position + Vector2(40, 0)

func _zone_switch(srv: MmoServer, id: int, zone: String) -> void:
	if id == 0:
		return
	var rec: Dictionary = srv.peers[id]["rec"]
	rec["zone"] = zone
	srv.chars.mark_dirty()
	srv.enter_zone(id, srv.zone_key_for(rec))
	srv.reply(id, "Przeniesiono: %s." % ("Pustkowie" if zone == "swiat" else "kampania"))
