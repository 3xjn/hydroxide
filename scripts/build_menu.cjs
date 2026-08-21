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
const generatedRoot = path.join(uiRoot, ".generated");

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

function posixRelative(from, to) {
	return path.relative(from, to).split(path.sep).join("/");
}

function resolvePrismRoot() {
	const candidates = [
		process.env.PRISM_ROOT,
		path.join(generatedRoot, "prism"),
		path.resolve(repoRoot, "../prism"),
		path.resolve(repoRoot, "../../prism"),
		"C:/git/prism",
	].filter(Boolean);
	const rejected = [];
	for (const candidate of candidates) {
		const indexPath = path.join(candidate, "src", "lib", "index.ts");
		if (!fs.existsSync(indexPath)) continue;
		const required = [
			["src/lib/components/Popover/types.ts", "closeOnOutsidePress"],
			["src/lib/components/Input/types.ts", "placeholder"],
			["src/lib/components/Button/types.ts", "onPress"],
			["src/lib/components/ScrollArea/types.ts", "automaticCanvasSize"],
			["src/lib/components/Pressable/types.ts", "onPress"],
			["src/lib/components/Stack/types.ts", "direction"],
			["src/lib/theme/index.ts", "DEFAULT_DARK_THEME"],
		];
		const compatible = required.every(([relative, token]) => {
			const filePath = path.join(candidate, relative);
			return fs.existsSync(filePath) && fs.readFileSync(filePath, "utf8").includes(token);
		});
		if (compatible) return path.resolve(candidate);
		rejected.push(path.resolve(candidate));
	}
	fail(
		"Set PRISM_ROOT to a compatible Prism checkout containing Popover, Input, Button, ScrollArea, Pressable, Stack, and DEFAULT_DARK_THEME. Tried: " +
			candidates.join(", ") +
			(rejected.length > 0 ? `. Incompatible: ${rejected.join(", ")}` : ""),
	);
}

function gitHead(directory) {
	const result = spawnSync("git", ["-C", directory, "rev-parse", "HEAD"], {
		encoding: "utf8",
	});
	return result.status === 0 ? result.stdout.trim() : "unknown";
}

function writeJson(filePath, value) {
	fs.mkdirSync(path.dirname(filePath), { recursive: true });
	fs.writeFileSync(filePath, `${JSON.stringify(value, null, "\t")}\n`);
}

function ensureNpmPackage(directory, binaryName) {
	const binary = path.join(
		directory,
		"node_modules",
		".bin",
		process.platform === "win32" ? `${binaryName}.cmd` : binaryName,
	);
	if (!fs.existsSync(binary)) {
		run("npm", ["install"], directory);
	}
	if (!fs.existsSync(binary)) {
		fail(`npm install in ${directory} did not produce ${binaryName}`);
	}
	return binary;
}

function downloadWax(destination) {
	if (fs.existsSync(destination)) {
		return destination;
	}
	const url = "https://github.com/latte-soft/wax/releases/download/0.4.2/wax.luau";
	const result = spawnSync("curl", ["-fsSL", url, "-o", destination], {
		stdio: "inherit",
		shell: process.platform === "win32",
	});
	if (result.status !== 0 || !fs.existsSync(destination)) {
		fail(`Failed to download Wax 0.4.2 from ${url}. Set WAX_PATH to a local wax.luau.`);
	}
	return destination;
}

function prismHasWindow(prismRoot) {
	return fs.existsSync(path.join(prismRoot, "src", "lib", "components", "Window", "index.ts"));
}

function main() {
	const prismRoot = resolvePrismRoot();
	fs.mkdirSync(generatedRoot, { recursive: true });
	fs.mkdirSync(path.join(uiRoot, "dist"), { recursive: true });

	const windowAvailable = prismHasWindow(prismRoot);
	writeJson(path.join(generatedRoot, "prism-window.json"), {
		available: windowAvailable,
		// TODO(prism-window): when this is true, Hydroxide must mount Prism Window
		// and delete ui/window.lua. Do not compose Draggable+Box chrome.
	});

	const prismSourceRoot = path.join(generatedRoot, "prism-src");
	fs.rmSync(prismSourceRoot, { recursive: true, force: true });
	fs.cpSync(path.join(prismRoot, "src"), prismSourceRoot, { recursive: true });
	fs.rmSync(path.join(prismSourceRoot, "playground"), { recursive: true, force: true });
	const prismLib = posixRelative(path.join(uiRoot, "src"), path.join(prismSourceRoot, "lib"));
	writeJson(path.join(uiRoot, "tsconfig.prism.json"), {
		compilerOptions: {
			rootDirs: ["src", posixRelative(uiRoot, prismSourceRoot)],
			paths: {
				"@prism": ["prismCompat"],
				"@prism/*": [`${prismLib}/*`],
			},
		},
	});

	const rbxtsc = ensureNpmPackage(uiRoot, "rbxtsc");
	ensureNpmPackage(prismRoot, "rbxtsc");
	if (!fs.existsSync(path.join(prismRoot, "out", "lib"))) {
		run("npm", ["run", "build"], prismRoot);
	}
	run(rbxtsc, ["-p", uiRoot], uiRoot);

	const initPath = path.join(generatedRoot, "init.lua");
	fs.writeFileSync(initPath, "return require(script.ReplicatedStorage.HydroxideUi)\n");

	const includePath = path.join(uiRoot, "include");
	const rbxtsPath = path.join(uiRoot, "node_modules", "@rbxts");
	const rbxtsJsPath = path.join(uiRoot, "node_modules", "@rbxts-js");
	if (!fs.existsSync(includePath) || !fs.existsSync(rbxtsPath)) {
		fail("rbxtsc did not emit ui/include and node_modules/@rbxts");
	}

	writeJson(path.join(generatedRoot, "hydroxide.project.json"), {
		name: "HydroxidePrismBundle",
		tree: {
			$className: "ModuleScript",
			$path: "init.lua",
			ReplicatedStorage: {
				$className: "Folder",
				HydroxideUi: {
					$path: posixRelative(generatedRoot, path.join(uiRoot, "out")),
				},
				Prism: {
					$path: posixRelative(generatedRoot, path.join(prismRoot, "out", "lib")),
				},
				rbxts_include: {
					$path: posixRelative(generatedRoot, includePath),
					node_modules: {
						$className: "Folder",
						"@rbxts": {
							$path: posixRelative(generatedRoot, rbxtsPath),
						},
						"@rbxts-js": {
							$path: posixRelative(generatedRoot, rbxtsJsPath),
						},
					},
				},
			},
		},
	});

	const waxPath = process.env.WAX_PATH || downloadWax(path.join(generatedRoot, "wax.luau"));
	if (fs.existsSync(path.join(prismRoot, "rokit.toml"))) {
		run("rokit", ["install", "--no-trust-check"], prismRoot);
	}
	run(
		"lune",
		[
			"run",
			waxPath,
			"bundle",
			`input=${path.join(generatedRoot, "hydroxide.project.json")}`,
			`output=${distLua}`,
			"env-name=HydroxidePrismBundle",
		],
		repoRoot,
	);

	const bundled = fs.readFileSync(distLua, "utf8");
	if (bundled.includes('ReplicatedStorage:WaitForChild("Prism")')) {
		fail("Wax bundle includes Prism playground code that reads the live DataModel");
	}
	const virtualImports = bundled
		.replaceAll('game:GetService("ReplicatedStorage")', "wax.shared.ReplicatedStorage")
		.replace(
			/(for _, Object in next, ObjectTree do\r?\n\s*CreateRefFromObject\(Object, RealObjectRoot\)\r?\nend)/,
			"$1\nSharedEnvironment.ReplicatedStorage = RealObjectRoot:GetChildren()[1].ReplicatedStorage",
		);
	if (
		virtualImports.includes('game:GetService("ReplicatedStorage")') ||
		!virtualImports.includes(
			"SharedEnvironment.ReplicatedStorage = RealObjectRoot:GetChildren()[1].ReplicatedStorage",
		)
	) {
		fail("Wax bundle could not isolate roblox-ts imports in the virtual ReplicatedStorage");
	}
	const entrypoint =
		'local Menu = LoadScript(RealObjectRoot:GetChildren()[1].ReplicatedStorage.HydroxideUi.src)\nassert(type(Menu) == "table" and type(Menu.mountHydroxide) == "function", "Wax src entry did not return the Hydroxide Prism islands")\nreturn Menu';
	const entrypointPatched = virtualImports.replace(
		/return LoadScript\(RealObjectRoot:GetChildren\(\)\[1\]\)\s*$/,
		entrypoint,
	);
	if (!entrypointPatched.endsWith(entrypoint)) {
		fail("Wax bundle epilogue could not target the HydroxideUi entry module");
	}
	const schedulerPatched = entrypointPatched.replace(
		/local function wrapPerformWorkWithCoroutine\(performWork\)[\s\S]*?\nend\r?\nperformWorkUntilDeadline = wrapPerformWorkWithCoroutine/,
		"local function wrapPerformWorkWithCoroutine(performWork)\n\treturn performWork\nend\nperformWorkUntilDeadline = wrapPerformWorkWithCoroutine",
	);
	if (schedulerPatched === entrypointPatched) {
		fail("Wax bundle is missing wrapPerformWorkWithCoroutine; cannot keep Instance work on the executor thread");
	}
	fs.writeFileSync(distLua, schedulerPatched);

	const sha256 = crypto.createHash("sha256").update(fs.readFileSync(distLua)).digest("hex");
	fs.writeFileSync(
		provenancePath,
		[
			"artifact=ui/dist/Hydroxide.lua",
			`sha256=${sha256}`,
			"prism_repository=https://github.com/3xjn/prism",
			`prism_commit=${gitHead(prismRoot)}`,
			`prism_window=${windowAvailable ? "available" : "pending"}`,
			"bundler=https://github.com/latte-soft/wax",
			"bundler_version=0.4.2",
			"mount_parent=host",
			"source=ui/src",
			"",
		].join("\n"),
	);
	console.log(`wrote ${posixRelative(repoRoot, distLua)}`);
	if (!windowAvailable) {
		console.log("Prism Window is not on master yet; ui/window.lua remains a temporary host.");
	}
}

main();
