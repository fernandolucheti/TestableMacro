# Testable Macro

A macro that produces tests hooks on DEBUG builds to allow testing private methods and properties as seen on:  
https://medium.com/@pm74367/unit-testing-private-methods-in-swift-8436cc649ddb

## Usage
 1 - add TestableMacro as a dependency  
 2 - import TestableMacro  
 3 - mark your class with the macro @Testable  

```swift
import TestableMacro
@Testable
class YourClass {
  private var somePrivateVariable: Int = 0
  private func somePrivateFunction() { }
}
```

auto-generated code: 
```swift
extension YourClass {
    #if DEBUG
    var testHooks: TestHooks {
        return TestHooks(target: self)
    }
    struct TestHooks {
        private var target: YourClass
        fileprivate init(target: YourClass) {
            self.target = target
        }
        var somePrivateVariable: Int {
          get { return target.someVariable }
          set { target.someVariable = newValue }
        }
        func somePrivateFunction() {
          target.someFunction()
        }
    }
    #endif
}
```
## Testing private properties & methods
```swift
@testable import YourModule
import XCTest

class YourTests: XCTestCase {
  let sut: YourClass

  func testSomePrivateFunction() {
    sut.testHooks.somePrivateFunction()
    // make a assetion
  }
}
```
