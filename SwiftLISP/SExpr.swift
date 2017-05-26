//
//  SExpr.swift
//  SwiftLISP
//
//  Created by Justin Purnell on 5/26/17.
//  Copyright © 2017 Justin Purnell. All rights reserved.
//

import Foundation

public enum SExpr {
	case Atom(String)
	case List([SExpr])
}

extension SExpr: Equatable {
	public static func ==(lhs: SExpr, rhs: SExpr) -> Bool {
		switch (lhs, rhs) {
		case let (.Atom(l), .Atom(r)):
			return l == r
		case let (.List(l), .List(r)):
			guard l.count == r.count else { return false }
			for (idx, el) in l.enumerated() {
				if el != r[idx] {
					return false
				}
			}
			return true
		default:
			return false
		}
	}
}

extension SExpr: CustomStringConvertible {
	public var description: String {
		switch self {
		case let .Atom(value):
			return value
		case let .List(subxexprs):
			var res = "("
			for expr in subxexprs {
				res += "\(expr) "
			}
			res += ")"
			return res
		default:
			<#code#>
		}
	}
}
