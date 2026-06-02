# Graph Report - .  (2026-06-02)

## Corpus Check
- 42 files · ~83,044 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 411 nodes · 603 edges · 38 communities (27 shown, 11 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 15 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Data Models & Codable|Data Models & Codable]]
- [[_COMMUNITY_SwiftUI Views Layer|SwiftUI Views Layer]]
- [[_COMMUNITY_Session Store & Lifecycle|Session Store & Lifecycle]]
- [[_COMMUNITY_RecentLineBuffer Tests|RecentLineBuffer Tests]]
- [[_COMMUNITY_Terminal Output Pipeline|Terminal Output Pipeline]]
- [[_COMMUNITY_App Delegate Lifecycle|App Delegate Lifecycle]]
- [[_COMMUNITY_Session Name Tests|Session Name Tests]]
- [[_COMMUNITY_Terminal Representable|Terminal Representable]]
- [[_COMMUNITY_App Entry & Commands|App Entry & Commands]]
- [[_COMMUNITY_Label Inference Service|Label Inference Service]]
- [[_COMMUNITY_New Session Sheet|New Session Sheet]]
- [[_COMMUNITY_Command Palette View|Command Palette View]]
- [[_COMMUNITY_Detail View Components|Detail View Components]]
- [[_COMMUNITY_Preferences Store|Preferences Store]]
- [[_COMMUNITY_Documentation & Build|Documentation & Build]]
- [[_COMMUNITY_Status Service|Status Service]]
- [[_COMMUNITY_Hero Image UI|Hero Image UI]]
- [[_COMMUNITY_Notification Service|Notification Service]]
- [[_COMMUNITY_Shell Resolver|Shell Resolver]]
- [[_COMMUNITY_Settings & Paths|Settings & Paths]]
- [[_COMMUNITY_App Icon Design|App Icon Design]]
- [[_COMMUNITY_Command Palette Model|Command Palette Model]]
- [[_COMMUNITY_Session & Status Types|Session & Status Types]]
- [[_COMMUNITY_Vercel Project Config|Vercel Project Config]]
- [[_COMMUNITY_Preferences & Config Types|Preferences & Config Types]]
- [[_COMMUNITY_Vercel Build Config|Vercel Build Config]]
- [[_COMMUNITY_AppPaths Utility|AppPaths Utility]]
- [[_COMMUNITY_Vercel Deployment|Vercel Deployment]]
- [[_COMMUNITY_SwiftPM Package|SwiftPM Package]]
- [[_COMMUNITY_Build Script|Build Script]]
- [[_COMMUNITY_DMG Script|DMG Script]]
- [[_COMMUNITY_Test Script|Test Script]]
- [[_COMMUNITY_Version Script|Version Script]]
- [[_COMMUNITY_Shell Resolver Utility|Shell Resolver Utility]]
- [[_COMMUNITY_Agents Doc|Agents Doc]]
- [[_COMMUNITY_Favicon Asset|Favicon Asset]]
- [[_COMMUNITY_Test Runner Wrapper|Test Runner Wrapper]]

## God Nodes (most connected - your core abstractions)
1. `SessionStore` - 47 edges
2. `TerminalSessionController` - 33 edges
3. `RecentLineBufferTests` - 19 edges
4. `AppDelegate` - 13 edges
5. `SessionNameGenerationTests` - 13 edges
6. `UUID` - 12 edges
7. `TerminalContainer` - 12 edges
8. `SessionStatus` - 11 edges
9. `AgentSession` - 11 edges
10. `LabelInferenceService` - 11 edges

## Surprising Connections (you probably didn't know these)
- `Release Workflow` --semantically_similar_to--> `DMG Packager`  [INFERRED] [semantically similar]
  .github/workflows/release.yml → script/create_dmg.sh
- `AgentBoard Landing Page` --references--> `AgentBoardApp`  [INFERRED]
  site/index.html → Sources/AgentBoard/App/AgentBoardApp.swift
- `CLAUDE.md - Project Instructions` --references--> `SessionStore`  [EXTRACTED]
  CLAUDE.md → Sources/AgentBoard/Stores/SessionStore.swift
- `Persisted Value-Type Metadata vs Non-Persisted Live Controllers` --rationale_for--> `SessionStore`  [EXTRACTED]
  CLAUDE.md → Sources/AgentBoard/Stores/SessionStore.swift
- `CLAUDE.md - Project Instructions` --references--> `TerminalSessionController`  [EXTRACTED]
  CLAUDE.md → Sources/AgentBoard/Services/TerminalSessionController.swift

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Terminal Find Flow** — TerminalDetailView_TerminalContainer, FindBar_FindBar, SessionStore_TerminalSessionController [EXTRACTED 1.00]
- **Command Prompt To Agent Workflow Icon** — appicon_agentboard_app_icon, appicon_terminal_prompt_symbol, appicon_agent_workflow_lanes, appicon_status_nodes [INFERRED 0.85]
- **Terminal Output Pipeline: raw bytes to stored lines** — services_terminalsessioncontroller_agentterminalview, support_recentlinebuffer_utf8streamdecoder, support_recentlinebuffer_ansisanitizer, support_recentlinebuffer_screencleardetector, support_recentlinebuffer_recentlinebuffer [EXTRACTED 1.00]
- **Periodic Sync: snapshot pull, inference, status recompute** — stores_sessionstore_sessionstore, services_terminalsessioncontroller_terminalsessioncontroller, services_terminalsessioncontroller_terminalsnapshot, services_labelinferenceservice_labelinferenceservice [EXTRACTED 1.00]
- **Sidebar View Composition: ContentView -> SidebarView -> SidebarRowView** — views_contentview_contentview, views_sidebarview_sidebarview, views_sidebarrowview_sidebarrowview, views_sidebarrowview_statusbadge, views_sidebarrowview_statuspill [EXTRACTED 1.00]

## Communities (38 total, 11 thin omitted)

### Community 0 - "Data Models & Codable"
Cohesion: 0.06
Nodes (42): CaseIterable, Codable, Decoder, Identifiable, AgentBoardPreferences, AppTheme, dark, light (+34 more)

### Community 1 - "SwiftUI Views Layer"
Cohesion: 0.06
Nodes (36): Color, FocusState, FolderGroup, CommandPaletteModel, PreferencesStore, SessionStore, Bool, String (+28 more)

### Community 2 - "Session Store & Lifecycle"
Cohesion: 0.10
Nodes (16): Periodic Sync Loop (0.5s timer coalescing terminal output), DispatchWorkItem, IndexSet, AgentLaunchConfig, AgentSession, Bool, FileManager, Int (+8 more)

### Community 3 - "RecentLineBuffer Tests"
Cohesion: 0.08
Nodes (13): RecentLineBufferTests, NSRegularExpression, S, Bool, Int, String, UInt8, AnsiSanitizer (+5 more)

### Community 4 - "Terminal Output Pipeline"
Cohesion: 0.09
Nodes (21): ArraySlice, CLAUDE.md - Project Instructions, Persisted Value-Type Metadata vs Non-Persisted Live Controllers, Terminal Output Pipeline (dataReceived -> UTF8 -> AnsiSanitizer -> RecentLineBuffer), LabelInferenceService, LocalProcessTerminalView, LocalProcessTerminalViewDelegate, RecentLineBuffer (+13 more)

### Community 5 - "App Delegate Lifecycle"
Cohesion: 0.16
Nodes (8): Any, AppDelegate, Notification, NSApplication, NSApplicationDelegate, NSObject, NSWindow, Bool

### Community 6 - "Session Name Tests"
Cohesion: 0.27
Nodes (5): SessionNameGenerationTests, Legacy Garbled Summary Cleanup on Load, AgentSession, SessionStore, URL

### Community 7 - "Terminal Representable"
Cohesion: 0.29
Nodes (7): AgentTerminalView, Context, NSFont, NSViewRepresentable, Double, TerminalSessionController, TerminalRepresentable

### Community 8 - "App Entry & Commands"
Cohesion: 0.17
Nodes (10): App, AgentBoardApp, AppCommands, Commands, Scene, AgentBoard Landing Page, CommandPaletteModel, Double (+2 more)

### Community 9 - "Label Inference Service"
Cohesion: 0.32
Nodes (6): User Edit Locks (isSummaryUserEdited/isAgentUserEdited prevent inference overwrite), Equatable, LabelInferenceService, Result, AgentSession, String

### Community 10 - "New Session Sheet"
Cohesion: 0.21
Nodes (6): AgentLaunchConfig, PreferencesStore, SessionStore, String, UUID, NewSessionSheet

### Community 11 - "Command Palette View"
Cohesion: 0.31
Nodes (6): Bool, CommandPaletteModel, SessionStore, String, CommandPaletteView, PaletteRow

### Community 12 - "Detail View Components"
Cohesion: 0.25
Nodes (8): FindBar, EmptyDetailView, ExitedPlaceholder, RenameSheet, TerminalContainer, TerminalDetailView, AgentTerminalView, TerminalRepresentable

### Community 13 - "Preferences Store"
Cohesion: 0.32
Nodes (5): AgentBoardPreferences, ColorScheme, Data, URL, PreferencesStore

### Community 14 - "Documentation & Build"
Cohesion: 0.32
Nodes (8): Application Lifecycle Delegate, Unsigned Gatekeeper Distribution, Notification Service, AgentBoard Project README, Release Workflow, Build and Run Launcher, DMG Packager, Central App Version

### Community 15 - "Status Service"
Cohesion: 0.25
Nodes (6): StatusService, Bool, Date, Int32, SessionStatus, TimeInterval

### Community 16 - "Hero Image UI"
Cohesion: 0.29
Nodes (7): AgentBoard Hero Screenshot, Sidebar with Agent Sessions, Terminal Detail Pane, LabelInferenceService, ContentView, SidebarView, TerminalDetailView

### Community 17 - "Notification Service"
Cohesion: 0.40
Nodes (3): NotificationService, Bool, String

### Community 18 - "Shell Resolver"
Cohesion: 0.40
Nodes (3): FileManager, String, ShellResolver

### Community 19 - "Settings & Paths"
Cohesion: 0.40
Nodes (5): AppPaths, NewSessionSheet, AgentBoardPreferences, PreferencesStore, SettingsView

### Community 20 - "App Icon Design"
Cohesion: 0.50
Nodes (5): Agent Workflow Lanes, AgentBoard App Icon, Dark Rounded Square Background, Workflow Status Nodes, Green Terminal Prompt Symbol

### Community 21 - "Command Palette Model"
Cohesion: 0.67
Nodes (4): AppDelegate, CommandPaletteModel, CommandPaletteView, PaletteRow

### Community 22 - "Session & Status Types"
Cohesion: 0.50
Nodes (4): Agent Session Metadata, Session Status, Command Palette Model, Status Evaluator

### Community 23 - "Vercel Project Config"
Cohesion: 0.50
Nodes (3): orgId, projectId, projectName

### Community 24 - "Preferences & Config Types"
Cohesion: 0.67
Nodes (3): App Theme, AgentBoard Preferences, Agent Launch Config

### Community 27 - "Vercel Deployment"
Cohesion: 0.67
Nodes (3): Vercel AgentBoard Project, Vercel Linked Project Notes, Vercel Static Output Configuration

## Knowledge Gaps
- **113 isolated node(s):** `Scene`, `SessionStore`, `CommandPaletteModel`, `PreferencesStore`, `Double` (+108 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **11 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `SessionStore` connect `Session Store & Lifecycle` to `Data Models & Codable`, `SwiftUI Views Layer`, `Terminal Output Pipeline`, `Session Name Tests`, `App Entry & Commands`, `Label Inference Service`?**
  _High betweenness centrality (0.338) - this node is a cross-community bridge._
- **Why does `TerminalSessionController` connect `Terminal Output Pipeline` to `Label Inference Service`, `Session Store & Lifecycle`, `RecentLineBuffer Tests`, `App Delegate Lifecycle`?**
  _High betweenness centrality (0.221) - this node is a cross-community bridge._
- **Why does `SidebarView` connect `SwiftUI Views Layer` to `Data Models & Codable`, `Session Store & Lifecycle`?**
  _High betweenness centrality (0.187) - this node is a cross-community bridge._
- **What connects `Scene`, `SessionStore`, `CommandPaletteModel` to the rest of the system?**
  _116 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Data Models & Codable` be split into smaller, more focused modules?**
  _Cohesion score 0.0602322206095791 - nodes in this community are weakly interconnected._
- **Should `SwiftUI Views Layer` be split into smaller, more focused modules?**
  _Cohesion score 0.05952380952380952 - nodes in this community are weakly interconnected._
- **Should `Session Store & Lifecycle` be split into smaller, more focused modules?**
  _Cohesion score 0.10104529616724739 - nodes in this community are weakly interconnected._