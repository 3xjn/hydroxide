#!/usr/bin/env node
import { mkdirSync, existsSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const uiRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const repoRoot = dirname(uiRoot);
const distLua = join(uiRoot, "dist", "Hydroxide.lua");
const projectPath = join(uiRoot, "default.project.json");
const outDir = join(uiRoot, "out");
const cacheRoot = join(
	process.env.XDG_CACHE_HOME || process.env.TMPDIR || "/tmp",
	"hydroxide",
	"wax",
);
const waxVersion = "0.4.2";
const waxUrl = `https://github.com/latte-soft/wax/releases/download/${waxVersion}/wax.luau`;

function fail(message) {
	console.error(message);
	process.exit(1);
}

function withRokitPath() {
	const rokitBin = join(homedir(), ".rokit", "bin");
	return existsSync(rokitBin) ? `${rokitBin}:${process.env.PATH || ""}` : process.env.PATH;
}

function run(command, args, cwd) {
	const result = spawnSync(command, args, {
		cwd,
		stdio: "inherit",
		env: { ...process.env, PATH: withRokitPath() },
		shell: process.platform === "win32",
	});
	if (result.status !== 0) {
		fail(`${command} ${args.join(" ")} failed`);
	}
}

function resolveWax() {
	if (process.env.WAX_PATH) {
		return process.env.WAX_PATH;
	}
	mkdirSync(cacheRoot, { recursive: true });
	const destination = join(cacheRoot, `wax-${waxVersion}.luau`);
	if (existsSync(destination)) {
		return destination;
	}
	run("curl", ["-fsSL", waxUrl, "-o", destination], repoRoot);
	if (!existsSync(destination)) {
		fail(`Failed to download Wax ${waxVersion} from ${waxUrl}. Set WAX_PATH to a local wax.luau.`);
	}
	return destination;
}

function main() {
	if (
		!existsSync(join(outDir, "init.luau")) &&
		!existsSync(join(outDir, "init.lua")) &&
		!existsSync(join(outDir, "index.lua"))
	) {
		fail("ui/out is missing. rbxtsc must run before the executor bundle.");
	}
	if (!existsSync(projectPath)) {
		fail("ui/default.project.json is required to bundle the rbxtsc emit.");
	}

	mkdirSync(join(uiRoot, "dist"), { recursive: true });
	const waxPath = resolveWax();
	run(
		"lune",
		["run", waxPath, "bundle", `input=${projectPath}`, `output=${distLua}`, "env-name=HydroxidePrismBundle"],
		repoRoot,
	);

	const bundled = readFileSync(distLua, "utf8");
	if (!bundled.includes("mountHydroxide")) {
		fail("Wax output is missing mountHydroxide; the GitHub import() entry is not loadable.");
	}
	writeFileSync(distLua, bundled);
	console.log("wrote ui/dist/Hydroxide.lua");
}

main();
