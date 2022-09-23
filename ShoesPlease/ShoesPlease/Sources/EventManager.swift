//
//  EventManager.swift
//  ShoesPlease
//
//  Created by YoungK on 2022/08/05.
//

import Foundation
import EventKit

class EventManager {
    static let shared = EventManager()
    
    func isAccessPermission(store: EKEventStore) async throws -> Bool {
        var isRequestAccessed = false
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined:
            print("EventManager: not Determined")
            isRequestAccessed = try await store.requestAccess(to: .event)
        case .restricted:
            print("EventManager: restricted")
        case .denied:
            // 권한 거부 시 설정 - 제발 한짝만 - 캘린더 접근 허용해야 함
            print("EventManager: denied")
        case .authorized:
            print("EventManager: autorized")
            isRequestAccessed = true
        default:
            print(#fileID, #function, #line, "unknown")
        }
        return isRequestAccessed
    }
    
    func addEvent(startDate: Date, eventName: String) async throws -> Bool {
        let eventStore = EKEventStore()
        print("🔨권한을 요청합니다.")
        let isAccessed = try await isAccessPermission(store: eventStore)
        if isAccessed {
            let calendars = eventStore.calendars(for: .event)
            for calendar in calendars {
                if calendar.title == "캘린더" || calendar.title == "Calendar" {
                    let event = EKEvent(eventStore: eventStore)
                    event.calendar = calendar
                    event.startDate = startDate
                    event.title = eventName
                    event.endDate = event.startDate.addingTimeInterval(1800)// 30 mins
                    let reminder1 = EKAlarm(relativeOffset: 0)
                    event.alarms = [reminder1]
                    do {
                        print("🔨이벤트 등록을 시도합니다.")
                        try eventStore.save(event, span: .thisEvent)
                        print("✅ 이벤트가 등록되었습니다.")
                        return true
                    } catch {
                        print(#fileID, #function, #line, error.localizedDescription)
                    }
                } else {
                    print("캘린더를 찾을 수 없습니다:", calendar.title)
                }
            }
        } else {
            print("❌ 권한이 거부됨")
            return false
        }
        print("❌ addEvent 종료됨")
        return false
    }
    
}
