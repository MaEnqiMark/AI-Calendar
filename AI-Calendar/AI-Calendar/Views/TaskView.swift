//
//  TaskView.swift
//  AI-Calendar
//
//  Created by Max Davidoff on 12/1/25.
//

import SwiftUI

struct TaskView: View {
    @StateObject private var vm = TaskViewModel()
    @State private var showingAddTaskSheet = false
    @State private var taskToEdit: TaskItem? = nil
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - To Do Section
                Section(header: Text("To do:")) {
                    ForEach(vm.pendingTasks) { task in
                        TaskRow(task: task) {
                            withAnimation {
                                vm.toggleCompletion(for: task)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            taskToEdit = task
                        }
                    }
                    .onDelete { offsets in
                        vm.delete(at: offsets, isCompletedSection: false)
                    }
                    .onMove { source, destination in
                        vm.move(from: source, to: destination)
                    }
                }
                
                // MARK: - Completed Section
                if !vm.completedTasks.isEmpty {
                    Section(header: Text("Completed:")) {
                        ForEach(vm.completedTasks) { task in
                            TaskRow(task: task) {
                                withAnimation {
                                    vm.toggleCompletion(for: task)
                                }
                            }
                            .foregroundColor(.gray)
                        }
                        .onDelete { offsets in
                            vm.delete(at: offsets, isCompletedSection: true)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTaskSheet = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.title2)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            // SHEET 1: New Task
            .sheet(isPresented: $showingAddTaskSheet) {
                TaskEditSheet(taskToEdit: nil) { title, date, priority, duration in
                    var newTask = TaskItem(title: title, dueDate: date, priority: priority)
                    newTask.duration = duration
                    vm.addTask(newTask)
                    showingAddTaskSheet = false
                }
            }
            // SHEET 2: Edit Task
            .sheet(item: $taskToEdit) { task in
                TaskEditSheet(taskToEdit: task) { title, date, priority, duration in
                    var updatedTask = task
                    updatedTask.title = title
                    updatedTask.dueDate = date
                    updatedTask.priority = priority
                    updatedTask.duration = duration
                    vm.updateTask(updatedTask)
                    taskToEdit = nil
                }
            }
        }
    }
}

// MARK: - Task Row View
struct TaskRow: View {
    let task: TaskItem
    var onToggle: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundColor(task.isCompleted ? .gray : .primary)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                // Show duration in subtitle
                Text("Est: \(Int(task.duration/60)) mins")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text("|").foregroundColor(.gray)
            
            if task.isCompleted, let completedDate = task.completedDate {
                Text(completedDate.formatted(date: .numeric, time: .omitted))
                    .font(.subheadline)
            } else {
                Text(task.dueDate.formatted(date: .numeric, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(task.priority == .high ? .red : .primary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Task Edit Sheet
struct TaskEditSheet: View {
    var taskToEdit: TaskItem?
    var onSave: (String, Date, TaskPriority, TimeInterval) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    @State private var taskTitle: String = ""
    @State private var selectedDate: Date = Date()
    @State private var selectedPriority: TaskPriority = .low
    @State private var selectedDuration: TimeInterval = 3600 // Default 1 hour
    
    let durationOptions: [(String, TimeInterval)] = [
        ("15 min", 900),
        ("30 min", 1800),
        ("45 min", 2700),
        ("1 hour", 3600),
        ("1.5 hours", 5400),
        ("2 hours", 7200),
        ("3 hours", 10800)
    ]
    
    var modeTitle: String { taskToEdit == nil ? "New Task" : "Edit Task" }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                TextField("Task Name", text: $taskTitle)
                    .font(.largeTitle)
                    .padding(.top)
                
                Divider()
                
                Group {
                    // Date
                    HStack {
                        Text("• Due Date:")
                            .font(.headline)
                        Spacer()
                        DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                    }
                    
                    // Priority
                    HStack {
                        Text("• Priority:")
                            .font(.headline)
                        Spacer()
                        Picker("Priority", selection: $selectedPriority) {
                            ForEach(TaskPriority.allCases, id: \.self) { priority in
                                Text(priority.rawValue).tag(priority)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    // Duration Picker
                    HStack {
                        Text("• Duration:")
                            .font(.headline)
                        Spacer()
                        Picker("Duration", selection: $selectedDuration) {
                            ForEach(durationOptions, id: \.1) { option in
                                Text(option.0).tag(option.1)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    Button(action: {
                        onSave(taskTitle, selectedDate, selectedPriority, selectedDuration)
                        dismiss()
                    }) {
                        Text(taskToEdit == nil ? "Add" : "Save")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 10)
                            .background(Color.black)
                            .cornerRadius(20)
                    }
                }
            }
            .padding()
            .navigationTitle(modeTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let task = taskToEdit {
                    taskTitle = task.title
                    selectedDate = task.dueDate
                    selectedPriority = task.priority
                    selectedDuration = task.duration
                } else {
                    taskTitle = "Task Name"
                    selectedDate = Date()
                    selectedPriority = .low
                    selectedDuration = 3600
                }
            }
        }
    }
}
