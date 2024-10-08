/// a macro that produces tests hooks on DEBUG builds to allow testing private methods and properties
@attached(extension, names: arbitrary)
public macro Testable() = #externalMacro(module: "TestableMacros", type: "TestableMacro")
