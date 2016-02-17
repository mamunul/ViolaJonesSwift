//
//  JsonWriter.swift
//  ViolaJonesSwift
//
//  Created by Mamunul on 2/15/16.
//  Copyright © 2016 Mamunul. All rights reserved.
//

import Foundation


class JSonWriter {
	
	
	static func writeJson(trainingData:TrainigData?) -> String{
		
		//		var test = "test:String"
		
		
		let root = NSXMLElement(name: "training-data")
		let xml = NSXMLDocument(rootElement: root)
		
		
		
		addSingleNodeWith(root,value: ((trainingData?.pFaceCount)! as NSNumber).stringValue , key: "positive-training-face")
		addSingleNodeWith(root,value: ((trainingData?.cascadeCount!)! as NSNumber).stringValue , key: "cascade-count")
		addSingleNodeWith(root,value: ((trainingData?.codeLink!)! as String) , key: "code-link")
		addSingleNodeWith(root,value: ((trainingData?.startTime!)! as String) , key: "start-time")
		addSingleNodeWith(root,value: ((trainingData?.endTime!)! as String) , key: "end-time")
		
		
		
		//		addSingleNodeWith(root,value: String(trainingData?.cascadeArray) , key: "positive-training-face" )
		
		
		
		addCascade(root, cascadeArray: (trainingData?.cascadeArray)!)
		
//		print(trainingData)
		
		print(xml.XMLString)
		
		
		return "<?xml version=\"1.0\" encoding=\"utf-8\"?>"+xml.XMLString
		
		
		
	}
	
	static func saveToDisk(str:String){
		
		let endtime = NSDate()
	
		let file = String(endtime) + "face-detection.xml" //this is the file. we will write to and read from it
		

		
//		if let dir : NSString = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true).first {
			if let dir : NSString = "/Users/mamunul/Documents/" {
			let path = dir.stringByAppendingPathComponent(file);
			
			//writing
			do {
				try str.writeToFile(path, atomically: true, encoding: NSUTF8StringEncoding)
				
				
			}
			catch {/* error handling here */}
		
		}
	
	}
	
	
	static func addCascade(parent:NSXMLElement,cascadeArray:[Cascade]){
		
		for cascade in cascadeArray {
			
			let cascadeNode = NSXMLElement(name: "cascade")
			
			addSingleNodeWith(cascadeNode,value: String(cascade.cascadeThreshold!) , key: "cascade-threshold")
			addSingleNodeWith(cascadeNode,value: String(cascade.featureCount!) , key: "classifier-count")
			addSingleNodeWith(cascadeNode,value: String(cascade.nonFaceImageCount!) , key: "negative-training-face")
			
			
			//			addSingleNodeWith(cascadeNode,value: String(cascade.featureArray) , key: "end-time")
			
			addClassifier(cascadeNode, classifierArray: cascade.featureArray!)
			addCompoundNodeWith(parent, value: cascadeNode, key: "cascade")
			
		}
		
	}
	static func addClassifier(parent:NSXMLElement, classifierArray:[HaarFeature]){
		
		
		
		for classifier in classifierArray{
			
			let classifierNode = NSXMLElement(name: "classifier")
			
			addSingleNodeWith(classifierNode,value: (classifier.x! as NSNumber).stringValue , key: "x")
			addSingleNodeWith(classifierNode,value: (classifier.y! as NSNumber).stringValue , key: "y")
			addSingleNodeWith(classifierNode,value: (classifier.w! as NSNumber).stringValue , key: "w")
			addSingleNodeWith(classifierNode,value: (classifier.h! as NSNumber).stringValue , key: "h")
			addSingleNodeWith(classifierNode,value: (classifier.fw! as NSNumber).stringValue, key: "fw")
			addSingleNodeWith(classifierNode,value: (classifier.fh! as NSNumber).stringValue , key: "fh")
			addSingleNodeWith(classifierNode,value: (classifier.polarity! as NSNumber).stringValue , key: "polarity")
			addSingleNodeWith(classifierNode,value: (classifier.alpha! as NSNumber).stringValue , key: "alpha")
			addSingleNodeWith(classifierNode,value: (classifier.error! as NSNumber).stringValue , key: "error")
			addSingleNodeWith(classifierNode,value: (classifier.beta! as NSNumber).stringValue , key: "beta")
			
			
		    addCompoundNodeWith(parent, value: classifierNode, key: "classifier")
		
			
		}
		
	}
	static func addCompoundNodeWith(parent:NSXMLElement, value:NSXMLElement, key:String) {
		
		
		parent.addChild(value)
		
	}
	
	static func addSingleNodeWith(parent:NSXMLElement, value:String, key:String) {
		
		
		parent.addChild(NSXMLElement(name: key, stringValue:value))
		
	}
	
	
	
	
}