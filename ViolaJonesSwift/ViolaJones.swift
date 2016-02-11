//
//  ViolaJones.swift
//  ViolaJonesSwift
//
//  Created by Mamunul on 2/10/16.
//  Copyright © 2016 Mamunul. All rights reserved.
//

import Foundation
import Cocoa

struct Point {
	var x = 0
	var y = 0
}

enum ImageType:Int{
	
	case Face = 0, NonFace
}


class ViolaJones {
	
	
	
	func executeLearning(var pImagePath:[String]){
		
		pImagePath = ["/Users/mamunul/Documents/MATLAB/my_experiment/faces","/Users/mamunul/Documents/MATLAB/my_experiment/nonfaces"]
		
		
		
		let imageArray = extractImage(pImagePath, imageLimitArray: [10,10])
		
		var featureArray = generateHaarFeature()
		
		processFeatureValue(&featureArray, imageArray: imageArray)
		
		
		
		let fRatePerCascade = 0.30
		let dRatePerCascade = 0.90
		let overallF = 0.0000006
		
		var f:[Double] = []
		var d:[Double] = []
		
		
		var i = 0;
		while f[i] > fRatePerCascade {
			
			i = i+1
			var n = 1
			f[i] = f[i-1]
			
			
			while f[i] > fRatePerCascade {
				
				n++;
				
				adaptiveBoosing(featureArray,imageArray: imageArray,T: n)
				
				
				
			}
			
		}
		
		
		
		
	}
	
	func processFeatureValue(inout featureArray:[HaarFeature], imageArray:[IntegralImage]){
		
		
		for var feature in featureArray {
			
			var i = 0
			var featureValue:[ImageFeature] = []
			for image in imageArray {
				
				
				let fv = calculateFeatureValue(feature, integralImage: image)
				
				
				let imf = ImageFeature(featureValue: fv, imageType: image.imageType, imageIndex: i)
				i++
				featureValue.append(imf)
				
			}
			
			feature.featureValue = featureValue
			
		}
		
		
	}
	
	
	func calculateFeatureValue(feature:HaarFeature, integralImage:IntegralImage) ->Double{
		
		
		var featureValue = 0.0
		
		var AN1 = 0.0, AN2 = 0.0, AN = 0.0
		
		var pixelSum:[Double] = []
		//
		var p = 0
		let dx = feature.w / feature.fw
		
		let dy = feature.h / feature.fh
		for var nx = feature.x; nx <= (feature.x + feature.w - dx); nx += dx {
			
			for var ny = feature.y; ny <= (feature.y + feature.h - dy); ny += dy {
				var A = 0.0, B = 0.0, C = 0.0, D = 0.0
				
				
				
				A = Double(integralImage.image[nx - 1 + dx][ny - 1 + dy].p)
				if ny > 0 {
					C = Double(integralImage.image[nx - 1 + dx][ny - 1].p)
				}
				if nx > 0{
					B = Double(integralImage.image[nx - 1][ny - 1 + dy].p)
				}
				if nx > 0 && ny > 0{
					D = Double(integralImage.image[nx - 1][ny - 1].p)
				}
				pixelSum[p] = A - B - C + D
				
				p += 1
				
			}
		}
		
		if (p == 2) {
			
			AN1 = pixelSum[0]
			AN2 = pixelSum[1]
			featureValue = AN1 - AN2
			
			
		} else if (p == 3) {
			
			AN = pixelSum[2] + pixelSum[0]
			AN1 = AN / 2
			
			AN2 = pixelSum[1]
			
			featureValue = AN - AN2
			
			
		} else if (p == 4) {
			
			AN1 = pixelSum[0] + pixelSum[3]
			AN2 = pixelSum[1] + pixelSum[2]
			
			featureValue = AN1 - AN2
			
		}
		
		return featureValue;
		
	}
	
	
	private func adaptiveBoosing(featureArray:[HaarFeature], var imageArray:[IntegralImage], T:Int){
		
		var cascadeArray:[Cascade] = []
		
		initializeWeight(&imageArray)
		
		for index in 0...T {
			
			normalizeWeight(&imageArray)
			
			var T = calculateTotalPositiveAndNegativeWeight(imageArray)
			
			
			
			for feature in featureArray {
				
				
				featureValueWithLowestError(feature)
				
				
			}
			
		}
		
		
	}
	
	func featureValueWithLowestError(var feature:HaarFeature){
	
	
		(feature.imageFeature)?.sortInPlace({$0.featureValue > $1.featureValue})
		
		
		for featureValue in feature.imageFeature! {
		
		
			
		
		}
	
	
	}

	
	private func calculateTotalPositiveAndNegativeWeight(imageArray:[IntegralImage]) -> (Tplus:Double,Tmin:Double){
	
		
	
	
		
		return(3.0,9.0)
	
	}
	
	private func initializeWeight(inout imageArray:[IntegralImage]){
		
		
		
	}
	
	
	private func normalizeWeight(inout imageArray:[IntegralImage]){
		
		
	}
	
	private func generateHaarFeature() ->[HaarFeature]{
		
		let window = 24
		
		
		let featureTypeArray:[Point] = [Point(x: 2, y: 1),Point(x: 1, y: 2),Point(x: 3, y: 1),Point(x: 1, y: 3),Point(x: 2, y: 2)]
		
		var featureArray:[HaarFeature] = []
		
		for point in featureTypeArray {
			
			for var width = point.x; width < (window + 1); ++width{
				for var height = point.y; height < (window + 1); ++height{
					
					for var pos_x = 1; pos_x<(window+1) - width; ++pos_x{
						for var pos_y = 1;pos_y<(window+1) - height; ++pos_y{
							
							
							let hf = HaarFeature(x:pos_x, y:pos_y, w:width, h:height, fw:point.x, fh:point.y)
							
							featureArray.append(hf)
							
							
						}
					}
				}
			}
			
		}
		
		return featureArray;
		
	}
	
	private  func extractImage(imagePathArray:[String], imageLimitArray:[Int]) -> [IntegralImage]{
		
		
		//		print("path:\(imagePathArray[0])")
		
		let fileManager = NSFileManager.defaultManager()
		
		
		var imageArray:[IntegralImage] = []
		
		
		for index in 0...1 {
			
			
			let enumerator:NSDirectoryEnumerator = fileManager.enumeratorAtPath(imagePathArray[index])!
			
			
			var count = 0;
			while let element = enumerator.nextObject() as? String{
				
				
				let path = imagePathArray[index]+"/"+element
				
				let img = readImageFromPath(path)
				
				if img != nil {
					
					let integralImage = IntegralImage(image: img!)
					
					if index == ImageType.Face.rawValue {
						
						integralImage.imageType = ImageType.Face
						
					}
					
					imageArray.append(integralImage)
					
					count++;
					if count == imageLimitArray[index]{
						
						break
						
					}
					
				}
				
			}
		}
		
		return imageArray
		
	}
	
	private func evaluateCascade(){
		
		
		
	}
	
	private func decreaseThreshold(){
		
		
		
	}
	
	private func detectFace(){
		
		
		
		
	}
	
	private func readImageFromPath(path:String) ->NSImage?{
		
		var image:NSImage?
		
		if path.hasSuffix("pgm"){
			
			let imageURL = NSURL(fileURLWithPath: path, isDirectory: false)
			
			
			image = NSImage(byReferencingURL: imageURL)
			
			//			print("image:\(image!.size)")
			//			count++
			
		}
		
		
		return image;
		
	}
	
	
}