//
//  File.swift
//  
//
//  Created by 周伟克 on 2021/1/2.
//

import UIKit

public class Banner: UIView {
    
    private lazy var cards: [UIImageView] = {
        let cards = [UIImageView(), UIImageView(), UIImageView()]
        cards.forEach { (card) in
            card.contentMode = .scaleAspectFill
            card.clipsToBounds = true
            addSubview(card)
        }
        bringSubviewToFront(pageControl)
        return cards
    }()
    private lazy var pageGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePageGesture(_:)))
        gesture.isEnabled = false
        addGestureRecognizer(gesture)
        return gesture
    }()
    private lazy var pageControl: LinearPageControl = {
        let pageControl = LinearPageControl()
        addSubview(pageControl)
        return pageControl
    }()
    private var startX = CGFloat(0)
    private var pageWorkItem: DispatchWorkItem?
    private var userInteractiveWorkItem: DispatchWorkItem?
    private var oldFrame: CGRect?
    private var centerCardDefaultLeft: CGFloat {
        preloadEdge + itemsHorizontalMargin
    }
    private var preferredSize: CGSize {
        CGSize(width: frame.width - centerCardDefaultLeft * 2, height: frame.height)
    }
    public var urls: [URL] = [] {
        didSet {
            guard urls != oldValue else {
                return
            }
            DispatchQueue.main.async {
                self.didSetURLs()
            }
        }
    }
    var pageBackgroundColor: UIColor? {
        didSet {
            pageControl.backgroundColor = pageBackgroundColor
        }
    }
    var pageIndicatorTintColor: UIColor? {
        didSet {
            pageControl.indicator.backgroundColor = pageIndicatorTintColor
        }
    }
    public var pageEvent: ((Int) -> ())?
    
    private let animDuration = 0.25
    
    // ---- 配置
    private var placeHolder: UIImage?
    private var itemsHorizontalMargin = CGFloat(0)
    private var preloadEdge = CGFloat(0)
    private var zoom: CGFloat = 1

    public func config(placeHodler: UIImage? = nil, itemsHorizontalMargin: CGFloat = 0, preloadEdge: CGFloat = 0, zoom: CGFloat = 1, cornerRadius: CGFloat = 0) {
        assert(zoom > 0 && zoom <= 1)
        self.placeHolder = placeHodler
        self.itemsHorizontalMargin = itemsHorizontalMargin
        self.preloadEdge = preloadEdge
        self.zoom = zoom
        cards.forEach { (card) in
            card.layer.cornerRadius = cornerRadius
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard urls.count != 0 else {
            return
        }
        guard let loc = touches.first?.location(in: self) else {
            return
        }
        guard cards[1].frame.contains(loc) else {
            return
        }
        pageEvent?(cards[1].tag)
    }
    
    @objc func handlePageGesture(_ gesture: UIPanGestureRecognizer) {
        let locationX = gesture.location(in: self).x
        let translationX = gesture.translation(in: self).x
        if gesture.state == .began {
            startX = locationX
            pageWorkItem?.cancel()
        } else if gesture.state == .changed {
            cards.forEach { (card) in
                let realScale = min(abs(card.center.x - frame.width * 0.5) / preferredSize.width, 1)
                card.frame.size = CGSize(width: preferredSize.width - realScale * (1 - zoom) * preferredSize.width,
                                         height: preferredSize.height - realScale * (1 - zoom) * preferredSize.height)
            }
            centerCards()
            gesture.setTranslation(.zero, in: self)
            
            sortCards()
            cards[1].frame.origin.x += translationX

            if translationX < 0, cards[1].frame.origin.x < 0 {
                cards[2].frame.origin.x = cards[1].frame.maxX + itemsHorizontalMargin
                cards[0].frame.origin.x = cards[2].frame.maxX + itemsHorizontalMargin
                cards[0].tag = (cards[2].tag + 1) % urls.count
            } else if translationX > 0, cards[1].frame.maxX > frame.width {
                cards[0].frame.origin.x = cards[1].frame.origin.x - itemsHorizontalMargin - cards[0].frame.width
                cards[2].frame.origin.x = cards[0].frame.origin.x - itemsHorizontalMargin - cards[2].frame.width
                cards[2].tag = (urls.count + cards[0].tag - 1) % urls.count
            } else {
                cards[0].frame.origin.x = cards[1].frame.origin.x - itemsHorizontalMargin - cards[0].frame.width
                cards[2].frame.origin.x = cards[1].frame.maxX + itemsHorizontalMargin
            }
            centerCards()
            setImages()
        } else {
            resetCardsSize(withDuration: animDuration)
            centerCards()
            resetCarsX(withDuration: animDuration)
            resetPageWorkItem()
            pageControl.page = cards[1].tag
            pauseUserInteractionIn(animDuration)
        }
    }
    
    func didSetURLs() {
        pageControl.numberOfPages = urls.count
        pageControl.page = 0
        pageGesture.isEnabled = urls.count > 1
        pageWorkItem?.cancel()
        userInteractiveWorkItem?.cancel()
        isUserInteractionEnabled = true
        guard urls.count != 0 else {
            cards.forEach { (card) in
                card.image = placeHolder
                card.isHidden = true
            }
            return
        }
        
        cards[1].isHidden = false
        cards[0].isHidden = urls.count <= 1
        cards[2].isHidden = cards[0].isHidden
        
        cards[1].tag = 0
        cards[2].tag = 1 % urls.count
        cards[0].tag = urls.count - 1
        
        setImages()
        
        if urls.count > 1 {
            resetPageWorkItem()
        }
    }
    
    func resetPageWorkItem() {
        pageWorkItem = DispatchWorkItem(block: { [weak self] in
            guard let ws = self else {
                return
            }
            let wholeDuration = ws.animDuration * Double(1 + ws.centerCardDefaultLeft / ws.preferredSize.width)
            ws.pauseUserInteractionIn(wholeDuration)
            UIView.animate(withDuration: wholeDuration) {
                ws.cards[2].frame.size = ws.preferredSize
                ws.cards[1].frame.size = CGSize(width: ws.preferredSize.width * ws.zoom,
                                                  height: ws.preferredSize.height * ws.zoom)
                ws.cards[0].frame.size = ws.cards[1].frame.size
                ws.centerCards()
            }

            UIView.animate(withDuration: ws.animDuration * TimeInterval(ws.centerCardDefaultLeft / ws.preferredSize.width)) {
                ws.cards.forEach { (card) in
                    card.frame.origin.x -= ws.centerCardDefaultLeft
                }
            } completion: { (_) in
                ws.cards[0].frame.origin.x = ws.cards[2].frame.maxX + ws.itemsHorizontalMargin
                ws.cards[0].tag = (ws.cards[2].tag + 1) % ws.urls.count
                ws.cards[0].setImage(ws.urls[ws.cards[0].tag], placeHolder: ws.placeHolder)
                ws.resetCarsX(withDuration: ws.animDuration)
                ws.pageControl.page = ws.cards[1].tag
            }
            ws.resetPageWorkItem()
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: pageWorkItem!)
    }
    
    func sortCards() {
        cards.sort { $0.frame.origin.x < $1.frame.origin.x }
    }
    
    func centerCards() {
        cards.forEach { (card) in
            card.center.y = frame.height * 0.5
        }
    }
    
    func resetCarsX(withDuration: Double) {
        sortCards()
        UIView.animate(withDuration: withDuration) {
            self.cards[1].frame.origin.x = self.centerCardDefaultLeft
            self.cards[0].frame.origin.x = self.cards[1].frame.origin.x - self.itemsHorizontalMargin - self.cards[0].frame.width
            self.cards[2].frame.origin.x = self.cards[1].frame.maxX + self.itemsHorizontalMargin
        }
    }
    
    func resetCardsSize(withDuration: Double) {
        sortCards()
        UIView.animate(withDuration: withDuration) {
            self.cards[1].frame.size = self.preferredSize
            self.cards[0].frame.size = CGSize(width: self.preferredSize.width * self.zoom,
                                              height: self.preferredSize.height * self.zoom)
            self.cards[2].frame.size = self.cards[0].frame.size
            self.centerCards()
        }
    }
    
    /**
     * 虽然layoutSubView可能会频繁触发，但是card.layer.presentation()的结束效果是和card的实际布局效果是一样的,
     * 所以并不响应card的过渡
     *
     * 在此处布局cards的另一个原因是在横竖屏切换，约束发生改变等情况下，无论是kvo frame，还是监听frame的didSet
     * 都不会触发，从而导致self的frame发生改变的时候，cards的下一次切换前UI是异常
     *
     */
    public override func layoutSubviews() {
        super.layoutSubviews()
        guard frame != oldFrame else {
            return
        }
        oldFrame = frame
        pageControl.center.x = frame.width * 0.5
        pageControl.frame.origin.y = frame.height - 10 - pageControl.frame.height
        pageWorkItem?.cancel()
        resetCardsSize(withDuration: 0)
        centerCards()
        resetCarsX(withDuration: 0)
        if urls.count > 1 {
            resetPageWorkItem()
        }
    }
    
    public override func removeFromSuperview() {
        super.removeFromSuperview()
        pageWorkItem?.cancel()
        userInteractiveWorkItem?.cancel()
    }
    
    func setImages() {
        cards.forEach { (card) in
            if !card.isHidden {
                card.setImage(urls[card.tag], placeHolder: placeHolder)
            } else {
                card.image = placeHolder
            }
        }
    }
    
    /// 暂停交互
    func pauseUserInteractionIn(_ time: Double) {
        isUserInteractionEnabled = false
        userInteractiveWorkItem?.cancel()
        userInteractiveWorkItem = DispatchWorkItem(block: { [weak self] in
            self?.isUserInteractionEnabled = true
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + time, execute: userInteractiveWorkItem!)
    }
}
