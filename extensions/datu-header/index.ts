import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { basename, dirname, join, relative } from "node:path";

type HeaderDetails = {
	model: string;
	prompt: string;
	context: string;
	skills: string;
	prompts: string;
	tools: string;
	extensions: string;
	themes: string;
};

const headerLines = [
	"██████╗  █████╗ ████████╗██╗   ██╗",
	"██╔══██╗██╔══██╗╚══██╔══╝██║   ██║",
	"██║  ██║███████║   ██║   ██║   ██║",
	"██║  ██║██╔══██║   ██║   ██║   ██║",
	"██████╔╝██║  ██║   ██║   ╚██████╔╝",
	"╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ",
];

const emptyDetails = (model = "no-model"): HeaderDetails => ({
	model,
	prompt: "default + append",
	context: summarizeContextFiles(process.cwd()),
	skills: "pending",
	prompts: "pending",
	tools: "pending",
	extensions: "pending",
	themes: effectiveThemeName(),
});

const countLabel = (count: number, singular: string, plural = `${singular}s`) => `${count} ${count === 1 ? singular : plural}`;

const itemName = (item: unknown): string => {
	if (typeof item === "string") return item;
	if (!item || typeof item !== "object") return "unknown";
	const record = item as Record<string, unknown>;
	for (const key of ["name", "id", "label", "filePath", "path"]) {
		const value = record[key];
		if (typeof value === "string" && value.length > 0) return value;
	}
	return "unknown";
};

const summarizeItems = (items: unknown, singular: string, maxNames = 3): string => {
	if (!Array.isArray(items)) return "0 " + `${singular}s`;
	const names = items.map(itemName).filter((name) => name !== "unknown");
	const count = items.length;
	if (count === 0) return countLabel(0, singular);
	const shown = names.slice(0, maxNames).join(", ");
	const extra = count > maxNames ? ` +${count - maxNames}` : "";
	return shown ? `${countLabel(count, singular)}: ${shown}${extra}` : countLabel(count, singular);
};

const summarizeNames = (names: string[], singular: string, maxNames = 3): string => {
	const count = names.length;
	if (count === 0) return countLabel(0, singular);
	const shown = names.slice(0, maxNames).join(", ");
	const extra = count > maxNames ? ` +${count - maxNames}` : "";
	return shown ? `${countLabel(count, singular)}: ${shown}${extra}` : countLabel(count, singular);
};

const displayPath = (filePath: string, cwd = process.cwd()): string => {
	const home = homedir();
	const relativePath = relative(cwd, filePath);
	if (relativePath && !relativePath.startsWith("..") && !relativePath.includes(`..${"/"}`)) return relativePath || basename(filePath);
	if (filePath.startsWith(`${home}/`)) return `~/${filePath.slice(home.length + 1)}`;
	return filePath;
};

const ancestorDirs = (start: string): string[] => {
	const dirs: string[] = [];
	let current = start;
	while (true) {
		dirs.push(current);
		const parent = dirname(current);
		if (parent === current) break;
		current = parent;
	}
	return dirs.reverse();
};

const contextFiles = (cwd: string): string[] => {
	if (process.argv.includes("--no-context-files") || process.argv.includes("-nc")) return [];
	const files: string[] = [];
	const add = (filePath: string) => {
		if (existsSync(filePath) && !files.includes(filePath)) files.push(filePath);
	};

	const agentDir = process.env.PI_CODING_AGENT_DIR || join(homedir(), ".pi", "agent");
	add(join(agentDir, "AGENTS.md"));
	add(join(agentDir, "CLAUDE.md"));
	for (const dir of ancestorDirs(cwd)) {
		add(join(dir, "AGENTS.md"));
		add(join(dir, "CLAUDE.md"));
	}

	return files;
};

const summarizeContextFiles = (cwd: string): string => summarizeNames(contextFiles(cwd).map((filePath) => displayPath(filePath, cwd)), "file");

const readJson = (filePath: string): Record<string, unknown> => {
	try {
		return JSON.parse(readFileSync(filePath, "utf8"));
	} catch {
		return {};
	}
};

const effectiveThemeName = (ctx?: any): string => {
	const activeTheme = ctx?.ui?.theme;
	for (const key of ["name", "id", "label"]) {
		const value = activeTheme?.[key];
		if (typeof value === "string" && value.length > 0) return value;
	}

	const settingsPaths = [
		join(process.env.PI_CODING_AGENT_DIR || join(homedir(), ".pi", "agent"), "settings.json"),
		join(process.cwd(), ".pi", "settings.json"),
		join(homedir(), ".pi", "agent", "settings.json"),
	];
	for (const settingsPath of settingsPaths) {
		const theme = readJson(settingsPath).theme;
		if (typeof theme === "string" && theme.length > 0) return theme;
	}

	return "datu";
};

const commandNames = (pi: ExtensionAPI, source: "extension" | "prompt" | "skill") => {
	try {
		return pi.getCommands()
			.filter((command) => command.source === source)
			.map((command) => command.name)
			.filter((name) => name.length > 0);
	} catch {
		return [];
	}
};

const summarizeTools = (pi: ExtensionAPI): string => {
	try {
		return summarizeItems(pi.getAllTools(), "tool");
	} catch {
		return "pending";
	}
};

const summarizePrompt = (options: Record<string, unknown>): string => {
	const parts: string[] = [];
	const customPrompt = options.customPrompt;
	const appendSystemPrompt = options.appendSystemPrompt;
	const promptGuidelines = options.promptGuidelines;

	parts.push(customPrompt ? "custom" : "default");
	if (typeof appendSystemPrompt === "string" && appendSystemPrompt.trim().length > 0) parts.push("append");
	if (Array.isArray(promptGuidelines) && promptGuidelines.length > 0) parts.push(countLabel(promptGuidelines.length, "guideline"));

	return parts.join(" + ");
};

const detailsFromOptions = (options: unknown, model: string): HeaderDetails => {
	const record = options && typeof options === "object" ? (options as Record<string, unknown>) : {};
	return {
		model,
		prompt: summarizePrompt(record),
		context: summarizeItems(record.contextFiles, "file"),
		skills: summarizeItems(record.skills, "skill"),
		prompts: "pending",
		tools: summarizeItems(record.selectedTools, "tool"),
		extensions: "pending",
		themes: "pending",
	};
};

const detailsFromRuntime = (pi: ExtensionAPI, ctx: any, previous: HeaderDetails): HeaderDetails => ({
	...previous,
	model: ctx.model?.id ?? "no-model",
	prompt: previous.prompt === "pending" ? "default + append" : previous.prompt,
	context: previous.context === "pending" ? summarizeContextFiles(ctx.cwd ?? process.cwd()) : previous.context,
	skills: summarizeNames(commandNames(pi, "skill"), "skill"),
	prompts: summarizeNames(commandNames(pi, "prompt"), "prompt"),
	tools: summarizeTools(pi),
	extensions: summarizeNames(commandNames(pi, "extension"), "extension command"),
	themes: effectiveThemeName(ctx),
});

const cell = (theme: any, color: string, text: string, width: number) => {
	const truncated = truncateToWidth(text, width);
	return theme.fg(color, truncated + " ".repeat(Math.max(0, width - visibleWidth(truncated))));
};

const renderTable = (theme: any, details: HeaderDetails, width: number): string[] => {
	const labelWidth = 10;
	const valueWidth = Math.max(8, width - labelWidth - 7);
	const line = (label: string, value: string) =>
		[
			theme.fg("borderMuted", "│ "),
			cell(theme, "muted", label, labelWidth),
			theme.fg("dim", " │ "),
			cell(theme, "text", value, valueWidth),
			theme.fg("borderMuted", " │"),
		].join("");

	const innerWidth = labelWidth + valueWidth + 3;
	return [
		theme.fg("borderAccent", `╭${"─".repeat(innerWidth + 2)}╮`),
		line("model", details.model),
		line("prompt", details.prompt),
		line("context", details.context),
		line("skills", details.skills),
		line("prompts", details.prompts),
		line("tools", details.tools),
		line("extensions", details.extensions),
		line("themes", details.themes),
		theme.fg("borderAccent", `╰${"─".repeat(innerWidth + 2)}╯`),
	];
};

const combineColumns = (left: string[], right: string[], width: number): string[] => {
	const gap = "  ";
	const leftWidth = Math.max(...left.map(visibleWidth));
	const rows = Math.max(left.length, right.length);
	const lines: string[] = [];

	for (let index = 0; index < rows; index++) {
		const leftLine = left[index] ?? "";
		const paddedLeft = leftLine + " ".repeat(Math.max(0, leftWidth - visibleWidth(leftLine)));
		lines.push(truncateToWidth(`${paddedLeft}${gap}${right[index] ?? ""}`, width));
	}

	return lines;
};

export default function (pi: ExtensionAPI) {
	let details = emptyDetails();
	let requestRender: (() => void) | undefined;

	pi.on("session_start", async (_event, ctx) => {
		if (!ctx.hasUI) return;

		details = detailsFromRuntime(pi, ctx, details);
		ctx.ui.setHeader((tui, theme) => {
			requestRender = () => tui.requestRender();

			return {
				invalidate() {},
				render(width: number): string[] {
					const narrow = width < 82;
					const artWidth = Math.min(36, width);
					const art = headerLines.map((line, index) => theme.fg(index === 1 ? "accent" : "borderAccent", truncateToWidth(line, artWidth)));
					const subtitle = [theme.fg("muted", "determinate"), theme.fg("dim", " ai "), theme.fg("accent", "agent")].join("");
					const banner = [...art, truncateToWidth(subtitle, artWidth)];

					if (narrow) return ["", ...banner.map((line) => truncateToWidth(line, width)), ""];

					const tableWidth = Math.max(34, width - artWidth - 2);
					const table = renderTable(theme, details, tableWidth);
					return ["", ...combineColumns(banner, table, width), ""];
				},
			};
		});

		setTimeout(() => {
			details = detailsFromRuntime(pi, ctx, details);
			requestRender?.();
		}, 0);
	});

	pi.on("resources_discover", async (_event, ctx) => {
		if (!ctx.hasUI) return;
		details = detailsFromRuntime(pi, ctx, details);
		requestRender?.();
	});

	pi.on("before_agent_start", async (event, ctx) => {
		details = detailsFromRuntime(pi, ctx, detailsFromOptions(event.systemPromptOptions, ctx.model?.id ?? "no-model"));
		requestRender?.();
	});

	pi.on("model_select", async (_event, ctx) => {
		details = detailsFromRuntime(pi, ctx, details);
		requestRender?.();
	});
}
