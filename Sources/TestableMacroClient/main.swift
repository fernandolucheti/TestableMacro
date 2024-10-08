import TestableMacro

@Testable
class MyClass {
    private var someVariable: Int = 0

    private func someFunction() {
    }
    private func someFunction(param1: String, param2: Int) {
        print("Hello, \(param1) with number \(param2)!")
    }
    private func anotherFunction2(_ param: Double, param2: Int) {
        print("Another function with param: \(param)")
    }
    fileprivate func anotherFunction(in param: Double) {
    }
}
