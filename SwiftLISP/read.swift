//
//  tokenizer.swift
//  SwiftLISP
//
//  Created by Justin Purnell on 5/26/17.
//  Copyright © 2017 Justin Purnell. All rights reserved.
//

import Foundation

extension SExpr {
	// Read a LISP string and convert it to a heirarchical S-Expression
	public static func read(_ sexpr: String) -> SExpr {
		enum Token {
			case pOpen, pClose, textBlock(String)
		}
		
		// Break down a string into a series of tokens
		// Parameter sexpr: Stringified S-Expression
		// Returns: Series of tokens
		
		func tokenize(_ sexpr: String) -> [Token] {
			var result = [Token]()
			var tempText = ""
			
			for c in sexpr.characters {
				switch c {
					case "(":
						if tempText != "" {
							result.append(.textBlock(tempText))
							tempText = ""
					}
					result.append(.pOpen)
					case ")":
						if tempText != "" {
							result.append(.textBlock(tempText))
							tempText = ""
					}
					result.append(.pClose)
					default:
						tempText.append(c)
				}
			}
			return result
		}
		
		// Parser
		// Parses a series of tokens to obtain a hierarchical S-Expression
		// Parameter tokens: Tokens to parse
		// Parameter node: Parent S-Expression if available
		
		// Returns: Tuple with remaining tokens and resulting S-Expression
		
		func parse(_ tokens: [Token], node: SExpr? = nil) -> (remaining:[Token], subexpr:SExpr?) {
			var tokens = tokens
			var node = node
			
			var i = 0
			repeat {
				let t = tokens[i]
				
				switch t {
				case .pOpen:
					//new sexpr
					let (tr,n) = parse( Array(tokens[(i+1)..<tokens.count]), node: .List([]))
					assert(n != nil) //Cannot be nil
					
					(tokens, i) = (tr, 0)
					node = appendTo(list: node, node: n!)
					
					if tokens.count != 0 {
						continue
					}else{
						break
					}
				case .pClose:
					//close sexpr
					return ( Array(tokens[(i+1)..<tokens.count]), node)
				case let .textBlock(value):
					node = appendTo(list: node, node: .Atom(value))
				}
				
				i += 1
			}while(tokens.count > 0)
			
			return ([],node)
		}
		

		func appendTo(list: SExpr?, node: SExpr) -> SExpr {
			var list = list
			if list != nil, case var .List(elements) = list! {
				elements.append(node)
				list = .List(elements)
			} else {
				list = node
			}
			return list!
		}
		
		// Read: Tokenize -> Parse -> Result
		let tokens = tokenize(sexpr)
		let result = parse(tokens)
		return result.subexpr ?? .List([])
	}
}


extension SExpr: ExpressibleByStringLiteral, ExpressibleByUnicodeScalarLiteral, ExpressibleByExtendedGraphemeClusterLiteral {
	public init(stringLiteral value: String){
		self = SExpr.read(value)
	}
	
	public init(extendedGraphemeClusterLiteral value: String){
		self.init(stringLiteral: value)
	}
	
	public init(unicodeScalarLiteral value: String){
		self.init(stringLiteral: value)
	}
}
