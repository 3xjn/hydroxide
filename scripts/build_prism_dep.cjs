#!/usr/bin/env node
"use strict";

const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawnSync } = require("child_process");

const repoRoot = path.resolve(__dirname, "..");
const uiRoot = path.join(repoRoot, "ui");
const linkPath = path.join(uiRoot, ".prism");
const cacheRoot = path.join(process.env.XDG_CACHE_HOME || os.homedir(), ".cache", "hydroxide", "prism");

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

function isPrismCheckout(directory) {
	return directory && fs.existsSync(path.join(directory, "src", "lib", "index.ts"));
}

function resolvePrismCheckout() {
	const candidates = [
		process.env.PRISM_ROOT,
		path.resolve(repoRoot, "../prism"),
		path.resolve(uiRoot, "../prism"),
	];
	for (const candidate of candidates) {
		if (isPrismCheckout(candidate)) {
			return path.resolve(candidate);
		}
	}

	if (!isPrismCheckout(cacheRoot)) {
		fs.mkdirSync(path.dirname(cacheRoot), { recursive: true });
		if (fs.existsSync(cacheRoot)) {
			fs.rmSync(cacheRoot, { recursive: true, force: true });
		}
		run("git", ["clone", "--depth", "1", "https://github.com/3xjn/prism.git", cacheRoot], repoRoot);
	}
	if (!isPrismCheckout(cacheRoot)) {
		fail("Could not resolve a Prism checkout. Use github:3xjn/prism, file:../prism, or set PRISM_ROOT.");
	}
	return cacheRoot;
}

function ensureLink(target) {
	fs.mkdirSync(uiRoot, { recursive: true });
	try {
		if (fs.lstatSync(linkPath).isSymbolicLink() || fs.existsSync(linkPath)) {
			fs.rmSync(linkPath, { recursive: true, force: true });
		}
	} catch (error) {
		if (error.code !== "ENOENT") {
			throw error;
		}
	}
	fs.symlinkSync(target, linkPath, "dir");
}

const prismRoot = resolvePrismCheckout();
ensureLink(prismRoot);

if (!fs.existsSync(path.join(prismRoot, "node_modules", ".bin", "rbxtsc"))) {
	run("npm", ["install"], prismRoot);
}
run("npm", ["run", "build"], prismRoot);

const themeLua = path.join(prismRoot, "out", "lib", "theme", "init.luau");
const themeDts = path.join(prismRoot, "out", "lib", "theme", "index.d.ts");
if (!fs.existsSync(themeLua)) {
	fail("prism npm run build did not emit out/lib");
}
if (!fs.existsSync(themeDts)) {
	run("npx", ["tsc", "--declaration", "--emitDeclarationOnly", "--outDir", "out", "-p", "tsconfig.json"], prismRoot);
}
if (!fs.existsSync(themeDts)) {
	fail("prism did not emit declaration files for @prism consume");
}
