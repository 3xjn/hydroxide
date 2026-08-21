#!/usr/bin/env node
"use strict";

const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");

const repoRoot = path.resolve(__dirname, "..");
const uiRoot = path.join(repoRoot, "ui");
const distLua = path.join(uiRoot, "dist", "Hydroxide.lua");
const provenancePath = path.join(uiRoot, "dist", "Hydroxide.provenance");
const projectPath = path.join(uiRoot, "default.project.json");
const outDir = path.join(uiRoot, "out");
const cacheRoot = path.join(
	process.env.XDG_CACHE_HOME || process.env.LOCALAPPDATA || process.env.TMPDIR || "/tmp",
	"hydroxide",
	"wax",
);

function fail(message) {
	console.error(message);
	process.exit(1);
}

function run(command, args, cwd) {
	const result = spawnSync(command, args, {
		cwd,
		stdio: "inherit",
		shell: process.platform === "win32",
	});
	if (result.status !== 0) {
		fail(`${command} ${args.join(" ")} failed`);
	}
}

function gitHead(directory) {
	const result = spawnSync("git", ["-C", directory, "rev-parse", "HEAD"], {
		encoding: "utf8",
	});
	return result.status === 0 ? result.stdout.trim() : "unknown";
}

function resolveWax() {
	if (process.env.WAX_PATH) {
		return process.env.WAX_PATH;
	}
	fs.mkdirSync(cacheRoot, { recursive: true });
	const destination = path.join(cacheRoot, "wax-0.4.2.luau");
	if (fs.existsSync(destination)) {
		return destination;
	}
	const url = "https://github.com/latte-soft/wax/releases/download/0.4.2/wax.luau";
	run("curl", ["-fsSL", url, "-o", destination], repoRoot);
	if (!fs.existsSync(destination)) {
		fail(`Failed to download Wax 0.4.2 from ${url}. Set WAX_PATH to a local wax.luau.`);
	}
	return destination;
}

function main() {
	if (!fs.existsSync(path.join(outDir, "init.luau")) && !fs.existsSync(path.join(outDir, "index.lua")) && !fs.existsSync(path.join(outDir, "src", "index.lua"))) {
		fail("ui/out is missing. Run npm run build (rbxtsc) in ui/ first.");
	}
	if (!fs.existsSync(projectPath)) {
		fail("ui/default.project.json is required for the optional Wax bundle.");
	}

	fs.mkdirSync(path.join(uiRoot, "dist"), { recursive: true });
	const waxPath = resolveWax();
	run(
		"lune",
		["run", waxPath, "bundle", `input=${projectPath}`, `output=${distLua}`, "env-name=HydroxidePrismBundle"],
		repoRoot,
	);

	let bundled = fs.readFileSync(distLua, "utf8");
	bundled = bundled.replaceAll('game:GetService("ReplicatedStorage")', "wax.shared.ReplicatedStorage");
	bundled = bundled.replace(
		/(for _, Object in next, ObjectTree do\r?\n\s*CreateRefFromObject\(Object, RealObjectRoot\)\r?\nend)/,
		"$1\nSharedEnvironment.ReplicatedStorage = RealObjectRoot:GetChildren()[1].ReplicatedStorage",
	);
	if (
		bundled.includes('game:GetService("ReplicatedStorage")') ||
		!bundled.includes("SharedEnvironment.ReplicatedStorage = RealObjectRoot:GetChildren()[1].ReplicatedStorage")
	) {
		fail("Wax bundle could not isolate roblox-ts imports in the virtual ReplicatedStorage");
	}

	const schedulerPatched = bundled.replace(
		/local function wrapPerformWorkWithCoroutine\(performWork\)[\s\S]*?\nend\r?\nperformWorkUntilDeadline = wrapPerformWorkWithCoroutine/,
		"local function wrapPerformWorkWithCoroutine(performWork)\n\treturn performWork\nend\nperformWorkUntilDeadline = wrapPerformWorkWithCoroutine",
	);
	if (schedulerPatched === bundled) {
		fail("Wax bundle is missing wrapPerformWorkWithCoroutine; cannot keep Instance work on the executor thread");
	}

	const entrypoint =
		'local Menu = LoadScript(RealObjectRoot:GetChildren()[1].ReplicatedStorage.HydroxideUi)\nassert(type(Menu) == "table" and type(Menu.mountHydroxide) == "function", "Wax entry did not return the Hydroxide Prism islands")\nreturn Menu\n';
	const output = schedulerPatched.replace(
		/return LoadScript\(RealObjectRoot:GetChildren\(\)\[1\]\)\s*$/,
		entrypoint,
	);
	if (!output.includes("Hydroxide Prism islands")) {
		fail("Wax bundle epilogue could not target the HydroxideUi entry module");
	}

	fs.writeFileSync(distLua, output);

	const prismRoot = path.join(uiRoot, ".prism");
	const sha256 = crypto.createHash("sha256").update(fs.readFileSync(distLua)).digest("hex");
	fs.writeFileSync(
		provenancePath,
		[
			"artifact=ui/dist/Hydroxide.lua",
			`sha256=${sha256}`,
			"prism_repository=https://github.com/3xjn/prism",
			`prism_commit=${gitHead(prismRoot)}`,
			`prism_window=${fs.existsSync(path.join(prismRoot, "src/lib/components/Window/index.ts")) ? "available" : "pending"}`,
			"bundler=https://github.com/latte-soft/wax",
			"bundler_version=0.4.2",
			"mount_parent=host",
			"source=ui/src",
			"",
		].join("\n"),
	);
	console.log("wrote ui/dist/Hydroxide.lua");
}

main();
