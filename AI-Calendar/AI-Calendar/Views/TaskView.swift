//
//  TaskView.swift
//  AI-Calendar
//
//  Created by Max Davidoff on 12/1/25.

import SwiftUI
import SwiftData

struct TaskView: View {
    @Environment(TaskViewModel.self) var vm
    @Environment(\.modelContext) var context
    @Environment(CalendarEventViewModel.self) var calendarVM

    // SwiftData live queries
    @Query(filter: #Predicate<TaskItem> { !$0.isCompleted },
           sort: \TaskItem.dueDate)
    var pendingTasks: [TaskItem]

    @Query(filter: #Predicate<TaskItem> { $0.isCompleted },
           sort: \TaskItem.completedDate)
    var completedTasks: [TaskItem]

    @State private var showingAddTaskSheet = false
    @State private var taskToEdit: TaskItem? = nil
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - To Do Section
                Section(header: Text(vm.pendingTasks.isEmpty && vm.completedTasks.isEmpty ? "Tap on the top right to add your first task!" : "To Do")) {
                    ForEach(vm.pendingTasks) { task in
                        TaskRow(task: task) {
                            withAnimation { vm.toggleCompletion(for: task, context: context) }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { taskToEdit = task }
                    }
                    .onDelete { offsets in
                        offsets.map { pendingTasks[$0] }.forEach { vm.delete($0, context: context) }
                    }
                }
                
                // MARK: - Completed Section
                if !completedTasks.isEmpty {
                    Section(header: Text("Completed")) {
                        ForEach(completedTasks) { task in
                            TaskRow(task: task) {
                                withAnimation { vm.toggleCompletion(for: task, context: context) }
                            }
                            .foregroundColor(.gray)
                        }
                        .onDelete { offsets in
                            offsets.map { completedTasks[$0] }.forEach { vm.delete($0, context: context) }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddTaskSheet = true } label: {
                        Image(systemName: "plus.circle").font(.title2)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddTaskSheet) {
                TaskEditSheet(taskToEdit: nil) { title, date, priority, duration in
                    let t = TaskItem(
                        title: title,
                        isCompleted: false,
                        dueDate: date,
                        priority: priority,
                        completedDate: nil,
                        duration: duration
                    )
                    vm.addTask(t, context: context)
                }
            }
            .sheet(item: $taskToEdit) { task in
                TaskEditSheet(taskToEdit: task) { title, date, priority, duration in
                    task.title = title
                    task.dueDate = date
                    task.priority = priority
                    task.duration = duration
                    vm.updateTask(task, context: context)
                    taskToEdit = nil
                }
            }
            .onAppear {
                vm.calendarVM = calendarVM
                vm.syncToCalendar(context: context)
            }
            .environment(vm)
        }
    }
}

// MARK: - Subviews

struct TaskRow: View {
    let task: TaskItem
    var onToggle: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                    .foregroundColor(task.isCompleted ? .gray : .primary)
                    .font(.title2)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading) {
                Text(task.title).strikethrough(task.isCompleted)
                Text("Est: \(Int(task.duration/60)) mins")
                    .font(.caption).foregroundColor(.gray)
            }
            
            Spacer()
            
            if !task.isCompleted {
                Text(task.dueDate.formatted(date: .numeric, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(task.priority == .high ? .red : .primary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct TaskEditSheet: View {
    var taskToEdit: TaskItem?
    var onSave: (String, Date, TaskPriority, TimeInterval) -> Void

    @Environment(\.dismiss) var dismiss
    @Environment(TaskViewModel.self) var vm

    @State private var title = ""
    @State private var date = Date()
    @State private var priority: TaskPriority = .medium
    @State private var duration: TimeInterval = 3600
    @State private var loading: Bool = false
    @State private var parseError: Bool = false
    
    let durations: [(String, TimeInterval)] = [
        ("15 min", 900), ("30 min", 1800), ("45 min", 2700),
        ("1 hour", 3600), ("1.5 hr", 5400), ("2 hr", 7200)
    ]
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Task Name", text: $title)
                
                Section("Smart Input") {
                    Button {
                        Task {
                            do {
                                parseError = false
                                loading = true

                                let newTask = try await vm.parseStringForTask(title)

                                title = newTask.title
                                date = newTask.dueDate
                                priority = newTask.priority
                                duration = newTask.duration

                                loading = false
                            } catch {
                                parseError = true       // <-- updated
                                loading = false
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text(
                                parseError ? "Something went wrong. Try again!" :
                                loading ? "Analyzing..." :
                                "Use natural language"
                            )
                        }
                    }
                }

                
                Section("Details") {
                    DatePicker("Due Date",
                               selection: $date,
                               displayedComponents: [.date, .hourAndMinute])
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    
                    Picker("Duration", selection: $duration) {
                        ForEach(durations, id: \.1) { opt in
                            Text(opt.0).tag(opt.1)
                        }
                    }
                }
                
                Section {
                    Button("Save") {
                        onSave(title, date, priority, duration)
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle(taskToEdit == nil ? "New Task" : "Edit Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let t = taskToEdit {
                    title = t.title
                    date = t.dueDate
                    priority = t.priority
                    duration = t.duration
                }
            }
        }
    }
}


#Preview {
    TaskView().environment(TaskViewModel())
}
