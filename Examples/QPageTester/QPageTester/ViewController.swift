//
//  ViewController.swift
//  QPageTester
//
//  Created by David Nemec on 22/06/2017.
//  Copyright © 2017 David Nemec. All rights reserved.
//

import UIKit
import QPageViewController
import SnapKit

extension Array where Element: SingleViewController {
    func itemPositionedAt(item: Element, advancedBy offset:Int) -> Element? {
        guard let itemIndex = self.index(of: item) else {
            return nil
        }

        var newIndex = (itemIndex+offset)%count
        if newIndex < 0 {
            newIndex += count
        }

        return self[newIndex]
    }
}

extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

extension UIColor {
    static func random() -> UIColor {
        return UIColor(red:   .random(),
                       green: .random(),
                       blue:  .random(),
                       alpha: 1.0)
    }
}




class SingleViewController: UIViewController{

    public static var nextNumber = 0

    let number: Int;
    let numberLabel = UILabel()

    init() {
        number = SingleViewController.nextNumber
        super.init(nibName: nil, bundle: nil)
        numberLabel.text = "\(number)"
        SingleViewController.nextNumber += 1
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .random()
        self.view.addSubview(numberLabel)
        numberLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        numberLabel.font = UIFont.systemFont(ofSize: 96)
        numberLabel.textColor = .white

    }
}

class ViewController: QPageViewController, QPageViewControllerDataSource, QPageViewControllerDelegate {


    var timer: Timer?
    var controllers = [SingleViewController(),SingleViewController(),SingleViewController(),SingleViewController(),SingleViewController()]
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(timedAction), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: RunLoopMode.commonModes)

        self.dataSource = self
        self.delegate = self
        self.reloadAll()
    }

    func timedAction(){
        print("timedAction")
        //self.scrollTo(controller: controllers[3])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func pageViewController(pageViewController: QPageViewController, controllerAfter controller: UIViewController?) -> UIViewController? {
        guard let controller = controller as? SingleViewController else {
            return controllers[0]
        }
        return controllers.itemPositionedAt(item: controller, advancedBy: 1)
    }

    func pageViewController(pageViewController: QPageViewController, controllerBefore controller: UIViewController?) -> UIViewController? {
        guard let controller = controller as? SingleViewController else {
            return controllers[0]
        }
        return controllers.itemPositionedAt(item: controller, advancedBy: -1)
    }


    func pageViewController(pageViewController: QPageViewController, didMove fromController: UIViewController, toController: UIViewController, finished: Bool) {
        guard let fromController = fromController as? SingleViewController, let toController = toController as? SingleViewController else {
            return
        }
        print("Moved FromController \(fromController.number) ToController \(toController.number) ")
    }

}

class OrigViewController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource{
    var controllers = [SingleViewController(),SingleViewController(),SingleViewController(),SingleViewController(),SingleViewController()]

    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
   
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setViewControllers([controllers[0]], direction: .forward, animated: false, completion: nil)
        self.delegate = self
        self.dataSource = self

    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let controller = viewController as? SingleViewController else {
            return controllers[0]
        }
        return controllers.itemPositionedAt(item: controller, advancedBy: -1)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let controller = viewController as? SingleViewController else {
            return controllers[0]
        }
        return controllers.itemPositionedAt(item: controller, advancedBy: 1)
    }
}


