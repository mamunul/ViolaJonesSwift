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
	
	var pImageCount = 0
	
	let stageNumber = 10
	
	func executeLearning(var pImagePath:[String]) -> TrainigData{
		
		//		pImagePath = ["/Users/mamunul/Documents/MATLAB/my_experiment/faces","/Users/mamunul/Documents/MATLAB/my_experiment/nonfaces"]
		
		pImagePath = ["/Users/mamunul/Documents/MATLAB/my_experiment/faces","/Users/mamunul/Downloads/Face Database/nonfacecollection"]
		
		pImageCount = 5000
		
		var starttime = NSDate()
		
		var imageArray = extractImage(pImagePath, imageLimitArray: [pImageCount,5000])
		
		var featureArray = generateHaarFeature(-1)
		
		featureArray = processFeatureValue(featureArray, imageArray: imageArray)
		
		//		clearImageData(&imageArray)
		
		var cascadeArray:[Cascade] = []
		
		var trainingData = TrainigData()
		
		let fRatePerCascade = 0.30
		let dRatePerCascade = 0.99
		let overallF = 0.0000006
		
		var f = [Double](count:15, repeatedValue:1.0)
		var d = [Double](count:15, repeatedValue:1.0)
		
		
		
		var i = 0;
		var n = 0
		while f[i] > overallF || i < stageNumber+1{
			
			i = i+1
			
			f[i] = f[i-1]
			var cascade:Cascade?
			
			while f[i] > (fRatePerCascade  * f[i-1]) {
				
				n++;
				
				cascade = adaptiveBoosting(featureArray,imageArray: imageArray,T: n)
				
				
				decreaseThreshold(&cascade!,imageArray: imageArray, requiredD: (dRatePerCascade * d[i-1]))
				
				let fd = evaluateCascade(cascade!, imageArray: imageArray, isOnlyPositive: false)
				
				f[i] = fd.Fi
				
				break
				
			}
			
			cascadeArray.append(cascade!)
			
			if i == 3
			{
				
				break
				
			}
			
		}
		
		
		var endtime = NSDate()
		trainingData.cascadeArray = cascadeArray
		trainingData.cascadeCount = cascadeArray.count
		trainingData.startTime = String(starttime)
		trainingData.endTime = String(endtime)
		trainingData.codeLink = "https://github.com/mamunul/ViolaJonesSwift.git"
		trainingData.pFaceCount = pImageCount
		
		return trainingData
	}
	
	func resizeImage(){
		
		
		
		
	}
	
	func clearImageData(inout imageArray:[IntegralImage]){
		
		
		
		for image in imageArray {
			
			image.pixelData = []
			
			
		}
		
	}
	
	func processFeatureValue(featureArray:[HaarFeature], imageArray:[Int:IntegralImage]) -> [HaarFeature]{
		
		
		var updatedFeatureArray = [HaarFeature]()
		
		for var feature in featureArray {
			
			
			for (imageIndex,image) in imageArray {
				
				
				let fv = calculateFeatureValue(feature, integralImage: image)
				
				let imf = ImageFeature(featureValue: fv, imageType: image.imageType, imageIndex: imageIndex)
				
				feature.imageFeature?.updateValue(imf, forKey: imageIndex)
				
				//				print("fv\(fv)")
				
			}
			
			updatedFeatureArray.append(feature)
			
		}
		
		return updatedFeatureArray
	}
	
	
	func calculateFeatureValue(feature:HaarFeature, integralImage:IntegralImage) ->Double{
		
		
		
		guard  (feature.imageFeature?.count < 1 || feature.imageFeature![integralImage.index!] == nil) else {
			//
			return (feature.imageFeature![integralImage.index!]?.featureValue)!
		}
		
		
		var featureValue = 0.0
		
		var AN1 = 0.0, AN2 = 0.0, AN = 0.0
		
		var pixelSum:[Double] = []
		//
		var p = 0
		let dx = feature.w! / feature.fw!
		
		let dy = feature.h! / feature.fh!
		for var nx = feature.x; nx <= (feature.x! + feature.w! - dx); nx! += dx {
			
			for var ny = feature.y!; ny <= (feature.y! + feature.h! - dy); ny += dy {
				var A = 0.0, B = 0.0, C = 0.0, D = 0.0
				
				
				A = Double(integralImage.pixelData[nx! - 1 + dx][ny - 1 + dy].p)
				if ny > 0 {
					C = Double(integralImage.pixelData[nx! - 1 + dx][ny - 1].p)
				}
				if nx > 0{
					B = Double(integralImage.pixelData[nx! - 1][ny - 1 + dy].p)
				}
				if nx > 0 && ny > 0{
					D = Double(integralImage.pixelData[nx! - 1][ny - 1].p)
				}
				pixelSum.append( A - B - C + D)
				
				
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
	
	
	private func adaptiveBoosting(featureArray:[HaarFeature], var imageArray:[Int:IntegralImage], T:Int) -> Cascade{
		
		//		var cascadeArray:[Cascade] = []
		var cascade = Cascade()
		var classifierArray:[HaarFeature] = []
		
		initializeWeight(&imageArray)
		cascade.cascadeThreshold = 0.0
		print("adaboost started")
		for _ in 0...T {
			
			normalizeWeight(&imageArray)
			
			let Tpm = calculateTotalPositiveAndNegativeWeight(imageArray)
			
			
			//			print("TPM2:\(Tpm)")
			
			var strongClassifier:HaarFeature = HaarFeature(x: 0, y: 0, w: 0, h: 0, fw: 0, fh: 0)
			strongClassifier.error = 100.0
			
			for var feature in featureArray {
				
				featureValueWithLowestError(&feature,strongClassifier:&strongClassifier,imageArray: imageArray, T: Tpm)
				
			}
			
			//			print("finished")
			//			strongClassifier?.imageFeature = []
			updateWeight(imageArray, strongClassifier: strongClassifier)
			classifierArray.append(strongClassifier)
			
			cascade.cascadeThreshold! += (strongClassifier.alpha)!
			
			
			
		}
		print("adaboost ended")
		
		//		for var classifier in classifierArray {
		//
		//
		//			classifier.imageFeature = []
		//
		//		}
		
		
		cascade.featureArray = classifierArray
		cascade.featureCount = classifierArray.count
		cascade.nonFaceImageCount = pImageCount - imageArray.count
		
		
		return cascade
		
	}
	
	func updateWeight(imageArray:[Int:IntegralImage],strongClassifier:HaarFeature){
		
		
		
		
		
		for (index,image) in imageArray {
			
			
			let fv = calculateFeatureValue(strongClassifier, integralImage: image)
			
			var isFace = false
			
			if Double(strongClassifier.polarity!) * fv < Double(strongClassifier.polarity!) * strongClassifier.thresholdValue!{
				
				
				
				isFace = true
			}
			
			
			if (isFace && image.imageType == ImageType.Face) || (!isFace && image.imageType == ImageType.NonFace){
				
				
				image.weight! *= strongClassifier.beta!
				
			}
			
			
		}
		
	}
	
	
	func featureValueWithLowestError(inout feature:HaarFeature, inout strongClassifier:HaarFeature, imageArray:[Int:IntegralImage], T:(Tplus:Double,Tmin:Double)){
		
		
		var imf = feature.imageFeature!
		
		//		let imageFeatureArray = (imf).sort({$0.featureValue < $1.featureValue})
		
		var Splus = 0.0
		var Smin = 0.0
		
		var lowestError = 1.0;
		
		lowestError = (strongClassifier.error)!
		
		let imageFeatureArray = imf.sort { ( f:(Int, ImageFeature), l:(Int, ImageFeature)) -> Bool in
			
			f.1.featureValue < l.1.featureValue
		}
		
		
		for (index,imageFeature) in imageFeatureArray{
			
			
			//			let imageFeature = imageFeatureArray[index]
			let image = imageArray[index]
			
			if imageFeature.imageType == ImageType.Face {
				
				Splus += image!.weight!
				
			}else {
				
				Smin += image!.weight!
				
			}
			
			let v1 = Splus + T.Tmin - Smin
			let v2 = Smin + T.Tplus - Splus
			
			
			let error = min(v1, v2)
			
			if error < 0 {
				
				print("error")
				
			}
			feature.error = error
			
			if error < lowestError {
				
				
				//				print("error:\(error) feature index:\(feature.x),\( feature.y ),\(feature.w),\( feature.h)")
				
				lowestError = error
				feature.thresholdValue = imageFeature.featureValue
				
				var beta = calculateBeta(error)
				feature.alpha = calculateAlpha(beta)
				feature.beta = beta
				if error == v1 {
					
					feature.polarity = -1
					
				}else {
					
					feature.polarity = 1
					
				}
				
				//				strongClassifier = HaarFeature()
				strongClassifier = feature
				
				
				if isnan(strongClassifier.alpha!){
					print("print")
					
				}
				//				strongClassifier.alpha = feature.alpha
			}
			
		}
		
		
		
	}
	
	func calculateBeta(error:Double) -> Double{
		
		
		let beta = error/(1-error)
		
		return beta
		
	}
	
	
	func calculateAlpha(beta:Double) -> Double{
		
		
		let alpha = log10(1/beta)
		
		return alpha
	}
	
	private func calculateTotalPositiveAndNegativeWeight(imageArray:[Int:IntegralImage]) -> (Tplus:Double,Tmin:Double){
		
		var Tplus = 0.0, Tmin = 0.0
		
		
		for (_,image) in imageArray {
			
			
			if image.imageType == ImageType.Face {
				
				Tplus += image.weight!
				
			} else {
				
				
				Tmin += image.weight!
				
			}
			
		}
		
		
		return(Tplus,Tmin)
		
	}
	
	private func initializeWeight(inout imageArray:[Int:IntegralImage]){
		
		let nImageCount = imageArray.count - pImageCount
		
		for (_,image) in imageArray{
			
			
			if image.imageType == ImageType.Face {
				
				image.weight = 1 / Double(2*pImageCount)
				
			} else {
				
				image.weight = 1 / Double(2*nImageCount)
			}
			
			
		}
		
		
	}
	
	
	private func normalizeWeight(inout imageArray:[Int:IntegralImage]){
		
		
		var sum = 0.0
		
		for (_,image) in imageArray{
			
			sum += image.weight!
			
		}
		
		for (_,image) in imageArray{
			
			image.weight  = image.weight! / sum
			
		}
		
	}
	
	private func generateHaarFeature(limit:Int) ->[HaarFeature]{
		
		let window = 24
		
		
		let featureTypeArray:[Point] = [Point(x: 2, y: 1),Point(x: 1, y: 2),Point(x: 3, y: 1),Point(x: 1, y: 3),Point(x: 2, y: 2)]
		
		var featureArray:[HaarFeature] = []
		
		var i = 0
		
		for point in featureTypeArray {
			
			for var width = point.x; width <= window; width += point.x{
				for var height = point.y; height <= window; height += point.y{
					
					for var pos_x = 0; pos_x <= window - width; ++pos_x{
						for var pos_y = 0;pos_y <= window - height; ++pos_y{
							
							
							let hf = HaarFeature(x:pos_x, y:pos_y, w:width, h:height, fw:point.x, fh:point.y)
							
							featureArray.append(hf)
							
							i++
						}
					}
					if i > limit && limit > 1 {
						
						break
					}
				}
				if i > limit && limit > 1  {
					
					break
				}
			}
			
			if i > limit && limit > 1  {
				
				break
			}
			
		}
		
		return featureArray;
		
	}
	
	private  func extractImage(imagePathArray:[String], imageLimitArray:[Int]) -> [Int:IntegralImage]{
		
		
		//		print("path:\(imagePathArray[0])")
		
		let fileManager = NSFileManager.defaultManager()
		
		
		var imageArray = [Int:IntegralImage]()
		
		var imageIndex = 0;
		for index in 0...1 {
			
			
			let enumerator:NSDirectoryEnumerator = fileManager.enumeratorAtPath(imagePathArray[index])!
			
			
			var count = 0;
			while let element = enumerator.nextObject() as? String{
				
				
				let path = imagePathArray[index]+"/"+element
				
				var image = readImageFromPath(path)
				
				
				
				if image != nil {
					
					
					if (image?.size.width > 400 || image?.size.height > 400 ) && index == 1{
						
						
						var nsize = image?.size
						
						nsize?.width /= 2
						nsize?.height /= 2
						
						if nsize?.height > 5000{
						
						
							continue
						
						}
						
						image = resizeImage(image!, size: nsize!)
						
						scrollImage(image!)
						
					}
					
					var size = NSZeroSize;
					
					size.width = 24;
					size.height = 24;
					
					let img = resizeImage(image!, size: size)
					
					let integralImage = IntegralImage(image: img)
					
					if index == ImageType.Face.rawValue {
						
						integralImage.imageType = ImageType.Face
						
					}
					integralImage.index = imageIndex
					imageArray.updateValue(integralImage, forKey: imageIndex)
					
					imageIndex++
					count++;
					if count == imageLimitArray[index]{
						
						break
						
					}
					
				}
				
			}
		}
		
		return imageArray
		
	}
	
	private func evaluateCascade(cascade:Cascade,imageArray:[Int:IntegralImage], isOnlyPositive:Bool) -> (Fi:Double, Di:Double){
		
		var d = 0.0
		var f = 0.0
		
		let nImageCount = imageArray.count - pImageCount
		
		
		if !isOnlyPositive {
			
			for (_,image) in imageArray {
				
				
				if image.imageType == ImageType.Face {
					
					d += detectFace(cascade, image:image) ? 1 : 0
					
				} else {
					
					f += detectFace(cascade, image:image) ? 1 : 0 // have confusion 1:0 or 0:1
					
				}
				
				
			}
			
			d /= Double(pImageCount)
			
			f /= Double(nImageCount)
			
		}else{
			var i = 0
			
			for (_,image) in imageArray {
				
				
				if image.imageType == ImageType.Face {
					i++
					d += detectFace(cascade, image:image) ? 1 : 0
					
				}
				
				
			}
			
			d /= Double(pImageCount)
			
			
		}
		
		return (f,d)
		
	}
	
	private func decreaseThreshold(inout cascade:Cascade,imageArray:[Int:IntegralImage],requiredD:Double) {
		
		var minThreshold = 0.0, maxThreshold = cascade.cascadeThreshold!/2
		
		
		while Int(maxThreshold * 1000) != Int(minThreshold * 1000) {
			
			var newThreshold = (minThreshold + maxThreshold)/2
			cascade.cascadeThreshold = newThreshold
			
			let fd = evaluateCascade(cascade,imageArray: imageArray, isOnlyPositive: true)
			
			
			if fd.Di < requiredD {
				
				maxThreshold = newThreshold
				
			}else {
				
				minThreshold = newThreshold
				
			}
		}
		
	}
	
	private func detectFace(cascade:Cascade, image:IntegralImage) -> Bool{
		
		
		var res = 0.0
		
		for classifier in cascade.featureArray! {
			
			//			classifier.imageFeature.
			
			let fv = calculateFeatureValue(classifier, integralImage: image)
			
			if Double(classifier.polarity!) * fv < Double(classifier.polarity!) * classifier.thresholdValue! {
				
				res += classifier.alpha!
			}
			
		}
		
		
		if res < cascade.cascadeThreshold{
			
			return false
			
		}else {
			
			return true
			
		}
		
	}
	
	private func readImageFromPath(path:String) ->NSImage?{
		
		var image:NSImage?
		var resizedImage:NSImage?
		
		if path.hasSuffix("pgm") || path.hasSuffix("jpg") {
			
			let imageURL = NSURL(fileURLWithPath: path, isDirectory: false)
			
			
			image = NSImage(byReferencingURL: imageURL)
			
			
			//			print("size:\(image?.size)")
			
			
			
			
			
		}
		
		
		return image;
		
	}
	
	func resizeImage(sourceImage:NSImage, size:NSSize ) -> NSImage
	{
		
		var targetFrame = NSMakeRect(0, 0, size.width, size.height)
		var targetImage:NSImage?
		var sourceImageRep = sourceImage.bestRepresentationForRect(targetFrame, context: nil, hints: nil)
		
		
		
		
		
		
		targetImage = NSImage(size:size)
		
		targetImage!.lockFocus()
		
		sourceImageRep?.drawInRect(targetFrame)
		//	[sourceImageRep drawInRect: targetFrame];
		targetImage?.unlockFocus()
		
		return targetImage!;
	}
	
	
	
	func scrollImage(image:NSImage){
		
		var size = NSZeroSize;
		
		size.width = 80;
		size.height = 80;
		
		for var i = 0; i < Int(image.size.height - size.height) ; i += Int(size.height/3) {
			
			for var j = 0; j < Int(image.size.width - size.width) ; j += Int(size.width/3)  {
				
				
				
//				let rect = NSMakeRect(CGFloat(i), CGFloat(j), size.width, size.height)
				
				
				let rect = NSMakeRect(CGFloat(j), CGFloat(i), size.height, size.width)
				
				
				let img = cropToBounds(image, cropRect: rect, size: size)
				
				
				print(rect)
			}
			
			
		}
		
		
		
	}
	
	
	func UUIDString() ->String {
	var theUUID = CFUUIDCreate(nil)
	var string = CFUUIDCreateString(nil, theUUID)

	return string as String;
	}
	
	func cropToBounds(sourceImage: NSImage, cropRect:NSRect,size:NSSize) -> NSImage {
		//
		var context = NSGraphicsContext.currentContext()
		var imageRect = NSMakeRect(0, 0, size.width, size.height)
		var targetImage:NSImage? = NSImage(size: size)
		
		
		context?.imageInterpolation = NSImageInterpolation.High
		targetImage!.lockFocus()
		sourceImage.drawInRect(imageRect, fromRect: cropRect, operation: NSCompositingOperation.CompositeCopy, fraction: 1.0)
		
		
		
		
		targetImage?.unlockFocus()
		
		
		var bmpImageRep = NSBitmapImageRep(data: (targetImage?.TIFFRepresentation)!)
		
		var data = bmpImageRep?.representationUsingType(NSBitmapImageFileType.NSPNGFileType,properties: [:])
		
		
		data?.writeToFile("/Users/mamunul/Documents/generatednonface/"+UUIDString()+".png", atomically: true)
		
		
		return targetImage!;
	}
	
}