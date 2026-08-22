import Foundation

/// z.ai 공식 피크타임(혼잡 시간대) 정책 기반 계산 헬퍼.
/// 피크: 월–금 14:00–18:00 (UTC+8, Singapore Standard Time) = KST 15:00–19:00
/// 참고: https://docs.z.ai/devpack/overview
struct PeakHours {
    static let startHourUTC8 = 14
    static let endHourUTC8 = 18

    private static var utc8Calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Singapore") ?? TimeZone.current
        return calendar
    }

    private static var kstTimeZone: TimeZone {
        TimeZone(identifier: "Asia/Seoul") ?? TimeZone.current
    }

    /// KST 기준 표기용 시간 라벨 (예: "15:00–19:00")
    static var windowLabelKST: String {
        let kstStart = startHourUTC8 + 1
        let kstEnd = endHourUTC8 + 1
        return String(format: "%02d:00–%02d:00", kstStart, kstEnd)
    }

    /// 지금이 혼잡(피크) 시간대인지. 주말은 항상 비혼잡.
    static func isPeak(at date: Date = Date()) -> Bool {
        let calendar = utc8Calendar
        let weekday = calendar.component(.weekday, from: date)
        let isWeekday = (2...6).contains(weekday) // 월=2 ... 금=6
        guard isWeekday else { return false }

        let hour = calendar.component(.hour, from: date)
        return hour >= startHourUTC8 && hour < endHourUTC8
    }

    /// 현재 시점 기준 다음 상태 전환까지 남은 초.
    /// 피크 중이면 종료까지, 비혼잡이면 다음 피크 시작까지.
    static func secondsUntilTransition(at date: Date = Date()) -> Int {
        let calendar = utc8Calendar
        let now = date

        if isPeak(at: now) {
            var end = calendar.date(bySettingHour: endHourUTC8, minute: 0, second: 0, of: now) ?? now
            if end <= now {
                end = calendar.date(byAdding: .day, value: 1, to: end) ?? now
            }
            return max(Int(end.timeIntervalSince(now)), 0)
        }

        // 다음 피크 시작(월–금 14:00 UTC+8) 탐색: 최대 7일 앞까지
        for dayOffset in 0...7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let weekday = calendar.component(.weekday, from: day)
            guard (2...6).contains(weekday) else { continue }

            if let start = calendar.date(bySettingHour: startHourUTC8, minute: 0, second: 0, of: day), start > now {
                return Int(start.timeIntervalSince(now))
            }
        }
        return 0
    }

    /// 오늘(또는 가장 가까운 날)이 주말인지 — 주말 안내 문구용.
    static func isWeekend(at date: Date = Date()) -> Bool {
        let weekday = utc8Calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }

    /// 남은 초를 "2h 13m" 형식으로.
    static func formatRemaining(_ seconds: Int) -> String {
        if seconds <= 0 { return "0m" }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    /// 배너에 표시할 KST 현재 시각 문자열 (디버그/표기용).
    static func kstClockString(at date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = kstTimeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
