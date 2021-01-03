//
//  File.swift
//  
//
//  Created by 周伟克 on 2021/1/2.
//

import UIKit

class LinearPageControl: UIView {
    
    private let sliceWidth = CGFloat(15)
    override var frame: CGRect {
        didSet {
            super.frame.size = CGSize(width: sliceWidth * CGFloat(numberOfPages), height: 1.5)
        }
    }
    
    lazy var indicator: UIView = {
        let indicator = UIView(frame: CGRect(origin: .zero, size: CGSize(width: sliceWidth, height: 1.5)))
        indicator.backgroundColor = pageIndicatorTintColor
        addSubview(indicator)
        return indicator
    }()
    
    var pageIndicatorTintColor = UIColor.white {
        didSet {
            indicator.backgroundColor = pageIndicatorTintColor
        }
    }
    
    var page = 0 {
        didSet {
            resetPageIfNeeded()
            moveIndicator()
        }
    }
    
    var numberOfPages = 0 {
        didSet {
            isHidden = numberOfPages < 2
            resetPageIfNeeded()
            frame.size = CGSize(width: sliceWidth * CGFloat(numberOfPages), height: 1.5)
            moveIndicator()
        }
    }
    
    func moveIndicator() {
        guard superview != nil else {
            return
        }
        UIView.animate(withDuration: 0.25) {
            self.indicator.frame.origin.x = CGFloat(self.page) * self.sliceWidth
        }
    }
    
    func resetPageIfNeeded() {
        guard page >= numberOfPages else {
            return
        }
        page = max(0, numberOfPages - 1)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    func setupUI() {
        backgroundColor = UIColor.white.withAlphaComponent(0.5)
    }
}

