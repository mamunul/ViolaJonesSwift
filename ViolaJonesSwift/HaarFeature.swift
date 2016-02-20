//
//  HaarFeature.swift
//  ViolaJonesSwift
//
//  Created by Mamunul on 2/10/16.
//  Copyright © 2016 Mamunul. All rights reserved.
//

import Foundation


struct ImageFeature {
	var featureValue:Double
	var imageType:ImageType
	var imageIndex:Int
//	var imageWeight:Double?
	
	init(featureValue:Double, imageType:ImageType, imageIndex:Int){
		
		self.featureValue = featureValue
		self.imageType = imageType
		self.imageIndex = imageIndex
		
	}
}

struct HaarFeature {
	
	var x:Int?
	var y:Int?
	var w:Int?
	var h:Int?
	var fw:Int?
	var fh:Int?
	var imageFeature:[Int:ImageFeature]?
	var thresholdValue:Double?
	var polarity:Int?
	var error:Double?
	var alpha:Double?
	var beta:Double?
	
	init(){
	
		
		imageFeature = [Int:ImageFeature]()
	
	}
	
	mutating func appendImageFeature(key:Int, value:ImageFeature){
	
		
	
		imageFeature?.updateValue(value, forKey: key)
	
	}
	
	init(x:Int, y:Int, w:Int, h:Int, fw:Int, fh:Int){
		
		self.x = x
		self.y = y
		self.w = w
		self.h = h
		self.fh = fh
		self.fw = fw
		
		imageFeature = [Int:ImageFeature]()
		
	}
	
	mutating func setImageFeature(imageFeature:[Int:ImageFeature]){
	
	self.imageFeature = imageFeature
	
	}
	
}
