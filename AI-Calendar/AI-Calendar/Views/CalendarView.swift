import SwiftUI

// =======================================================
// MARK: - GLOBAL CALENDAR (local timezone, always correct)
// =======================================================

let appCalendar: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone.current
    return c
}()

// Build "today at hour" in local timezone
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

    // Unified, correct “start of week”
    func weekStart(for offset: Int) -> Date {
        let today = Date()
        let startOfWeek = appCalendar.dateInterval(of: .weekOfYear, for: today)!.start

        var dc = appCalendar.dateComponents([.year, .month, .day], from: startOfWeek)
        dc.timeZone = .current
        dc.hour = 0
        dc.minute = 0
        dc.second = 0

        let localStart = appCalendar.date(from: dc)!
        return appCalendar.date(byAdding: .day, value: offset * 7, to: localStart)!
    }

    var body: some View {
        GeometryReader { geo in
            let dayWidth = (geo.size.width - 50) / 7.0

            VStack(spacing: 0) {

                let ws = weekStart(for: currentWeekOffset)
                let we = appCalendar.date(byAdding: .day, value: 6, to: ws)!

                // HEADER
                Text(weekRangeString(start: ws, end: we))
                    .font(.title3)
                    .bold()
                    .padding(.top, 8)

                // DAY LABELS
                HStack(spacing: 0) {
                    ForEach(0..<7) { offset in
                        let d = appCalendar.date(byAdding: .day, value: offset, to: ws)!
                        VStack {
                            Text(weekdayString(d))
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(dayString(d))
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 8)

                Divider()

                // WEEK PAGES
                TabView(selection: $currentWeekOffset) {
                    ForEach(-10...10, id: \.self) { offset in
                        ScrollableWeekView(
                            weekStart: weekStart(for: offset),
                            dayWidth: dayWidth,
                            events: vm.events                // <-- HERE
                        )
                        .tag(offset)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                HStack(spacing: 20) {
                    // RETURN TO TODAY BUTTON
                    Button {
                        withAnimation {
                            currentWeekOffset = 0
                        }
                    } label: {
                        Image(systemName: "calendar.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                    }

                    // JUMP TO DATE BUTTON
                    Button {
                        showingDatePicker = true
                    } label: {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 28))
                            .foregroundColor(.green)
                    }
                }
                .padding(.vertical, 12)
                .sheet(isPresented: $showingDatePicker) {
                    VStack {
                        DatePicker(
                            "Jump to date",
                            selection: $selectedDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .padding()

                        Button("Go") {
                            jumpToWeek(of: selectedDate)
                            showingDatePicker = false
                        }
                        .padding()
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
            
    }
    
    func jumpToWeek(of date: Date) {
        let startOfTodayWeek = weekStart(for: 0)
        let startOfTargetWeek = appCalendar.dateInterval(of: .weekOfYear, for: date)!.start

        // difference in days / 7 = offset
        let diff = appCalendar.dateComponents([.day], from: startOfTodayWeek, to: startOfTargetWeek).day ?? 0
        currentWeekOffset = diff / 7
    }

}


// =======================================================
// MARK: - SCROLLABLE WEEK VIEW
// =======================================================

struct ScrollableWeekView: View {
    let weekStart: Date
    let dayWidth: CGFloat
    @State private var showingEventSheet = false
    @State private var selectedEvent: CalendarEvent? = nil
    let events: [CalendarEvent]

    private let hourHeight: CGFloat = 60

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                HStack(alignment: .top, spacing: 0) {

                    // LEFT COLUMN: HOURS
                    VStack(spacing: 0) {
                        ForEach(0..<24) { hour in
                            Text("\(hour):00")
                                .id("hour-\(hour)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .frame(height: hourHeight, alignment: .top)
                                .padding(.leading, 4)
                        }
                    }
                    .frame(width: 50)

                    // RIGHT SIDE: GRID + EVENTS
                    GeometryReader { geo in
                        let fullHeight = hourHeight * 24

                        ZStack(alignment: .topLeading) {

                            // HOUR GRID LINES (exactly hourHeight tall)
                            VStack(spacing: 0) {
                                ForEach(0..<24) { _ in
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(height: hourHeight)
                                        .overlay(
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(height: 1),
                                            alignment: .top
                                        )
                                }
                            }

                            // DAY COLUMNS + EVENTS
                            HStack(spacing: 0) {
                                ForEach(0..<7) { offset in
                                    let date = appCalendar.date(byAdding: .day, value: offset, to: weekStart)!

                                    ZStack(alignment: .top) {
                                        ForEach(eventsForDay(date)) { event in
                                            eventView(event, hourHeight: hourHeight)
                                        }

                                        if appCalendar.isDateInToday(date) {
                                            nowLine
                                        }
                                    }
                                    .frame(width: dayWidth)

                                    if offset != 6 {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 1)
                                    }
                                }
                            }
                            .zIndex(2)
                        }
                        .frame(height: fullHeight)
                    }
                }
            }
            .onAppear {
                proxy.scrollTo("hour-7", anchor: .top)
            }
            
        }    .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event)
        }
    }

    // EVENTS FOR A SPECIFIC DAY
    func eventsForDay(_ date: Date) -> [CalendarEvent] {
        events.filter {
            appCalendar.isDate($0.start, equalTo: date, toGranularity: .day)
        }
    }

    // EVENT VIEW WITH EXPLICIT hourHeight
    func eventView(_ event: CalendarEvent, hourHeight: CGFloat) -> some View {
        let startFraction = hourFraction(event.start)     // 3.0 for 3:00, etc.
        let endFraction   = hourFraction(event.end)

        let yOffset = (startFraction - 9) * hourHeight
        let height  = max((endFraction - startFraction) * hourHeight, 4)
        
        return VStack(alignment: .leading) {
            Text(event.title)
                .font(.caption)
                .foregroundColor(.white)
                .padding(4)
        }
        .frame(height: height, alignment: .top)
        .frame(maxWidth: .infinity)
        .background(event.color)
        .cornerRadius(6)
        .offset(y: yOffset)
        .onTapGesture {
            selectedEvent = event     // <— store tap
            showingEventSheet = true
        }
    }

    // “NOW” RED LINE USING SAME COORD SYSTEM
    var nowLine: some View {
        // same visual +9h shift you applied to events
        let shiftedNow = Date().addingTimeInterval(-9 * 60 * 60)
        let pos = hourFraction(shiftedNow) * hourHeight

        return Rectangle()
            .fill(Color.red)
            .frame(height: 2)
            .offset(y: pos)
    }


    func hourFraction(_ date: Date) -> CGFloat {
        let dc = appCalendar.dateComponents([.hour, .minute], from: date)
        let h = CGFloat(dc.hour ?? 0)
        let m = CGFloat(dc.minute ?? 0)
        return h + m / 60.0
    }
    
}

// =======================================================
// MARK: - DATE HELPERS
// =======================================================

func weekdayString(_ date: Date) -> String {
    let df = DateFormatter()
    df.calendar = appCalendar
    df.timeZone = .current
    df.dateFormat = "EEE"
    return df.string(from: date)
}

func dayString(_ date: Date) -> String {
    let df = DateFormatter()
    df.calendar = appCalendar
    df.timeZone = .current
    df.dateFormat = "d"
    return df.string(from: date)
}

func weekRangeString(start: Date, end: Date) -> String {
    let df = DateFormatter()
    df.calendar = appCalendar
    df.timeZone = .current
    df.dateFormat = "MMMM yyyy"
    return "\(df.string(from: start)) – \(df.string(from: end))"
}
