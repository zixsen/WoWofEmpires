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
		if (request.method !== "POST") return page();
		const form = await request.formData();
		const word = String(form.get("word") || "").trim().toLowerCase().replace(/\s+/g, " ");
		const file = form.get("file");
		if (!env.PASSWORD || form.get("password") !== env.PASSWORD) return page("Fel lösenord.");
		// The whole chat message has to match the word. Letters needed: messages that are numbers play the taunts.
		if (!/^[a-z0-9]+( [a-z0-9]+)*$/.test(word) || !/[a-z]/.test(word) || word.length < 2 || word.length > 24) {
			return page("Ordet får bara ha a–z och 0–9 (inga å, ä eller ö), 2 till 24 tecken. Mellanslag mellan orden går bra.");
		}
		if (!(file instanceof File) || file.size === 0) return page("Välj en ljudfil.");
		if (file.size > MAX_BYTES) return page("Filen är större än 2 MB.");

		const github = (path, init = {}) => fetch(`https://api.github.com/repos/${REPO}/${path}`, {
			...init,
			headers: {
				Authorization: `Bearer ${env.GITHUB_TOKEN}`,
				"User-Agent": "woe-sound-uploader",
				Accept: "application/vnd.github+json",
				...init.headers,
			},
		});
		const core = await github(`contents/core.lua?ref=${BRANCH}`, { headers: { Accept: "application/vnd.github.raw" } });
		if (!core.ok) return page("Kunde inte nå GitHub. Försök igen om en stund.");
		if ((await core.text()).includes(`["${word}"]`)) return page(`"${word}" har redan ett ljud.`);

		const saved = await github(`contents/incoming/${encodeURIComponent(word)}`, {
			method: "PUT",
			body: JSON.stringify({ message: `Upload sound: ${word}`, content: base64(await file.arrayBuffer()), branch: BRANCH }),
		});
		if (saved.status === 422) return page(`Någon annan laddade precis upp "${word}".`); // the file already exists
		if (!saved.ok) return page("Kunde inte spara ljudet. Försök igen om en stund.");
		return page(`Klart! "${word}" kommer med i nästa WowUp-uppdatering, om några minuter.`, true);
	},
};

function base64(buffer) {
	const bytes = new Uint8Array(buffer);
	let text = "";
	for (let i = 0; i < bytes.length; i += 0x8000) text += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
	return btoa(text);
}

// Messages only ever contain the checked word (letters, digits, spaces), so they need no escaping.
function page(message = "", ok = false) {
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
`, { headers: { "content-type": "text/html; charset=utf-8" } });
}
