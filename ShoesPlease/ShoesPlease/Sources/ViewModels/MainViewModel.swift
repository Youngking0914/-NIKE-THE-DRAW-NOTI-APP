//
//  MainViewModel.swift
//  NikeTheDrawNotiApp
//
//  Created by YoungK on 2022/04/18.
//

import Foundation
import SwiftSoup
import Alamofire
import Combine

class MainViewModel: ObservableObject {
    var parseManager = ParseManager()
    var networkManager = NetworkManager()
    
    @Published var testString = "수신 전"
    @Published var drawableItems = [DrawableItem]()
    @Published var isRefreshing = false
    
    var subscription = Set<AnyCancellable>()
    var refreshActionSubject = PassthroughSubject<(), Never>()
    
    init() {
        print("vm init")
        refreshActionSubject.sink { [weak self] _ in
            self?.fetchDrawableItems()
        }.store(in: &subscription)
        
        fetchDrawableItems()
    }
    
    deinit { print("vm deinit") }
   
    func setDrawableItems(items: [DrawableItem]?) -> Bool {
        guard let items = items else { return false }
        self.drawableItems = items
        return true
    }
    
    /// 응모 시작 전인 아이템들을 가져옵니다.
    func fetchDrawableItems() {
        Task {
            isRefreshing = true
            HapticManager.shared.impact(style: .medium)
            let html = try await networkManager.getLaunchItemPage()
            let items = parseManager.parseDrawableItems(html)
            let isSuccess = setDrawableItems(items: items)
            self.isRefreshing = false
            HapticManager.shared.notification(success: isSuccess)
        }
    }
    
    /// Date 를 String 으로 변환합니다.
    /// - Parameter date: String 으로 변환하고 싶은 Date
    /// - Parameter format: 원하는 변환 형식 ex) "M/dd"
    /// - Returns: String: ex) "9/14"
    func dateToString(from date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        let dateString = formatter.string(from: date)
        print("dateToString:", dateString)
        return dateString
    }
    
    /// 해당 아이템의 응모시작시간을 캘린더에 등록합니다.
    /// - Parameter item: 캘린더에 등록할 아이템
    func addEvent(item: DrawableItem) async throws -> Bool {
        print("🔨VM: addEvent를 호출합니다.")
        let eventName = item.title + " " + item.theme + " " + "응모"
        let startDate = try await getStartDate(item: item)
        let isSuccess = try await EventManager.shared.addEvent(startDate: startDate, eventName: eventName)
        HapticManager.shared.notification(success: isSuccess)
        return isSuccess
    }
    
    /// item 의 응모시작시간을 반환합니다.
    /// - Parameter item: 응모시작시간을 추출할 item
    func getStartDate(item: DrawableItem) async throws -> Date {
        let html = try await networkManager.getLaunchItemDetailPage(from: item)
        guard let calendar = parseManager.parseCalendar(from: html) else { return Date() }
        return parseManager.parseStartDate(from: calendar)
    }
}

// MARK: - 더미 데이터와 관련된 익스텐션입니다.
extension MainViewModel {
    func setDummyDrawableItems() {
        self.drawableItems = DrawableItem.dummyDrawableItems
    }
    func getDummyStartDate(item: DrawableItem) -> Date {
        item.startDate ?? Date()
    }
}