# JelloSwift

[![CI Status](http://img.shields.io/travis/LuizZak/JelloSwift.svg?style=flat)](https://travis-ci.org/LuizZak/JelloSwift)
[![Version](https://img.shields.io/cocoapods/v/JelloSwift.svg?style=flat)](http://cocoapods.org/pods/JelloSwift)
[![License](https://img.shields.io/cocoapods/l/JelloSwift.svg?style=flat)](http://cocoapods.org/pods/JelloSwift)
[![Platform](https://img.shields.io/cocoapods/p/JelloSwift.svg?style=flat)](http://cocoapods.org/pods/JelloSwift)

Soft-body physics dynamics library written in Swift
----------

Video demo available here: https://www.youtube.com/watch?v=0J6P5WaxSHA

This is a port of JelloPhysics, a C#/C++ soft-body physics engine (the original license is included at the JelloPhysics-License.md file).

This port more closely resembles the AS3 version of the engine, [JelloAS3](http://sourceforge.net/projects/jelloas3/), with many optimizations and modifications made to better fit Swift, with the biggest change being how spring and pressure bodies are defined.

The project comes with a demo scene for the iPad, so just fire up and drag the soft bodies around!

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

To compile this project, you require Xcode 8.0 w/ Swift 3 installed.

## Installation

#### CocoaPods

JelloSwift is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "JelloSwift"
```

#### Swift Package Manager

JelloSwift is also available as a [Swift Package](https://swift.org/package-manager)

```swift
import PackageDescription

let package = Package(
    name: "project_name",
    targets: [],
    dependencies: [
        .Package(url: "https://github.com/LuizZak/JelloSwift.git", majorVersion: 0, minor: 8)
    ]
)
```

## Author

LuizZak, luizinho_mack@yahoo.com.br

## License

JelloSwift is available under the MIT license. See the LICENSE file for more info.
