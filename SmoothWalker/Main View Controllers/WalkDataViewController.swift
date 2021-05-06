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

private extension CGFloat {
    static let inset: CGFloat = 20
    static let itemSpacing: CGFloat = 12
    static let itemSpacingWithTitle: CGFloat = 0
}

class WalkDataViewController: UIViewController {
    private var chartViewBottomConstraint: NSLayoutConstraint?
    private lazy var headerView: UIView = {
        let view = UIView()
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
        
    private lazy var chartView: OCKCartesianChartView = {
        let chartView = OCKCartesianChartView(type: .line)
        
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.applyHeaderStyle()
        
        return chartView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Walk"
        self.view.backgroundColor = .white
        setupChart()
        self.view.addSubview(headerView)
        headerView.addSubview(chartView)
        setUpConstraints()
    }
    
    override func updateViewConstraints() {
        chartViewBottomConstraint?.constant = .itemSpacing
        
        super.updateViewConstraints()
    }
    
    private func setUpConstraints() {
        var constraints: [NSLayoutConstraint] = []
        
        constraints += createHeaderViewConstraints()
        constraints += createChartViewConstraints()
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func createHeaderViewConstraints() -> [NSLayoutConstraint] {
        let leading = headerView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: .inset)
        let trailing = headerView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -.inset)
        let top = headerView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 100)
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
    
    private func setupChart() {
        /// First create an array of CGPoints that you will use to generate your data series.
        /// We use the handy map method to generate some random points.
        let dataPoints = Array(0...20).map { _ in CGPoint(x: CGFloat.random(in: 0...20),
                                                          y: CGFloat.random(in: 1...5)) }

        /// Now you create an instance of `OCKDataSeries` from your array of points, give it a title and a color. The title is used for the label below the graph (just like in Microsoft Excel)
        var data = OCKDataSeries(dataPoints: dataPoints,
                                 title: "Random stuff",
                                 color: .green)

        /// You can create as many data series as you like 🌈
        let dataPoints2 = Array(0...20).map { _ in CGPoint(x: CGFloat.random(in: 0...20),
                                                           y: CGFloat.random(in: 1...5)) }
        var data2 = OCKDataSeries(dataPoints: dataPoints2,
                                  title: "Other random stuff",
                                  color: .red)

        /// Set the pen size for the data series...
        data.size = 2
        data2.size = 1

        /// ... and gradients if you like.
        /// Gradients and colors will be used for the graph as well as the color indicator of your label that shows the title of your data series.
        data.gradientStartColor = .blue
        data.gradientEndColor = .red

        /// Finally you add the prepared data series to your graph view.
        chartView.graphView.dataSeries = [data, data2]

        /// If you do not specify the minimum and maximum of your graph, `OCKCartesianGraphView` will take care of the right scaling.
        /// This can be helpful if you do not know the range of your values but it makes it more difficult to animate the graphs.
        chartView.graphView.yMinimum = 0
        chartView.graphView.yMaximum = 6
        chartView.graphView.xMinimum = 0
        chartView.graphView.xMaximum = 10

        /// You can also set an array of strings to set custom labels on the x-axis.
        /// I am not sure if that works on the y-axis as well.
        chartView.graphView.horizontalAxisMarkers = ["123", "123", "123", "hello"]

        /// With theses properties you can set a title and a subtitle for your graph.
        chartView.headerView.titleLabel.text = "Hello"
        chartView.headerView.detailLabel.text = "I am a graph"
      }
}
