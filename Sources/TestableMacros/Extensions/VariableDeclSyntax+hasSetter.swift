//
//  VariableDeclSyntax+hasSetter.swift
//  ProtocolMacro
//
//  Created by Fernando Lucheti on 22/10/24.
//

import SwiftSyntax

extension VariableDeclSyntax {
    var hasSetter: Bool {
        switch bindings.first?.accessorBlock?.accessors {
        case .accessors(let accessors):
            return accessors.contains { $0.accessorSpecifier.text.contains(Keywords.set) }
        case .getter:
            return false
        case .none:
            return bindingSpecifier.text == Keywords.var
        }
    }
}
