import EventKit
import Foundation

protocol ProductivityActionServicing {
    func createReminder(title: String, dueDate: Date?) async -> String
    func createCalendarEvent(title: String, startDate: Date?) async -> String
}

final class EventKitActionService: ProductivityActionServicing {
    private let eventStore = EKEventStore()

    func createReminder(title: String, dueDate: Date?) async -> String {
        let hasAccess = await requestReminderAccess()
        guard hasAccess else {
            return "Reminder access denied. Enable access in Settings."
        }

        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.calendar = eventStore.defaultCalendarForNewReminders()

        if let dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: dueDate
            )
        }

        do {
            try eventStore.save(reminder, commit: true)
            return dueDate == nil ? "Reminder created (no due date)." : "Reminder created."
        } catch {
            return "Could not create reminder."
        }
    }

    func createCalendarEvent(title: String, startDate: Date?) async -> String {
        let hasAccess = await requestCalendarAccess()
        guard hasAccess else {
            return "Calendar access denied. Enable access in Settings."
        }

        guard let calendar = eventStore.defaultCalendarForNewEvents else {
            return "No default calendar is available."
        }

        let eventStartDate = startDate ?? Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        let eventEndDate = Calendar.current.date(byAdding: .hour, value: 1, to: eventStartDate) ?? eventStartDate.addingTimeInterval(3600)

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.calendar = calendar
        event.startDate = eventStartDate
        event.endDate = eventEndDate

        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            if startDate == nil {
                return "Calendar event created with a fallback time."
            }
            return "Calendar event created."
        } catch {
            return "Could not create calendar event."
        }
    }

    private func requestReminderAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            let status = EKEventStore.authorizationStatus(for: .reminder)
            if status == .fullAccess || status == .authorized {
                return true
            }
        } else if EKEventStore.authorizationStatus(for: .reminder) == .authorized {
            return true
        }

        if #available(iOS 17.0, *) {
            return (try? await eventStore.requestFullAccessToReminders()) ?? false
        }

        return await withCheckedContinuation { continuation in
            eventStore.requestAccess(to: .reminder) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    private func requestCalendarAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            let status = EKEventStore.authorizationStatus(for: .event)
            if status == .writeOnly || status == .fullAccess || status == .authorized {
                return true
            }
            return (try? await eventStore.requestWriteOnlyAccessToEvents()) ?? false
        }

        if EKEventStore.authorizationStatus(for: .event) == .authorized {
            return true
        }

        return await withCheckedContinuation { continuation in
            eventStore.requestAccess(to: .event) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }
}
