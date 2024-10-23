import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import TestableMacros

let testMacros: [String: Macro.Type] = [
    "Testable": TestableMacro.self,
]
final class MacroTests: XCTestCase {
    
    func testTestableMacro() throws {
        let source = """
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
}
"""
        
        let expectedOutput = """

extension MyClass {
    #if DEBUG
    var testHooks: TestHooks {
        return TestHooks(target: self)
    }
    struct TestHooks {
        private var target: MyClass
        fileprivate init(target: MyClass) {
            self.target = target
        }
        var someConstant: Int {
            get {
                return target.someConstant
            }
        }
        var someVariable: Int {
            get {
                return target.someVariable
            }
            set {
                target.someVariable = newValue
            }
        }
        var someVariableGetOnly: Int {
            get {
                return target.someVariableGetOnly
            }
        }
        var somePropertyGetOnlyImplicit: String {
            get {
                return target.somePropertyGetOnlyImplicit
            }
        }
        var somePropertyGetOnlyExplicit: String {
            get {
                return target.somePropertyGetOnlyExplicit
            }
        }
        var somePropertyGetAndSetExplicit: String {
            get {
                return target.somePropertyGetAndSetExplicit
            }
            set {
                target.somePropertyGetAndSetExplicit = newValue
            }
        }
        func someFunction2() {
            return target.someFunction2()
        }
        func someFunction(param1: String, param2: Int) -> (() -> Void)? {
            return target.someFunction(param1: param1, param2: param2)
        }
        func anotherFunction2(_ param: Double, param2: Int) -> [String: String] {
            return target.anotherFunction2(_: param, param2: param2)
        }
        func anotherFunction(in param: Double) -> Double? {
            return target.anotherFunction(in: param)
        }
    }
    #endif
}
"""
        assertMacroExpansion(["@Testable", source].joined(separator: "\n"),
                             expandedSource: [source, expectedOutput].joined(separator: "\n"),
                             macros: testMacros,
                             indentationWidth: .spaces(4))
    }
}
