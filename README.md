# VirtualTourist
> Visit the World in a tap of your fingers!

[![Swift Version][swift-image]][swift-url]
[![License][license-image]][license-url]
[![Platform][platform-image]][platform-url]
[![PRs Welcome][prswelcome-image]][prswelcome-url]

VirtualTourist is an app developed as part of the [Udacity iOS Developer Nanodegree](https://www.udacity.com/course/ios-developer-nanodegree-nd003), in particular is the result of the [iOS Persistence and Core Data](https://www.udacity.com/course/ios-persistence-and-core-data-ud325) course.  
  
Users can "visit" any place they want by dropping pins on the map in order to show photos taken near the locations (downloaded from Flickr).    
  
The purpose of the project is to learn how to use Core Data to persist application data with the use of different contexts which serves different purpses.  
In particular:  
- a persistent context, in order to persist data on a background queue
- a main context, whose purpose is to display data in the main queue (child of the persistent context)
- a background context, to execute background tasks on a background queue (child of the main context)

## Requirements
- iOS 9.0+
- Xcode 8.0

## Third Party Libraries
- [Alamofire](https://github.com/Alamofire/Alamofire) for networking
- [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) for JSON parsing
- [PromiseKit](https://github.com/mxcl/PromiseKit) for asynchronous tasks

## License
VirtualTourist is released under the MIT license. See [LICENSE](LICENSE) for details.

[swift-image]:https://img.shields.io/badge/swift-3.0-orange.svg
[swift-url]: https://swift.org/
[license-image]:https://img.shields.io/badge/License-MIT-blue.svg
[license-url]: LICENSE
[platform-image]:https://img.shields.io/cocoapods/p/LFAlertController.svg?style=flat
[platform-url]:https://cocoapods.org/pods/LFAlertController
[prswelcome-image]:https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square
[prswelcome-url]:https://makeapullrequest.com
