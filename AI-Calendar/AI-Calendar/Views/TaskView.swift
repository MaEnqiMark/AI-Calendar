//
//  TaskView.swift
//  AI-Calendar
//
//  Created by Max Davidoff on 12/1/25.
//

import SwiftUI

struct TaskView: View {
    @Environment(TaskViewModel.self) var vm
    
    @State private var showingAddTaskSheet = false
    @State private var taskToEdit: TaskItem? = nil
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - To Do Section
                Section(header: Text("To Do")) {
                    ForEach(vm.pendingTasks) { task in
                        TaskRow(task: task) {
                            withAnimation { vm.toggleCompletion(for: task) }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { taskToEdit = task }
                    }
                    .onDelete { offsets in vm.delete(at: offsets, isCompleted: false) }
                    .onMove { source, dest in
                        vm.move(from: source, to: dest)
                    }
                }
                
                // MARK: - Completed Section
                if !vm.completedTasks.isEmpty {
                    Section(header: Text("Completed")) {
                        ForEach(vm.completedTasks) { task in
                            TaskRow(task: task) {
                                withAnimation { vm.toggleCompletion(for: task) }
                            }
                            .foregroundColor(.gray)
                        }
                        .onDelete { offsets in vm.delete(at: offsets, isCompleted: true) }
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
                    var t = TaskItem(title: title, dueDate: date, priority: priority)
                    t.duration = duration
                    vm.addTask(t)
                }
            }
            .sheet(item: $taskToEdit) { task in
                TaskEditSheet(taskToEdit: task) { title, date, priority, duration in
                    var t = task
                    t.title = title
                    t.dueDate = date
                    t.priority = priority
                    t.duration = duration
                    vm.updateTask(t)
                    taskToEdit = nil
                }
            }.environment(vm)
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
    @State private var priority: TaskPriority = .low
    @State private var duration: TimeInterval = 3600
    @State private var loading: Bool = false
    
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
                                loading = true
                                let newTask = try await vm.parseStringForTask(title)
                                title = newTask.title
                                date = newTask.dueDate
                                priority = newTask.priority
                                duration = newTask.duration
                                loading = false
                            } catch {
                                print("error")
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text(loading ? "Analyzing..." : "Use natural language")
                        }
                    }
                }
                
                Section("Details") {
                    DatePicker("Due Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    
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
