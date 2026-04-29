# Testable Macro

A macro that produces tests hooks on DEBUG builds to allow testing private methods and properties as seen on:  
https://medium.com/@pm74367/unit-testing-private-methods-in-swift-8436cc649ddb

## Features
- ✅ Test private instance properties and methods
- ✅ Test private static properties and methods  
- ✅ Support for computed properties with getters/setters
- ✅ DEBUG-only code generation (no production overhead)

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
  
  // Static members are also supported
  nonisolated(unsafe) private static var staticVariable: Int = 42
  private static let staticConstant: String = "test"
  private static func staticFunction() -> String { "result" }
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
        
        // Instance members
        var somePrivateVariable: Int {
          get { return target.somePrivateVariable }
          set { target.somePrivateVariable = newValue }
        }
        func somePrivateFunction() {
          return target.somePrivateFunction()
        }
        
        // Static members
        static var staticVariable: Int {
          get { return YourClass.staticVariable }
          set { YourClass.staticVariable = newValue }
        }
        static var staticConstant: String {
          get { return YourClass.staticConstant }
        }
        static func staticFunction() -> String {
          return YourClass.staticFunction()
        }
    }
    #endif
}
```

## Testing private properties & methods

### Instance Members
```swift
@testable import YourModule
import XCTest

class YourTests: XCTestCase {
  let sut: YourClass

  func testPrivateInstanceMembers() {
    // Test private instance properties
    sut.testHooks.somePrivateVariable = 100
    XCTAssertEqual(sut.testHooks.somePrivateVariable, 100)
    
    // Test private instance methods
    sut.testHooks.somePrivateFunction()
    // make an assertion
  }
}
```

### Static Members
```swift
func testPrivateStaticMembers() {
  // Test private static properties
  YourClass.TestHooks.staticVariable = 200
  XCTAssertEqual(YourClass.TestHooks.staticVariable, 200)
  XCTAssertEqual(YourClass.TestHooks.staticConstant, "test")
  
  // Test private static methods
  let result = YourClass.TestHooks.staticFunction()
  XCTAssertEqual(result, "result")
}
```

## Notes
- For static variables with concurrency safety concerns, use `nonisolated(unsafe)` in your test/example code
- All generated test hooks are wrapped in `#if DEBUG` so they won't affect production builds
- Both `let` constants and `var` variables are supported for both instance and static members
- Computed properties with custom getters/setters are properly handled
