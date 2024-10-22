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
        var properties = ""
        var functions = ""
        
        properties = testableProperties.map { varDecl in
            let propertyName = varDecl.bindings.first?.pattern.description.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let propertyType = varDecl.bindings.first?.typeAnnotation?.type.description.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Any"
            
            var hasSetter = false
            var propertyAccess = "get { return target.\(propertyName) }"
            switch varDecl.bindings.first?.accessorBlock?.accessors {
            case .accessors(let accessors):
                hasSetter = accessors.contains(where: { $0.accessorSpecifier.text.contains("set") })
            case .getter:
                break
            case .none:
                hasSetter = true
            }
            if hasSetter {
                propertyAccess.append("set { target.\(propertyName) = newValue }")
            }
            return "var \(propertyName): \(propertyType) {\(propertyAccess)}"
        }.joined(separator: "\n")
        
        functions = testableFunctions.map { funcDecl in
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
            
            let returnType = funcDecl.signature.returnClause?.type.description.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Void"
            
            return "func \(funcName)(\(parameters)) -> \(returnType) { return target.\(funcName)(\(paramNames)) }"
        }.joined(separator: "\n")
        
        return [try ExtensionDeclSyntax("extension \(type.trimmed)", membersBuilder: {
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
            \(raw: properties) 
            \(raw: functions)
        }
        #endif
        """
        })]
    }
}

@main
struct TestableMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        TestableMacro.self
    ]
}
