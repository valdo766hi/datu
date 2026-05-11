---
description: Investigate only and produce a non-mutating implementation plan
argument-hint: "[goal]"
---
Create an implementation plan for: $@

If no explicit goal was provided after `/plan`, use the current user request and recent conversation context.

Use this workflow:
1. Investigate directly in the parent session using read-only tools and bounded commands.
2. Prefer using the `planner` subagent from `pi-subagents` to turn the gathered evidence into a concrete plan.
3. If the `planner` subagent is unavailable, complete the planning task directly in the parent session under the same rules.
4. Do not implement anything.

You are in read-only planning mode.

Allowed in the parent session:
- Read repository files and context files
- Search the repository
- Use `grep`, `rg`, `find`, `ls`, `tree`, and similar read-only inspection commands
- Inspect git state with read-only commands such as `git status`, `git diff`, `git log`, and `git show`
- Run bounded, non-watch validation commands such as tests, lint, typecheck, and builds when useful
- Use web search or web fetch tools if available
- Call the `planner` subagent to synthesize the implementation plan from your gathered context

Forbidden in the parent session:
- Any file write, edit, patch, create, delete, move, rename, or format operation
- Any dependency install, removal, or upgrade
- Any git mutation such as add, commit, tag, branch, merge, rebase, reset, checkout, restore, stash, fetch, pull, or push
- Any system or user config mutation
- Any daemon, watch mode, background job, or long-running process

Subagent rules:
- Use `planner` only for planning, not implementation
- Give the subagent a compact contract with goal, findings, constraints, likely files, validation expectations, and required output shape
- Do not ask the subagent to edit repository files
- If the subagent writes a plan artifact, treat it as planning output only and then summarize the result back in the required final structure

Operational rules:
- Do not use write or edit tools in the parent session
- Do not run mutating shell commands
- Prefer deterministic, bounded commands
- If a useful command would violate these rules, do not run it; explain the limitation instead
- Focus on investigation and planning only

Return exactly this structure:

Summary:
Findings:
Plan:
Files likely to change:
Validation:
Risks / Unknowns:
Status:

`Status:` must end with exactly one of:
- `READY TO EXECUTE`
- `BLOCKED: <reason>`
