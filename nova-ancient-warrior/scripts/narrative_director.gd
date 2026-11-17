extends RefCounted
## Original, localization-ready story beats for the three-chapter campaign.
## Dialogue is kept as data so scenes can be authored and translated independently.

static func chapter_dialogue(chapter: int) -> Array[Dictionary]:
	match clampi(chapter, 1, 3):
		1:
			return [
				{"speaker": "THE WAYFINDER", "text": "The temple sank to hide the first seal.", "text_ar": "غرق المعبد ليخفي الختم الأول."},
				{"speaker": "NOVA", "text": "Then I will bring its secret back to the light.", "text_ar": "إذن سأعيد سره إلى النور."},
				{"speaker": "THE WAYFINDER", "text": "The Ash Titan guards the drowned passage. The seal order is two, one, three. Watch the ground; the old stones still remember war.", "text_ar": "يحرس عملاق الرماد الممر الغارق. ترتيب الأختام: اثنان، ثم واحد، ثم ثلاثة. احذر الأرض؛ فالأحجار القديمة ما زالت تتذكر الحرب."}
			]
		2:
			return [
				{"speaker": "THE WAYFINDER", "text": "The second seal burns beyond the causeway.", "text_ar": "الختم الثاني يحترق خلف الجسر البركاني."},
				{"speaker": "NOVA", "text": "Fire can break stone. It cannot break my oath.", "text_ar": "النار قد تكسر الحجر، لكنها لن تكسر عهدي."},
				{"speaker": "THE WAYFINDER", "text": "The Warlord strikes hard and controls the distance. Follow the seal order: three, one, two. Read the warning, then punish the recovery.", "text_ar": "قائد الحرب يضرب بقوة ويتحكم في المسافة. ترتيب الأختام: ثلاثة، ثم واحد، ثم اثنان. راقب إشارة الهجوم ثم استغل لحظة التعافي."}
			]
		_:
			return [
				{"speaker": "THE WAYFINDER", "text": "The final seal waits beneath the Obsidian Throne.", "text_ar": "الختم الأخير ينتظرك تحت العرش الأسود."},
				{"speaker": "NOVA", "text": "Three seals. One truth. No more kingdoms buried in silence.", "text_ar": "ثلاثة أختام وحقيقة واحدة. لن تُدفن ممالك أخرى في الصمت."},
				{"speaker": "THE WAYFINDER", "text": "The Sovereign changes its rhythm as it weakens. The final seal order is one, three, two. Stay mobile, keep your guard, and strike only when the throne falls quiet.", "text_ar": "يتغير إيقاع الحاكم كلما ضعف. ترتيب الأختام الأخير: واحد، ثم ثلاثة، ثم اثنان. تحرك باستمرار، وحافظ على دفاعك، واضرب حين يصمت العرش."}
			]


static func boss_dialogue(boss_kind: String) -> Array[Dictionary]:
	match boss_kind:
		"ember_warlord":
			return [
				{"speaker": "THE EMBER WARLORD", "text": "Kneel. The causeway consumes every challenger.", "text_ar": "اركع. هذا الجسر يلتهم كل من يتحداني."},
				{"speaker": "NOVA", "text": "Then let it witness who walks through the flame.", "text_ar": "فليرَ إذن من يعبر اللهيب."}
			]
		"obsidian_sovereign":
			return [
				{"speaker": "THE OBSIDIAN SOVEREIGN", "text": "The seals were chains. I was the lock.", "text_ar": "كانت الأختام قيوداً، وكنت أنا القفل."},
				{"speaker": "NOVA", "text": "Your silence ends here.", "text_ar": "ينتهي صمتك هنا."}
			]
		_:
			return [
				{"speaker": "THE ASH TITAN", "text": "The drowned dead are mine. Turn back.", "text_ar": "الموتى الغارقون لي. عُد من حيث أتيت."},
				{"speaker": "NOVA", "text": "I came for the seal. I leave with the truth.", "text_ar": "أتيت من أجل الختم، وسأرحل بالحقيقة."}
			]
