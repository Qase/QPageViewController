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

class SingleModel {
    public static var nextNumber = 0
    public let number: Int = {
        let ret = nextNumber
        nextNumber+=1
        return ret
    }()
    public let color: UIColor = .random()


}




class SingleViewController: UIViewController{

    public static var nextNumber = 0

    public var model: SingleModel? {
        didSet{
            guard let model = model else{
                return
            }
            self.numberLabel.text = "\(model.number)"
            self.view.backgroundColor = model.color

        }
    }

    override var description: String{
        return "SingleViewController \(model!.number)"
    }

    let numberLabel = UILabel()

    init() {
        super.init(nibName: nil, bundle: nil)
        print("SingleViewController")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(numberLabel)
        numberLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        numberLabel.font = UIFont.systemFont(ofSize: 96)
        numberLabel.textColor = .white

    }
}

class ViewController: QPageViewController {

    var timer: Timer?
    //var controllers = [SingleViewController(),SingleViewController(),SingleViewController(),SingleViewController(),SingleViewController()]
//    var currentControllerInt = 0
//
//    func nextController(model: SingleModel) -> SingleViewController {
//        currentControllerInt = (currentControllerInt + 1)%controllers.count
//        controllers[currentControllerInt].model = model
//        return controllers[currentControllerInt]
//    }

    var model = [SingleModel(),SingleModel(),SingleModel(),SingleModel(),SingleModel(),SingleModel(),SingleModel(),
                 SingleModel(),SingleModel(),SingleModel(),SingleModel(),SingleModel(),SingleModel(),SingleModel(),
                 SingleModel(),SingleModel(),SingleModel(),SingleModel(),SingleModel(),SingleModel(),SingleModel()
                 ]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(timedAction), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: RunLoopMode.commonModes)

        self.dataSource = self
        self.delegate = self
        //self.extraControllers = [SingleViewController(),SingleViewController(),SingleViewController(),SingleViewController()]
        self.reloadAll()
    }

    @objc func timedAction(){
//        print(" ")
//        print("timedAction")
//
//        let controller:SingleViewController = self.reusableController()
//        controller.model = model[3]
//
//        self.scrollTo(controller: controller)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

//    private func reusableController(){
//        var retController : SingleViewController
//        if let controller = self.getController() as? SingleViewController {
//            retController = controller
//        }
//        else{
//            retController = SingleViewController()
//        }
//        return retController
//    }


    func nextModel(currentModel: SingleModel) -> SingleModel{
        if currentModel.number == model.last!.number{
            return model.first!
        }
        return model[currentModel.number+1]
    }

    func prevModel(currentModel: SingleModel) -> SingleModel{
        if currentModel.number == 0{
            return model.last!
        }
        return model[currentModel.number-1]
    }

}

extension ViewController: QPageViewControllerDataSource{
    
    func pageViewController(_ pageViewController: QPageViewController, controllerAfter controller: UIViewController?) -> UIViewController? {
        let retController:SingleViewController = reusableController()

        guard let controller = controller as? SingleViewController, let currentModel = controller.model else {
            retController.model = model[0]
            return retController
        }

        retController.model = self.nextModel(currentModel: currentModel)
        return retController

    }

    func pageViewController(_ pageViewController: QPageViewController, controllerBefore controller: UIViewController?) -> UIViewController? {
        let retController:SingleViewController = reusableController()

        guard let controller = controller as? SingleViewController, let currentModel = controller.model else {
            retController.model = model[0]
            return retController
        }

        retController.model = self.prevModel(currentModel: currentModel)
        return retController
    }
}

extension ViewController: QPageViewControllerDelegate{
    func pageViewController(_ pageViewController: QPageViewController, didMove fromController: UIViewController?, toController: UIViewController?) {
        guard let fromController = fromController as? SingleViewController, let toController = toController as? SingleViewController else {
            return
        }
        self.title = "\(toController.model?.number ?? 999)"
        print("didMove FromController \(String(describing: fromController.model?.number)) ToController \(String(describing: toController.model?.number)) ")
    }

    func pageViewController(_ pageViewController: QPageViewController, endedMove onController: UIViewController) {
        guard let onController = onController as? SingleViewController else {
            return
        }
        print("endedMove  \(String(describing: onController.model?.number)) ")
    }

    func pageViewController(_ pageViewController: QPageViewController, willMove fromController: UIViewController?, toController: UIViewController?) {
        guard let fromController = fromController as? SingleViewController, let toController = toController as? SingleViewController else {
            return
        }
        print("willMove FromController \(String(describing: fromController.model?.number)) ToController \(String(describing: toController.model?.number)) ")
    }

    func pageViewController(_ pageViewController: QPageViewController, isMoving fromController: UIViewController?, toController: UIViewController?, progress: CGFloat) {
        guard let fromController = fromController as? SingleViewController, let toController = toController as? SingleViewController else {
            return
        }
        print("isMoving FromController \(String(describing: fromController.model?.number)) ToController \(String(describing: toController.model?.number)) progress \(progress)")
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
        print("viewControllerBefore")
        guard let controller = viewController as? SingleViewController else {
            return controllers[0]
        }
        return controllers.itemPositionedAt(item: controller, advancedBy: -1)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        print("viewControllerAfter")
        guard let controller = viewController as? SingleViewController else {
            return controllers[0]
        }
        return controllers.itemPositionedAt(item: controller, advancedBy: 1)
    }
}


