import TestableMacro
import SwiftUI

@Testable
class MyClass {
    private let someConstant: Int = 0
    private var someVariable: Int = 0
    private var someVariableGetOnly: Int { 0 }
    private var somePropertyGetOnlyImplicit: String {
        ""
    }
    private var somePropertyGetOnlyExplicit: String {
        get { "" }
    }
    private var somePropertyGetAndSetExplicit: String {
        get { "" }
        set { }
    }
    nonisolated(unsafe) private static var staticVariable: Int = 42
    private static let staticConstant: String = "test"
    private static var staticComputedProperty: Double {
        get { 3.14 }
        set { }
    }

    private func someFunction2() {
    }
    private func someFunction(param1: String, param2: Int) -> (() -> Void)? {
        nil
    }
    private func anotherFunction2(_ param: Double, param2: Int) -> [String: String] {
        [:]
    }
    fileprivate func anotherFunction(in param: Double) -> Double? {
        nil
    }
    private static func staticFunction() -> String {
        "static result"
    }
    private static func staticFunctionWithParams(_ value: Int, name: String) -> Bool {
        value > 0
    }
}
