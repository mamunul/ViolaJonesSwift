//
//  main.swift
//  ViolaJonesSwift
//
//  Created by Mamunul on 2/10/16.
//  Copyright © 2016 Mamunul. All rights reserved.
//

import Foundation

print("Hello, World!")

var p = ["Test Message",""]


let vj = ViolaJones()

var td = vj.executeLearning(p)


var xml = JSonWriter.writeJson(td)
//
JSonWriter.saveToDisk(xml)



