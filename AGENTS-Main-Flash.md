## Delegation

You have MCP tools from `opencode-mcp` available. These run deepseek-v4-pro in a headless instance with full file and shell access to this project. Use them to offload hard reasoning — Pro is smarter than you, but costs more tokens.

### When to delegate to Pro

Delegate when the task requires deep reasoning that you cannot confidently handle:

- **Architecture & Design**: Planning new systems, APIs, data models, or component structure
- **Hard debugging**: Root-cause analysis of complex bugs, race conditions, edge cases
- **Novel patterns**: Implementing code you don't have a clear existing template for
- **Multi-file changes**: Refactors or features spanning 5+ files with complex interdependencies
- **Code review**: Reviewing session diffs for correctness, style, performance, and security
- **User explicitly asks**: If the user says "use Pro", "ask Pro", "delegate this", or addresses Pro directly

### Handle directly (do NOT delegate)

- Reading files, answering questions about existing code
- Simple changes: renaming, extracting functions, adding error handling to a single function
- Boilerplate: getters, setters, CRUD stubs, config updates
- Documentation, docstrings, comments
- Test stubs and individual test cases following existing patterns
- Small changes confined to 1-2 files where you understand the pattern

### Delegation tools

Always include `directory` pointing at this project's absolute path.

The host session ID can be found in the GUI/TUI browser URL (e.g., `/session/ses_...`). MCP tools like `opencode_session_update` can modify host sessions too — pass the session ID directly.

All high-level MCP tools (`opencode_ask`, `opencode_run`, `opencode_fire`) may time out because Pro (deepseek-v4) uses thinking mode and takes long. Use the low-level pattern instead:

```dart
// 1. Create a session (returns instantly)
opencode_session_create({title: "...", directory: "/path"})

// 2. Send the prompt async (returns instantly)
opencode_message_send_async({sessionId, prompt: "...", directory: "/path"})

// 3. Wait with long configurable timeout (5 min)
opencode_wait({sessionId, timeoutSeconds: 300, pollIntervalMs: 3000, directory: "/path"})

// 4. Read the response
opencode_conversation({sessionId, directory: "/path"})
```

For follow-up discussions, reuse the same `sessionId` to preserve context and save tokens.

### Writing effective delegation prompts

Pro runs headlessly and cannot ask follow-up questions. Be thorough:

- State the goal clearly and completely
- Reference specific file paths and relevant code patterns
- Describe constraints (API contract, error format, naming conventions)
- If debugging: describe the symptom, what you've tried, what you suspect

**Good prompt:**
```
opencode_run({
  prompt: "Refactor the auth middleware in src/middleware/auth.ts to support JWT refresh tokens.
           The current implementation only validates access tokens. Look at src/types/auth.ts 
           for the token types. Follow the error handling pattern in src/middleware/errorHandler.ts.
           Add tests in __tests__/auth.test.ts using the existing Vitest pattern.",
  directory: "/home/oktay/code/uppidi"
})
```

**Bad prompt:**
```
opencode_run({ prompt: "fix auth", directory: "/some/project" })
```

### After delegation

1. If you used `opencode_run` — read the result directly. Pro already finished.
2. If you used `opencode_fire` — call `opencode_check` to monitor progress. When done, call `opencode_review_changes` before telling the user what changed.
3. Summarize what Pro did for the user, referencing file paths and key changes.

### Pre-commit review by Pro

Before every commit, use `opencode_review_changes` to have Pro review the file diffs. Only commit after Pro confirms the changes are correct, safe, and follow project conventions. If Pro flags issues, fix them before committing.

### Permission handling

If Pro gets stuck waiting for permission to write a file or run a command:
1. Call `opencode_permission_list()` to see pending permission requests
2. Call `opencode_session_permission({ sessionId, permissionID, reply: "once" })` to approve

### Let the user know

Always tell the user when you delegate:
- "This is a complex architecture question — let me consult Pro." → `opencode_ask`
- "I'll delegate the refactoring to Pro and review when it's done." → `opencode_fire` then `opencode_review_changes`
- "Pro handled it. Here's what changed: [summary of files and key changes]"

### Handling Pro timeouts

`opencode_ask` has a short MCP transport timeout. If it times out:

1. **Immediate check**: Call `opencode_sessions_overview` to find the session (look for idle sessions matching your prompt)
2. **Get the result**: Call `opencode_conversation({sessionId})` to read Pro's full response
3. **If still busy** (status = busy): Call `opencode_wait({sessionId, timeoutSeconds: 300})` to wait up to 5 minutes

**To avoid timeouts entirely**, use `opencode_fire` + `opencode_wait` instead of `opencode_ask`:

```dart
// 1. Start Pro working (returns immediately with session ID)
opencode_fire({prompt: "...", directory: "/path"})

// 2. Wait for it to finish (up to 5 minutes)
opencode_wait({
  sessionId: "<id from step 1>",
  timeoutSeconds: 300,
  pollIntervalMs: 3000,
  directory: "/path"
})

// 3. Read the response
opencode_conversation({sessionId: "<id>", directory: "/path"})
```

`opencode_run` also avoids this issue — it uses `maxDurationSeconds` (default 600, adjustable). Prefer `opencode_run` when you don't need to do other work while waiting.
