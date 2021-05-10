//
//  WalkDataViewController.swift
//  SmoothWalker
//
//  Created by Yangbin Wen on 5/5/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit
import HealthKit
import CareKitUI
import RxSwift
import RxDataSources

private extension CGFloat {
    static let inset: CGFloat = 20
    static let itemSpacing: CGFloat = 12
    static let itemSpacingWithTitle: CGFloat = 0
}

class WalkDataViewController: UIViewController {
    var viewModel: WalkViewModel!
    
    private var chartViewBottomConstraint: NSLayoutConstraint?
    private let disposeBag = DisposeBag()
    private let cellIndentifier = "tableViewCell"
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        return tableView
    }()
    
    private lazy var headerView: UIView = {
        let view = UIView()
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
        
    private lazy var chartView: OCKCartesianChartView = {
        let chartView = OCKCartesianChartView(type: .bar)
        
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.applyHeaderStyle()
        
        return chartView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Walk"
        self.view.backgroundColor = .white
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIndentifier)
        setupBingdings()
    }
    
    override func loadView() {
        super.loadView()
        
        view.addSubview(headerView)
        headerView.addSubview(chartView)
        view.addSubview(tableView)
        setUpConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.requestWalkDataAccessIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        viewModel.removeWalkDataObserver()
    }
    
    override func updateViewConstraints() {
        chartViewBottomConstraint?.constant = .itemSpacing
        
        super.updateViewConstraints()
    }
    
    private func setupBingdings() {
        viewModel.walkSpeedDataSubject
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: {[weak self] (dataValues) in
                if dataValues.count > 0 {
                    self?.setupChart(with: dataValues)
                }
            })
            .disposed(by: disposeBag)

        let dataSource = RxTableViewSectionedReloadDataSource<WalkDataTableViewSection>(
          configureCell: {[weak self] dataSource, tableView, indexPath, item in
            guard let strongSelf = self else { return UITableViewCell() }
            var cell = tableView.dequeueReusableCell(withIdentifier: strongSelf.cellIndentifier)
            if cell == nil {
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: strongSelf.cellIndentifier)
            }
            cell!.textLabel?.text = "Average walk speed \(round(100*item.speed)/100) m/min on \(item.startDate) "
            return cell!
        })
        
        viewModel.tableviewSecions
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
    
    private func setUpConstraints() {
        var constraints: [NSLayoutConstraint] = []
        
        constraints += createHeaderViewConstraints()
        constraints += createChartViewConstraints()
        constraints += createTableViewConstraints()
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func createHeaderViewConstraints() -> [NSLayoutConstraint] {
        let leading = headerView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: .inset)
        let trailing = headerView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -.inset)
        let top = headerView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 10)
        let centerX = headerView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)
        
        return [leading, trailing, top, centerX]
    }
    
    private func createChartViewConstraints() -> [NSLayoutConstraint] {
        let leading = chartView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor)
        let top = chartView.topAnchor.constraint(equalTo: headerView.topAnchor)
        let trailing = chartView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor)
        let bottomConstant: CGFloat = .itemSpacing
        let bottom = chartView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -bottomConstant)
        
        chartViewBottomConstraint = bottom
        
        trailing.priority -= 1
        bottom.priority -= 1

        return [leading, top, trailing, bottom]
    }
    
    private func createTableViewConstraints() -> [NSLayoutConstraint] {
        let leading = tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let top = tableView.topAnchor.constraint(equalTo: chartView.bottomAnchor)
        let trailing = tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        let bottomConstant: CGFloat = .itemSpacing
        let bottom = tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -bottomConstant)

        return [leading, top, trailing, bottom]
    }
    
    private func setupChart(with values: [HealthDataTypeValue]) {
        var xPoint = 0
        let copyOfValue = values.sorted { (v1, v2) -> Bool in
            v1.startDate < v2.startDate
        }
        let dataPoints = copyOfValue.map { (data) -> CGPoint in
            xPoint += 1
            return CGPoint(x: CGFloat(Double(xPoint)),
                           y: CGFloat(data.value))
        }

        var data = OCKDataSeries(dataPoints: dataPoints,
                                 title: "walk Speed: m/min",
                                 color: .green)
        
        data.size = 1

        data.gradientStartColor = .blue
        data.gradientEndColor = .red

        chartView.graphView.dataSeries = [data]

        var yMax = values.sorted { (v1, v2) -> Bool in
            v1.value < v2.value
        }.last?.value
        yMax = (yMax == nil) ? 50 : yMax! + 20.0
        
        chartView.graphView.yMinimum = 0
        chartView.graphView.yMaximum = CGFloat(yMax!)
        chartView.graphView.xMinimum = 0
        chartView.graphView.xMaximum = CGFloat(values.count)

        let horizontalAxisMarkers = [timeToString(copyOfValue.first!.startDate.timeIntervalSince1970),
                                     timeToString(copyOfValue.last!.startDate.timeIntervalSince1970)]
            
        chartView.graphView.horizontalAxisMarkers = horizontalAxisMarkers

        chartView.headerView.titleLabel.text = "Walk Chart"
        chartView.headerView.detailLabel.text = "Here's your data"
      }
}

extension WalkDataViewController {
    private func timeToString(_ timeInterval: Double) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .current
        dateFormatter.dateStyle = DateFormatter.Style.short
        return dateFormatter.string(from: Date(timeIntervalSince1970: timeInterval))
    }
}
