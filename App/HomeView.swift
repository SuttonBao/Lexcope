import SwiftUI
import LexcopeCore

struct HomeView: View {
    @EnvironmentObject private var model: AppModel
    @State private var isStudying = false
    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(model.now.formatted(.dateTime.month(.wide).day().weekday(.wide)))
                                .font(.subheadline).foregroundStyle(.secondary)
                            Text("一点一点，\n记得更久。").font(.largeTitle.weight(.semibold))
                        }
                        Spacer()
                        Image(systemName: "leaf").font(.system(size: 32, weight: .light)).foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                    }.padding(.top, 16)

                    if let state = model.state, !state.activeDeckIDs.isEmpty {
                        studyPanel(state)
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("从一个词集开始").font(.title2.weight(.semibold))
                            Text("选择生活、学术备考词集，或导入你自己的单词与短语。")
                                .foregroundStyle(.secondary)
                            Button("选择词集") { selectedTab = 1 }.buttonStyle(PrimaryButtonStyle())
                        }.panel()
                    }
                    if let state = model.state {
                        HStack(spacing: 16) {
                            metric("今日回忆", value: Learning.reviewedToday(in: state, at: model.now), unit: "词")
                            metric("连续学习", value: Learning.streak(in: state, at: model.now), unit: "天")
                        }
                        VStack(alignment: .leading, spacing: 12) {
                            Text("先回忆，再看答案").font(.headline)
                            Text("卡片上只留单词与音标。按真实熟悉度评分，把下一次见面的时间交给复习计划。")
                                .font(.subheadline).foregroundStyle(.secondary).lineSpacing(4)
                        }.padding(.vertical, 8)
                        if !state.activeDeckIDs.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("正在学习").font(.headline)
                                    Spacer()
                                    Button("管理") { selectedTab = 1 }.font(.subheadline)
                                }
                                ForEach(state.decks.filter { state.activeDeckIDs.contains($0.id) }) { deck in
                                    HStack {
                                        Text(deck.title)
                                        Spacer()
                                        Text("\(deck.wordIDs.count) 词").foregroundStyle(.secondary)
                                    }.font(.subheadline)
                                }
                            }.panel()
                        }
                    }
                }.padding(24).frame(maxWidth: 680).frame(maxWidth: .infinity)
            }
            .background(Theme.canvas)
            .navigationTitle("Lexcope").inlineTitle()
            .navigationDestination(isPresented: $isStudying) { StudyView() }
            .refreshable { model.refresh() }
        }
    }

    private func studyPanel(_ state: AppState) -> some View {
        let queue = model.queue
        return VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .firstTextBaseline) {
                Text(queue.wordIDs.isEmpty ? "此刻已完成" : "今天的记忆计划").font(.headline)
                Spacer()
                Text("复习优先").font(.caption).foregroundStyle(Theme.accent)
            }
            HStack(spacing: 32) {
                count(queue.due.count, label: "待复习")
                count(queue.new.count, label: "待学新词")
            }
            if queue.wordIDs.isEmpty {
                if let next = queue.nextReviewAt {
                    Text("下次复习 \(next.formatted(date: .abbreviated, time: .shortened))")
                        .font(.subheadline).foregroundStyle(.secondary)
                } else {
                    Text("当前词集已学完，或今天的新词额度已用完。明天再见，也可以添加其他词集。")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Button(queue.wordIDs.isEmpty ? "查看学习状态" : "开始记忆") {
                model.refresh(); isStudying = true
            }.buttonStyle(PrimaryButtonStyle())
            Text("今日已学新词 \(queue.studiedNewToday) / \(state.settings.dailyNewLimit)")
                .font(.footnote).foregroundStyle(.secondary)
        }.panel()
    }

    private func count(_ value: Int, label: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(value)").font(.system(.largeTitle, design: .rounded).weight(.medium)).monospacedDigit()
            Text(label).font(.subheadline).foregroundStyle(.secondary)
        }
    }
    private func metric(_ title: String, value: Int, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.subheadline).foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(value)").font(.title.weight(.semibold)).monospacedDigit()
                Text(unit).font(.subheadline).foregroundStyle(.secondary)
            }
        }.frame(maxWidth: .infinity, alignment: .leading).panel()
    }
}
