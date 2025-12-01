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
    @State private var taskToEdit: TaskItem? = nil // Tracks which task is being edited
    
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
                        // Allow tapping the row to edit
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
                // Add Button (Top Right)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTaskSheet = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.title2)
                    }
                }
                // Edit Button (for manual drag/drop on pending tasks)
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            // SHEET 1: Creating a NEW task
            .sheet(isPresented: $showingAddTaskSheet) {
                TaskEditSheet(taskToEdit: nil) { title, date, priority in
                    vm.addTask(title: title, date: date, priority: priority)
                    showingAddTaskSheet = false
                }
            }
            // SHEET 2: Editing an EXISTING task
            .sheet(item: $taskToEdit) { task in
                TaskEditSheet(taskToEdit: task) { title, date, priority in
                    var updatedTask = task
                    updatedTask.title = title
                    updatedTask.dueDate = date
                    updatedTask.priority = priority
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
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundColor(task.isCompleted ? .gray : .primary)
            }
            .buttonStyle(.plain) // Prevents the whole row from being clickable by the button style
            
            // Task Name
            Text(task.title)
                .strikethrough(task.isCompleted)
            
            Spacer()
            
            // Date separator stick "|"
            Text("|")
                .foregroundColor(.gray)
            
            // Date (Due or Completed), indicates the coloring of the date
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

// MARK: - Task Edit Sheet (Previously NewTaskSheet)
struct TaskEditSheet: View {
    // Optional task to edit. If nil, we are in "Create Mode"
    var taskToEdit: TaskItem?
    
    // Callback passes back the data to the parent view to handle (add or update)
    var onSave: (String, Date, TaskPriority) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    @State private var taskTitle: String = ""
    @State private var selectedDate: Date = Date()
    @State private var selectedPriority: TaskPriority = .low
    
    // Determine title based on mode
    var modeTitle: String {
        taskToEdit == nil ? "New Task" : "Edit Task"
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Editable Title
                TextField("Task Name", text: $taskTitle)
                    .font(.largeTitle)
                    .padding(.top)
                
                Divider()
                
                // Input Fields
                Group {
                    // Date Due
                    HStack {
                        Text("• Date Due:")
                            .font(.headline)
                        Spacer()
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    
                    // Time Due
                    HStack {
                        Text("• Time Due:")
                            .font(.headline)
                        Spacer()
                        DatePicker("", selection: $selectedDate, displayedComponents: .hourAndMinute)
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
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                // Save Button
                HStack {
                    Spacer()
                    Button(action: {
                        onSave(taskTitle, selectedDate, selectedPriority)
                        dismiss()
                    }) {
                        Text(taskToEdit == nil ? "Add" : "Save")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 10)
                            .background(Color.black)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.black, lineWidth: 1)
                            )
                    }
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(modeTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Pre-fill data if editing an existing task
                if let task = taskToEdit {
                    taskTitle = task.title
                    selectedDate = task.dueDate
                    selectedPriority = task.priority
                } else {
                    // Default values for new task
                    taskTitle = "Task_Name"
                    selectedDate = Date()
                    selectedPriority = .low
                }
            }
        }
    }
}
