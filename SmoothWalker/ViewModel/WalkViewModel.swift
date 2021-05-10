//
//  WalkViewModel.swift
//  SmoothWalker
//
//  Created by Yangbin Wen on 5/6/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import Foundation
import RxSwift
import HealthKit

enum WalkSpeedTimeInterval {
    case pastMonth
    case pastWeek
    case pastDay
}

class WalkViewModel {
    // Health data related property
    var walkTimeInterval: WalkSpeedTimeInterval!
    private let mockDailyKey = "WalkSpeedDailyMock"
    private let mockWeeklyKey = "WalkSpeedWeeklyMock"
    private let mockMonthlyKey = "WalkSpeedMonthlyMock"
    private let healthStore = HealthData.healthStore
    private let walkSpeedUnit = HKUnit.meter().unitDivided(by: HKUnit.minute())
    private var query: HKStatisticsCollectionQuery!
    
    
    private var quantityTypeIdentifier: String {
        return HKQuantityTypeIdentifier.walkingSpeed.rawValue
    }
    
    private lazy var componetDay: Int = {
        switch walkTimeInterval {
        case .pastDay:
            return -1
        case .pastWeek:
            return -7
        case .pastMonth:
            return -30
        default:
            return 0
        }
    }()
    
    var quantityType: HKQuantityType {
        return HKQuantityType.quantityType(forIdentifier: .walkingSpeed)!
    }
    
    // Subjects
    var accessGrantedSubject: BehaviorSubject<Bool> = .init(value: false)
    var walkSpeedDataSubject: BehaviorSubject<[HealthDataTypeValue]> = .init(value: [])
    var tableviewSecions: Observable<[WalkDataTableViewSection]> {
        walkSpeedDataSubject
            .asObservable()
            .map {[weak self] (values) -> [WalkDataTableViewSection] in
                guard let ss = self else { return [] }
                var models: [WalkDataTableCellModel] = []
                for item in values {
                    models.append(WalkDataTableCellModel(cellType: .normalCell,
                                                         startDate: ss.timeToString(item.startDate.timeIntervalSince1970),
                                                         endDate: ss.timeToString(item.endDate.timeIntervalSince1970, shouldShowDate: false),
                                                         speed: item.value))
                }
                return [WalkDataTableViewSection(id: "firstSection", items: models)]
            }
    }
    
    init(timeInterval: WalkSpeedTimeInterval) {
        walkTimeInterval = timeInterval
        addMockData()
    }
    
    func requestWalkDataAccessIfNeeded() {
        HealthData.requestHealthDataAccessIfNeeded(dataTypes: [quantityTypeIdentifier]) {[weak self] (isSuccessful) in
            self?.accessGrantedSubject.onNext(isSuccessful)
            if isSuccessful {
                self?.addMockData()
                self?.readWalkSpeedData()
            }
        }
    }
    
    func removeWalkDataObserver() {
        healthStore.stop(query)
    }
    
    private func readWalkSpeedData() {
        let currentDate = Date()
        let speedType = HKSampleType.quantityType(forIdentifier: .walkingSpeed)!
        let daily = DateComponents(day: 1)
        let sometimeAgo = Calendar.current.date(byAdding: DateComponents(day: componetDay), to: currentDate)!
        let predicate = HKQuery.predicateForSamples(withStart: sometimeAgo, end: currentDate, options: .strictStartDate)
        
        query = HKStatisticsCollectionQuery(quantityType: speedType,
                                                quantitySamplePredicate: predicate,
                                                options: .discreteAverage,
                                                anchorDate: Date(),
                                                intervalComponents: daily)
        
        query.initialResultsHandler = {[weak self] query, statisticsCollection, err in
            if let collection = statisticsCollection {
                print("initResult: \(collection)")
                self?.updateSpeedData(collection)
            }
        }
        
        query.statisticsUpdateHandler = {[weak self] query, statictics, statisticsCollection, error in
            if let collection = statisticsCollection {
                print("updateResult: \(collection)")
                self?.updateSpeedData(collection)
            }
        }
        
        healthStore.execute(query)
    }
    
    // Protal for out sending queried walking data
    private func updateSpeedData(_ speedCollection: HKStatisticsCollection) {
        let startDate = Calendar.current.date(byAdding: .day, value: componetDay, to: Date())!
        let endDate = Date()
        var dataValues = [HealthDataTypeValue]()
        
        speedCollection.enumerateStatistics(from: startDate, to: endDate) { [weak self] (statistics, stop) in
            let dataValue = HealthDataTypeValue(startDate: statistics.startDate,
                                                endDate: statistics.endDate,
                                                value: statistics.averageQuantity()?.doubleValue(for: self!.walkSpeedUnit) ?? 0)
            
            dataValues.append(dataValue)
        }
        dataValues = dataValues.filter({ (data) -> Bool in
            data.value > 0
        })
        walkSpeedDataSubject.onNext(dataValues)
    }
    
    private func addMockData() {
        var samples = [HKQuantitySample]()
        
        switch walkTimeInterval {
        case .pastDay:
            if UserDefaults.standard.bool(forKey: mockDailyKey) == true {
                return
            }
            for i in 0..<3 {
                let value = Double.random(in: 15...115)
                let start = Calendar.current.date(byAdding: DateComponents(day: -1, hour: i-1, minute: 00), to: Date())!
                let end = Calendar.current.date(byAdding: DateComponents(day: -1, hour: i-1, minute: 30 + i), to: Date())!
                guard let sample = processWalkSpeedSample(with: value,
                                                       start: start,
                                                       end: end) else { return }
                samples.append(sample)
            }
        case .pastWeek:
            if UserDefaults.standard.bool(forKey: mockWeeklyKey) == true {
                return
            }
            for i in 1..<8 {
                let value = Double.random(in: 20...110)
                let start = Calendar.current.date(byAdding: DateComponents(day: -i, hour: 13,minute: 00), to: Date())!
                let end = Calendar.current.date(byAdding: DateComponents(day: -i, hour: 13,minute: 30), to: Date())!
                guard let sample = processWalkSpeedSample(with: value,
                                                       start: start,
                                                       end: end) else { return }
                samples.append(sample)
            }
        case .pastMonth:
            if UserDefaults.standard.bool(forKey: mockMonthlyKey) == true {
                return
            }
            for i in 1..<31 {
                let value = Double.random(in: 15...115)
                let start = Calendar.current.date(byAdding: DateComponents(day: -i, hour: 13,minute: 00), to: Date())!
                let end = Calendar.current.date(byAdding: DateComponents(day: -i, hour: 13,minute: 30), to: Date())!
                guard let sample = processWalkSpeedSample(with: value,
                                                       start: start,
                                                       end: end) else { return }
                samples.append(sample)
            }
        default:
            break
        }

        HealthData.saveHealthData(samples) { [weak self] (success, error) in
            guard let strongSelf = self,
                  error == nil else {
                print("DataTypeTableViewController didAddNewData error: \(error!.localizedDescription)")
                return
            }
            if success {
                var mockKey = strongSelf.mockDailyKey
                
                switch strongSelf.walkTimeInterval {
                case .pastDay:
                    mockKey = strongSelf.mockDailyKey
                case .pastWeek:
                    mockKey = strongSelf.mockWeeklyKey
                case .pastMonth:
                    mockKey = strongSelf.mockMonthlyKey
                default:
                    break
                }
                
                UserDefaults.standard.setValue(true, forKey: mockKey)
                print("Successfully saved a new sample for interval \(String(describing: self?.walkTimeInterval))", samples)
                strongSelf.readWalkSpeedData()
            } else {
                print("Error: Could not save new sample.", samples)
            }
        }
    }
    
    //Generate mocked sample
    private func processWalkSpeedSample(with value: Double, start: Date, end: Date) -> HKQuantitySample? {
        let dataTypeIdentifier = quantityTypeIdentifier
        
        guard  let sampleType = getSampleType(for: dataTypeIdentifier) else {
            return nil
        }

        var optionalSample: HKQuantitySample?
        if let quantityType = sampleType as? HKQuantityType {
            let quantity = HKQuantity(unit: walkSpeedUnit, doubleValue: value)
            let quantitySample = HKQuantitySample(type: quantityType, quantity: quantity, start: start, end: end)
            optionalSample = quantitySample
        }
        
        return optionalSample
    }
    
    private func timeToString(_ timeInterval: Double, shouldShowDate: Bool = true) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .current
        if shouldShowDate {
            dateFormatter.dateStyle = .short
        }
        
        return dateFormatter.string(from: Date(timeIntervalSince1970: timeInterval))
    }
}
