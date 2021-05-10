//
//  WalkDataContainerViewController.swift
//  SmoothWalker
//
//  Created by Yangbin Wen on 5/8/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit

class WalkDataContainerViewController: UIViewController {
    
    private var updatedSegmentControlIndex: Int = 0
    private var childVcs: [UIViewController]?
    private let titleForSegment = ["PastDay", "PastWeek", "PastMonth"]
    
    private weak var segmentControl: UISegmentedControl!
    private weak var containerView: UIView!
    private weak var segmentView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Walk Report"
        view.backgroundColor = .white
        segmentView.backgroundColor = .brown
        containerView.backgroundColor = .cyan
        setupChildViewControllers()
    }
    
    override func loadView() {
        super.loadView()
        
        let sv = UIView(frame: .zero)
        sv.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sv)
        sv.topAnchor.constraint(equalTo: view.topAnchor, constant: 100.0).isActive = true
        sv.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10.0).isActive = true
        sv.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10.0).isActive = true
        sv.heightAnchor.constraint(equalToConstant: 45).isActive = true
        segmentView = sv
        
        let sc = UISegmentedControl(items: titleForSegment)
        sc.translatesAutoresizingMaskIntoConstraints = false
        segmentView.addSubview(sc)
        sc.addTarget(self, action: #selector(segmentValueChanged(_:)), for: .valueChanged)
        sc.selectedSegmentIndex = 0
        NSLayoutConstraint.activate([
            sc.topAnchor.constraint(equalTo: segmentView.topAnchor, constant: 0.0),
            sc.leftAnchor.constraint(equalTo: segmentView.leftAnchor, constant: 0.0),
            sc.rightAnchor.constraint(equalTo: segmentView.rightAnchor, constant: 0.0),
            sc.bottomAnchor.constraint(equalTo: segmentView.bottomAnchor, constant: 0.0)
        ])
        segmentControl = sc
        
        let cv = UIView()
        cv.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cv)
        NSLayoutConstraint.activate([
            cv.topAnchor.constraint(equalTo: segmentView.bottomAnchor, constant: 12.0),
            cv.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0.0),
            cv.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0.0),
            cv.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80.0)
        ])
        containerView = cv
    }
    
    private func setupChildViewControllers() {
        let dailyVc = WalkDataViewController()
        let weeklyVc = WalkDataViewController()
        let monthlyVc = WalkDataViewController()
        dailyVc.viewModel = WalkViewModel(timeInterval: .pastDay)
        weeklyVc.viewModel = WalkViewModel(timeInterval: .pastWeek)
        monthlyVc.viewModel = WalkViewModel(timeInterval: .pastMonth)
        addChildVcsToContainer([dailyVc, weeklyVc, monthlyVc])
    }
    
    @objc func segmentValueChanged(_: Any) {
        updatedSegmentControlIndex = segmentControl.selectedSegmentIndex
        resetContainersChildViewController()
    }
    
    func addChildVcsToContainer(_ childVcs: [UIViewController]) {
        removeAllChildVcs()
        segmentControl.removeAllSegments()
        self.childVcs = childVcs

        if childVcs.count == 1 {
            segmentControl.isHidden = true
        } else {
            var indexCount = 0
            _ = childVcs.map { vc in
                let title = titleForSegment[indexCount]
                segmentControl.insertSegment(withTitle: title, at: indexCount, animated: false)
                indexCount += 1
            }
            segmentControl.selectedSegmentIndex = updatedSegmentControlIndex
        }

        resetContainersChildViewController()
    }
    
    private func resetContainersChildViewController() {
        guard let childVcs = self.childVcs else {
            return
        }
        removeAllChildVcs()

        let selectedIndex = segmentControl.selectedSegmentIndex
        let childVcTobeAdded = childVcs[selectedIndex == -1 ? 0 : selectedIndex]
        addChildVc(childVcTobeAdded)

        if childVcs.count == 1 {
            self.title = titleForSegment[0]
        }
    }

    private func removeAllChildVcs() {
        guard let childVcs = self.childVcs else {
            return
        }

        for vc in childVcs {
            vc.willMove(toParent: nil)
            vc.removeFromParent()
            vc.view.removeFromSuperview()
        }
    }

    private func addChildVc(_ childVc: UIViewController) {
        self.addChild(childVc)
        containerView.addSubview(childVc.view)
        childVc.view.frame = containerView.bounds
        childVc.didMove(toParent: self)
    }
}
