//
//  main.swift
//  SwiftLISP
//
//  Created by Justin Purnell on 5/26/17.
//  Copyright © 2017 Justin Purnell. All rights reserved.
//

import Foundation

var exit = false

while(!exit) {
	print(">>>", terminator: " ")
	let input = readLine(strippingNewline: true)
	exit = (input=="exit") ? true : false
	
	if !exit {
		let e  = SExpr.read(input!)
		print(e.eval()!)
	}
}
