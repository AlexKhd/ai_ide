1. Purpose

This application is an AI coding agent platform. It allows users to interact with LLMs in sessions, where each session can switch or connect to different models dynamically via OpenRouter.

The system acts as a thin orchestration layer between the user and multiple LLM providers.

2. Core Domain
Users create and manage chat sessions
Each session is associated with a selected LLM model
Models are fetched dynamically from OpenRouter
Sessions maintain conversation state and tool usage context

Key entities:

User
Session (current conversation with an LLM)
LLM Model (fetched from OpenRouter)
Message (user/assistant/tool messages)
ToolCall (optional MCP-style tool execution)

3. Architecture
Ruby on Rails 8 monolith
Hotwire (Turbo + Stimulus) for UI reactivity
SQLite3 for persistence
Service-oriented design inside /app/services

Key service layer:

app/services/open_router/ → handles OpenRouter API integration

4. LLM / OpenRouter Integration
Models are fetched from OpenRouter API (not hardcoded)
Each session binds to one active model
Model switching may occur per session (or per request if allowed)

Behavior assumption:

The LLM is treated as stateless externally
All memory is maintained inside the Session + Message history

5. Key Models + Relationships
User has_many Sessions
Session belongs_to User
Session has_many Messages
Session belongs_to Model (OpenRouter model)
Message belongs_to Session
Message may include ToolCalls

6. Background Jobs / Services
(TBD)
Likely candidates:
message streaming processing
tool execution
OpenRouter sync (model list refresh)

7. Auth System
Rails 8 built-in authentication
Session-based login
User-scoped data access everywhere

8. External Integrations
OpenRouter API → model listing + inference routing
MCP-style tools:
defined in docs/tools.md
executed via internal tool runner service layer

9. Important Design Rules
The app does NOT store model behavior logic locally
All LLM intelligence comes from selected provider
Session state is the source of truth for conversation memory
Tools are explicit and schema-driven (no hidden tool execution)
