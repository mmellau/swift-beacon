import SwiftUI
import Beacon

struct TasksView: View {
    @State private var store = TaskStore()
    @State private var showAddSheet = false
    @State private var priorityPickerTask: TaskItem?
    @State private var slideshowTask: Task<Void, Never>?
    @State private var priorityDiscoveryInProgress = false

    private let demoState = DemoState.shared

    var body: some View {
        NavigationStack {
            List {
                if !demoState.onboardingComplete {
                    OnboardingCard(
                        isRunning: Beacon.Sequence.isRunning,
                        onStart: { startOnboarding() }
                    )
                }

                if !demoState.priorityTutorialComplete || !demoState.priorityTryItComplete {
                    PriorityFeatureCard(
                        priorityTryItComplete: demoState.priorityTryItComplete,
                        priorityTutorialComplete: demoState.priorityTutorialComplete,
                        priorityDiscoveryInProgress: priorityDiscoveryInProgress,
                        slideshowRunning: slideshowTask != nil,
                        onTryIt: { Task { await tryPriorityFeature() } },
                        onWatchTutorial: { startPrioritySlideshow() }
                    )
                }

                TasksSection(
                    tasks: store.tasks,
                    firstTaskId: store.tasks.first?.id,
                    firstPriorityTaskId: store.tasks.first(where: { $0.priority != .none })?.id,
                    onToggle: { store.toggle($0) },
                    onDelete: { indexSet in
                        indexSet.forEach { store.delete(store.tasks[$0]) }
                    },
                    onPriorityTap: { priorityPickerTask = $0 }
                )
            }
            .navigationTitle("Tasks")
            .toolbar { toolbarContent }
            .sheet(isPresented: $showAddSheet) {
                AddTaskSheet(
                    onAdd: { store.add($0) },
                    showBeaconTargets: Beacon.Sequence.isRunning
                )
            }
            .sheet(item: $priorityPickerTask) { task in
                PriorityPickerSheet(
                    task: task,
                    showBeaconTargets: slideshowTask != nil,
                    onSelect: { newPriority in
                        if let index = store.tasks.firstIndex(where: { $0.id == task.id }) {
                            store.tasks[index].priority = newPriority
                        }
                    }
                )
            }
        }
        .onDisappear {
            stopAllTutorials()
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus")
            }
            .beaconTarget("add-task")
        }

        ToolbarItem(placement: .topBarLeading) {
            Menu("More", systemImage: "ellipsis.circle") {
                Button("Reset Tasks") { store.reset() }
            }
        }
    }

    private var onboardingSequence: BeaconSequence {
        BeaconSequence {
            BeaconStep(
                targets: [
                    BeaconTarget("add-task", alignment: .bottomTrailing, offset: CGSize(width: 0, height: 60)) {
                        TooltipLabel("Tap here to add a task", systemImage: "hand.tap")
                    }
                ],
                tapBehavior: .custom { showAddSheet = true },
                dimmedTapBehavior: .ignore
            )
            BeaconStep(
                targets: [
                    BeaconTarget("title-field", alignment: .top, offset: CGSize(width: 0, height: -60)) {
                        TooltipLabel("Enter a task name", systemImage: "pencil")
                    }
                ],
                tapBehavior: .advance,
                dimmedTapBehavior: .ignore
            )
            BeaconStep(
                targets: [
                    BeaconTarget("due-toggle", alignment: .top, offset: CGSize(width: 0, height: -60)) {
                        TooltipLabel("Set a due date", systemImage: "calendar")
                    }
                ],
                tapBehavior: .advance,
                dimmedTapBehavior: .ignore
            )
            BeaconStep(
                targets: [
                    BeaconTarget("add-button", alignment: .bottomTrailing, offset: CGSize(width: 0, height: 60)) {
                        TooltipLabel("Save your task", systemImage: "checkmark.circle")
                    }
                ],
                tapBehavior: .custom { showAddSheet = false },
                dimmedTapBehavior: .ignore
            )
            BeaconStep(
                targets: [
                    BeaconTarget("task-checkbox", alignment: .bottomLeading, offset: CGSize(width: 0, height: 60)) {
                        TooltipLabel("Mark it done!", systemImage: "hand.tap")
                    }
                ],
                tapBehavior: .advance,
                dimmedTapBehavior: .ignore
            )
        }
    }

    private func startOnboarding() {
        store.reset()
        Task {
            await Beacon.Sequence.runAsync(onboardingSequence)
            withAnimation { demoState.onboardingComplete = true }
        }
    }

    private func tryPriorityFeature() async {
        priorityDiscoveryInProgress = true

        let result = await Beacon.presentAsync(
            BeaconTarget("priority-tag", alignment: .topTrailing, offset: CGSize(width: 0, height: -60)) {
                TooltipLabel("Tap a priority tag to change it", systemImage: "tag")
            }
        )

        if case .tappedRegion = result {
            if let firstPriorityTask = store.tasks.first(where: { $0.priority != .none }) {
                priorityPickerTask = firstPriorityTask
            }
        }

        priorityDiscoveryInProgress = false
        withAnimation { demoState.priorityTryItComplete = true }
    }

    private var prioritySlideshowSequence: BeaconSequence {
        BeaconSequence {
            BeaconStep(
                targets: ["priority-tag"],
                dimmedTapBehavior: .ignore
            )
            BeaconStep(
                targets: ["priority-high"],
                dimmedTapBehavior: .ignore
            )
            BeaconStep(
                targets: ["priority-medium"],
                dimmedTapBehavior: .ignore
            )
            BeaconStep(
                targets: ["priority-low"],
                dimmedTapBehavior: .ignore
            )
        }
    }

    private func startPrioritySlideshow() {
        Beacon.Sequence.run(prioritySlideshowSequence)

        slideshowTask = Task {
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled, Beacon.Sequence.isRunning else { return }

            if let firstPriorityTask = store.tasks.first(where: { $0.priority != .none }) {
                priorityPickerTask = firstPriorityTask
            }

            try? await Task.sleep(for: .seconds(0.8))

            for _ in 0..<3 {
                guard !Task.isCancelled, Beacon.Sequence.isRunning else { break }
                Beacon.Sequence.next()
                try? await Task.sleep(for: .seconds(2.0))
            }

            Beacon.Sequence.stop()
            priorityPickerTask = nil
            withAnimation { demoState.priorityTutorialComplete = true }
            slideshowTask = nil
        }
    }

    private func stopAllTutorials() {
        slideshowTask?.cancel()
        slideshowTask = nil
        if Beacon.Sequence.isRunning {
            Beacon.Sequence.stop()
        }
    }
}

private struct OnboardingCard: View {
    let isRunning: Bool
    let onStart: () -> Void

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "graduationcap.fill")
                        .foregroundStyle(.blue)
                    Text("Welcome!")
                        .font(.headline)
                }

                Text("Learn how to add and complete tasks.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    onStart()
                } label: {
                    Text("Start Tour")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRunning)
            }
            .padding(.vertical, 8)
        }
    }
}

private struct PriorityFeatureCard: View {
    let priorityTryItComplete: Bool
    let priorityTutorialComplete: Bool
    let priorityDiscoveryInProgress: Bool
    let slideshowRunning: Bool
    let onTryIt: () -> Void
    let onWatchTutorial: () -> Void

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.yellow)
                    Text("Priority Tags")
                        .font(.headline)
                }

                Text("Organize tasks by importance with color-coded priorities.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    if !priorityTryItComplete {
                        Button {
                            onTryIt()
                        } label: {
                            Text("Try It")
                        }
                        .buttonStyle(.bordered)
                        .disabled(priorityDiscoveryInProgress)
                    }

                    if !priorityTutorialComplete {
                        Button {
                            onWatchTutorial()
                        } label: {
                            Text("Watch Tutorial")
                        }
                        .buttonStyle(.bordered)
                        .disabled(slideshowRunning)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

private struct TasksSection: View {
    let tasks: [TaskItem]
    let firstTaskId: UUID?
    let firstPriorityTaskId: UUID?
    let onToggle: (TaskItem) -> Void
    let onDelete: (IndexSet) -> Void
    let onPriorityTap: (TaskItem) -> Void

    var body: some View {
        Section {
            ForEach(tasks) { task in
                TaskRow(
                    task: task,
                    onToggle: { onToggle(task) },
                    beaconId: task.id == firstTaskId ? "task" : nil,
                    priorityBeaconId: task.id == firstPriorityTaskId ? "priority-tag" : nil,
                    onPriorityTap: { onPriorityTap(task) }
                )
            }
            .onDelete { indexSet in
                onDelete(indexSet)
            }
        } header: {
            Text("Tasks")
        }
    }
}

private struct TooltipLabel: View {
    let text: String
    let systemImage: String

    init(_ text: String, systemImage: String) {
        self.text = text
        self.systemImage = systemImage
    }

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.callout)
            .padding()
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
    }
}

#Preview {
    TasksView()
}
