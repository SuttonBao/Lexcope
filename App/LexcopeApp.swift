import SwiftUI

@main
struct LexcopeApp: App {
    @StateObject private var model = AppModel()
    @StateObject private var speech = SpeechPlayer()
    @State private var selectedTab = 0
    @Environment(\.scenePhase) private var scenePhase
    private let timer = Timer.publish(every: 20, on: .main, in: .common).autoconnect()

    var body: some Scene {
        WindowGroup {
            Group {
                if model.state != nil {
                    TabView(selection: $selectedTab) {
                        HomeView(selectedTab: $selectedTab)
                            .tabItem { Label("今日", systemImage: "sun.max") }.tag(0)
                        LibraryView()
                            .tabItem { Label("词集", systemImage: "books.vertical") }.tag(1)
                        SettingsView()
                            .tabItem { Label("设置", systemImage: "slider.horizontal.3") }.tag(2)
                    }
                } else {
                    ContentUnavailableView {
                        Label("无法打开学习记录", systemImage: "externaldrive.badge.exclamationmark")
                    } description: {
                        Text(model.errorMessage ?? "请重试。原始记录已保留。")
                    } actions: {
                        Button("重新载入") { model.load() }.buttonStyle(.borderedProminent)
                    }
                }
            }
            .environmentObject(model).environmentObject(speech).tint(Theme.accent)
            .alert("操作未完成", isPresented: Binding(get: { model.state != nil && model.errorMessage != nil },
                                                   set: { if !$0 { model.errorMessage = nil } })) {
                Button("知道了", role: .cancel) { model.errorMessage = nil }
            } message: { Text(model.errorMessage ?? "") }
            .alert("发音暂不可用", isPresented: Binding(get: { speech.errorMessage != nil },
                                                   set: { if !$0 { speech.errorMessage = nil } })) {
                Button("知道了", role: .cancel) { speech.errorMessage = nil }
            } message: { Text(speech.errorMessage ?? "") }
            .task {
                if let settings = model.state?.settings {
                    try? await ReminderService.sync(settings, requestPermission: false)
                }
            }
            .onReceive(timer) { _ in if scenePhase == .active { model.refresh() } }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { model.refresh() } else { speech.stop() }
            }
        }
    }
}
