//
//  CalendarEvent.swift
//  AI-Calendar
//
//  Created by 马恩奇 on 11/30/25.
//

import SwiftUI

// =======================================================
// MARK: - GLOBAL CALENDAR
// =======================================================
var appCalendar: Calendar {
    // Returns the user's current system calendar
    return Calendar.current
}

func todayAt(hour: Int) -> Date {
    let now = Date()
    let base = appCalendar.dateComponents([.year, .month, .day], from: now)
    var dc = DateComponents()
    dc.timeZone = .current
    dc.year = base.year
    dc.month = base.month
    dc.day = base.day
    dc.hour = hour
    return appCalendar.date(from: dc)!
}

// =======================================================
// MARK: - MAIN CALENDAR VIEW
// =======================================================

struct CalendarView: View {
    @Environment(CalendarEventViewModel.self) var vm
    @Environment(AuthViewModel.self) var auth

    @State private var currentWeekOffset = 0
    
    @State private var showingDatePicker = false
    @State private var selectedDate = Date()

    func weekStart(for offset: Int) -> Date {
        let today = Date()
        let startOfWeek = appCalendar.dateInterval(of: .weekOfYear, for: today)!.start
        var dc = appCalendar.dateComponents([.year, .month, .day], from: startOfWeek)
        dc.timeZone = .current; dc.hour = 0; dc.minute = 0; dc.second = 0
        let localStart = appCalendar.date(from: dc)!
        return appCalendar.date(byAdding: .day, value: offset * 7, to: localStart)!
    }
    
    

    var body: some View {
        NavigationView {
            GeometryReader { geo in
                let dayWidth = (geo.size.width - 50) / 7.0
                VStack(spacing: 0) {
                    let ws = weekStart(for: currentWeekOffset)
                    let we = appCalendar.date(byAdding: .day, value: 6, to: ws)!

                    // Header
                    Text(weekRangeString(start: ws, end: we))
                        .font(.title3).bold().padding(.top, 8)

                    // Day Labels
                    HStack(spacing: 0) {
                        ForEach(0..<7) { offset in
                            let d = appCalendar.date(byAdding: .day, value: offset, to: ws)!
                            VStack {
                                Text(weekdayString(d)).font(.caption).foregroundColor(.gray)
                                Text(dayString(d)).font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 8)

                    Divider()

                    // Week Pages
                    TabView(selection: $currentWeekOffset) {
                        ForEach(-10...10, id: \.self) { offset in
                            ScrollableWeekView(
                                weekStart: weekStart(for: offset),
                                dayWidth: dayWidth,
                                events: vm.getEvents()
                            )
                            .tag(offset)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    // Controls
                    HStack(spacing: 20) {
                        Button { withAnimation { currentWeekOffset = 0 } } label: {
                            Image(systemName: "calendar.circle.fill").font(.largeTitle).foregroundColor(.blue)
                        }
                        Button { showingDatePicker = true } label: {
                            Image(systemName: "calendar.badge.plus").font(.largeTitle).foregroundColor(.green)
                        }
                    }
                    .padding()
                    .sheet(isPresented: $showingDatePicker) {
                        VStack {
                            DatePicker("Jump", selection: $selectedDate, displayedComponents: .date)
                                .datePickerStyle(.graphical).padding()
                            Button("Go") { jumpToWeek(of: selectedDate); showingDatePicker = false }.padding()
                        }
                    }
                }
            }
        }.onChange(of: currentWeekOffset) {
            guard let currentUser = auth.getUser() else {
                print("No user!")
                return
            }
            Task {
                await vm.checkIfMustFetchEvents(offset: currentWeekOffset, user: currentUser)
            }
        }
        .navigationBarHidden(true)

    }
    
    func jumpToWeek(of date: Date) {
        let startOfToday = weekStart(for: 0)
        let targetStart = appCalendar.dateInterval(of: .weekOfYear, for: date)!.start
        let diff = appCalendar.dateComponents([.day], from: startOfToday, to: targetStart).day ?? 0
        currentWeekOffset = diff / 7
    }
}

// =======================================================
// MARK: - SCROLLABLE WEEK VIEW
// =======================================================

struct ScrollableWeekView: View {
    let weekStart: Date
    let dayWidth: CGFloat
    @State private var selectedEvent: CalendarEvent? = nil
    let events: [CalendarEvent]
    private let hourHeight: CGFloat = 60

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                HStack(alignment: .top, spacing: 0) {
                    // Hours
                    VStack(spacing: 0) {
                        ForEach(0..<24) { h in
                            Text("\(h):00").font(.caption2).foregroundColor(.gray)
                                .frame(height: hourHeight, alignment: .top).id("hour-\(h)")
                        }
                    }.frame(width: 50)

                    // Grid
                    GeometryReader { geo in
                        ZStack(alignment: .topLeading) {
                            // Lines
                            VStack(spacing: 0) {
                                ForEach(0..<24) { _ in
                                    Rectangle().fill(Color.clear).frame(height: hourHeight)
                                        .overlay(Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 1), alignment: .top)
                                }
                            }
                            // Events
                            HStack(spacing: 0) {
                                ForEach(0..<7) { offset in
                                    let date = appCalendar.date(byAdding: .day, value: offset, to: weekStart)!
                                    ZStack(alignment: .top) {
                                        ForEach(eventsForDay(date)) { event in
                                            eventView(event)
                                        }
                                        if appCalendar.isDateInToday(date) { nowLine }
                                    }
                                    .frame(width: dayWidth)
                                    // This one line fixed everything!!!!
                                    .frame(height: 24 * hourHeight, alignment: .top)
                                    if offset != 6 { Rectangle().fill(Color.gray.opacity(0.3)).frame(width: 1) }
                                }
                            }
                        }
                    }
                }
            }
            .onAppear { proxy.scrollTo("hour-7", anchor: .top) }
            .sheet(item: $selectedEvent) { event in EventDetailView(event: event) }
        }
    }

    func eventsForDay(_ date: Date) -> [CalendarEvent] {
        events.filter { appCalendar.isDate($0.start, equalTo: date, toGranularity: .day) }
    }

    func eventView(_ event: CalendarEvent) -> some View {
        let startF = hourFraction(event.start)
        let endF = hourFraction(event.end)
        let y = startF * hourHeight
        let h = max((endF - startF) * hourHeight, 15)
        
        return VStack(alignment: .leading) {
            Text(event.title).font(.caption).foregroundColor(.white).padding(4)
        }
        .frame(height: h, alignment: .top).frame(maxWidth: .infinity)
        .background(event.color).cornerRadius(6).offset(y: y)
        .onTapGesture { selectedEvent = event }
    }

    var nowLine: some View {
        let now = Date()
        let pos = hourFraction(now) * hourHeight
        
        return Rectangle() .fill(Color.red) .frame(height: 2) .offset(y: pos)
    }

    func hourFraction(_ date: Date) -> CGFloat {
        let dc = appCalendar.dateComponents([.hour, .minute], from: date)
        return CGFloat(dc.hour ?? 0) + CGFloat(dc.minute ?? 0)/60.0
    }
}

// Helpers
func weekdayString(_ d: Date) -> String {
    let f = DateFormatter(); f.dateFormat = "EEE"; return f.string(from: d)
}
func dayString(_ d: Date) -> String {
    let f = DateFormatter(); f.dateFormat = "d"; return f.string(from: d)
}
func weekRangeString(start: Date, end: Date) -> String {
    let f = DateFormatter(); f.dateFormat = "MMM yyyy"; return "\(f.string(from: start)) – \(f.string(from: end))"
}
