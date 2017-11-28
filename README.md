[![Platform](https://img.shields.io/cocoapods/p/PagingKit.svg?style=flat)](http://cocoapods.org/pods/PagingKit)
![Swift 4.0](https://img.shields.io/badge/Swift-4.0-orange.svg)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![](https://img.shields.io/github/release/Qase/QPageViewController.svg?style=flat-square)](https://github.com/lukaskubanek/LoremSwiftum/releases)
[![](https://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat-square "License")](LICENSE.md)

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