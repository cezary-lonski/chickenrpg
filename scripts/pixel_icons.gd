class_name PixelIcons
extends RefCounted
## Ikony przedmiotów jako prawdziwy pixel art 16×16 (rysowane w kodzie jako mapy znaków).
## Litery: a/A/L = kolor przedmiotu (średni / ciemny / jasny), m/M stal, g/G złoto, n/N drewno,
## r/R czerwień, e/E zieleń, u/U błękit, p/P fiolet, y żółć, w biel, s/S skorupka/skóra, k czerń.
## Kontur dodawany jest automatycznie.

const DEFAULT_TINT := {
	"miecz": Color(0.82, 0.85, 0.92), "szabla": Color(0.82, 0.85, 0.92), "kol": Color(0.6, 0.4, 0.22), "kij": Color(0.6, 0.4, 0.22),
	"widelec": Color(0.8, 0.82, 0.88), "kosa": Color(0.8, 0.82, 0.88), "mlot": Color(0.62, 0.64, 0.72), "kolce": Color(0.7, 0.72, 0.8),
	"laska": Color(0.6, 0.4, 0.22), "luk": Color(0.62, 0.42, 0.24), "strzala": Color(0.8, 0.82, 0.88), "pioro": Color(0.95, 0.95, 0.9), "dziobak": Color(0.97, 0.75, 0.2),
	"helm": Color(0.7, 0.72, 0.8), "korona": Color(0.98, 0.8, 0.25), "pancerz": Color(0.62, 0.64, 0.72), "kolczuga": Color(0.62, 0.64, 0.72),
	"kamizelka": Color(0.55, 0.38, 0.22), "szmata": Color(0.7, 0.62, 0.5), "skorupa": Color(0.45, 0.6, 0.4), "skrzydla": Color(0.95, 0.95, 0.98),
	"plaszcz": Color(0.5, 0.3, 0.55), "upior": Color(0.7, 0.75, 0.85), "buty": Color(0.55, 0.38, 0.22), "obroza": Color(0.85, 0.3, 0.3),
	"koraliki": Color(0.9, 0.5, 0.4), "kiel": Color(0.95, 0.93, 0.85), "piercien": Color(0.98, 0.8, 0.25), "szalik": Color(0.8, 0.25, 0.3),
	"amulet": Color(0.55, 0.8, 0.95), "okulary": Color(0.3, 0.3, 0.38), "feniks": Color(1.0, 0.5, 0.2), "jajko": Color(0.97, 0.93, 0.82),
	"jajko_duze": Color(0.97, 0.93, 0.82), "skamielina": Color(0.7, 0.66, 0.55), "cebula": Color(0.78, 0.5, 0.7), "mikstura": Color(0.85, 0.25, 0.3),
	"eliksir": Color(0.35, 0.6, 0.95), "koktajl": Color(0.95, 0.6, 0.3), "rosol": Color(0.95, 0.8, 0.4), "sztabka": Color(0.75, 0.78, 0.85),
	"krysztal": Color(0.55, 0.4, 0.85), "diament": Color(0.7, 0.95, 1.0), "klucz": Color(0.98, 0.8, 0.25), "list": Color(0.95, 0.9, 0.7), "lutnia": Color(0.9, 0.6, 0.3),
}

const SPRITES := {
	"miecz": [
		"..............LL", ".............LLa", "............LLaA", "...........LLaA.", "..........LLaA..", ".........LLaA...", "..g.....LLaA....",
		"..gg...LLaA.....", "...gg.LLaA......", "....ggLaA.......", ".....ggA........", "....nggg........", "...nNg.g........", "..nN............", ".nN.............", "................"],
	"szabla": [
		"..........LLLL..", ".........LLaaaA.", "........LLaA..AA", ".......LLaA...A.", "......LLaA......", ".....LLaA.......", "....LLaA........",
		"..g.LaA.........", "...ggA..........", "...nGg..........", "..nNg...........", ".nN.............", "................", "................", "................", "................"],
	"kol": [
		"......nn........", ".....nnNn.......", ".....nnNn.......", ".....nnNn.......", ".....nnNn.......", ".....nnNn.......", ".....nnNn.......",
		".....nnNn.......", "......nN........", "......nN........", "......nN........", "......nN........", "......nN........", "................", "................", "................"],
	"kij": [
		".....aaaa.......", "....aLLaaA......", "....aLaaaA......", "....aaaaAA......", ".....aAAA.......", "......nN........", "......nN........", "......nN........",
		"......nN........", "......nN........", "......nN........", "......nN........", "......nN........", "................", "................", "................"],
	"laska": [
		".......y........", "......yyy.......", ".....yyyyy......", "......yyy.......", ".......y........", "......nN........", "......nN........", "......nN........",
		"......nN........", "......nN........", "......nN........", "......nN........", "......nN........", "................", "................", "................"],
	"widelec": [
		"....m..m..m.....", "....m..m..m.....", "....m..m..m.....", "....mmmmmmm.....", ".....mmmmm......", "......mMm.......", "......nNn.......", "......nNn.......",
		"......nNn.......", "......nNn.......", "......nNn.......", "......nNn.......", "......nNn.......", "................", "................", "................"],
	"kosa": [
		"....mmmmmm......", "..mmmMMMMMm.....", ".mmM......mm....", "mM.........mM...", "...........nN...", "..........nN....", ".........nN.....", "........nN......",
		".......nN.......", "......nN........", ".....nN.........", "....nN..........", "...nN...........", "................", "................", "................"],
	"mlot": [
		"..mmmmmmmmmm....", "..mLLLLLLLLm....", "..mmmmmmmmmm....", ".......nN.......", ".......nN.......", ".......nN.......", ".......nN.......", ".......nN.......",
		".......nN.......", ".......nN.......", ".......nN.......", ".......nN.......", ".......nN.......", "................", "................", "................"],
	"kolce": [
		".......m........", "...m...m...m....", "....m.mmm.m.....", ".....mmmmm......", "..mmmmLLmmmm....", ".mmmmLLmmmmmm...", "..mmmmmmmmmm....", ".....mmmmm......",
		"....m.mmm.m.....", "...m...m...m....", ".......m........", "................", "................", "................", "................", "................"],
	"dziobak": [
		"......yyyy......", "....yyyyyyyy....", "...yyyLLyyyy....", "..yyyL....yyy...", "..yy........yy..", "..y..........y..", "................", "................",
		"................", "................", "................", "................", "................", "................", "................", "................"],
	"pioro": [
		"..........aaaa..", ".........aLLaaA.", "........aLaaaAA.", ".......aLaaaAA..", "......aLaaaAA...", ".....aLaaaAA....", "....aaaaAA......", "...aaaAA........",
		"..aaAA..........", ".naA............", "nN..............", "................", "................", "................", "................", "................"],
	"strzala": [
		".......aa.......", "......aaaa......", ".....aLaaaA.....", ".......aa.......", ".......nn.......", ".......nn.......", ".......nn.......", ".......nn.......",
		".......nn.......", ".......nn.......", ".......nn.......", "......wnnw......", ".....www.ww.....", "....ww..ww.w....", "................", "................"],
	"luk": [
		"....nn..........", "...nNn..........", "..nNn....w.......", "..nN......w......", ".nN.......w......", ".nN.......w......", ".nN.......w......", "..nN......w......",
		"..nNn....w.......", "...nNn..........", "....nn..........", "................", "................", "................", "................", "................"],
	"helm": [
		".....mmmmmm.....", "...mmLLLLLmmm...", "..mLLLaaaaammm..", "..mLaaaaaaaamm..", "..maaaaaaaaaMm..", "..maaaaaaaaaMm..", "..mAAAAAAAAAMM..", "..mMMMMMMMMMMM..",
		"..mM.kkkkkk.Mm..", "..mM.k....k.Mm..", "..mM........Mm..", "................", "................", "................", "................", "................"],
	"korona": [
		"................", "..g....g....g...", "..gg..ggg..gg...", "..ggg.ggg.ggg...", "..gggggggggggg..", "..gLgggggggLgG..", "..gggggggggggG..", "..gGGGGGGGGGGG..",
		"..gr.g.u.g.rG...", "................", "................", "................", "................", "................", "................", "................"],
	"pancerz": [
		"...aa......aa...", "..aaaa....aaaa..", "..aLaaaaaaaaaA..", "..aLaaaaaaaaAA..", "...aaaaaaaaaA...", "...aaLaaaaaAA...", "...aaLaaaaaAA...", "...aaaaaaaaAA...",
		"...aaaaaaaaAA...", "...aaaaaaaaAA...", "....aaaaaaAA....", "....aaaaaaAA....", "....AAAAAAAA....", "................", "................", "................"],
	"kolczuga": [
		"...aa......aa...", "..aaaa....aaaa..", "..aLaaaaaaaaaA..", "..aLaAaAaAaaaA..", "...aAaAaAaAaA...", "...aaAaAaAaaA...", "...aAaAaAaAaA...", "...aaAaAaAaaA...",
		"...aAaAaAaAaA...", "...aaAaAaAaaA...", "....aAaAaAaA....", "....aaAaAaaA....", "....AAAAAAAA....", "................", "................", "................"],
	"kamizelka": [
		"...aa......aa...", "..aaaa....aaaa..", "..aLaaa..aaaaA..", "..aLaa....aaaA..", "...aaa....aaA...", "...aaa.gg.aaA...", "...aaa....aaA...", "...aaa.gg.aaA...",
		"...aaa....aaA...", "...aaa.gg.aaA...", "....aa....aA....", "....AA....AA....", "................", "................", "................", "................"],
	"szmata": [
		"..aa........aa..", ".aaaaa....aaaaa.", ".aLaaaaaaaaaaaA.", ".aLaaaaaaaaaaAA.", "..aaaaaaaaaaAA..", "...aaaaaaaaAA...", "...aaaaaAaaAA...", "...aaaaaaaaAA...",
		"...aaaAaaaaAA...", "...aaaaaaaaAA...", "....aaaaaaAA....", "....aaAaaAAA....", "....A.A..A.A....", "................", "................", "................"],
	"skorupa": [
		"....aaaaaaaa....", "..aaaLLaaaaaaA..", ".aaLaAaaAaaAaaA.", ".aaaAaaAaaAaaaA.", ".aAaaaAaaaaAaaA.", ".aaAaaaaAaaaAaA.", ".aaaaAaaaaAaaAA.", "..aAaaaAaaaAaA..",
		"...AAaaaaaaAA...", "....AAAAAAAA....", "................", "................", "................", "................", "................", "................"],
	"skrzydla": [
		"w..........w....", "ww........ww....", "wLw......wLw....", "wLLw....wLLw....", "wLLLw..wLLLw....", ".wLLLwwLLLw.....", ".wLLaLwLaLLw....", "..wLaaLLaaLw....",
		"...wLaaaaLw.....", "....wLaaLw......", ".....wLLw.......", "......ww........", "................", "................", "................", "................"],
	"plaszcz": [
		"....aaaaaa......", "...aLaaaaaA.....", "..aLaaaaaaaA....", "..aLaaggaaaA....", ".aLaaaaaaaaaA...", ".aLaaaaaaaaaA...", ".aaaaaaaaaaaA...", ".aaaaaaaaaaaAA..",
		".aaaaaaaaaaaAA..", "aaaaaaaaaaaaAA..", "aaAaaaaaaaaAAA..", "AAAAAAAAAAAAA...", "................", "................", "................", "................"],
	"upior": [
		"....aaaaaa......", "...aLLaaaaA.....", "..aLaaaaaaaA....", "..aLakaakaaA....", "..aaakaakaaA....", "..aaaaaaaaaA....", "..aaaakkaaaA....", "..aaaaaaaaaA....",
		"..aaaaaaaaaA....", "..aaaaaaaaaA....", "..aAaaAaaAaA....", "..A.aA.aA.AA....", "................", "................", "................", "................"],
	"buty": [
		"................", "...nnnn.........", "...nLLn.........", "...nLaN.........", "...nLaN.........", "...nLaN.........", "...nLaNN........", "...nLaaNN.......",
		"...nLaaaNN......", "..nnLaaaaaNN....", ".nLLaaaaaaaaN...", ".nLaaaaaaaaaN...", ".nNNNNNNNNNNN...", "................", "................", "................"],
	"obroza": [
		"...aaaaaaaa.....", "..aLLLLLLLLa....", ".aL........Aa...", ".aL........Aa...", ".aL........Aa...", ".aL........Aa...", "..aA......aA....", "...aaa..aaA.....",
		"....AaaaAA......", "......gg........", ".....gGGg.......", ".....gGGg.......", "......gg........", "................", "................", "................"],
	"koraliki": [
		"..a.........a...", "..aa.......aa...", "...a.......a....", "...aa.....aa....", "....a.....a.....", "....aa...aa.....", ".....a...a......", ".....aa.aa......",
		"......aaa.......", "......aLa.......", ".......A........", "................", "................", "................", "................", "................"],
	"kiel": [
		"......aaaa......", ".....aLaaaA.....", ".....aLaaaA.....", "......aLaaA.....", "......aLaaA.....", ".......aLaA.....", ".......aLaA.....", "........aaA.....",
		"........aA......", ".........A......", "................", "................", "................", "................", "................", "................"],
	"piercien": [
		".......aa.......", "......aLLa......", ".....aLuuLa.....", "......aLLa......", ".....aaaaaa.....", "....aLA..AaA....", "...aLA....AaA...", "...aA......AA...",
		"...aA......AA...", "...aLA....AaA...", "....aAA..AAA....", ".....aAAAAA.....", "................", "................", "................", "................"],
	"szalik": [
		"................", "..aaaaaaaaaa....", ".aLLLLLLLLLaa...", ".aaaaaaaaaaAA...", "..AAAAAAAAAAA...", "......aaA.......", "......aaA.......", "......aLaA......",
		".....aLaaA......", ".....aaaaA......", ".....aAaAA......", ".....a.a.A......", "................", "................", "................", "................"],
	"amulet": [
		"...a.......a....", "....a.....a.....", ".....a...a......", "......a.a.......", "......aaa.......", ".....gGGGg......", "....gLaaaGg.....", "....gLaaaAGg....",
		"....gaaLaAGg....", "....gaaaaAGg....", ".....gAAAGg.....", "......gGGg......", "................", "................", "................", "................"],
	"okulary": [
		"................", "................", "..aaaa....aaaa..", ".aLLLLa..aLLLLa.", ".aLuuLaaaaLuuLa.", ".aLuuLa..aLuuLa.", ".aLLLLa..aLLLLa.", "..aaaa....aaaa..",
		"................", "................", "................", "................", "................", "................", "................", "................"],
	"feniks": [
		"........r.......", ".......rr.......", "......rrry......", ".....rrryy......", "..r..rryyyr.....", ".rr.rryyyrr.....", ".rrrryyyyrr.....", "..rryyyyyrr.....",
		"...ryyyyrr......", "....ryyrr.......", ".....rrr........", "......r.........", "................", "................", "................", "................"],
	"jajko": [
		"................", "......aaaa......", ".....aLLaaa.....", "....aLLaaaaA....", "....aLaaaaaA....", "...aLaaaaaaAA...", "...aLaaaaaaAA...", "...aaaaaaaaAA...",
		"...aaaaaaaaAA...", "....aaaaaaAA....", "....AaaaaAAA....", ".....AAAAAA.....", "................", "................", "................", "................"],
	"jajko_duze": [
		"......aaaa......", ".....aLLaaa.....", "....aLLaaaaA....", "...aLLaaAaaaA...", "...aLaaaaaaAA...", "..aLaaAaaaaaAA..", "..aLaaaaaAaaAA..", "..aaaAaaaaaaAA..",
		"..aaaaaaaaAaAA..", "..aaaaAaaaaAAA..", "...aaaaaaaAAA...", "....AaaaaAAA....", ".....AAAAAA.....", "................", "................", "................"],
	"skamielina": [
		"....nnnnnn......", "..nnnLLLLnnn....", ".nnLnnnnnLnnn...", ".nLnnLLLnnLnn...", ".nLnLnnnLnLnN...", ".nLnLnLnLnLnN...", ".nLnLnnnLnLnN...", ".nnLnnLLnnLNN...",
		"..nnLnnnnLNN....", "...nnnLLnNN.....", ".....nnnNN......", "................", "................", "................", "................", "................"],
	"cebula": [
		".......e........", "......ee........", ".....eeE........", ".....aaaa.......", "....aLaaaa......", "...aLaaaaaA.....", "...aLaaaaaA.....", "..aaLaaAaaAA....",
		"..aaaaaAaaAA....", "...aaaaaaaAA....", "....AaaaaAA.....", ".....AAAAA......", "................", "................", "................", "................"],
	"mikstura": [
		"......nnnn......", "......nNNn......", ".......ww.......", ".......ww.......", "......wwww......", "....wwaaaaww....", "...waaLaaaaaw...", "...waLaaaaaAw...",
		"...waaaaaaaAw...", "...waaaaaaAAw...", "...wAaaaaAAAw...", "....wAAAAAAw....", ".....wwwwww.....", "................", "................", "................"],
	"eliksir": [
		".....nnnnnn.....", ".....nNNNNn.....", "......wwww......", "......wLaw......", "......waaw......", "......waaw......", ".....wwaaww.....", "....waaLaaaw....",
		"...waaLaaaaAw...", "...waaaaaaaAw...", "...waaaaaaAAw...", "....wAAAAAAw....", ".....wwwwww.....", "................", "................", "................"],
	"koktajl": [
		"..wwwwwwwwww....", "..waaaaaaaaaw...", "...waaLaaaaw....", "....waaaaaw.....", ".....waaaw......", "......www.......", ".......w........", ".......w........",
		".......w........", "....wwwwwww.....", "................", "................", "................", "................", "................", "................"],
	"rosol": [
		"................", "...y..y..y......", "....y..y..y.....", "................", "..nnnnnnnnnnn...", ".nyyyyyyyyyyyn..", ".naaaLaaaaaaan..", ".naaaaaaaaaaAn..",
		"..naaaaaaaaAn...", "...nnAAAAAnn....", "....nnnnnnn.....", "................", "................", "................", "................", "................"],
	"sztabka": [
		"................", "................", "....aaaaaaaa....", "...aLLLLLLLaa...", "..aLLaaaaaaaAA..", ".aaaaaaaaaaAAAA.", ".aaaaaaaaaaaAAA.", ".aAAAAAAAAAAAAA.",
		"................", "................", "................", "................", "................", "................", "................", "................"],
	"krysztal": [
		".......aa.......", "......aLLa......", ".....aLLaaA.....", "....aLLaaaAA....", "....aLaaaaAA....", "....aLaaaaAA....", "....aLaaaaAA....", ".....aLaaAA.....",
		".....aaaAAA.....", "......aaAA......", ".......AA.......", "................", "................", "................", "................", "................"],
	"diament": [
		"................", "................", "...LLLLLLLLLL...", "..LLaaLaaLaaLL..", ".LLaaaLaaLaaaLL.", "LLLLLLLLLLLLLLLL", ".aLaaaLaaLaaaAa.", "..aLaaLaaLaaAa..",
		"...aLaaLaaLAa...", "....aLaLaLAa....", ".....aLLLAa.....", "......aLAa......", ".......aa.......", "................", "................", "................"],
	"klucz": [
		"...gggg.........", "..gGGGGg........", "..gG..Gg........", "..gG..Gg........", "..gGGGGg........", "...ggggg........", "....gGg.........", "....gGg.........",
		"....gGggg.......", "....gGg.g.......", "....gGgggg......", "....gGg.........", "................", "................", "................", "................"],
	"lutnia": [
		".............GG.", "............nNG.", "...........nN...", "..........nN....", ".........nN.....", "....aaa.nN......", "...aLLLaN.......",
		"..aLLkLLaA......", "..aLkkkLaA......", "..aLLkLLaA......", "..aaLLLaaA......", "...aaaaAA.......", "....AAAA........", "................", "................", "................"],
	"list": [
		"................", "................", ".wwwwwwwwwwwww..", ".wLLLLLLLLLLAw..", ".wLwLLLLLLwLAw..", ".wLLwLLLLwLLAw..", ".wLLLwLLwLLLAw..", ".wLLLLwwLLLLAw..",
		".wLLLLLLLLLLAw..", ".wAAAAAAAAAAAw..", ".wwwwwwwwwwwww..", "................", "................", "................", "................", "................"],
}

static func _color(ch: String, tint: Color) -> Color:
	match ch:
		"a": return tint
		"A": return tint.darkened(0.3)
		"L": return tint.lightened(0.38)
		"m": return Color(0.78, 0.8, 0.86)
		"M": return Color(0.5, 0.52, 0.6)
		"w": return Color(0.96, 0.96, 0.98)
		"g": return Color(0.98, 0.8, 0.25)
		"G": return Color(0.75, 0.55, 0.15)
		"n": return Color(0.6, 0.4, 0.22)
		"N": return Color(0.4, 0.26, 0.14)
		"r": return Color(0.88, 0.22, 0.2)
		"R": return Color(0.6, 0.12, 0.12)
		"e": return Color(0.4, 0.75, 0.3)
		"E": return Color(0.25, 0.5, 0.2)
		"u": return Color(0.4, 0.7, 0.98)
		"U": return Color(0.25, 0.45, 0.75)
		"p": return Color(0.7, 0.4, 0.9)
		"P": return Color(0.45, 0.25, 0.65)
		"y": return Color(1.0, 0.92, 0.4)
		"k": return Color(0.05, 0.04, 0.07)
	return Color(0, 0, 0, 0)

static func has(kind: String) -> bool:
	return SPRITES.has(kind)

## Obraz size×size (powiększony metodą najbliższego sąsiada); null, jeśli brak sprite'a.
static func make(kind: String, tint: Color, size: int) -> Image:
	if not SPRITES.has(kind):
		return null
	var t := tint if tint.a > 0.0 else (DEFAULT_TINT.get(kind, Color(0.8, 0.8, 0.85)) as Color)
	var rows: Array = SPRITES[kind]
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var filled := {}
	for y in mini(16, rows.size()):
		var row := String(rows[y]).rpad(16, ".")
		for x in 16:
			var c := _color(row[x], t)
			if c.a > 0.0:
				img.set_pixel(x, y, c)
				filled[Vector2i(x, y)] = true
	for p in filled.keys():
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q: Vector2i = p + d
			if q.x >= 0 and q.y >= 0 and q.x < 16 and q.y < 16 and not filled.has(q):
				img.set_pixel(q.x, q.y, Color(0.05, 0.04, 0.07))
	if size != 16:
		img.resize(size, size, Image.INTERPOLATE_NEAREST)
	return img
