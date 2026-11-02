import SwiftUI
import UserNotifications
#if os(iOS)
import UIKit
#endif
import LexcopeCore

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var draft = LexcopeCore.Settings()
    @State private var reminderTime = Date()
    @State private var loaded = false
    @State private var isSaving = false
    @State private var status: UNAuthorizationStatus = .notDetermined
    @State private var settingsError: String?
    @State private var didSave = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("每天新词：\(draft.dailyNewLimit)", value: $draft.dailyNewLimit, in: 0...200, step: 5)
                    Picker("英语发音", selection: $draft.voiceLanguage) {
                        Text("英式英语").tag("en-GB")
                        Text("美式英语").tag("en-US")
                    }
                } header: { Text("学习节奏") } footer: {
                    Text("每日额度只限制新词。到期复习全部保留。设为 0 时只复习；内置音标采用英式读法，切换语音不会改写音标。")
                }
                Section {
                    Toggle("每日复习提醒", isOn: $draft.reminderEnabled)
                    if draft.reminderEnabled {
                        DatePicker("提醒时间", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        if status == .denied {
                            Text("系统通知权限已关闭，请在系统设置中允许通知。")
                                .font(.footnote).foregroundStyle(.orange)
                            #if os(iOS)
                            Link("打开系统设置", destination: URL(string: UIApplication.openSettingsURLString)!)
                            #endif
                        }
                    }
                } header: { Text("给复习留个时间") } footer: {
                    Text("点击保存后才会请求通知权限。提醒按设备当地时间每天发送，不需要联网；即使当天没有到期单词，也会发送学习提醒。")
                }
                Section("学习记录") {
                    NavigationLink("查看进度与复习安排") { ProgressViewScreen() }
                }
                Section("关于 Lexcope") {
                    NavigationLink("词库来源与授权") { SourcesView() }
                    NavigationLink("数据与隐私") { PrivacyView() }
                    LabeledContent("版本", value: "1.0.0 · V1")
                }
                if didSave {
                    Section { Label("设置已保存", systemImage: "checkmark.circle").foregroundStyle(Theme.accent) }
                }
            }
            .disabled(isSaving)
            .navigationTitle("设置")
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                Button(isSaving ? "保存中…" : "保存") { save() }.disabled(isSaving || !hasChanges)
            } }
            .task {
                if !loaded, let settings = model.state?.settings {
                    draft = settings
                    reminderTime = Calendar.current.date(bySettingHour: settings.reminderHour, minute: settings.reminderMinute, second: 0, of: Date()) ?? Date()
                    loaded = true
                }
                status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus } }
            }
            .alert("设置未保存", isPresented: Binding(get: { settingsError != nil }, set: { if !$0 { settingsError = nil } })) {
                Button("知道了", role: .cancel) { settingsError = nil }
            } message: { Text(settingsError ?? "") }
        }
    }

    private var resolvedSettings: LexcopeCore.Settings {
        var result = draft
        let time = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        result.reminderHour = time.hour ?? 20; result.reminderMinute = time.minute ?? 0
        return result
    }
    private var hasChanges: Bool { resolvedSettings != model.state?.settings }

    private func save() {
        guard !isSaving, let previous = model.state?.settings else { return }
        let updated = resolvedSettings
        isSaving = true; didSave = false
        Task {
            do {
                try await ReminderService.sync(updated, requestPermission: true)
                if model.updateSettings(updated) {
                    draft = updated
                    didSave = true
                } else {
                    try? await ReminderService.sync(previous, requestPermission: false)
                    settingsError = model.errorMessage
                    model.errorMessage = nil
                }
            } catch { settingsError = error.localizedDescription }
            status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            isSaving = false
        }
    }
}

private struct ProgressViewScreen: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        List {
            if let state = model.state {
                Section("今日") {
                    LabeledContent("已回忆的不同单词", value: "\(Learning.reviewedToday(in: state, at: model.now))")
                    LabeledContent("已学新词", value: "\(model.queue.studiedNewToday)")
                    LabeledContent("连续学习", value: "\(Learning.streak(in: state, at: model.now)) 天")
                    LabeledContent("当前到期", value: "\(model.queue.due.count)")
                }
                Section {
                    ForEach(1...7, id: \.self) { day in
                        let date = Calendar.current.date(byAdding: .day, value: day, to: model.now)!
                        let count = Learning.selectedWordIDs(in: state).filter { id in
                            state.progress[id].map { Calendar.current.isDate($0.dueAt, inSameDayAs: date) } ?? false
                        }.count
                        LabeledContent(date.formatted(.dateTime.month().day().weekday()), value: "\(count) 词")
                    }
                } header: { Text("未来 7 天 · 当前词集") } footer: {
                    Text("根据已保存的下次复习时间统计。后续评分会改变安排；尚未学过的新词不计入。")
                }
                Section("累计 · 全部词集") {
                    LabeledContent("已学单词", value: "\(state.progress.count)")
                    LabeledContent("回忆次数", value: "\(state.events.count)")
                }
                Section("复习规则") {
                    Text("认识：1 → 2 → 4 → 7 → 15 → 30 天。达到最后阶段后继续每 30 天巩固。")
                    Text("不认识：重置阶段，5 分钟后重学。模糊：回退一个阶段，10 分钟后重学。")
                    Text("这是受遗忘曲线启发的间隔重复规则，不是对个人记忆率的精确预测。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
        }.navigationTitle("进度与安排").inlineTitle()
    }
}

private struct PrivacyView: View {
    var body: some View {
        List {
            Section("学习数据属于你") {
                Text("词集、导入内容、评分历史和设置保存在设备的应用数据目录中。V1 不需要账号，没有广告或分析 SDK，也不会向 Lexcope 服务器上传数据。")
                Text("发音由 Apple 系统语音合成提供，可用声音取决于设备已安装的语音资源。通知由系统本地调度。")
            }
            Section("备份与卸载") {
                Text("应用数据可能随系统设备备份保存。卸载应用可能移除全部学习记录；V1 暂不提供账户同步或应用内备份恢复。")
                Text("损坏或不兼容的记录不会被静默重置或覆盖。应用会提示重新载入。")
            }
            Section("外部链接") {
                Text("词表来源和授权链接会打开外部网站。其数据处理规则由各网站决定。")
            }
        }.navigationTitle("数据与隐私").inlineTitle()
    }
}
