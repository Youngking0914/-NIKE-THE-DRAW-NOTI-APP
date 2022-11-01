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
    @Published var drawingItems = [DrawableItem]()
    @Published var drawableItems = [DrawableItem]()
    @Published var launchedItems = [DrawableItem]()
    @Published var isRefreshing = false
    
    var subscription = Set<AnyCancellable>()
    var refreshActionSubject = PassthroughSubject<(), Never>()
    
    init() {
        print("vm init")
        refreshActionSubject.sink { [weak self] _ in
            #if DEBUG
            self?.fakeRefresh()
            self?.fetchLaunchedItems()
            #else
            self?.fetchDrawingItems()
            self?.fetchDrawableItems()
            #endif
        }.store(in: &subscription)
        
        #if DEBUG
        setDummyDrawingItems()
        setDummyDrawableItems()
        fetchLaunchedItems()
        #else
        fetchDrawingItems()
        fetchDrawableItems()
        #endif
    }
    
    deinit { print("vm deinit") }
   
    func setDrawableItems(items: [DrawableItem]?) -> Bool {
        guard let items = items else { return false }
        self.drawableItems = items
        return true
    }
    
    func setDrawingItems(items: [DrawableItem]?) -> Bool {
        guard let items = items else { return false }
        self.drawingItems = items
        return true
    }
    
    func setLaunchedItems(items: [DrawableItem]?) -> Bool {
        guard let items = items else { return false }
        self.launchedItems = items
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
            fetchItemsCalendar()
            self.isRefreshing = false
            HapticManager.shared.notification(success: isSuccess)
        }
    }
    
    /// 응모 진행 중인 아이템들을 가져옵니다.
    func fetchDrawingItems() {
        Task {
            isRefreshing = true
            HapticManager.shared.impact(style: .medium)
            let html = try await networkManager.getLaunchItemPage()
            let items = parseManager.parseDrawingItems(html)
            let isSuccess = setDrawingItems(items: items)
            self.isRefreshing = false
            HapticManager.shared.notification(success: isSuccess)
        }
    }
    
    /// 출시된 아이템들을 가져옵니다.
    func fetchLaunchedItems() {
        print("fetchLaunchedItems called")
        Task {
            isRefreshing = true
            HapticManager.shared.impact(style: .medium)
            let html = try await networkManager.getLaunchItemPage()
            let items = parseManager.parseLaunchedItems(html)
            let isSuccess = setDrawingItems(items: items)
            self.isRefreshing = false
            HapticManager.shared.notification(success: isSuccess)
        }
    }
    
    /// 응모 시작 전인 아이템들의 캘린더를 가져옵니다.
    func fetchItemsCalendar() {
        Task {
            for index in 0..<drawableItems.count {
                let monthDay = try await getStartDate(item: drawableItems[index]).toString(format: "M/dd")
                drawableItems[index].monthDay = monthDay
            }
        }
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
    func setDummyDrawingItems() {
        self.drawingItems = DrawableItem.dummyDrawaingItems
    }
    func getDummyStartDate(item: DrawableItem) -> String {
        item.monthDay ?? ""
    }
    
    func fakeRefresh() {
        DispatchQueue.main.asyncAfter(deadline: .now()+0.5) { [weak self] in
            self?.isRefreshing = false
            HapticManager.shared.notification(success: false)
        }
    }
}
