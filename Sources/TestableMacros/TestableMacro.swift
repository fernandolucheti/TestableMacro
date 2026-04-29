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

        let privateMembers: TypeMembers = extractPrivateMembers(declaration.memberBlock.members)
        let instanceProperties = stringify(privateMembers.instanceProperties, isStatic: false, typeName: type.trimmed.description)
        let instanceFunctions = stringify(privateMembers.instanceFunctions, isStatic: false, typeName: type.trimmed.description)
        let staticProperties = stringify(privateMembers.staticProperties, isStatic: true, typeName: type.trimmed.description)
        let staticFunctions = stringify(privateMembers.staticFunctions, isStatic: true, typeName: type.trimmed.description)

        return [try ExtensionDeclSyntax("extension \(type.trimmed)",
                                        membersBuilder: {
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
            \(raw: instanceProperties) 
            \(raw: instanceFunctions)
            \(raw: staticProperties)
            \(raw: staticFunctions)
        }
        #endif
        """
        })]
    }
}

extension TestableMacro {

    private struct TypeMembers {
        var instanceProperties: [VariableDeclSyntax]
        var instanceFunctions: [FunctionDeclSyntax]
        var staticProperties: [VariableDeclSyntax]
        var staticFunctions: [FunctionDeclSyntax]
    }

    private static func extractPrivateMembers(_ members: MemberBlockItemListSyntax) -> TypeMembers {
        var typeMembers = TypeMembers(instanceProperties: [], instanceFunctions: [], staticProperties: [], staticFunctions: [])
        members.forEach { member in
            if let varDecl = member.decl.as(VariableDeclSyntax.self),
               varDecl.modifiers.contains(where: { $0.name.text.contains(Keywords.private) }) {
                if varDecl.modifiers.contains(where: { $0.name.text.contains(Keywords.static) }) {
                    typeMembers.staticProperties.append(varDecl)
                } else {
                    typeMembers.instanceProperties.append(varDecl)
                }
            }
            if let funcDecl = member.decl.as(FunctionDeclSyntax.self),
               funcDecl.modifiers.contains(where: { $0.name.text.contains(Keywords.private) }) {
                if funcDecl.modifiers.contains(where: { $0.name.text.contains(Keywords.static) }) {
                    typeMembers.staticFunctions.append(funcDecl)
                } else {
                    typeMembers.instanceFunctions.append(funcDecl)
                }
            }
        }
        return typeMembers
    }

    private static func stringify(_ properties: [VariableDeclSyntax], isStatic: Bool, typeName: String) -> String {
        properties.map { varDecl in
            let propertyName = varDecl.bindings.first?.pattern.description
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? .empty
            let propertyType = varDecl.bindings.first?.typeAnnotation?.type.description
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? "Any"

            let targetAccess = isStatic ? typeName : "target"
            let staticModifier = isStatic ? "\(Keywords.static) " : ""

            var accessors = "\(Keywords.get) { \(Keywords.return) \(targetAccess).\(propertyName) }"
            if varDecl.hasSetter {
                accessors.append("\(Keywords.set) { \(targetAccess).\(propertyName) = newValue }")
            }
            return "\(staticModifier)\(Keywords.var) \(propertyName): \(propertyType) {\(accessors)}"
        }.joined(separator: "\n")
    }

    private static func stringify(_ functions: [FunctionDeclSyntax], isStatic: Bool, typeName: String) -> String {
        functions.map { funcDecl in
            let funcName = funcDecl.name.text

            let parameters = funcDecl.signature.parameterClause.parameters.map { param in
                var parameterName = param.firstName.text
                if let secondParamName = param.secondName?.text {
                    parameterName += " \(secondParamName)"
                }
                let paramType = param.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
                return "\(parameterName): \(paramType)"
            }.joined(separator: ", ")

            let paramNames = funcDecl.signature.parameterClause.parameters.map { param in
                "\(param.firstName.text): \(param.secondName?.text ?? param.firstName.text)"
            }.joined(separator: ", ")

            let returnType = funcDecl.signature.returnClause?.type.description
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let returnSuffix = returnType.isEmpty ? .empty : " -> \(returnType)"

            let targetAccess = isStatic ? typeName : "target"
            let staticModifier = isStatic ? "\(Keywords.static) " : ""

            return "\(staticModifier)\(Keywords.func) \(funcName)(\(parameters))\(returnSuffix) { \(Keywords.return) \(targetAccess).\(funcName)(\(paramNames)) }"
        }.joined(separator: "\n")
    }
}

@main
struct TestableMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        TestableMacro.self
    ]
}
