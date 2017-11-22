//
//  QPageViewController.swift
//  QPageViewController
//
//  Created by David Nemec on 21/06/2017.
//  Copyright © 2017 David Nemec. All rights reserved.
//

// swiftlint:disable file_length
import Foundation
import UIKit

/// Direction of scroll in page view controller.
///
/// - forward: Forward direction
/// - backward: Backward direction
public enum ScrollDirection {
    case forward
    case backward
}

@objc public protocol QPageViewControllerDelegate: class {
    
    /// Informs about start of scrolling to new view controller
    ///
    /// - Parameters:
    ///   - pageViewController: The page view controller instance
    ///   - fromController: Currently selected view controller the transition starts from
    ///   - toController: View controller that will be scrolled to
    @objc optional func pageViewController(_ pageViewController: QPageViewController, willMove fromController: UIViewController?, toController: UIViewController?)
    
    /// Informs about progress of transition to new view controller
    ///
    /// - Parameters:
    ///   - pageViewController: The page view controller instance
    ///   - fromController: Currently selected view controller the transition starts from
    ///   - toController: View controller that is being scrolled to
    ///   - progress: Progress of transition. Value is between zero and progressLimit
    @objc optional func pageViewController(_ pageViewController: QPageViewController, isMoving fromController: UIViewController?, toController: UIViewController?, progress: CGFloat)
    
    /// Informs about change of currentViewController. This callback is fired after transition exceedes progressLimit property of QPageViewController
    ///
    /// - Parameters:
    ///   - pageViewController: The page view controller instance
    ///   - fromController: Currently selected view controller the transition started from
    ///   - toController: View controller that was scrolled to (transition might still not be finished)
    @objc optional func pageViewController(_ pageViewController: QPageViewController, didMove fromController: UIViewController?, toController: UIViewController?)
    
    /// Informs about transition end.
    ///
    /// - Parameters:
    ///   - pageViewController: The page view controller instance
    ///   - onController: Controller that transition ended on. Should be same as currentViewController
    @objc optional func pageViewController(_ pageViewController: QPageViewController, endedMove onController: UIViewController)
}

public protocol QPageViewControllerDataSource: class {
    
    /// Called to obtain ViewController that should be to the right from currentViewController
    ///
    /// - Parameters:
    ///   - pageViewController: The page view controller instance
    ///   - controller: Instance of currentViewController (nil if no previous controller)
    /// - Returns: Instance of ViewController or nil
    func pageViewController(_ pageViewController: QPageViewController, controllerAfter controller: UIViewController?) -> UIViewController?
    
    /// Called to obtain ViewController that should be to the left from currentViewController
    ///
    /// - Parameters:
    ///   - pageViewController: The page view controller instance
    ///   - controller: Instance of currentViewController (nil if no previous controller)
    /// - Returns: Instance of ViewController or nil
    func pageViewController(_ pageViewController: QPageViewController, controllerBefore controller: UIViewController?) -> UIViewController?
    
}

open class QPageViewController: UIViewController {
    
    /// Object that receives callback about page view controller transitions.
    open weak var delegate: QPageViewControllerDelegate?
    
    /// Object that provides instances of UIViewControllers to page view controller.
    open weak var dataSource: QPageViewControllerDataSource?
    
    /// If smart cache is enabled all unused ViewControllers are stored in cachedControllers property. Instances of ViewController then must be obtained by calling reusableController().
    open var smartCacheEnabled = true
    
    /// Snaps to currentViewController after progress exceeds progressLimit
    open var automaticcallyCompleteUserDrag = false
    
    /// Instances of ViewController that were removed from PageViewController and can be reused
    open var cachedControllers: [UIViewController] = []
    
    /// During transition to new controller, controller which user swipes to us considered to be currentViewController after progress exceeds this limit. Value must be between 0.5 and 1.00.
    open var progressLimit: CGFloat {
        if inProgramTransition {
            return programProgressLimit
        }
        return userProgressLimit
    }
    open var userProgressLimit: CGFloat = 1.00
    open var programProgressLimit: CGFloat = 1.00
    
    fileprivate var inProgramTransition = false
    
    /// QPageViewControllerDataSource methods should use controllers provided by this. Caching works only if smartCacheEnabled property is set to true.
    ///
    /// - Returns: Unused instance of T (subclass of UIViewController) or created new if no unused instances are available
    open func reusableController<T: UIViewController>() -> T {
        var retController: T
        if let controller = self.getCachedController() as? T {
            retController = controller
        } else {
            retController = T()
        }
        return retController
    }
    
    /// Dequeues instance of UIViewController from cached controllers
    ///
    /// - Returns: Cached ViewController or nil if no controller was in cache
    fileprivate func getCachedController() -> UIViewController? {
        if  cachedControllers.count > 0 {
            return cachedControllers.removeFirst()
        }
        return nil
    }
    
    open var disableTouchesDuringTransition = true
    open var reenableTouchesAfterTransition = true
    
    open var disableScrollForSingleController = false
    
    //fileprivate var ignoreNextCenterEvent = false
    
    /// ViewController on the left side from Center ViewController
    open var isScrollEnabled: Bool {
        get {
            return self.scrollView.isScrollEnabled
        }
        set {
            if disableScrollForSingleController && hasOnlyOneController {
                return
            }
            self.scrollView.isScrollEnabled = newValue
        }
    }
    
    private var hasOnlyOneController: Bool {
        return self.previousViewControler == nil && self.nextViewControler == nil
    }
    
    /// ViewController in center of PageViewController
    fileprivate(set) open var currentViewController: UIViewController? {
        didSet {
            guard let currentViewController = currentViewController else {
                return
            }
            currentViewControllerOrScrolledTo = currentViewController
            self.delegate?.pageViewController?(self, didMove: oldValue, toController: currentViewController)
            self.prevProgress = -self.prevProgress
        }
    }
    
    fileprivate(set) open var currentViewControllerOrScrolledTo: UIViewController?
    
    /// ViewController on the right side from Center ViewController
    fileprivate(set) open var nextViewControler: UIViewController?
    /// ViewController on the left side from Center ViewController
    fileprivate(set) open var previousViewControler: UIViewController?
    
    /// If true adjacent viewcontrollers are reloaded on trasition end (used by scrollTo)
    open var shoudReloadAdjacent = false
    
    /// True if pageviewcontroller is in transition
    fileprivate(set) var isScrolling = false
    
    /// Is used to generate willMove events. WillMove event is generated when this property changes sign.
    fileprivate var prevProgress: CGFloat = 0.0
    
    /// Most of logic is in this scrollView. ScrollView has 3*width of current view and same height. ScrollView in idle state is always centered.
    fileprivate lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.translatesAutoresizingMaskIntoConstraints = true
        scrollView.autoresizingMask = [.flexibleTopMargin, .flexibleRightMargin, .flexibleBottomMargin, .flexibleLeftMargin]
        scrollView.bounces = true
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        scrollView.isPagingEnabled = true
        return scrollView
    }()
    
    /// Width of single view
    fileprivate var viewWidth: CGFloat {
        return self.view.bounds.width
    }
    
    /// Height of single view
    fileprivate var viewHeight: CGFloat {
        return self.view.bounds.height
    }
    
    /// Check if controller is currently or one of adjacent view controller
    ///
    /// - Parameter controller: Instance of UIViewController
    /// - Returns: True if controller is already in view controller hierarchy.
    open func isOneOfControllers(_ controller: UIViewController) -> Bool {
        return controller==previousViewControler || controller==currentViewController || controller==nextViewControler
    }
    
    open func cancelTouchEvents() {
        self.scrollView.panGestureRecognizer.isEnabled = false
        self.scrollView.panGestureRecognizer.isEnabled = true
    }
    
    /// Scrolls to ViewController. This method canceles all previous animations and start.
    ///
    /// - Parameters:
    ///   - controller: ViewController that should be presented as currentViewController
    ///   - direction: Direction of transition to ViewController. This parameter is ignored if controller is already preloaded as previous, current, or next controller.
    open func scrollTo(_ controller: UIViewController, direction: ScrollDirection = .forward) {
        //print ("scrollTo distance \(self.distance) \(self.progress)")
        if currentViewController == controller {
            centerScrollView(animated: false)
            return
        }
        
        if controller == previousViewControler {
            scrollToPrevious()
            return
        }
        
        if controller == nextViewControler {
            scrollToNext()
            return
        }
        
        centerScrollView(animated: false)
        
        shoudReloadAdjacent = true
        
        switch direction {
        case .forward:
            self.removeChild(self.nextViewControler)
            self.addChild(controller)
            self.nextViewControler = controller
            self.layoutSubviews()
            scrollToNext()
        case .backward:
            self.removeChild(self.previousViewControler)
            self.addChild(controller)
            self.previousViewControler = controller
            self.layoutSubviews()
            scrollToPrevious()
        }
    }
    
    /// Automatically scroll to next controller. Scrooling is animated. Touch are disabled during transition.
    open func scrollToNext() {
        //scrollView.layer.removeAllAnimations()
        inProgramTransition = true
        currentViewControllerOrScrolledTo=nextViewControler
        
        if progress > 0.0 {
            //self.ignoreNextCenterEvent = true
            self.centerScrollView(animated: false)
        } else {
            //self.centerScrollView(animated: false)
            self.scrollView.setContentOffset(scrollView.contentOffset, animated: false)
        }
        
        if disableTouchesDuringTransition {
            //cancelTouchEvents()
            self.isScrollEnabled = false
        } else {
            //cancelTouchEvents()
        }
        
        if self.progress >= 1.0 {
            return
        }
        
        //print("Should actually scroll")
        
        scrollView.setContentOffset(CGPoint(x: distance*2, y: 0), animated: true)
    }
    
    /// Automatically scroll to previous controller. Scrooling is animated. Touch are disabled during transition.
    open func scrollToPrevious() {
        //scrollView.layer.removeAllAnimations()
        inProgramTransition = true
        
        if disableTouchesDuringTransition {
            self.isScrollEnabled = false
        } else {
            cancelTouchEvents()
        }
        
        if progress < 0.0 {
            //self.ignoreNextCenterEvent = true
            self.centerScrollView(animated: false)
        }
        
        currentViewControllerOrScrolledTo=previousViewControler
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    
    /// Reload all controller, this method should be called when current controller should remain same, but adjacent ViewControllers were changed.
    open func reloadAdjacent(afterFinishedDrag: Bool = false) {
        //print("reloadAdjacent start")
        self.removeChild(self.nextViewControler )
        self.removeChild(self.previousViewControler)
        
        self.nextViewControler = dataSource?.pageViewController(self, controllerAfter: self.currentViewController)
        self.previousViewControler = dataSource?.pageViewController(self, controllerBefore: self.currentViewController)
        
        self.addChild(nextViewControler)
        self.addChild(previousViewControler)
        
        if !afterFinishedDrag && disableScrollForSingleController {
            if hasOnlyOneController {
                self.scrollView.isScrollEnabled = false
            } else {
                self.scrollView.isScrollEnabled = true
            }
        }
        //print("reloadAdjacent end")
    }
    
    /// Reload all controller, this method should be called when it is required to reload all ViewControllers
    open func reloadAll() {
        self.removeChild(self.currentViewController)
        
        self.currentViewController = dataSource?.pageViewController(self, controllerAfter: nil)
        
        self.addChild(currentViewController)
        
        reloadAdjacent()
        layoutSubviews()
    }
    
    // MARK: Views handling
    
    /// When a view's bounds change, the view adjusts the position of its subviews.
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        self.scrollView.frame = self.view.bounds
        self.scrollView.contentSize = CGSize(width: viewWidth * 3, height: viewHeight)
        layoutSubviews()
        if !inProgramTransition {
            centerScrollView()
        }
        
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // This method is called after the view controller has loaded its view hierarchy into memory.
    open override func viewDidLoad() {
        super.viewDidLoad()
        //self.automaticallyAdjustsScrollViewInsets = false
        self.view.addSubview(scrollView)
        self.view.backgroundColor = .white
        self.scrollView.delegate = self
    }
    
    /// Layouts view of loaded controllers. Views are layouted in single row next to eachother.
    fileprivate func layoutSubviews() {
        self.previousViewControler?.view.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
        self.currentViewController?.view.frame = CGRect(x: viewWidth, y: 0, width: viewWidth, height: viewHeight)
        self.nextViewControler?.view.frame = CGRect(x: viewWidth * 2, y: 0, width: viewWidth, height: viewHeight)
        //print("layoutSubviews")
    }
    
    /// Adds ViewController as child VeiwController and adds its view as subview
    ///
    /// - Parameter viewController: Instance of ViewController to be added
    fileprivate func addChild(_ viewController: UIViewController?) {
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
            cachedControllers = cachedControllers.filter { $0 != viewController }
        }
    }
    
    /// Removes ViewController from parent and removes its view as subview
    ///
    /// - Parameter viewController: Instance of ViewController to be removed
    fileprivate func removeChild(_ viewController: UIViewController?) {
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

extension QPageViewController: UIScrollViewDelegate {
    
    fileprivate var distance: CGFloat {
        return self.view.bounds.width
    }
    
    fileprivate var progress: CGFloat {
        return (self.scrollView.contentOffset.x - distance) / distance
    }
    
    fileprivate func centerScrollView(animated: Bool = false) {
        scrollView.setContentOffset(CGPoint(x: distance, y: 0), animated: animated)
    }
    
    fileprivate func centerScrollViewIfNeeded() {
        let progress = self.progress
        
        var aboveLimit = false
        
        if progress <= -progressLimit {
            //print("centerScrollViewIfNeeded start")
            self.removeChild(self.nextViewControler)
            self.nextViewControler = self.currentViewController
            self.currentViewController = self.previousViewControler
            self.previousViewControler = self.dataSource?.pageViewController(self, controllerBefore: self.currentViewController)
            self.addChild(self.previousViewControler)
            self.layoutSubviews()
            scrollView.setContentOffset(CGPoint(x: distance*(2-progressLimit), y: 0), animated: false)
            aboveLimit = true
        } else if progress >= progressLimit {
            //print("centerScrollViewIfNeeded start")
            self.removeChild(self.previousViewControler)
            self.previousViewControler = self.currentViewController
            self.currentViewController = self.nextViewControler
            self.nextViewControler = self.dataSource?.pageViewController(self, controllerAfter: self.currentViewController)
            self.addChild(self.nextViewControler)
            self.layoutSubviews()
            scrollView.setContentOffset(CGPoint(x: distance*progressLimit, y: 0), animated: false)
            aboveLimit = true
        }
        
        if (automaticcallyCompleteUserDrag  && aboveLimit) ||
            (!automaticcallyCompleteUserDrag && aboveLimit && !self.scrollView.isDragging) {
            
            //DispatchQueue.main.async {
            //            UIView.animate(withDuration: 0.1, delay: 0, options: [.curveLinear, .curveEaseOut], animations: {
            //                self.centerScrollView()
            //            }, completion: { (completed) in
            //                //print("scrollViewDidEndDecelerating Animation End distance \(self.distance) progress \(self.progress)")
            //                if completed {
            self.centerScrollView(animated: true)
            //                }
            //
            //            })
            //}
        }
    }
    
    func finishedDrag() {
        if self.shoudReloadAdjacent {
            self.shoudReloadAdjacent = false
            self.reloadAdjacent(afterFinishedDrag: true)
        }
        self.layoutSubviews()
        if self.reenableTouchesAfterTransition {
            self.isScrollEnabled = true
        }
        
        self.isScrolling = false
        inProgramTransition = false
        guard let currentViewController = self.currentViewController else {
            return
        }
        
        self.delegate?.pageViewController?(self, endedMove: currentViewController)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        centerScrollViewIfNeeded()
        let startingController: UIViewController? = self.currentViewController
        var targetController: UIViewController?
        
        isScrolling = true
        
        if progress < 0 {
            targetController = self.previousViewControler
        } else {
            targetController = self.nextViewControler
        }
        if (prevProgress >= 0 && progress < 0) || (prevProgress <= 0 && progress > 0) {
            self.delegate?.pageViewController?(self, willMove: startingController, toController: targetController)
        }
        
        self.delegate?.pageViewController?(self, isMoving: startingController, toController: targetController, progress: progress)
        
        if fabs(progress) <= 0.001 {
            finishedDrag()
            
        }
        
        self.prevProgress = progress
        
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        //print("scrollViewWillBeginDragging distance \(distance) progress \(progress)")
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        //print("scrollViewDidEndDragging distance \(distance) progress \(progress)")
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        //print("scrollViewDidEndDecelerating distance \(distance) progress \(progress)")
        //self.scrollView.isScrollEnabled = true
        //        if progress < 0.02 {
        //            self.delegate?.pageViewController?(pageViewController: self, endedMove: currentViewController!)
        //        }
        
    }
}

