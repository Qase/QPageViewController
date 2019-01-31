[![Platform](https://img.shields.io/cocoapods/p/PagingKit.svg?style=flat)](http://cocoapods.org/pods/PagingKit)
![Swift 4.0](https://img.shields.io/badge/Swift-4.0-orange.svg)
[![travis badge](https://travis-ci.org/Qase/QPageViewController.svg)](https://travis-ci.org/Qase/QPageViewController)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Release](https://img.shields.io/github/release/qase/QPageViewController.svg?style=flat)](https://github.com/Qase/QPageViewController/releases/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![codebeat badge](https://codebeat.co/badges/7acb4504-7c0c-4c56-b72e-383ba8268df7)](https://codebeat.co/projects/github-com-qase-qpageviewcontroller-master-3f1df7e6-4a93-4e3a-9b89-61e38fa67797)
[![Qase: QPageViewController](https://img.shields.io/badge/Qase-QuantiLogger-ff69b4.svg)](https://github.com/Qase/QPageViewController)




# QPageViewController

QPage view controller is lightweight View Controller similar to UIPageViewController, but with better delegates and reusable UIVIewControllers.

## Demo

![Demo](https://user-images.githubusercontent.com/5677479/33329998-f6ae1598-d45d-11e7-94c9-6793de74790e.gif "Demo")



## Usage Example

``` swift
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
```

## Requirements

- Swift 4.0
- Xcode 9
- iOS 10.0+

## Installation

### Carthage

The easiest way to integrate this framework in your project is to use [Carthage](https://github.com/Carthage/Carthage/).

1. Add `github "Qase/QPageViewController"` to your `Cartfile`.
2. Run `carthage bootstrap`.
3. Drag either the `QPageViewController.xcodeproj` or the `QPageViewController.framework` into your project/workspace and link your target against the `QPageViewController.framework`.
4. Make sure the framework [gets copied](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application) to your application bundle.

### Submodules

Another option for integrating this framework is to use [Git submodules](http://git-scm.com/book/en/v2/Git-Tools-Submodules).


## License

`QPageViewController` is released under the [MIT License](LICENSE.md).
