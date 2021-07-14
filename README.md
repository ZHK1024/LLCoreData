# LLCoreData

[![CI Status](https://img.shields.io/travis/Ruris/LLCoreData.svg?style=flat)](https://travis-ci.org/Ruris/LLCoreData)
[![Version](https://img.shields.io/cocoapods/v/LLCoreData.svg?style=flat)](https://cocoapods.org/pods/LLCoreData)
[![License](https://img.shields.io/cocoapods/l/LLCoreData.svg?style=flat)](https://cocoapods.org/pods/LLCoreData)
[![Platform](https://img.shields.io/cocoapods/p/LLCoreData.svg?style=flat)](https://cocoapods.org/pods/LLCoreData)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

To install it, simply add the following line to your Podfile:

> 使用之前先添加私有源: [查看说明](https://github.com/ZHK1024/LLSpecs)

```ruby
# 私有源
source 'https://github.com/ZHK1024/LLSpecs.git'

# 如果不包含 `官方源` 当 `私有源` 库里面依赖了 `公有源` 库的第三方, 则会报错
source 'https://github.com/CocoaPods/Specs.git'

# 添加依赖
pod 'LLCoreData', '~> 0.3.0'

```
或者直接使用 `git` 的方式添加依赖

```ruby
pod 'LLCoreData', :git => 'https://github.com/ZHK1024/LLCoreData.git'

pod 'LLCoreData', :git => 'https://github.com/ZHK1024/LLCoreData.git', :tag => '0.3.0'
```

[Setting Up Core Data with CloudKit](https://developer.apple.com/documentation/coredata/mirroring_a_core_data_store_with_cloudkit/setting_up_core_data_with_cloudkit)

## Author

ZHK1024, ZHK1024@foxmail.com

## License

LLCoreData is available under the MIT license. See the LICENSE file for more info.
