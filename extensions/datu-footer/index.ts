import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const thinkingColor = (level: string) => {
	switch (level) {
		case "minimal":
			return "muted";
		case "low":
			return "success";
		case "medium":
			return "warning";
		case "high":
			return "accent";
		case "xhigh":
			return "error";
		case "off":
		default:
			return "dim";
	}
};

export default function (pi: ExtensionAPI) {
	let turns = 0;
	let thinkingLevel = "off";
	let requestRender: (() => void) | undefined;

	pi.on("session_start", async (_event, ctx) => {
		if (!ctx.hasUI) return;

		thinkingLevel = pi.getThinkingLevel();
		const theme = ctx.ui.theme;
		ctx.ui.setStatus("datu", `${theme.fg("accent", "datu")} ${theme.fg("success", "ready")}`);

		ctx.ui.setFooter((tui, theme, footerData) => {
			requestRender = () => tui.requestRender();
			const unsubscribe = footerData.onBranchChange(() => tui.requestRender());

			return {
				dispose: unsubscribe,
				invalidate() {},
				render(width: number): string[] {
					let input = 0;
					let output = 0;
					let cost = 0;

					for (const entry of ctx.sessionManager.getBranch()) {
						if (entry.type === "message" && entry.message.role === "assistant") {
							const message = entry.message as AssistantMessage;
							input += message.usage.input;
							output += message.usage.output;
							cost += message.usage.cost.total;
						}
					}

					const totalTokens = input + output;
					const contextWindow = (ctx.model as any)?.contextWindow ?? null;
					const ctxPercent = contextWindow ? Math.round((totalTokens / contextWindow) * 100) : null;

					const branch = footerData.getGitBranch();
					const short = (value: number) => (value < 1000 ? `${value}` : `${(value / 1000).toFixed(1)}k`);
					const model = ctx.model?.id ?? "no-model";
					const cwd = process.cwd().replace(`${process.env.HOME}/`, "~/");

					const left = [
						theme.fg("accent", "datu"),
						theme.fg("dim", " | "),
						theme.fg("muted", cwd),
						branch ? theme.fg("dim", ` (${branch})`) : "",
						theme.fg("dim", " | "),
						theme.fg("success", `in ${short(input)}`),
						theme.fg("dim", " / "),
						theme.fg("warning", `out ${short(output)}`),
						theme.fg("dim", " / "),
						theme.fg("accent", `ctx ${ctxPercent ?? "?"}`),
						theme.fg("dim", "%"),
						theme.fg("dim", " / "),
						theme.fg("warning", `$${cost.toFixed(3)}`),
					].join("");

					const right = [
						theme.fg("muted", model),
						theme.fg("dim", " | "),
						theme.fg(thinkingColor(thinkingLevel), `thinking ${thinkingLevel}`),
						theme.fg("dim", " | "),
						theme.fg("accent", `turn ${turns}`),
					].join("");

					const gap = " ".repeat(Math.max(1, width - visibleWidth(left) - visibleWidth(right)));
					return [truncateToWidth(left + gap + right, width)];
				},
			};
		});
	});

	pi.on("turn_start", async (_event, ctx) => {
		if (!ctx.hasUI) return;
		turns += 1;
		thinkingLevel = pi.getThinkingLevel();
		const theme = ctx.ui.theme;
		ctx.ui.setStatus("datu", `${theme.fg("accent", "datu")} ${theme.fg("warning", `thinking ${turns}`)}`);
		requestRender?.();
	});

	pi.on("thinking_level_select", async (event, ctx) => {
		if (!ctx.hasUI) return;
		thinkingLevel = event.level;
		const theme = ctx.ui.theme;
		ctx.ui.setStatus("datu", `${theme.fg("accent", "datu")} ${theme.fg(thinkingColor(thinkingLevel), `thinking ${thinkingLevel}`)}`);
		requestRender?.();
	});

	pi.on("turn_end", async (_event, ctx) => {
		if (!ctx.hasUI) return;
		const theme = ctx.ui.theme;
		ctx.ui.setStatus("datu", `${theme.fg("accent", "datu")} ${theme.fg("success", `done ${turns}`)}`);
		requestRender?.();
	});
}
