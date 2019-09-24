# JelloSwift

[![Build Status](https://dev.azure.com/luiz-fs/JelloSwift/_apis/build/status/LuizZak.JelloSwift?branchName=master)](https://dev.azure.com/luiz-fs/JelloSwift/_build/latest?definitionId=6&branchName=master)

Soft-body physics dynamics library written in Swift
----------

![](http://i.imgur.com/mLgeLOl.png)  
_they all look so *squishy!\*_

Video demo available here: https://www.youtube.com/watch?v=0J6P5WaxSHA

This is a port of JelloPhysics, a C#/C++ soft-body physics engine (the original license is included at the JelloPhysics-License.md file).

This port more closely resembles the AS3 version of the engine, [JelloAS3](http://sourceforge.net/projects/jelloas3/), with many optimizations and modifications made to better fit Swift, with the biggest change being how spring and pressure bodies are defined.

The project comes with a demo scene for the iPad, so just fire up and drag the soft bodies around!

## Example

To run the example project, clone the repo, open the Sample project under Sample/Sample.xcodeproj, select a platform and run.

## Requirements

To compile this project, you require Xcode 10.2 w/ Swift 5.0 installed.

## Installation

#### Swift Package Manager

JelloSwift is also available as a [Swift Package](https://swift.org/package-manager)

```swift
dependencies: [
    // [...]
    .package(url: "https://github.com/LuizZak/JelloSwift.git", from: "0.14.0"),
],
```

## License

JelloSwift is available under the MIT license. See the LICENSE file for more info.
