# Graph Report - Agentboard  (2026-06-06)

## Corpus Check
- 50 files · ~57,911 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 650 nodes · 1048 edges · 41 communities (30 shown, 11 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 28 edges (avg confidence: 0.81)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `46616b50`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Update Check & Codable Infra|Update Check & Codable Infra]]
- [[_COMMUNITY_Terminal Session Controller|Terminal Session Controller]]
- [[_COMMUNITY_Session Store & Persistence|Session Store & Persistence]]
- [[_COMMUNITY_Views & UI Components|Views & UI Components]]
- [[_COMMUNITY_Terminal Buffer Tests|Terminal Buffer Tests]]
- [[_COMMUNITY_Update & Preferences Tests|Update & Preferences Tests]]
- [[_COMMUNITY_Command Palette Tests & App Entry|Command Palette Tests & App Entry]]
- [[_COMMUNITY_Preferences Model|Preferences Model]]
- [[_COMMUNITY_Ghost Text & NSView Bridge|Ghost Text & NSView Bridge]]
- [[_COMMUNITY_Session Store Tests|Session Store Tests]]
- [[_COMMUNITY_Inline Autocomplete Engine|Inline Autocomplete Engine]]
- [[_COMMUNITY_App Delegate Lifecycle|App Delegate Lifecycle]]
- [[_COMMUNITY_Notification Service|Notification Service]]
- [[_COMMUNITY_Session Sheets (NewRename)|Session Sheets (New/Rename)]]
- [[_COMMUNITY_Label Inference Tests|Label Inference Tests]]
- [[_COMMUNITY_Autocomplete Engine Tests|Autocomplete Engine Tests]]
- [[_COMMUNITY_Hero Screenshot UI|Hero Screenshot UI]]
- [[_COMMUNITY_Command History Tests|Command History Tests]]
- [[_COMMUNITY_Landing Page Features|Landing Page Features]]
- [[_COMMUNITY_Command Palette View|Command Palette View]]
- [[_COMMUNITY_App Version Parsing|App Version Parsing]]
- [[_COMMUNITY_Status Service|Status Service]]
- [[_COMMUNITY_Build & Deploy Scripts|Build & Deploy Scripts]]
- [[_COMMUNITY_Shell Resolver|Shell Resolver]]
- [[_COMMUNITY_App Icon Design|App Icon Design]]
- [[_COMMUNITY_Vercel Config|Vercel Config]]
- [[_COMMUNITY_SwiftPM Manifest|SwiftPM Manifest]]
- [[_COMMUNITY_Test Runner Script|Test Runner Script]]
- [[_COMMUNITY_CICD Workflows|CI/CD Workflows]]
- [[_COMMUNITY_Find Bar|Find Bar]]
- [[_COMMUNITY_Shell Resolver (singleton)|Shell Resolver (singleton)]]
- [[_COMMUNITY_Project Documentation|Project Documentation]]
- [[_COMMUNITY_Launch Config|Launch Config]]
- [[_COMMUNITY_Notification Service (singleton)|Notification Service (singleton)]]
- [[_COMMUNITY_Test Script Wrapper|Test Script Wrapper]]
- [[_COMMUNITY_Status Evaluator|Status Evaluator]]
- [[_COMMUNITY_Community 38|Community 38]]
- [[_COMMUNITY_Community 39|Community 39]]
- [[_COMMUNITY_Community 40|Community 40]]

## God Nodes (most connected - your core abstractions)
1. `SessionStore` - 63 edges
2. `TerminalSessionController` - 37 edges
3. `UpdateCheckService` - 30 edges
4. `InlineAutocompleteEngine` - 23 edges
5. `AgentTerminalView` - 20 edges
6. `AppDelegate` - 18 edges
7. `CommandHistoryStore` - 16 edges
8. `PreferencesStore` - 16 edges
9. `AgentSession` - 15 edges
10. `NewSessionSheet` - 15 edges

## Surprising Connections (you probably didn't know these)
- `Sheet Dismiss Pattern` --rationale_for--> `NewSessionSheet`  [EXTRACTED]
  docs/refactoring-checklist.md → Sources/AgentBoard/Views/NewSessionSheet.swift
- `Sheet Dismiss Pattern` --rationale_for--> `RenameSheet`  [EXTRACTED]
  docs/refactoring-checklist.md → Sources/AgentBoard/Views/RenameSheet.swift
- `Session Action Button Consolidation` --rationale_for--> `SessionActionButtons`  [EXTRACTED]
  docs/refactoring-checklist.md → Sources/AgentBoard/Views/SessionActionButtons.swift
- `AgentBoardPreferencesMigrationTests` --references--> `AgentBoardPreferences`  [EXTRACTED]
  Tests/AgentBoardTests/UpdateCheckServiceTests.swift → Sources/AgentBoard/Models/AgentBoardPreferences.swift
- `CommandHistoryStoreTests` --references--> `CommandHistoryStore`  [EXTRACTED]
  Tests/AgentBoardTests/CommandHistoryStoreTests.swift → Sources/AgentBoard/Services/CommandHistoryStore.swift

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Command Prompt To Agent Workflow Icon** — appicon_agentboard_app_icon, appicon_terminal_prompt_symbol, appicon_agent_workflow_lanes, appicon_status_nodes [INFERRED 0.85]
- **Terminal Output Pipeline Flow** — services_terminalsessioncontroller_agentterminalview, support_recentlinebuffer_utf8streamdecoder, support_recentlinebuffer_ansisanitizer, support_recentlinebuffer_recentlinebuffer, support_recentlinebuffer_attentionevaluator [EXTRACTED 1.00]
- **Singleton Services (shared instances)** — stores_sessionstore_sessionstore, stores_preferencesstore_preferencesstore, services_commandpalettemodel_commandpalettemodel, services_updatecheckservice_updatecheckservice, services_commandhistorystore_commandhistorystore [EXTRACTED 1.00]
- **JSON Persistence Layer** — stores_sessionstore_sessionstore, stores_preferencesstore_preferencesstore, services_commandhistorystore_commandhistorystore, support_apppaths_apppaths, support_jsonhelpers_jsonencoder_agentboard [EXTRACTED 1.00]
- **Sheet Dismiss and Refocus Pattern** — views_newsessionsheet_newsessionsheet, views_renamesheet_renamesheet, docs_refactoring_checklist_sheet_dismiss_pattern [EXTRACTED 0.95]
- **Session Action Button Consumers** — views_sessionactionbuttons_sessionactionbuttons, views_sidebarview_sidebarview, views_terminaldetailview_terminalcontainer [EXTRACTED 1.00]
- **Build and Release Pipeline** — script_build_and_run, script_create_dmg, script_version, site_vercel_json [EXTRACTED 0.95]
- **AgentBoard Core Feature Set** — site_index_feature_monitor_sessions, site_index_feature_spot_attention, site_index_feature_restart_with_history, site_index_feature_native_macos_workflow [EXTRACTED 1.00]
- **Supported Agent Ecosystem** — site_index_supported_agents, site_index_agent_heavy_development, site_index_feature_monitor_sessions, site_index_feature_spot_attention [INFERRED 0.85]
- **Multiple AI Agent Sessions Displayed** — assets_agentboard_hero_claude_session, assets_agentboard_hero_codex_session, assets_agentboard_hero_gemini_session, assets_agentboard_hero_aider_session, assets_agentboard_hero_shell_session [EXTRACTED 1.00]
- **macOS NavigationSplitView UI Layout** — assets_agentboard_hero_sidebar, assets_agentboard_hero_terminal_detail, assets_agentboard_hero_toolbar, assets_agentboard_hero_statusbar, assets_agentboard_hero_navigationsplitview [EXTRACTED 1.00]

## Communities (41 total, 11 thin omitted)

### Community 0 - "Update Check & Codable Infra"
Cohesion: 0.07
Nodes (37): AppVersion, CodingKey, Decodable, Equatable, LocalizedError, Asset, AvailableUpdate, CodingKeys (+29 more)

### Community 1 - "Terminal Session Controller"
Cohesion: 0.06
Nodes (31): ArraySlice, CGPoint, CGSize, CommandHistoryStore, Date, InlineAutocompleteEngine, LabelInferenceService, LocalProcessTerminalView (+23 more)

### Community 2 - "Session Store & Persistence"
Cohesion: 0.09
Nodes (20): SessionStorePersistenceTests, AgentLaunchConfig, AgentSession, FileManager, IndexSet, SessionStatus, AgentLaunchConfig, AgentSession (+12 more)

### Community 3 - "Views & UI Components"
Cohesion: 0.06
Nodes (39): Color, Session Action Button Consolidation, FocusState, FolderGroup, Identifiable, AgentLaunchConfig, String, UUID (+31 more)

### Community 4 - "Terminal Buffer Tests"
Cohesion: 0.10
Nodes (12): TerminalBufferTests, NSRegularExpression, S, Bool, Int, String, UInt8, AnsiSanitizer (+4 more)

### Community 5 - "Update & Preferences Tests"
Cohesion: 0.16
Nodes (4): AgentBoardPreferencesMigrationTests, AppVersionTests, UpdateCheckServiceTests, Data

### Community 6 - "Command Palette Tests & App Entry"
Cohesion: 0.05
Nodes (31): CommandPaletteModelTests, App, AgentBoardApp, AppCommands, ColorScheme, Commands, ObservableObject, Scene (+23 more)

### Community 7 - "Preferences Model"
Cohesion: 0.09
Nodes (31): CaseIterable, Codable, Decoder, AgentBoardPreferences, AppTheme, dark, light, system (+23 more)

### Community 8 - "Ghost Text & NSView Bridge"
Cohesion: 0.10
Nodes (19): AgentTerminalView, CGFloat, Context, Double, NSCoder, NSPoint, NSRect, NSView (+11 more)

### Community 9 - "Session Store Tests"
Cohesion: 0.13
Nodes (8): SessionStorePersistenceTests, CommandHistoryStore, DispatchWorkItem, Int, String, URL, JSONEncoder, URL

### Community 10 - "Inline Autocomplete Engine"
Cohesion: 0.15
Nodes (12): InlineAutocompleteEngine, State, collecting, inactive, suggesting, AgentTerminalView, ArraySlice, Bool (+4 more)

### Community 11 - "App Delegate Lifecycle"
Cohesion: 0.15
Nodes (8): Any, AppDelegate, Notification, NSApplication, NSApplicationDelegate, NSObject, NSWindow, Bool

### Community 12 - "Notification Service"
Cohesion: 0.12
Nodes (12): Content, NotificationService, Bool, String, PreferencesStore, UpdateCheckService, UpdateCheckService, View (+4 more)

### Community 13 - "Session Sheets (New/Rename)"
Cohesion: 0.13
Nodes (11): Sheet Dismiss Pattern, AgentLaunchConfig, PreferencesStore, SessionStore, String, UUID, AgentSession, SessionStore (+3 more)

### Community 14 - "Label Inference Tests"
Cohesion: 0.18
Nodes (5): LabelInferenceServiceTests, LabelInferenceService, Result, AgentSession, String

### Community 15 - "Autocomplete Engine Tests"
Cohesion: 0.24
Nodes (3): InlineAutocompleteEngineTests, CommandHistoryStore, InlineAutocompleteEngine

### Community 16 - "Hero Screenshot UI"
Cohesion: 0.18
Nodes (12): AgentBoard Hero Screenshot, Aider bugfix/tty Session, Claude api-refactor Session, Codex feature/cli Session, Gemini docs-sync Session, NavigationSplitView Layout Pattern, Shell server Session, Navigation Sidebar with Sessions (+4 more)

### Community 18 - "Landing Page Features"
Cohesion: 0.20
Nodes (11): Agent-Heavy Development Workflow, Download Distribution via GitHub Releases, Feature: Monitor Sessions, Feature: Native macOS Workflow, Feature: Restart with History, Feature: Spot Attention, GitHub Repository (fahmidhasann/agentboard), Keyboard Shortcuts (Cmd+N, Cmd+1-9, Cmd+Shift+P, Cmd+K) (+3 more)

### Community 19 - "Command Palette View"
Cohesion: 0.33
Nodes (6): Bool, CommandPaletteModel, SessionStore, String, CommandPaletteView, PaletteRow

### Community 20 - "App Version Parsing"
Cohesion: 0.33
Nodes (7): Comparable, CustomStringConvertible, Bool, Int, String, AppVersion, SemanticVersion

### Community 21 - "Status Service"
Cohesion: 0.25
Nodes (6): StatusService, Bool, Date, Int32, SessionStatus, TimeInterval

### Community 22 - "Build & Deploy Scripts"
Cohesion: 0.29
Nodes (3): build_and_run.sh script, create_dmg.sh script, version.sh script

### Community 23 - "Shell Resolver"
Cohesion: 0.40
Nodes (3): FileManager, String, ShellResolver

### Community 24 - "App Icon Design"
Cohesion: 0.50
Nodes (5): Agent Workflow Lanes, AgentBoard App Icon, Dark Rounded Square Background, Workflow Status Nodes, Green Terminal Prompt Symbol

### Community 25 - "Vercel Config"
Cohesion: 0.50
Nodes (3): buildCommand, ignoreCommand, outputDirectory

### Community 31 - "Project Documentation"
Cohesion: 0.22
Nodes (7): Architecture, Commands, Conventions & gotchas, graphify, Release workflow, Source layout, What this is

### Community 39 - "Community 39"
Cohesion: 0.17
Nodes (11): AgentBoard Refactoring Checklist, Minor, Moderate, Significant, [x] 1. Extract `sessionIndex(for:)` helper in `SessionStore`, [x] 2. Consolidate session action buttons into a shared `@ViewBuilder`, [x] 3. Deduplicate JSON encoder configuration, [x] 4. Consolidate `focusSelectedTerminal` dispatch at sheet/view dismissal (+3 more)

### Community 40 - "Community 40"
Cohesion: 0.25
Nodes (7): AgentBoard, Build from source, Features, Gatekeeper notice, Install, License, Why

## Knowledge Gaps
- **169 isolated node(s):** `PreToolUse`, `Scene`, `SessionStore`, `CommandPaletteModel`, `PreferencesStore` (+164 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **11 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `SessionStore` connect `Session Store & Persistence` to `Terminal Session Controller`, `Views & UI Components`, `Command Palette Tests & App Entry`, `Preferences Model`, `App Delegate Lifecycle`, `Notification Service`, `Session Sheets (New/Rename)`, `Label Inference Tests`, `Command Palette View`?**
  _High betweenness centrality (0.371) - this node is a cross-community bridge._
- **Why does `TerminalSessionController` connect `Terminal Session Controller` to `Session Store & Persistence`, `Terminal Buffer Tests`, `Ghost Text & NSView Bridge`, `App Delegate Lifecycle`, `Label Inference Tests`?**
  _High betweenness centrality (0.238) - this node is a cross-community bridge._
- **Why does `UpdateCheckService` connect `Update Check & Codable Infra` to `Update & Preferences Tests`, `Command Palette Tests & App Entry`, `App Delegate Lifecycle`, `Notification Service`, `App Version Parsing`?**
  _High betweenness centrality (0.141) - this node is a cross-community bridge._
- **What connects `PreToolUse`, `Scene`, `SessionStore` to the rest of the system?**
  _171 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Update Check & Codable Infra` be split into smaller, more focused modules?**
  _Cohesion score 0.07256894049346879 - nodes in this community are weakly interconnected._
- **Should `Terminal Session Controller` be split into smaller, more focused modules?**
  _Cohesion score 0.05837173579109063 - nodes in this community are weakly interconnected._
- **Should `Session Store & Persistence` be split into smaller, more focused modules?**
  _Cohesion score 0.08525506638714186 - nodes in this community are weakly interconnected._