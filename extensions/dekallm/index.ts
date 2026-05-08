import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	pi.registerProvider("dekallm", {
		name: "DekaLLM",
		baseUrl: "https://dekallm.cloudeka.ai/v1",
		api: "openai-completions",
		apiKey: "DEKALLM_API_KEY",
		authHeader: true,
		models: [
			{
				id: "qwen/qwen3-coder",
				name: "Qwen3 Coder",
				reasoning: true,
				input: ["text"],
				cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
				contextWindow: 128000,
				maxTokens: 8192,
				compat: {
					thinkingFormat: "qwen",
				},
			},
			{
				id: "qwen/qwen25-vl-7b-instruct",
				name: "Qwen2.5 VL 7B Instruct",
				reasoning: false,
				input: ["text", "image"],
				cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
				contextWindow: 128000,
				maxTokens: 8192,
			},
			{
				id: "qwen/qwen25-72b-instruct",
				name: "Qwen2.5 72B Instruct",
				reasoning: false,
				input: ["text"],
				cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
				contextWindow: 128000,
				maxTokens: 8192,
			},
			{
				id: "qwen/qwen3-30b-a3b-instruct-2507",
				name: "Qwen3 30B A3B Instruct",
				reasoning: true,
				input: ["text"],
				cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
				contextWindow: 128000,
				maxTokens: 8192,
				compat: {
					thinkingFormat: "qwen",
				},
			},
			{
				id: "zai/glm-4.7-fp8",
				name: "ZAI GLM-4.7 FP8",
				reasoning: false,
				input: ["text"],
				cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
				contextWindow: 128000,
				maxTokens: 8192,
			},
		],
	});
}
