import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct TestableMacro: ExtensionMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                                 attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
                                 providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
                                 conformingTo protocols: [SwiftSyntax.TypeSyntax],
                                 in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        
        let classDecl = declaration
        var testableFunctions: [FunctionDeclSyntax] = []
        var testableProperties: [VariableDeclSyntax] = []
        
        for member in classDecl.memberBlock.members {
            if let funcDecl = member.decl.as(FunctionDeclSyntax.self),
                   funcDecl.modifiers.contains(where: { modifier in
                       modifier.name.text == "private" || modifier.name.text == "fileprivate" }) == true {
                testableFunctions.append(funcDecl)
            }
            if let varDecl = member.decl.as(VariableDeclSyntax.self),
                   varDecl.modifiers.contains(where: { $0.name.text == "private" || $0.name.text == "fileprivate" }) == true {
                            testableProperties.append(varDecl)
                        }
        }
        
        return [
            try ExtensionDeclSyntax("""
        extension \(type.trimmed)
        """, membersBuilder: {
            """
            #if DEBUG
            var testHooks: TestHooks {
                return TestHooks(target: self)
            }
            
            struct TestHooks {
                private var target: \(type.trimmed)
                
                fileprivate init(target: \(type.trimmed)) {
                    self.target = target
                }
                
                \(raw: testableProperties.map { varDecl in
                let propertyName = varDecl.bindings.first?.pattern.description.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let propertyType = varDecl.bindings.first?.typeAnnotation?.type.description.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Any"
                return """
                var \(propertyName): \(propertyType) {
                    get { return target.\(propertyName) }
                    set { target.\(propertyName) = newValue }
                }
                """
                }.joined(separator: "\n"))
        
                \(raw: testableFunctions.map { funcDecl in
                let funcName = funcDecl.name.text
                let parameters = funcDecl.signature.parameterClause.parameters.map { param in
                var suffix = ""
                if let secondParamName = param.secondName?.text {
                    suffix = " \(secondParamName)"
                }
                let paramName = param.firstName.text + suffix
                let paramType = param.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
                return "\(paramName): \(paramType)"
                }.joined(separator: ", ")
        
                let paramNames = funcDecl.signature.parameterClause.parameters.map { param in
                    "\(param.firstName.text): \(param.secondName?.text ?? param.firstName.text)"
                }.joined(separator: ", ")

                return """
                func \(funcName)(\(parameters)) {
                    target.\(funcName)(\(paramNames))
                }
                """
                }.joined(separator: "\n"))
            }
            #endif
        """})]
    }
}


@main
struct TestableMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        TestableMacro.self
    ]
}
