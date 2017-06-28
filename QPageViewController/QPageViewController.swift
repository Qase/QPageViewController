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
//        guard let fromController = fromController as? SingleViewController, let toController = toController as? SingleViewController else {
//            return
//        }
//        print("Moved FromController \(fromController.model?.number) ToController \(toController.model?.number) ")

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

    public var smartCacheEnabled = true
    public var automaticcallyCompleteUserDrag = false
    public var cachedControllers: [UIViewController] = []
    public var progressLimit:CGFloat = 0.55
    public var preloadAdjacentControllers = true

    private func getCachedController() -> UIViewController? {
        if  cachedControllers.count > 0 {
            return cachedControllers.removeFirst()
        }
        return nil
    }

    public func reusableController<T:UIViewController>() -> T {
        var retController : T
        if let controller = self.getCachedController() as? T {
            retController = controller
        }
        else{
            retController = T()
        }
        return retController
    }




    public var isScrollEnabled = true {
        didSet {
            self.scrollView.isScrollEnabled = isScrollEnabled
        }
    }



    fileprivate(set) var currentViewController: UIViewController? {
        didSet {
            guard let oldValue = oldValue, let currentViewController = currentViewController else {
                return
            }

            self.delegate?.pageViewController?(pageViewController: self, didMove: oldValue, toController: currentViewController)
            self.prevProgress = -self.prevProgress
        }
    }


    fileprivate(set) var nextViewControler: UIViewController?
    fileprivate(set) var previousViewControler: UIViewController?
    fileprivate var shoudReloadAdjacent = false
    fileprivate var inUserDrag = false
    fileprivate(set) var isScrolling = false
    fileprivate var prevProgress: CGFloat = 0.0

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
        //print("layoutSubviews")
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
            self.layoutSubviews()
            scrollToNext()
        case .backward:
            self.removeChild(viewController: self.previousViewControler)
            self.addChild(viewController: controller)
            self.previousViewControler = controller
            self.layoutSubviews()
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
        //print("reloadAdjacent start")
        self.removeChild(viewController: self.nextViewControler )
        self.removeChild(viewController: self.previousViewControler)

        self.nextViewControler = dataSource?.pageViewController(pageViewController: self, controllerAfter: self.currentViewController)
        self.previousViewControler = dataSource?.pageViewController(pageViewController: self, controllerBefore: self.currentViewController)

        self.addChild(viewController: nextViewControler)
        self.addChild(viewController: previousViewControler)
        //print("reloadAdjacent end")
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
            //print(currentViewController)
            return
        }
        //print("addChild")
        self.addChildViewController(viewController)
        viewController.beginAppearanceTransition(true, animated: false)
        self.scrollView.addSubview(viewController.view)
        viewController.endAppearanceTransition()
        viewController.didMove(toParentViewController: self)
        if self.smartCacheEnabled {
            cachedControllers = cachedControllers.filter{ $0 != viewController }
        }

    }

    fileprivate func removeChild(viewController: UIViewController?){
        guard let viewController = viewController else {
            return
        }
        //print("removeChild")
        viewController.view.removeFromSuperview()
        viewController.didMove(toParentViewController: nil)
        viewController.removeFromParentViewController()
        if self.smartCacheEnabled {
            cachedControllers.append(viewController)
        }

    }
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
            //print("centerScrollViewIfNeeded start")
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
            //print("centerScrollViewIfNeeded start")
            self.removeChild(viewController: self.previousViewControler)
            self.previousViewControler = self.currentViewController
            self.currentViewController = self.nextViewControler
            self.nextViewControler = self.dataSource?.pageViewController(pageViewController: self, controllerAfter: self.currentViewController)
            self.addChild(viewController: self.nextViewControler)
            self.layoutSubviews()
            scrollView.setContentOffset(CGPoint(x: distance*progressLimit, y: 0), animated: false)
            aboveLimit = true
        }

        if (automaticcallyCompleteUserDrag  && aboveLimit) ||
            (!automaticcallyCompleteUserDrag && aboveLimit && !self.inUserDrag) {
            //print("centerScrollViewIfNeeded end")
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.1, delay: 0, options: [.curveLinear, .curveEaseOut], animations: {
                    self.centerScrollView()
                }, completion: { (finished) in
                    //print("scrollViewDidEndDecelerating Animation End distance \(self.distance) progress \(self.progress)")
                    if self.shoudReloadAdjacent{
                        self.reloadAdjacent()
                    }
                    self.layoutSubviews()
                    self.scrollView.isScrollEnabled = true
                    self.isScrolling = false
                    guard let currentViewController = self.currentViewController else{
                        return
                    }
                    self.delegate?.pageViewController?(pageViewController: self, endedMove: currentViewController)
                })
                
            }
        }
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //print("scrollViewDidScroll distance \(distance) progress \(progress)")
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
        if (prevProgress >= 0 && progress < 0) || (prevProgress <= 0 && progress > 0) {
            self.delegate?.pageViewController?(pageViewController: self, willMove: startingController, toController: targetController)
        }

        self.delegate?.pageViewController?(pageViewController: self, isMoving: startingController, toController: targetController, progress: progress)

        self.prevProgress = progress

    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        //print("scrollViewWillBeginDragging distance \(distance) progress \(progress)")
        inUserDrag = true
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        //print("scrollViewDidEndDragging distance \(distance) progress \(progress)")
        inUserDrag = false
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        //print("scrollViewDidEndDecelerating distance \(distance) progress \(progress)")
        self.scrollView.isScrollEnabled = true
        if progress == 0.0 {
                self.delegate?.pageViewController?(pageViewController: self, endedMove: currentViewController!)
        }


    }

}
