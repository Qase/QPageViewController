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

    @objc optional func pageViewController(pageViewController: QPageViewController, willMoveFrom: UIViewController, to: UIViewController)

    @objc optional func pageViewController(pageViewController: QPageViewController, isMovingFrom: UIViewController, to: UIViewController, progress: Double)

    @objc optional func pageViewController(pageViewController: QPageViewController, didMoveFrom: UIViewController, to: UIViewController, finished: Bool)
}

extension QPageViewControllerDelegate {
    func pageViewController(pageViewController: QPageViewController, willMoveFrom: UIViewController, to: UIViewController) { }

    func pageViewController(pageViewController: QPageViewController, isMovingFrom: UIViewController, to: UIViewController, progress: Double) { }

    func pageViewController(pageViewController: QPageViewController, didMoveFrom: UIViewController, to: UIViewController, finished: Bool) { }
}

public protocol QPageViewControllerDataSource: class {

    func pageViewController(pageViewController: QPageViewController, controllerAfter controller: UIViewController?) -> UIViewController?

    func pageViewController(pageViewController: QPageViewController, controllerBefore controller: UIViewController?) -> UIViewController?

}


open class QPageViewController: UIViewController {


    public weak var delegate: QPageViewControllerDelegate?
    public weak var dataSource: QPageViewControllerDataSource?

    public var preloadAdjacentControllers = true
    public var scrollingEnabled = true

    fileprivate(set) var currentViewController: UIViewController? {
        didSet {
            guard let oldValue = oldValue, let currentViewController = currentViewController else {
                return
            }
            self.delegate?.pageViewController(pageViewController: self, didMoveFrom: oldValue, to: currentViewController, finished: true)
        }
    }
    fileprivate(set) var nextViewControler: UIViewController?
    fileprivate(set) var previousViewControler: UIViewController?


    fileprivate var inUserDrag = false

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


    open override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        self.view.addSubview(scrollView)
        self.view.backgroundColor = .white
        self.scrollView.delegate = self
    }

    public func scrollTo(controller: UIViewController, direction: ScrollDirection = .forward){

    }

    public func scrollToNext(){
    }

    public func scrollToPrevious(){

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



    public var isInAnimation: Bool {
        return false
    }


    // MARK Views
    fileprivate func addChild(viewController: UIViewController?){
        guard let viewController = viewController else {
            return
        }
        self.scrollView.addSubview(viewController.view)
        self.addChildViewController(viewController)
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

    fileprivate func centerScrollView(){
        scrollView.setContentOffset(CGPoint(x: distance, y: 0), animated: false)
    }

    fileprivate func centerScrollViewIfNeeded(){
        let progress = self.progress
        if progress <= -1.0{
            self.removeChild(viewController: self.nextViewControler)
            self.nextViewControler = self.currentViewController
            self.currentViewController = self.previousViewControler
            self.previousViewControler = self.dataSource?.pageViewController(pageViewController: self, controllerBefore: self.currentViewController)
            self.addChild(viewController: self.previousViewControler)
            self.layoutSubviews()
            self.centerScrollView()
        }
        else if progress >= 1.0{
            self.removeChild(viewController: self.previousViewControler)
            self.previousViewControler = self.currentViewController
            self.currentViewController = self.nextViewControler
            self.nextViewControler = self.dataSource?.pageViewController(pageViewController: self, controllerAfter: self.currentViewController)
            self.addChild(viewController: self.nextViewControler)
            self.layoutSubviews()
            self.centerScrollView()
        }
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("scrollViewDidScroll distance \(distance) progress \(progress)")

        centerScrollViewIfNeeded()
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


    }
}
