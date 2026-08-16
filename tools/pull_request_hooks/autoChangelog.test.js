import assert from "node:assert/strict";
import {
	changelogToYml,
	formatDiscordChangelog,
} from "./autoChangelog.js";
import { parseChangelog } from "./changelogParser.js";

const sample = parseChangelog(`
			My cool PR!
			:cl: DenverCoder9
			add: Adds new stuff
			add: Adds more stuff
			/:cl:
		`);

assert.equal(
	changelogToYml(sample),

	`author: "DenverCoder9"
delete-after: True
changes:
  - rscadd: "Adds new stuff"
  - rscadd: "Adds more stuff"`
);

assert.equal(
	formatDiscordChangelog(sample, "fallback", 42),
	`DenverCoder9:
* ✅: Adds new stuff
* ✅: Adds more stuff

(PR #42)`
);
