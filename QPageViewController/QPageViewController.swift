//
//  QPageViewController.swift
//  QPageViewController
//
//  Created by David Nemec on 21/06/2017.
//  Copyright © 2017 David Nemec. All rights reserved.
//

import Foundation
import UIKit

public enum ScrollDirection{
    case forward
    case backward
}


@objc public protocol QPageViewControllerDelegate: class {

    @objc optional func pageViewController(pageViewController: QPageViewController, willMove fromController: UIViewController?, toController: UIViewController?)

    @objc optional func pageViewController(pageViewController: QPageViewController, isMoving fromController: UIViewController?, toController: UIViewController?, progress: CGFloat)

    @objc optional func pageViewController(pageViewController: QPageViewController, didMove fromController: UIViewController?, toController: UIViewController?)

    @objc optional func pageViewController(pageViewController: QPageViewController, endedMove onController: UIViewController)
}

public protocol QPageViewControllerDataSource: class {

    func pageViewController(pageViewController: QPageViewController, controllerAfter controller: UIViewController?) -> UIViewController?

    func pageViewController(pageViewController: QPageViewController, controllerBefore controller: UIViewController?) -> UIViewController?

}


open class QPageViewController: UIViewController {


    public weak var delegate: QPageViewControllerDelegate?
    public weak var dataSource: QPageViewControllerDataSource?

    
    public var extraControllers: [UIViewController] = []
    public func getController() -> UIViewController {
        return extraControllers.removeFirst()
    }



    public var preloadAdjacentControllers = true
    public var isScrollEnabled = true {
        didSet {
            self.scrollView.isScrollEnabled = isScrollEnabled
        }
    }

    public var progressLimit:CGFloat = 0.55

    fileprivate(set) weak var currentViewController: UIViewController? {
        didSet {
            guard let oldValue = oldValue, let currentViewController = currentViewController else {
                return
            }

            self.delegate?.pageViewController?(pageViewController: self, didMove: oldValue, toController: currentViewController)
        }
    }


    fileprivate(set) weak var nextViewControler: UIViewController?
    fileprivate(set) weak var previousViewControler: UIViewController?
    fileprivate var shoudReloadAdjacent = false

    fileprivate var inUserDrag = false
    fileprivate(set) var isScrolling = false

    fileprivate lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        //scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.translatesAutoresizingMaskIntoConstraints = true
        scrollView.autoresizingMask = [.flexibleTopMargin, .flexibleRightMargin, .flexibleBottomMargin, .flexibleLeftMargin]
        scrollView.bounces = true
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        scrollView.isPagingEnabled = true
        return scrollView
    }()

    fileprivate var viewWidth: CGFloat {
        return self.view.bounds.width
    }

    fileprivate var viewHeight: CGFloat {
        return self.view.bounds.height
    }

    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        self.scrollView.frame = self.view.bounds
        self.scrollView.contentSize = CGSize(width: viewWidth * 3, height: viewHeight)

        layoutSubviews()
        centerScrollView()
    }

    func layoutSubviews()
    {
        self.previousViewControler?.view.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
        self.currentViewController?.view.frame = CGRect(x: viewWidth, y: 0, width: viewWidth, height: viewHeight)
        self.nextViewControler?.view.frame = CGRect(x: viewWidth * 2, y: 0, width: viewWidth, height: viewHeight)
        print("layoutSubviews")
    }

    fileprivate func isOneOfControllers(controller: UIViewController) -> Bool {
        return controller==previousViewControler || controller==currentViewController || controller==nextViewControler
    }


    open override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        self.view.addSubview(scrollView)
        self.view.backgroundColor = .white
        self.scrollView.delegate = self
    }

    public func scrollTo(controller: UIViewController, direction: ScrollDirection = .forward){

        self.scrollView.isScrollEnabled = false
        centerScrollView(animated: false)

        if currentViewController == controller{
            self.scrollView.isScrollEnabled = true
            return
        }

        if controller == previousViewControler{
            self.scrollView.isScrollEnabled = true
            scrollToPrevious()
            return
        }

        if controller == nextViewControler{
            self.scrollView.isScrollEnabled = true
            scrollToNext()
            return
        }

        shoudReloadAdjacent = true

        switch direction {
        case .forward:
            self.removeChild(viewController: self.nextViewControler)
            self.addChild(viewController: controller)
            self.nextViewControler = controller
            scrollToNext()
        case .backward:
            self.removeChild(viewController: self.previousViewControler)
            self.addChild(viewController: controller)
            self.previousViewControler = controller
            scrollToPrevious()
        }
    }

    public func scrollToNext(){
        self.scrollView.isScrollEnabled = false
        scrollView.setContentOffset(CGPoint(x: distance*2, y: 0), animated: true)
    }

    public func scrollToPrevious(){
        self.scrollView.isScrollEnabled = false
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }

    public func reloadAdjacent(){

        self.removeChild(viewController: self.nextViewControler )
        self.removeChild(viewController: self.previousViewControler)

        self.nextViewControler = dataSource?.pageViewController(pageViewController: self, controllerAfter: self.currentViewController)
        self.previousViewControler = dataSource?.pageViewController(pageViewController: self, controllerBefore: self.currentViewController)

        self.addChild(viewController: nextViewControler)
        self.addChild(viewController: previousViewControler)
    }

    public func reloadAll(){
        self.removeChild(viewController: self.currentViewController)

        self.currentViewController = dataSource?.pageViewController(pageViewController: self, controllerAfter: nil)

        self.addChild(viewController: currentViewController)

        reloadAdjacent()
        layoutSubviews()
    }


    // MARK Views
    fileprivate func addChild(viewController: UIViewController?){
        guard let viewController = viewController else {
            return
        }
        self.addChildViewController(viewController)

        viewController.beginAppearanceTransition(true, animated: false)
        self.scrollView.addSubview(viewController.view)
        viewController.endAppearanceTransition()


        viewController.didMove(toParentViewController: self)
    }

    fileprivate func removeChild(viewController: UIViewController?){
        viewController?.view.removeFromSuperview()
        viewController?.didMove(toParentViewController: nil)
        viewController?.removeFromParentViewController()
    }

    fileprivate var prevProgress: CGFloat = 0.0
}

extension QPageViewController: UIScrollViewDelegate{

    fileprivate var distance: CGFloat {
        return self.view.bounds.width
    }

    fileprivate var progress: CGFloat {
        return (self.scrollView.contentOffset.x - distance) / distance
    }

    fileprivate func centerScrollView(animated: Bool = false){
        scrollView.setContentOffset(CGPoint(x: distance, y: 0), animated: animated)
    }

    fileprivate func centerScrollViewIfNeeded(){
        let progress = self.progress

        var aboveLimit = false

        if progress <= -progressLimit{
            self.removeChild(viewController: self.nextViewControler)
            self.nextViewControler = self.currentViewController
            self.currentViewController = self.previousViewControler
            self.previousViewControler = self.dataSource?.pageViewController(pageViewController: self, controllerBefore: self.currentViewController)
            self.addChild(viewController: self.previousViewControler)
            self.layoutSubviews()
            scrollView.setContentOffset(CGPoint(x: distance*(2-progressLimit), y: 0), animated: false)
            aboveLimit = true
        }
        else if progress >= progressLimit{
            self.removeChild(viewController: self.previousViewControler)
            self.previousViewControler = self.currentViewController
            self.currentViewController = self.nextViewControler
            self.nextViewControler = self.dataSource?.pageViewController(pageViewController: self, controllerAfter: self.currentViewController)
            self.addChild(viewController: self.nextViewControler)
            self.layoutSubviews()
            scrollView.setContentOffset(CGPoint(x: distance*progressLimit, y: 0), animated: false)
            aboveLimit = true
        }

        if aboveLimit {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.1, delay: 0, options: [.curveLinear, .curveEaseOut], animations: {
                    self.centerScrollView()
                }, completion: { (finished) in
                    print("scrollViewDidEndDecelerating Animation End distance \(self.distance) progress \(self.progress)")
                    guard let currentViewController = self.currentViewController else{
                        return
                    }
                    self.scrollView.isScrollEnabled = true
                    self.isScrolling = false
                    if self.shoudReloadAdjacent{
                        self.reloadAdjacent()
                    }
                    self.delegate?.pageViewController?(pageViewController: self, endedMove: currentViewController)
                    
                })
                
            }
        }
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("scrollViewDidScroll distance \(distance) progress \(progress)")
        centerScrollViewIfNeeded()
        let startingController: UIViewController? = self.currentViewController
        var targetController: UIViewController?

        isScrolling = true

        if progress < 0 {
            targetController = self.previousViewControler
        }
        else {
            targetController = self.nextViewControler
        }
        self.delegate?.pageViewController?(pageViewController: self, isMoving: startingController, toController: targetController, progress: progress)

    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        print("scrollViewWillBeginDragging distance \(distance) progress \(progress)")
        inUserDrag = true
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        print("scrollViewDidEndDragging distance \(distance) progress \(progress)")
        inUserDrag = false
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print("scrollViewDidEndDecelerating distance \(distance) progress \(progress)")
        self.scrollView.isScrollEnabled = true
    }

}
