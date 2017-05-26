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
	
	fileprivate enum Builtins: String {
		case quote, car, cdr, cons, equal, atom, cond, lambda, defun, list, println, eval
		
		// True if the given parameter stop evaluation of sub-expressions
		// Sub-expressions will be evaluated lazily by the operator
		
		// Parameter atom: Stringified Atom
		// Returns: True if the atom is the quote operator
		
		public static func mustSkip(_ atom: String) -> Bool {
			return	(atom == Builtins.quote.rawValue) ||
					(atom == Builtins.cond.rawValue)  ||
					(atom == Builtins.defun.rawValue) ||
					(atom == Builtins.lambda.rawValue)
		}
	}
	
	/// Local environment for locally defined functions
	static public var localContext = [String: (SExpr, [SExpr]?, [SExpr]?) -> SExpr] ()
	
	// Global default builtin functions environment
	static private var defaultEnvironment: [String: (SExpr, [SExpr]?, [SExpr]?) -> SExpr] = {
		
		
		var env = [String: (SExpr, [SExpr]?, [SExpr]?) -> SExpr]()
		
		env[Builtins.quote.rawValue] = { params, locals, values in
			guard case let .List(parameters) = params, parameters.count == 2 else { return .List([]) }
			return parameters[1]
		}
		
		env[Builtins.cdr.rawValue] = { params, locals, values in
			guard case let .List(parameters) = params, parameters.count == 2 else { return .List([]) }
			
			guard case let .List(elements) = parameters[1], elements.count > 1 else { return .List([]) }
			
			return .List(Array(elements.dropFirst(1)))
		}
		
		env[Builtins.cons.rawValue] = { params, locals, values in
			guard case let .List(parameters) = params, parameters.count == 3 else {return .List([])}
			
			guard case .List(let elRight) = parameters[2] else {return .List([])}
			
			switch parameters[1].eval(with: locals,for: values)!{
			case let .Atom(p):
				return .List([.Atom(p)]+elRight)
			default:
				return .List([])
			}
		}
		
		env[Builtins.cond.rawValue] = { params, locals, values in
			guard case let .List(parameters) = params, parameters.count > 1 else { return .List([]) }
			
			for el in parameters.dropFirst(1) {
				guard case let .List(c) = el, c.count == 2 else { return .List([]) }
				
				if c[0].eval(with: locals, for: values) != .List([]) {
					let result = c[1].eval(with: locals, for: values)
					return result!
				}
			}
			return .List([])
		}
		
		env[Builtins.defun.rawValue] = { params, locals, values in
			guard case let .List(parameters) = params, parameters.count == 4 else { return .List([]) }
			
			guard case let .Atom(lname) = parameters[1] else { return .List([]) }
			guard case let .List(vars) = parameters[2] else { return .List([]) }
			
			let lambda = parameters[3]
			
			let f: (SExpr, [SExpr]?, [SExpr]?) -> SExpr = { params, locals, values in
				guard case var .List(p) = params else { return .List([]) }
				p = Array(p.dropFirst(1))
				
				// Replace parameters in the lambda with values
				if let result = lambda.eval(with: vars, for: p) {
					return result
				} else {
					return .List([])
				}
			}
			localContext[lname] = f
			return .List([])
		}
		
		
		env[Builtins.equal.rawValue] = { params, locals, values in
			guard case let .List(elements) = params, elements.count == 3 else { return .List([]) }
			
			var me = env[Builtins.equal.rawValue]!
			
			switch (elements[1].eval(with: locals, for: values)!, elements[2].eval(with: locals, for: values)!) {
			case (.Atom(let elLeft), .Atom(let elRight)):
				return elLeft == elRight ? .Atom("true") : .List([])
			case (.List(let elLeft), .List(let elRight)):
				guard elLeft.count == elRight.count else { return .List([]) }
				for (idx, el) in elLeft.enumerated() {
					let testEq:[SExpr] = [.Atom("Equal"), el, elRight[idx]]
					if me(.List(testEq), locals, values) != SExpr.Atom("true") {
						return .List([])
					}
				}
				return .Atom("true")
			default:
				return .List([])
			}
		}
		
		env[Builtins.atom.rawValue] = { params, locals, values in
			guard case let .List(parameters) = params, parameters.count == 2 else { return .List([]) }
			
			switch parameters[1].eval(with: locals, for: values)! {
			case .Atom:
				return .Atom("true")
			default:
				return .List([])
			}
		}
		
		env[Builtins.list.rawValue] = { params,locals,values in
        guard case let .List(parameters) = params, parameters.count > 1 else {return .List([])}
        var res: [SExpr] = []
        
        for el in parameters.dropFirst(1) {
            switch el {
            case .Atom:
                res.append(el)
            case let .List(els):
                res.append(contentsOf: els)
            }
        }
        return .List(res)
    }
		env[Builtins.println.rawValue] = { params,locals,values in
			guard case let .List(parameters) = params, parameters.count > 1 else {return .List([])}
		
			print(parameters[1].eval(with: locals,for: values)!)
			return .List([])
		}
		env[Builtins.eval.rawValue] = { params,locals,values in
			guard case let .List(parameters) = params, parameters.count == 2 else {return .List([])}
			
			return parameters[1].eval(with: locals,for: values)!
		}
		return env
	}()

	public func eval(with locals: [SExpr]? = nil, for values: [SExpr]? = nil) -> SExpr? {
		var node = self
		
		switch node {
		case .Atom:
			return evaluateVariable(node, with: locals, for: values)
		case var .List(elements):
			var skip = false
			
		if elements.count > 1, case let .Atom(value) = elements[0] {
			skip = Builtins.mustSkip(value)
			}
			
			// Evaluate all subexpressions
		if !skip {
			elements = elements.map{
				return $0.eval(with: locals, for: values)!
				}
			}
			node = .List(elements)
			
			// Obtain a reference to the function represented by the first atom and apply it, local definitions shadow global ones
			if elements.count > 0, case let .Atom(value) = elements[0], let f  = SExpr.localContext[value] ?? SExpr.defaultEnvironment[value] {
				let r = f(node, locals, values)
				return r
			}
			
			return node
		}
		
	}

	private func evaluateVariable(_ v: SExpr, with locals: [SExpr]?, for values: [SExpr]?) -> SExpr {
		guard let locals = locals, let values = values else { return v }
		
		if locals.contains(v) {
			// The current atom is a variable, replace it with its value
			return values[locals.index(of: v)!]
		} else {
			// Not a variable, just return it
			return v
		}
	}
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
		}
	}
}
