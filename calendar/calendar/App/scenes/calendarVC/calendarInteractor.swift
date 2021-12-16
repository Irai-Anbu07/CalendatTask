//
//  calendarInteractor.swift
//  calendar
//
//  Created by iraiAnbu on 30/11/21.
//  Copyright (c) 2021 ___ORGANIZATIONNAME___. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

protocol calendarBusinessLogic
{
    func doSomething(request: CalendarVC.Something.Request)
    
    func previousMonth() -> ([Day] , Date?)
    
    func nextmonth() -> ([Day] , Date?)
}

protocol calendarDataStore
{
    //var name: String { get set }
}

class calendarInteractor: calendarBusinessLogic, calendarDataStore
{
    func previousMonth() -> ([Day], Date?) {
        self.baseDate = self.calendar.date(
            byAdding: .month,
            value: -1,
            to: self.baseDate ?? Date()
        ) ?? self.baseDate
        
        return ( days , baseDate )
    }
    
    
    
    func nextmonth() -> ([Day] , Date?) {
        
        self.baseDate = self.calendar.date(
            byAdding: .month,
            value: 1,
            to: self.baseDate ?? Date()
        ) ?? self.baseDate
        
        return ( days , baseDate )
    }
    
    
    init(baseDate: Date, selectedDateChanged: @escaping ((Date) -> Void)) {
        self.selectedDate = baseDate
        self.baseDate = baseDate
        self.selectedDateChanged = selectedDateChanged
        
    }
    
    
    var presenter: calendarPresentationLogic?
    var worker: calendarWorker?
    //var name: String = ""
    
    var days: [Day] = []
    var selectedDate: Date
    var selectedDateChanged: ((Date) -> Void)
    var calendar = Calendar(identifier: .gregorian)
    var numberOfWeeksInBaseDate: Int? {
        calendar.range(of: .weekOfMonth, in: .month, for: baseDate!)?.count ?? 0
    }
    
    var baseDate: Date? {
        didSet {
            days = generateDaysInMonth(for: baseDate!)
            print("days from interactor \(days.count)")
            //            headerView.baseDate = baseDate
        }
    }
    
    private lazy var dateFormatter: DateFormatter? = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"
        return dateFormatter
    }()
    
    // MARK: Do something
    
    func doSomething(request: CalendarVC.Something.Request)
    {
        worker = calendarWorker()
        worker?.doSomeWork()
        
        baseDate = Date()
        
        var response = CalendarVC.Something.Response()
        response.days = days
        response.numberOfWeeksinBaseDate = self.numberOfWeeksInBaseDate
        response.baseDate = baseDate
        presenter?.presentSomething(response: response)
    }
}


private extension calendarInteractor {
    
    func monthMetadata(for baseDate: Date) throws -> MonthMetadata {
        
        guard
            let numberOfDaysInMonth = calendar.range(
                of: .day,
                in: .month,
                for: baseDate)?.count,
            let firstDayOfMonth = calendar.date(
                from: calendar.dateComponents([.year, .month], from: baseDate))
        else {
            
            throw CalendarDataError.metadataGeneration
        }
        
        
        let firstDayWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        
        return MonthMetadata(
            numberOfDays: numberOfDaysInMonth,
            firstDay: firstDayOfMonth,
            firstDayWeekday: firstDayWeekday)
    }
    
    
    func generateDaysInMonth(for baseDate: Date) -> [Day] {
        
        guard let metadata = try? monthMetadata(for: baseDate) else {
            preconditionFailure("An error occurred when generating the metadata for \(baseDate)")
        }
        
        let numberOfDaysInMonth = metadata.numberOfDays
        let offsetInInitialRow = metadata.firstDayWeekday
        let firstDayOfMonth = metadata.firstDay
        
        
        var days: [Day] = (1..<(numberOfDaysInMonth + offsetInInitialRow))
            .map { day in
                // 4
                let isWithinDisplayedMonth = day >= offsetInInitialRow
                // 5
                let dayOffset =
                isWithinDisplayedMonth ?
                day - offsetInInitialRow :
                -(offsetInInitialRow - day)
                
                // 6
                return generateDay(
                    offsetBy: dayOffset,
                    for: firstDayOfMonth,
                    isWithinDisplayedMonth: isWithinDisplayedMonth)
            }
        
        days += generateStartOfNextMonth(using: firstDayOfMonth)
        
        return days
    }
    
    
    func generateDay(
        offsetBy dayOffset: Int,
        for baseDate: Date,
        isWithinDisplayedMonth: Bool
    ) -> Day {
        let date = calendar.date(
            byAdding: .day,
            value: dayOffset,
            to: baseDate)
        ?? baseDate
        
        return Day(
            date: date,
            number: dateFormatter!.string(from: date),
            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
            isWithinDisplayedMonth: isWithinDisplayedMonth
        )
    }
    
    
    func generateStartOfNextMonth(
        using firstDayOfDisplayedMonth: Date
    ) -> [Day] {
        
        guard
            let lastDayInMonth = calendar.date(
                byAdding: DateComponents(month: 1, day: -1),
                to: firstDayOfDisplayedMonth)
        else {
            return []
        }
        
        
        let additionalDays = 7 - calendar.component(.weekday, from: lastDayInMonth)
        guard additionalDays > 0 else {
            return []
        }
        
        
        let days: [Day] = (1...additionalDays)
            .map {
                generateDay(
                    offsetBy: $0,
                    for: lastDayInMonth,
                    isWithinDisplayedMonth: false)
            }
        
        return days
    }
    
    enum CalendarDataError: Error {
        case metadataGeneration
    }
}

