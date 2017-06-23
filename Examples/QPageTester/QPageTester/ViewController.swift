//
//  ViewController.swift
//  QPageTester
//
//  Created by David Nemec on 22/06/2017.
//  Copyright © 2017 David Nemec. All rights reserved.
//

import UIKit
import QPageViewController

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
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .random()
    }
}

class ViewController: QPageViewController, QPageViewControllerDataSource {


    var controllers = [SingleViewController(),SingleViewController(),SingleViewController(),SingleViewController(),SingleViewController()]
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.dataSource = self
        self.reloadAll()
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


}
