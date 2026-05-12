{
  agentOverrides = {
    worker = {
      model = "openai-codex/gpt-5.3-codex";
      thinking = "medium";
      fallbackModels = false;
    };
    reviewer = {
      model = "openai-codex/gpt-5.4-mini";
      thinking = "medium";
      fallbackModels = false;
    };
    oracle = {
      model = "openai-codex/gpt-5.5";
      thinking = "high";
      fallbackModels = false;
    };
    planner = {
      model = "openai-codex/gpt-5.4";
      thinking = "high";
      fallbackModels = false;
    };
    scout = {
      model = "openai-codex/gpt-5.4-mini";
      thinking = "low";
      fallbackModels = false;
    };
    researcher = {
      model = "openai-codex/gpt-5.4-mini";
      thinking = "low";
      fallbackModels = false;
    };
    context-builder = {
      model = "openai-codex/gpt-5.4-mini";
      thinking = "low";
      fallbackModels = false;
    };
    delegate = {
      model = "openai-codex/gpt-5.4-mini";
      thinking = "low";
      fallbackModels = false;
    };
  };
}
