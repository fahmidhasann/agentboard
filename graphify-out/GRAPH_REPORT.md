# Graph Report - .  (2026-06-01)

## Corpus Check
- Corpus is ~43,549 words - fits in a single context window. You may not need a graph.

## Summary
- 401 nodes · 593 edges · 29 communities (22 shown, 7 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 13 edges (avg confidence: 0.76)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Preferences Model|Preferences Model]]
- [[_COMMUNITY_Main Views State|Main Views State]]
- [[_COMMUNITY_Session Persistence|Session Persistence]]
- [[_COMMUNITY_Terminal Controller|Terminal Controller]]
- [[_COMMUNITY_Core UI Flow|Core UI Flow]]
- [[_COMMUNITY_App Architecture Docs|App Architecture Docs]]
- [[_COMMUNITY_Terminal Text Parsing|Terminal Text Parsing]]
- [[_COMMUNITY_App Lifecycle|App Lifecycle]]
- [[_COMMUNITY_Label Inference|Label Inference]]
- [[_COMMUNITY_Terminal Bridge View|Terminal Bridge View]]
- [[_COMMUNITY_New Session Flow|New Session Flow]]
- [[_COMMUNITY_App Commands|App Commands]]
- [[_COMMUNITY_Command Palette|Command Palette]]
- [[_COMMUNITY_Status Evaluation|Status Evaluation]]
- [[_COMMUNITY_Preferences Store|Preferences Store]]
- [[_COMMUNITY_Notifications|Notifications]]
- [[_COMMUNITY_Shell Resolution|Shell Resolution]]
- [[_COMMUNITY_App Icon Design|App Icon Design]]
- [[_COMMUNITY_Vercel Project Metadata|Vercel Project Metadata]]
- [[_COMMUNITY_Vercel Build Config|Vercel Build Config]]
- [[_COMMUNITY_App Paths|App Paths]]
- [[_COMMUNITY_Vercel Site Setup|Vercel Site Setup]]
- [[_COMMUNITY_Attention Sanitization|Attention Sanitization]]
- [[_COMMUNITY_Build Script|Build Script]]
- [[_COMMUNITY_DMG Packaging|DMG Packaging]]
- [[_COMMUNITY_Version Script|Version Script]]
- [[_COMMUNITY_Test Script|Test Script]]

## God Nodes (most connected - your core abstractions)
1. `SessionStore` - 35 edges
2. `TerminalSessionController` - 23 edges
3. `SessionStore` - 19 edges
4. `AppDelegate` - 13 edges
5. `UUID` - 12 edges
6. `TerminalContainer` - 12 edges
7. `SessionStatus` - 11 edges
8. `AgentSession` - 11 edges
9. `NewSessionSheet` - 11 edges
10. `AppTheme` - 10 edges

## Surprising Connections (you probably didn't know these)
- `Release Workflow` --semantically_similar_to--> `DMG Packager`  [INFERRED] [semantically similar]
  .github/workflows/release.yml → script/create_dmg.sh
- `AgentBoard Website Landing Page` --references--> `Central App Version`  [INFERRED]
  site/index.html → script/version.sh
- `Notification Service` --conceptually_related_to--> `Unsigned Gatekeeper Distribution`  [INFERRED]
  Sources/AgentBoard/Services/NotificationService.swift → README.md
- `Terminal Session Controller` --implements--> `Terminal Output Pipeline`  [EXTRACTED]
  Sources/AgentBoard/Services/TerminalSessionController.swift → CLAUDE.md
- `Terminal Session Controller` --shares_data_with--> `Recent Line Buffer`  [EXTRACTED]
  Sources/AgentBoard/Services/TerminalSessionController.swift → CLAUDE.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Release Packaging Pipeline** — release_release_workflow, script_create_dmg_packager, script_build_and_run_launcher, script_version_app_version [EXTRACTED 1.00]
- **Persisted Session Architecture** — agentsession_agent_session, external_session_store, terminalsessioncontroller_terminal_controller, concept_persisted_metadata_live_controllers [EXTRACTED 1.00]
- **Terminal Output Pipeline** — terminalsessioncontroller_agent_terminal_view, terminalsessioncontroller_terminal_controller, external_recent_line_buffer, labelinferenceservice_label_inference, external_attention_evaluator [EXTRACTED 1.00]
- **Session Lifecycle Flow** — SessionStore_SessionStore, SessionStore_AgentSession, SessionStore_TerminalSessionController, ShellResolver_ShellResolver [EXTRACTED 1.00]
- **Terminal Find Flow** — TerminalDetailView_TerminalContainer, FindBar_FindBar, SessionStore_TerminalSessionController [EXTRACTED 1.00]
- **Quick Launch Preferences Flow** — PreferencesStore_PreferencesStore, ContentView_ContentView, NewSessionSheet_NewSessionSheet, SettingsView_SettingsView, SessionStore_AgentLaunchConfig [INFERRED 0.85]
- **Command Prompt To Agent Workflow Icon** — appicon_agentboard_app_icon, appicon_terminal_prompt_symbol, appicon_agent_workflow_lanes, appicon_status_nodes [INFERRED 0.85]

## Communities (29 total, 7 thin omitted)

### Community 0 - "Preferences Model"
Cohesion: 0.06
Nodes (42): CaseIterable, Codable, Decoder, Identifiable, AgentBoardPreferences, AppTheme, dark, light (+34 more)

### Community 1 - "Main Views State"
Cohesion: 0.05
Nodes (35): Color, FocusState, FolderGroup, CommandPaletteModel, PreferencesStore, SessionStore, Bool, String (+27 more)

### Community 2 - "Session Persistence"
Cohesion: 0.11
Nodes (15): Data, DispatchWorkItem, IndexSet, AgentLaunchConfig, AgentSession, FileManager, Int, Int32 (+7 more)

### Community 3 - "Terminal Controller"
Cohesion: 0.10
Nodes (18): ArraySlice, LabelInferenceService, LocalProcessTerminalView, LocalProcessTerminalViewDelegate, RecentLineBuffer, AgentTerminalView, TerminalSessionController, TerminalSnapshot (+10 more)

### Community 4 - "Core UI Flow"
Cohesion: 0.10
Nodes (34): AppPaths, AppDelegate, CommandPaletteModel, CommandPaletteView, PaletteRow, ContentView, FindBar, NewSessionSheet (+26 more)

### Community 5 - "App Architecture Docs"
Cohesion: 0.08
Nodes (34): App Menu Commands, AgentBoard SwiftUI App Shell, App Theme, AgentBoard Preferences, Agent Launch Config, Agent Session Metadata, Session Status, Application Lifecycle Delegate (+26 more)

### Community 6 - "Terminal Text Parsing"
Cohesion: 0.16
Nodes (10): NSRegularExpression, S, Bool, Int, String, UInt8, AnsiSanitizer, AttentionEvaluator (+2 more)

### Community 7 - "App Lifecycle"
Cohesion: 0.16
Nodes (8): Any, AppDelegate, Notification, NSApplication, NSApplicationDelegate, NSObject, NSWindow, Bool

### Community 8 - "Label Inference"
Cohesion: 0.30
Nodes (6): Equatable, LabelInferenceService, Result, AgentSession, Int, String

### Community 9 - "Terminal Bridge View"
Cohesion: 0.29
Nodes (7): AgentTerminalView, Context, NSFont, NSViewRepresentable, Double, TerminalSessionController, TerminalRepresentable

### Community 10 - "New Session Flow"
Cohesion: 0.21
Nodes (6): AgentLaunchConfig, PreferencesStore, SessionStore, String, UUID, NewSessionSheet

### Community 11 - "App Commands"
Cohesion: 0.18
Nodes (9): App, AgentBoardApp, AppCommands, Commands, Scene, CommandPaletteModel, Double, PreferencesStore (+1 more)

### Community 12 - "Command Palette"
Cohesion: 0.31
Nodes (6): Bool, CommandPaletteModel, SessionStore, String, CommandPaletteView, PaletteRow

### Community 13 - "Status Evaluation"
Cohesion: 0.25
Nodes (6): StatusService, Bool, Date, Int32, SessionStatus, TimeInterval

### Community 14 - "Preferences Store"
Cohesion: 0.38
Nodes (4): AgentBoardPreferences, ColorScheme, URL, PreferencesStore

### Community 15 - "Notifications"
Cohesion: 0.40
Nodes (3): NotificationService, Bool, String

### Community 16 - "Shell Resolution"
Cohesion: 0.40
Nodes (3): FileManager, String, ShellResolver

### Community 17 - "App Icon Design"
Cohesion: 0.50
Nodes (5): Agent Workflow Lanes, AgentBoard App Icon, Dark Rounded Square Background, Workflow Status Nodes, Green Terminal Prompt Symbol

### Community 18 - "Vercel Project Metadata"
Cohesion: 0.50
Nodes (3): orgId, projectId, projectName

### Community 21 - "Vercel Site Setup"
Cohesion: 0.67
Nodes (3): Vercel AgentBoard Project, Vercel Linked Project Notes, Vercel Static Output Configuration

## Knowledge Gaps
- **108 isolated node(s):** `Scene`, `SessionStore`, `CommandPaletteModel`, `PreferencesStore`, `Double` (+103 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `FolderGroup` connect `Preferences Model` to `Main Views State`?**
  _High betweenness centrality (0.101) - this node is a cross-community bridge._
- **Why does `SessionStore` connect `Session Persistence` to `Preferences Model`?**
  _High betweenness centrality (0.077) - this node is a cross-community bridge._
- **What connects `Scene`, `SessionStore`, `CommandPaletteModel` to the rest of the system?**
  _108 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Preferences Model` be split into smaller, more focused modules?**
  _Cohesion score 0.06184012066365008 - nodes in this community are weakly interconnected._
- **Should `Main Views State` be split into smaller, more focused modules?**
  _Cohesion score 0.05272108843537415 - nodes in this community are weakly interconnected._
- **Should `Session Persistence` be split into smaller, more focused modules?**
  _Cohesion score 0.1076923076923077 - nodes in this community are weakly interconnected._
- **Should `Terminal Controller` be split into smaller, more focused modules?**
  _Cohesion score 0.09682539682539683 - nodes in this community are weakly interconnected._