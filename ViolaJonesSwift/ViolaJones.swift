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
	
	case Face = 0, NonFace, All
}


class ViolaJones {
	
	var pImageCount = 0
	
	var nImageCount = 0
	
	let stageNumber = 20
	var featureArray:[HaarFeature] = []
	
	//	var nonFaceBackgroundImageArray = [String]()
	
	func executeLearning(var pImagePath:[String]) -> TrainigData{
		
		//		pImagePath = ["/Users/mamunul/Documents/MATLAB/my_experiment/faces","/Users/mamunul/Documents/MATLAB/my_experiment/nonfaces"]
		
		pImagePath = ["/Users/mamunul/Documents/MATLAB/my_experiment/faces","/Users/mamunul/Downloads/Face Database/nonfacecollection"]
		
		pImageCount = 1000
		nImageCount = 1000
		
		
		let starttime = NSDate()
		
		let backgroundImageArray  = traverseNonFaceImage(pImagePath[1], limit: 180)
		
		var imageArray = extractPNormalizedImage(pImagePath[0], imageLimit: pImageCount)
		
//		for (index,intImage) in imageArray {
//		
//			
//			var byteData = NSData(bytes: intImage.pixelData, length: 576)
//			let imageRep = NSBitmapImageRep(data: byteData)
//			
//	
//			var imageSize = NSMakeSize(24, 24);
//			
//			var image = NSImage(size: imageSize)
//			image.addRepresentation(imageRep!)
//			
//	
//		}
		
		featureArray = generateHaarFeature(-1)
		
		featureArray = processFeatureValue(featureArray, imageArray: imageArray,imageType: ImageType.Face)
		
		clearImageData(&imageArray)
		
		var cascadeArray:[Cascade] = []
		
		var trainingData = TrainigData()
		
		let fRatePerCascade = 0.30
		let dRatePerCascade = 0.99
		let overallF = 0.0000006
		
		var f = [Double](count:25, repeatedValue:1.0)
		var d = [Double](count:25, repeatedValue:1.0)
		
		var i = 0;
		var n = 0
		while f[i] > overallF || i < stageNumber+1{
			
			
			i = i+1
			print("Timestamp: \(Timestamp)")
			print("cascade started:\(i)")
			
			extractNNormalizedImageIn(&imageArray, bgImagePathArray: backgroundImageArray, imageLimit: nImageCount,stageNo: i)
			
			if i == stageNumber ||  (imageArray.count - pImageCount) < nImageCount
			{
				
				break
				
			}
			
			featureArray = processFeatureValue(featureArray, imageArray: imageArray,imageType: ImageType.NonFace)
			
			clearImageData(&imageArray)
			
			f[i] = f[i-1]
			var cascade:Cascade?
			
			while f[i] > (fRatePerCascade  * f[i-1]) || cascade == nil {
				
				n++;
				
				cascade = adaptiveBoosting(featureArray,imageArray: imageArray,T: n)
				
				if cascade?.cascadeThreshold > Double(INT8_MAX) {
					
					break
					
				}
				
				
				decreaseThreshold(&cascade!,imageArray: imageArray, requiredD: (dRatePerCascade * d[i-1]))
				
				let fd = evaluateCascade(cascade!, imageArray: &imageArray, imageType: ImageType.All, toDelete: false)
				
				f[i] = fd.Fi
				
				if n == 3{
					break
				}
				
				//	break
				
			}
			
			
			
			evaluateCascade(cascade!, imageArray: &imageArray, imageType: ImageType.NonFace, toDelete: true)
			
			var nfeatureArra = [HaarFeature]()
			for var feature in (cascade?.featureArray)! {
			
			
				feature.imageFeature?.removeAll()
				
				nfeatureArra.append(feature)
			
			}
			
			cascade?.featureArray = nfeatureArra
			
			cascadeArray.append(cascade!)
			print("Timestamp: \(Timestamp)")
			print("cascade ended:\(i) size:\(cascade?.featureCount)")
			
			let endtime = NSDate()
			trainingData.cascadeArray = cascadeArray
			trainingData.cascadeCount = cascadeArray.count
			trainingData.startTime = String(starttime)
			trainingData.endTime = String(endtime)
			trainingData.codeLink = "https://github.com/mamunul/ViolaJonesSwift.git"
			trainingData.pFaceCount = pImageCount
			
			var xml = JSonWriter.writeJson(trainingData)
			
			JSonWriter.saveToDisk(xml)
			
		}
		
		
		
		
		return trainingData
	}
	
	
	
	
	func clearImageData(inout imageArray:[Int:IntegralImage]){
		
		
		
		for (index,image) in imageArray {
			
			image.pixelData.removeAll()
			
			
		}
		
	}
	
	var Timestamp: String {
		return "\(NSDate())"
	}
	
	func processFeatureValue( featureArray:[HaarFeature], imageArray:[Int:IntegralImage], imageType:ImageType) -> [HaarFeature]{
		
		
		var updatedFeatureArray = [HaarFeature]()
		
		for  var feature in featureArray {
			
			//			if imageType == ImageType.NonFace {
			
			//				for (key,imageFeature) in feature.imageFeature! {
			
			
			//					if imageFeature.imageType == ImageType.NonFace {
			
			//						let index = feature.imageFeature?.indexForKey(key)
			
			//						guard index == nil else {
			
			//							feature.imageFeature?.removeAtIndex(index!)
			//
			//							continue
			//						}
			
			//					}
			
			
			//				}
			
			//			}
			
			
			for (imageIndex,image) in imageArray {
				
				
				//				if imageType == ImageType.NonFace && image.imageType == ImageType.Face{
				//
				//
				//					continue
				//
				//				}
				
				
				
				
				let fv = calculateFeatureValue(feature, integralImage: image)
				
				let imf = ImageFeature(featureValue: fv, imageType: image.imageType, imageIndex: imageIndex)
				
				//				feature.appendImageFeature(imageIndex, value: imf)
				
				feature.imageFeature?.updateValue(imf, forKey: imageIndex)
				
				//print("fv\(fv)")
				
			}
			
			//			feature.imageFeature
			
			updatedFeatureArray.append(feature)
			
		}
		
		return updatedFeatureArray
	}
	
	
	func calculateFeatureValue(feature:HaarFeature, integralImage:IntegralImage) ->Double{
		
		
		
		guard  (feature.imageFeature?.count < 1 || feature.imageFeature![integralImage.index!] == nil) else {
			//
			return (feature.imageFeature![integralImage.index!]?.featureValue)!
		}
		
		if integralImage.pixelData.count < 24 {
		
		
		print("")
		
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
				
				
				A = Double(integralImage.pixelData[nx! - 1 + dx][ny - 1 + dy])
				if ny > 0 {
					C = Double(integralImage.pixelData[nx! - 1 + dx][ny - 1])
				}
				if nx > 0{
					B = Double(integralImage.pixelData[nx! - 1][ny - 1 + dy])
				}
				if nx > 0 && ny > 0{
					D = Double(integralImage.pixelData[nx! - 1][ny - 1])
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
		
		print("Timestamp: \(Timestamp)")
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
//			strongClassifier.imageFeature!.removeAll()
			classifierArray.append(strongClassifier)
			
			cascade.cascadeThreshold! += (strongClassifier.alpha)!
			
			if strongClassifier.alpha > Double(INT8_MAX) {
				
				break
				
			}
			
		}
		print("Timestamp: \(Timestamp)")
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
		
		
		
		
		
		for (_,image) in imageArray {
			
			
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
		
		
		let imf = feature.imageFeature!
		
		//		let imageFeatureArray = (imf).sort({$0.featureValue < $1.featureValue})
		
		var Splus = 0.0
		var Smin = 0.0
		
		var lowestError = 1.0;
		
		lowestError = (strongClassifier.error)!
		
//		for (index,imageFeature) in imf{
//			
//			print("image:\(imageFeature.featureValue), index:\(index)")
//			
//		}
		
		print("\n\nsorting\n\n")
		let imageFeatureArray = imf.sort { ( f:(Int, ImageFeature), l:(Int, ImageFeature)) -> Bool in
			
			f.1.featureValue < l.1.featureValue
		}
//		for (index,imageFeature) in imageFeatureArray{
//			
//			print("image:\(imageFeature.featureValue), index:\(index)")
//			
//		}
		
		print("\n\n calculating \n\n")
		
		for (index,imageFeature) in imageFeatureArray{
			
			
			//			let imageFeature = imageFeatureArray[index]
			let image = imageArray[index]
			
//			print("image:\(index), w:\(image?.weight), in:\(image?.index), type:\(image?.imageType)")
			
			if imageFeature.imageType == ImageType.Face {
				
				Splus += image!.weight!
				
			}else {
				
				Smin += image!.weight!
				
			}
			
			let v1 = Splus + T.Tmin - Smin
			let v2 = Smin + T.Tplus - Splus
			
//			print("Splus:\(Splus), Smin:\(Smin), v1:\(v1), v2:\(v2)")
			
			
			let error = min(v1, v2)
			
			if error <= 0 {
				//				print("feature:\(feature.x),\(feature.y),\(feature.w),\(feature.h),\(feature.fw),\(feature.fh)")
				//				print("error is zero")
				continue
			}
			
			if error > 1 {
				
				
				print("")
				
			}
			
			//			if error == 0 {
			//
			//				continue
			//			}
			
			
			
			feature.error = error
			
			if error < lowestError {
				
				
				//				print("error:\(error) feature index:\(feature.x),\( feature.y ),\(feature.w),\( feature.h)")
				
				lowestError = error
				feature.thresholdValue = imageFeature.featureValue
				
				let beta = calculateBeta(error)
				feature.alpha = calculateAlpha(beta)
				feature.beta = beta
				if error == v1 {
					
					feature.polarity = -1
					
				}else {
					
					feature.polarity = 1
					
				}
				
				//				strongClassifier = HaarFeature()
				strongClassifier = feature
				
				
				
				
				if isnan(strongClassifier.alpha!) || strongClassifier.alpha == nil || isinf(strongClassifier.alpha!) {
					
					print("alpha:\(strongClassifier.alpha), beta:\(beta), error:\(error)")
					
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
							
//							<x>17</x>
//							<y>7</y>
//							<w>5</w>
//							<h>2</h>
//							<fw>1</fw>
//							<fh>2</fh>
//							
//							<x>15</x>
//							<y>2</y>
//							<w>3</w>
//							<h>2</h>
//							<fw>1</fw>
//							<fh>2</fh>
							
//							if hf.x == 15 && hf.y == 2 && hf.w == 3 && hf.h == 2 && hf.fw == 1 && hf.fh == 2 {
//							
//								featureArray.append(hf)
//							i++
//							}
//							
//							if hf.x == 17 && hf.y == 7 && hf.w == 5 && hf.h == 2 && hf.fw == 1 && hf.fh == 2 {
//								
//								featureArray.append(hf)
//								i++
//							}
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
	
	private func traverseNonFaceImage( path:String, limit:Int) -> [String]{
		
		var backgroundImagePathArray = [String]()
		
		
		let fileManager = NSFileManager.defaultManager()
		
		let enumerator:NSDirectoryEnumerator = fileManager.enumeratorAtPath(path)!
		
		
		while let element = enumerator.nextObject() as? String{
			let path = path+"/"+element
			
			if path.hasSuffix("pgm") || path.hasSuffix("jpg") {
				
				
				
				backgroundImagePathArray.append(path)
				
			}
			
		}
		
		return backgroundImagePathArray
		
		
	}
	
	
	private  func extractNNormalizedImageIn(inout imageArray: [Int:IntegralImage],var bgImagePathArray:[String], imageLimit:Int, stageNo:Int){
		
		
		//		var imageArray = [Int:IntegralImage]()
		
		
		var count = imageArray.count - pImageCount
		
		var imageIndex = stageNo * 10000
		for path in bgImagePathArray {
			
			
			var image = readImageFromPath(path)
			
			
			let index = bgImagePathArray.indexOf(path)
			
			bgImagePathArray.removeAtIndex(index!)
			
			if image != nil {
				
				if (image?.size.width > 400 || image?.size.height > 400 ) {
					
					
					var nsize = image?.size
					
					nsize?.width /= 2
					nsize?.height /= 2
					
					if nsize?.height > 5000{
						
						
						continue
						
					}
					
					image = resizeImage(image!, size: nsize!)
					
					let unprocessedImageArray = scrollImage(image!)
					
					
					
					for nimage in unprocessedImageArray {
						
						
						
						var size = NSZeroSize;
						
						size.width = 24;
						size.height = 24;
						
						let img = resizeImage(nimage, size: size)
						
						let integralImage = IntegralImage(image: img, isGrayScale: false)
						
						if integralImage.sd < 30{
						
//							print("lastp: \(integralImage.pixelData[23][23])")
//							print("mean: \(integralImage.mean)")
							
//							print("sd: \(integralImage.sd)")
//							print("index: \(imageIndex)")
							
							continue
							
							
//							var bmpImageRep = NSBitmapImageRep(data: (img.TIFFRepresentation)!)
//							//
//												var data = bmpImageRep?.representationUsingType(NSBitmapImageFileType.NSPNGFileType,properties: [:])
//							//
//							//
//												data?.writeToFile("/Users/mamunul/Documents/generatednonface/"+String(integralImage.sd)+"-"+UUIDString()+".png", atomically: true)
							//
							
							
						}
						
						
						if integralImage.pixelData[23][23] < 0.04 {
							
							//					print("lastp: \(integralImage.pixelData[23][23])")
							//					print(integralImage.sd)
							//					print(integralImage.mean)
							//					var bmpImageRep = NSBitmapImageRep(data: (img.TIFFRepresentation)!)
							//
							//							var data = bmpImageRep?.representationUsingType(NSBitmapImageFileType.NSPNGFileType,properties: [:])
							//
							//
							//							data?.writeToFile("/Users/mamunul/Documents/generatednonface/"+UUIDString()+".png", atomically: true)
							
							continue
							
						}
						
//						print("lastp: \(integralImage.pixelData[23][23])")
						
						integralImage.imageType = ImageType.NonFace
						
						integralImage.index = imageIndex
						imageArray.updateValue(integralImage, forKey: imageIndex)
						
						imageIndex++
						count++;
						if count == imageLimit{
							
							break
							
						}
					}
					
				}
			}
			if count == imageLimit{
				
				break
				
			}
		}
		
		
		
		
	}
	
	private  func extractPNormalizedImage(imagePath:String, imageLimit:Int) -> [Int:IntegralImage]{
		
		
		let fileManager = NSFileManager.defaultManager()
		
		
		var imageArray = [Int:IntegralImage]()
		
		var imageIndex = 0;
		
		
		
		let enumerator:NSDirectoryEnumerator = fileManager.enumeratorAtPath(imagePath)!
		
		
		var count = 0;
		while let element = enumerator.nextObject() as? String{
			
			
			let path = imagePath+"/"+element
			
			var image = readImageFromPath(path)
			
			
			
			if image != nil {
				
				
				var size = NSZeroSize;
				
				size.width = 24;
				size.height = 24;
				
				let img = resizeImage(image!, size: size)
				
				
				
				let integralImage = IntegralImage(image: img, isGrayScale: true)
				
				if integralImage.sd < 30{
					
					//							print("lastp: \(integralImage.pixelData[23][23])")
					//							print("mean: \(integralImage.mean)")
					
					//							print("sd: \(integralImage.sd)")
					//							print("index: \(imageIndex)")
					
					continue
				}
				
				if integralImage.pixelData[23][23] < 0.04 {
				
//					print("lastp: \(integralImage.pixelData[23][23])")
//					print(integralImage.sd)
//					print(integralImage.mean)
//					var bmpImageRep = NSBitmapImageRep(data: (img.TIFFRepresentation)!)
//					
//							var data = bmpImageRep?.representationUsingType(NSBitmapImageFileType.NSPNGFileType,properties: [:])
//					
//					
//							data?.writeToFile("/Users/mamunul/Documents/generatednonface/"+UUIDString()+".png", atomically: true)
					
			continue
				
				}
				
//				print("lastp: \(integralImage.pixelData[23][23])")
				integralImage.imageType = ImageType.Face
				
				integralImage.index = imageIndex
				imageArray.updateValue(integralImage, forKey: imageIndex)
				
				imageIndex++
				count++;
				if count == imageLimit{
					
					break
					
				}
				
			}
			
		}
		
	

		
		
		return imageArray
		
	}
	
	private func evaluateCascade(cascade:Cascade,inout imageArray:[Int:IntegralImage],imageType:ImageType, toDelete:Bool) -> (Fi:Double, Di:Double){
		
		var d = 0.0
		var f = 0.0
		
		let nImageCount = imageArray.count - pImageCount
		
		
		if imageType == ImageType.All {
			
			for (_,image) in imageArray {
				
				
				if image.imageType == ImageType.Face {
					
					d += detectFace(cascade, image:image) ? 1 : 0
					
				} else {
					
					f += detectFace(cascade, image:image) ? 1 : 0 // have confusion 1:0 or 0:1
					
				}
				
				
			}
			
			d /= Double(pImageCount)
			
			f /= Double(nImageCount)
			
		}else if imageType == ImageType.Face {
			
			
			for (_,image) in imageArray {
				
				
				if image.imageType == ImageType.Face {
					
					let detected = detectFace(cascade, image:image)
					
					d += detected ? 1 : 0
					
					
				}
				
				
			}
			
			d /= Double(pImageCount)
			
			
		}else if imageType == ImageType.NonFace{
			
			var keyArray = [Int]()
			
			for (keyIndex,image) in imageArray {
				
				
				if image.imageType == ImageType.NonFace {
					
					let detected = detectFace(cascade, image:image)
					
					//					d += detected ? 1 : 0
					
					if toDelete &&  !detected{
						
						let dictindex = imageArray.indexForKey(keyIndex)
						
						
						
						guard dictindex == nil else {
							imageArray.removeAtIndex(dictindex!)
							keyArray.append(keyIndex)
							
							
							continue
						}
						
					}
					
				}
				
				
			}
			
			if toDelete {
				var i = 0
				for var feature in featureArray {
					
					for keyIndex in keyArray {
						
						let ind = feature.imageFeature?.indexForKey(keyIndex)
						
						guard ind == nil else {
							feature.imageFeature?.removeAtIndex(ind!)
							continue
							
						}
						
					}
					
					featureArray[i] = feature
					i++
				}
			}
			
			
		}
		
		return (f,d)
		
	}
	
	
	private func decreaseThreshold(inout cascade:Cascade,var imageArray:[Int:IntegralImage],requiredD:Double) {
		
		var minThreshold = 0.0, maxThreshold = cascade.cascadeThreshold!/2
		
		
		while Int(maxThreshold * 1000) != Int(minThreshold * 1000) {
			
			let newThreshold = (minThreshold + maxThreshold)/2
			cascade.cascadeThreshold = newThreshold
			
			let fd = evaluateCascade(cascade,imageArray: &imageArray, imageType: ImageType.Face,toDelete: false)
			
			
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
		//		_:NSImage?
		
		if path.hasSuffix("pgm") || path.hasSuffix("jpg") {
			
			let imageURL = NSURL(fileURLWithPath: path, isDirectory: false)
			
			
			image = NSImage(byReferencingURL: imageURL)
			
			
			//			print("size:\(image?.size)")
			
			
			
			
			
		}
		
		
		return image;
		
	}
	
	func resizeImage(sourceImage:NSImage, size:NSSize ) -> NSImage
	{
		
		let targetFrame = NSMakeRect(0, 0, size.width, size.height)
		var targetImage:NSImage?
		let sourceImageRep = sourceImage.bestRepresentationForRect(targetFrame, context: nil, hints: nil)
		
		
		
		
		
		
		targetImage = NSImage(size:size)
		
		targetImage!.lockFocus()
		
		sourceImageRep?.drawInRect(targetFrame)
		//	[sourceImageRep drawInRect: targetFrame];
		targetImage?.unlockFocus()
		
		return targetImage!;
	}
	
	
	
	func scrollImage(image:NSImage) -> [NSImage]{
		
		var imageArray:[NSImage] = []
		
		var size = NSZeroSize;
		
		size.width = 80;
		size.height = 80;
		
		for var i = 0; i < Int(image.size.height - size.height) ; i += Int(size.height/3) {
			
			for var j = 0; j < Int(image.size.width - size.width) ; j += Int(size.width/3)  {
				
				
				
				//				let rect = NSMakeRect(CGFloat(i), CGFloat(j), size.width, size.height)
				
				
				let rect = NSMakeRect(CGFloat(j), CGFloat(i), size.height, size.width)
				
				
				let img = cropToBounds(image, cropRect: rect, size: size)
				
				imageArray.append(img)
				//				print(rect)
			}
			
			
		}
		
		
		
		return imageArray
		
	}
	
	
	func UUIDString() ->String {
		let theUUID = CFUUIDCreate(nil)
		let string = CFUUIDCreateString(nil, theUUID)
		
		return string as String;
	}
	
	func cropToBounds(sourceImage: NSImage, cropRect:NSRect,size:NSSize) -> NSImage {
		//
		let context = NSGraphicsContext.currentContext()
		let imageRect = NSMakeRect(0, 0, size.width, size.height)
		let targetImage:NSImage? = NSImage(size: size)
		
		
		context?.imageInterpolation = NSImageInterpolation.High
		targetImage!.lockFocus()
		sourceImage.drawInRect(imageRect, fromRect: cropRect, operation: NSCompositingOperation.CompositeCopy, fraction: 1.0)
		
		
		
		
		targetImage?.unlockFocus()
		
		
		//		var bmpImageRep = NSBitmapImageRep(data: (targetImage?.TIFFRepresentation)!)
		
		//		var data = bmpImageRep?.representationUsingType(NSBitmapImageFileType.NSPNGFileType,properties: [:])
		
		
		//		data?.writeToFile("/Users/mamunul/Documents/generatednonface/"+UUIDString()+".png", atomically: true)
		
		
		return targetImage!;
	}
	
}