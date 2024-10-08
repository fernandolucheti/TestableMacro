import TestableMacro

@Testable
class MyClass {
    private var someVariable: Int = 0

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
