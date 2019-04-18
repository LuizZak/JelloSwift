# JelloSwift

[![Build Status](https://dev.azure.com/luiz-fs/JelloSwift/_apis/build/status/LuizZak.JelloSwift?branchName=master)](https://dev.azure.com/luiz-fs/JelloSwift/_build/latest?definitionId=6&branchName=master)
[![Version](https://img.shields.io/cocoapods/v/JelloSwift.svg?style=flat)](http://cocoapods.org/pods/JelloSwift)
[![License](https://img.shields.io/cocoapods/l/JelloSwift.svg?style=flat)](http://cocoapods.org/pods/JelloSwift)
[![Platform](https://img.shields.io/cocoapods/p/JelloSwift.svg?style=flat)](http://cocoapods.org/pods/JelloSwift)

Soft-body physics dynamics library written in Swift
----------

![](http://i.imgur.com/mLgeLOl.png)  
_they all look so *squishy!\*_

Video demo available here: https://www.youtube.com/watch?v=0J6P5WaxSHA

This is a port of JelloPhysics, a C#/C++ soft-body physics engine (the original license is included at the JelloPhysics-License.md file).

This port more closely resembles the AS3 version of the engine, [JelloAS3](http://sourceforge.net/projects/jelloas3/), with many optimizations and modifications made to better fit Swift, with the biggest change being how spring and pressure bodies are defined.

The project comes with a demo scene for the iPad, so just fire up and drag the soft bodies around!

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

To compile this project, you require Xcode 10.2 w/ Swift 5.0 installed.

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
    dependencies: [
        .package(url: "https://github.com/LuizZak/JelloSwift.git", from: "0.14.0")
    ],
    targets: [
        // ...
    ]
)
```

## License

JelloSwift is available under the MIT license. See the LICENSE file for more info.
