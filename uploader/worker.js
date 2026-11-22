// Sound uploader for WoW of Empires, a Cloudflare Worker: a page (in Swedish) where friends upload a
// sound and the chat word that plays it. The Worker saves the file as incoming/<word> in the repo; the
// "Add sounds" GitHub Action (.github/workflows/sounds.yml) then converts it, adds it to the addon and
// publishes a release that WowUp picks up.
//
// Set up in the Worker's Settings > Variables and Secrets, both as secrets:
//   PASSWORD      the password you give your friends
//   GITHUB_TOKEN  a fine-grained token for this repo only, with Contents: Read and write
const REPO = "zixsen/WoWofEmpires";
const BRANCH = "forever-port";
const MAX_BYTES = 2 * 1024 * 1024;

export default {
	async fetch(request, env) {
		const github = (path, init = {}) => fetch(`https://api.github.com/repos/${REPO}/${path}`, {
			...init,
			headers: {
				Authorization: `Bearer ${env.GITHUB_TOKEN}`,
				"User-Agent": "woe-sound-uploader",
				Accept: "application/vnd.github+json",
				...init.headers,
			},
		});
		const raw = { headers: { Accept: "application/vnd.github.raw" } };
		const path = new URL(request.url).pathname;

		// An upload's password is checked before anything reaches GitHub, so wrong guesses can't use up
		// the token's rate limit. The page for a wrong one goes without the sound list for that reason.
		let form;
		if (request.method === "POST" && !path.startsWith("/ljud/")) {
			form = await request.formData();
			if (!env.PASSWORD || form.get("password") !== env.PASSWORD) return page("Fel lösenord.");
		}

		// The sounds there already, for the list on the page, its play buttons and the "taken" check.
		const core = await github(`contents/core.lua?ref=${BRANCH}`, raw);
		const sounds = core.ok ? Sounds(await core.text()) : null;
		const reply = (message, ok) => page(message, ok, sounds);

		// /ljud/<file>: a listed sound, for its play button. Served from here: GitHub's own file links
		// can be blocked by browsers when another site plays them.
		if (path.startsWith("/ljud/")) {
			let name = "";
			try { name = decodeURIComponent(path.slice("/ljud/".length)); } catch {}
			if (!sounds?.some((s) => s.file === name)) return new Response("Finns inte", { status: 404 });
			const audio = await github(`contents/sound/${encodeURIComponent(name)}?ref=${BRANCH}`, raw);
			if (!audio.ok) return new Response("Kunde inte hämta ljudet", { status: 502 });
			return new Response(audio.body, {
				headers: { "content-type": name.endsWith(".ogg") ? "audio/ogg" : "audio/mpeg", "cache-control": "public, max-age=3600" },
			});
		}
		if (!form) return reply();

		const word = String(form.get("word") || "").trim().toLowerCase().replace(/\s+/g, " ");
		const file = form.get("file");
		// The whole chat message has to match the word. Letters needed: messages that are numbers play the taunts.
		if (!/^[a-z0-9]+( [a-z0-9]+)*$/.test(word) || !/[a-z]/.test(word) || word.length < 2 || word.length > 24) {
			return reply("Ordet får bara ha a–z och 0–9 (inga å, ä eller ö), 2 till 24 tecken. Mellanslag mellan orden går bra.");
		}
		if (!(file instanceof File) || file.size === 0) return reply("Välj en ljudfil.");
		if (file.size > MAX_BYTES) return reply("Filen är större än 2 MB.");
		if (!sounds) return reply("Kunde inte nå GitHub. Försök igen om en stund.");
		if (sounds.some((s) => s.word === word)) return reply(`"${word}" har redan ett ljud.`);

		const saved = await github(`contents/incoming/${encodeURIComponent(word)}`, {
			method: "PUT",
			body: JSON.stringify({ message: `Upload sound: ${word}`, content: base64(await file.arrayBuffer()), branch: BRANCH }),
		});
		if (saved.status === 422) return reply(`Någon annan laddade precis upp "${word}".`); // the file already exists
		if (!saved.ok) return reply("Kunde inte spara ljudet. Försök igen om en stund.");
		return reply(`Klart! "${word}" kommer med i nästa WowUp-uppdatering, om några minuter.`, true);
	},
};

// ns.words in core.lua as [{ word, file }], sorted by word.
function Sounds(coreLua) {
	const table = coreLua.match(/^ns\.words = \{([^]*?)^\}/m);
	if (!table) return [];
	return [...table[1].matchAll(/\["([^"]+)"\]\s*=\s*"([^"]+)"/g)]
		.map((m) => ({ word: m[1], file: m[2] }))
		.sort((a, b) => a.word.localeCompare(b.word, "sv"));
}

function escape(text) {
	return text.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);
}

function base64(buffer) {
	const bytes = new Uint8Array(buffer);
	let text = "";
	for (let i = 0; i < bytes.length; i += 0x8000) text += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
	return btoa(text);
}

// Messages only ever contain the checked word (letters, digits, spaces), so they need no escaping;
// the list's words and file names come from core.lua and are escaped.
function page(message = "", ok = false, sounds = null) {
	const list = sounds?.length ? `
<h2>Ljud som redan finns (${sounds.length})</h2>
<ul class="sounds">
${sounds.map((s) => `	<li><button type="button" data-src="ljud/${encodeURIComponent(s.file)}" aria-label="Spela ${escape(s.word)}">▶</button> ${escape(s.word)}</li>`).join("\n")}
</ul>
<script>
	let playing;
	document.querySelector(".sounds").addEventListener("click", (event) => {
		const button = event.target.closest("button");
		if (!button) return;
		playing?.pause();
		playing = new Audio(button.dataset.src);
		playing.play();
	});
</script>` : "";
	return new Response(`<!doctype html>
<html lang="sv">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>WoW of Empires ljud</title>
<style>
	:root { color-scheme: light dark; --ok: #2e7d32; --bad: #c62828; }
	body { font: 16px/1.5 system-ui, sans-serif; max-width: 30em; margin: 2em auto; padding: 0 16px; }
	label { display: block; margin: 1.2em 0 0.3em; font-weight: 600; }
	input { font: inherit; width: 100%; box-sizing: border-box; padding: 0.4em; }
	button { font: inherit; margin-top: 1.6em; padding: 0.5em 1.6em; }
	.message { padding: 0.6em 0.8em; border-left: 4px solid var(--${ok ? "ok" : "bad"}); }
	.hint { opacity: 0.75; font-size: 0.9em; }
	h2 { margin-top: 2em; font-size: 1.2em; }
	.sounds { list-style: none; padding: 0; display: grid; grid-template-columns: repeat(auto-fill, minmax(9em, 1fr)); gap: 0.4em 1em; }
	.sounds li { overflow-wrap: anywhere; }
	.sounds button { margin: 0 0.3em 0 0; padding: 0.1em 0.55em; }
</style>
<h1>Lägg till ett ljud i WoW of Empires</h1>
<p>Skriv ordet i party, raid, guild, say eller whisper så hör alla som har addonen ljudet.
Ljuden klipps till 10 sekunder och volymen jämnas ut.</p>
${message ? `<p class="message">${message}</p>` : ""}
<form method="post" enctype="multipart/form-data">
	<label for="file">Ljudfil</label>
	<input id="file" type="file" name="file" accept="audio/*,.mp3,.ogg,.wav,.m4a" required>
	<div class="hint">mp3, ogg, wav eller m4a, högst 2 MB</div>
	<label for="word">Ord i chatten</label>
	<input id="word" name="word" maxlength="24" autocomplete="off" required>
	<div class="hint">Hela chattmeddelandet måste vara just det här ordet, som "bruh" eller "fake news". Bara a–z och 0–9, inga å, ä eller ö.</div>
	<label for="password">Lösenord</label>
	<input id="password" type="password" name="password" required>
	<button>Ladda upp</button>
</form>
${list}
`, { headers: { "content-type": "text/html; charset=utf-8" } });
}
