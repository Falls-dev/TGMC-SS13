import { parseChangelog } from "./changelogParser.js";

const DISCORD_MESSAGE_LIMIT = 2000;

/** Same emoji map as tools/ss13_discord_changelog.py (changelogKey → emoji). */
const PREFIX_EMOJI = {
	rscadd: "✅",
	add: "✅",
	rscdel: "❌",
	del: "❌",
	qol: "❇️",
	balance: "⚖️",
	bugfix: "♿",
	fix: "♿",
	sound: "🔊",
	soundadd: "🔊",
	sounddel: "🔇",
	image: "🖼️",
	imageadd: "📥",
	imagedel: "📤",
	expansion: "🗺️",
	map: "🗺️",
	spellcheck: "📋",
	typo: "🖥️",
	code_imp: "💻",
	code: "🛜",
	refactor: "♻️",
	config: "🧰",
	admin: "🛡️",
	server: "💾",
	wip: "☢️",
	experiment: "⚠️",
};

const safeYml = (string) =>
	string.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\n/g, "\\n");

export function changelogToYml(changelog, login) {
	const author = changelog.author || login;
	const ymlLines = [];

	ymlLines.push(`author: "${safeYml(author)}"`);
	ymlLines.push(`delete-after: True`);
	ymlLines.push(`changes:`);

	for (const change of changelog.changes) {
		ymlLines.push(
			`  - ${change.type.changelogKey}: "${safeYml(change.description)}"`
		);
	}

	return ymlLines.join("\n");
}

/**
 * Format a parsed :cl: block for Discord webhook content.
 * Example:
 *   Author:
 *   * ✅: added stuff
 */
export function formatDiscordChangelog(changelog, login, prNumber) {
	const author = changelog.author || login || "Unknown";
	const lines = [`${author}:`];

	for (const change of changelog.changes) {
		const key = change.type.changelogKey;
		const emoji = PREFIX_EMOJI[key] || "📝";
		const text = String(change.description)
			.replaceAll("@everyone", "(@everyone)")
			.replaceAll("@here", "(@here)");
		lines.push(`* ${emoji}: ${text}`);
	}

	if (prNumber) {
		lines.push("");
		lines.push(`(PR #${prNumber})`);
	}

	return lines.join("\n").trim();
}

function splitDiscordMessages(text, limit = DISCORD_MESSAGE_LIMIT) {
	if (text.length <= limit) {
		return [text];
	}

	const chunks = [];
	let current = [];
	let currentLen = 0;

	for (const line of text.split("\n")) {
		const lineLen = line.length + (current.length ? 1 : 0);
		if (line.length > limit) {
			if (current.length) {
				chunks.push(current.join("\n"));
				current = [];
				currentLen = 0;
			}
			for (let i = 0; i < line.length; i += limit) {
				chunks.push(line.slice(i, i + limit));
			}
			continue;
		}
		if (currentLen + lineLen > limit && current.length) {
			chunks.push(current.join("\n"));
			current = [line];
			currentLen = line.length;
		} else {
			current.push(line);
			currentLen += lineLen;
		}
	}

	if (current.length) {
		chunks.push(current.join("\n"));
	}

	return chunks;
}

/**
 * Post changelog text to a Discord webhook. Never throws — logs and returns false on failure.
 */
export async function postChangelogToDiscord(webhookUrl, content) {
	if (!webhookUrl) {
		console.log("CHANGELOG_DISCORD_HOOK empty; skipping Discord post.");
		return false;
	}

	const messages = splitDiscordMessages(content);
	console.log(`Posting changelog to Discord (${messages.length} message(s))...`);

	for (let index = 0; index < messages.length; index++) {
		const response = await fetch(webhookUrl, {
			method: "POST",
			headers: {
				"Content-Type": "application/json",
				"User-Agent": "TGMC-autoChangelog-discord",
			},
			body: JSON.stringify({ content: messages[index] }),
		});

		if (!response.ok) {
			const body = await response.text().catch(() => "");
			console.error(
				`Discord webhook failed: HTTP ${response.status} ${response.statusText}`,
				body
			);
			return false;
		}

		console.log(
			`Posted Discord message ${index + 1}/${messages.length} (HTTP ${response.status}).`
		);

		if (index < messages.length - 1) {
			await new Promise((resolve) => setTimeout(resolve, 600));
		}
	}

	return true;
}

export async function processAutoChangelog({ github, context }) {
	const pullRequest = context.payload.pull_request;
	const changelog = parseChangelog(pullRequest.body);
	if (!changelog || changelog.changes.length === 0) {
		console.log("no changelog found");
		return;
	}

	const login = pullRequest.user.login;
	const prNumber = pullRequest.number;
	const yml = changelogToYml(changelog, login);
	const path = `html/changelogs/AutoChangeLog-pr-${prNumber}.yml`;

	// Post to Discord first (from the same :cl: parse). Failures must not block YAML commit.
	const webhookUrl = (process.env.CHANGELOG_DISCORD_HOOK || "").trim();
	try {
		const discordBody = formatDiscordChangelog(changelog, login, prNumber);
		await postChangelogToDiscord(webhookUrl, discordBody);
	} catch (error) {
		console.error("Discord changelog post threw:", error);
	}

	let sha;
	try {
		const existing = await github.rest.repos.getContent({
			owner: context.repo.owner,
			repo: context.repo.repo,
			path,
		});
		if (!Array.isArray(existing.data) && existing.data.sha) {
			sha = existing.data.sha;
		}
	} catch (error) {
		if (error.status !== 404) {
			throw error;
		}
	}

	await github.rest.repos.createOrUpdateFileContents({
		owner: context.repo.owner,
		repo: context.repo.repo,
		path,
		message: `Automatic changelog for PR #${prNumber} [ci skip]`,
		content: Buffer.from(yml).toString("base64"),
		...(sha ? { sha } : {}),
	});

	console.log(`Wrote ${path}`);
}
