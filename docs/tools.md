MCP Tool Execution Loop in short, sequential steps:

1. The Trigger (User → LLM)The user inputs a query in the frontend view asking for an operation (e.g., "Read app/models/user.rb"). Controller passes the request directly to Mcp::AgentRunner.The runner formats the entire historical database message stack into an array of clean JSON hashes.It gathers all active tool schemas using Mcp::ToolRegistry.definitions_for_llm and passes both the history and schemas to OpenRouter.

2. The Request (LLM → Agent)A tool-capable model (like cohere/north-mini-code:free) analyzes the query and decides it needs an external operation.The model returns an HTTP 200 OK response. The body contains an empty content block but a highly structured tool_calls array, including a generated id (e.g., file_read_vap0dghkg9r1), the tool name (file_read), and parsed JSON arguments.

3. The Interception & Record (Agent → Database)Mcp::AgentRunner catches the tool_calls payload.It saves an assistant role message to database containing the tool call request structure in its metadata field.It initializes a log record in ai_tool_calls table with a status of "running" and passes the payload to the execution gateway.

4. The Action (ToolExecutor)The runner hands the call arguments to Mcp::ToolExecutor.call.The executor maps the name (file_read) to the target Ruby class (Mcp::Tools::FileReadTool).The tool performs path safety checks, executes standard file system operations (File.read), and returns a success block wrapped in a native Ruby hash context: { ok: true, data: { path: ..., content: ... } }.The ai_tool_calls database record is updated to "success" along with the recorded duration execution time.

5. The Response Feedback Loop (Agent → LLM)The runner saves a brand new message to database with the specialized role of "tool". This record explicitly attaches the original tool_call_id and prints the file text contents as its string value (content).

#MCP Tool Design Rules (VERY important)

To keep the system stable:

✔ Tools must be:
deterministic
stateless
schema-validated
side-effect explicit
❌ Tools must NOT:
call LLMs internally (avoid recursion chaos)
mutate session state silently
return unstructured text
