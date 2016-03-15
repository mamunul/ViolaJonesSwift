//
//  IntegralImage.swift
//  ViolaJonesSwift
//
//  Created by Mamunul on 2/10/16.
//  Copyright © 2016 Mamunul. All rights reserved.
//


import Foundation
import Cocoa
import Darwin

class IntegralImage {
	
	
	
	var height:Int?
	var width:Int?
	var imageType:ImageType = ImageType.NonFace
	var weight:Double?
	var pixelData:[[Float]]
	var index:Int?
	var mean:Int64 = 0
	var reUse:Bool = true
	var sd = 0.0
//	var avg = 0

	
	init(image:NSImage, isGrayScale:Bool){
		
		
		
		self.pixelData = image.pixelData(isGrayScale)
		
		let p = UnsafePointer<[[Int]]>(pixelData)
		var byteData = NSData(bytes: p, length: 576)
		
//		var sum = 0
		
//		for i in 0..<24 {
//			
//			for j in 0..<24 {
//				
////				p[i*24+j] = pixelData[i][j]
//				
//				avg += Int(pixelData[i][j])
//				
//				
//			}
//			
//		}
//		
//		avg /= 576
		
		
//		if avg < 60 {
//			
//			var bmpImageRep = NSBitmapImageRep(data: (image.TIFFRepresentation)!)
//			
//					var data = bmpImageRep?.representationUsingType(NSBitmapImageFileType.NSPNGFileType,properties: [:])
//			
//			
//					data?.writeToFile("/Users/mamunul/Documents/generatednonface/"+String(avg)+"-"+UUIDString()+".png", atomically: true)
//		
////			print(avg)
//		
//		}
		
//					let imageRep = NSBitmapImageRep(data: byteData)
//		//
//		//
//					var imageSize = NSMakeSize(24, 24);
//		//
//					var image = NSImage(size: imageSize)
//					image.addRepresentation(imageRep!)
		
		height = (Int)(image.size.height)
		width = (Int)(image.size.width)
		
		processImage()
		
		
//		for i in 0..<24 {
//			
//			for j in 0..<24 {
		
				//				p[i*24+j] = pixelData[i][j]
		
		
				
//			}
//			
//		}
//		print("\n")
	}
	
	
	
	func UUIDString() ->String {
		let theUUID = CFUUIDCreate(nil)
		let string = CFUUIDCreateString(nil, theUUID)
		
		return string as String;
	}
	func processImage(){
	
		mean = getMean()
		sd = getStandardDeviation(mean)
		

		
	
		
		
		normalizeImage(sd, mean: mean)
	
		integralImage()
		
	
		
//		if pixelData[23][23] > 60 {
//			
//			print("lastp: \(pixelData[23][23])")
//			print("mean: \(mean)")
//			
//			print("sd: \(sd)")
//			
//			for i in 0..<24 {
//			//
//				for j in 0..<24 {
//							
//					print(pixelData[i][j])
//							
//				}
//			}
//			
//			
//			
//		}

	}
	
	
	
	private func integralImage(){
		
		for row in 0..<width! {
			for col in 0..<height! {
				
				var a = 0.0, b = 0.0, c = 0.0
				
				if row > 0 {
				
						a = Double((pixelData[row-1][col]))
				}
				
				if col > 0 {
				
					b = Double(pixelData[row][col - 1])
				}
				
				if row > 0 && col > 0 {
				
					c = Double(pixelData[row - 1][col - 1])
				
				}
				
				
				pixelData[row][col] = pixelData[row][col] + Float(a) + Float(b) - Float(c)
			}
		}

	
	}
	
	private func normalizeImage(sd:Double, mean:Int64){
		
		for row in 0..<width! {
			for col in 0..<height! {
				
				
				if Int(sd) == 0 {
					
					pixelData[row][col] = Float(pixelData[row][col]) - Float(mean)
				
				}else{
				
					pixelData[row][col] = (Float(pixelData[row][col]) - Float(mean)) / Float(2 * sd);
				
				}
				
			}
		}
	

	
	}
	
	private func getMean() ->Int64{
	
		
		var sum:Int64 = 0
		var mean:Int64 = 0
		
		for row in 0..<width! {
			for col in 0..<height! {

				sum = sum + Int64((pixelData[row][col]))
				
			}

		}
		
		mean = Int64(sum) / Int64(width! * height!)
		
	
		return mean
	
	}
	
	private func getStandardDeviation(mean:Int64) ->Double{
		
		var sum:Int64 = 0
		var subtraction = 0
		var sd:Double = 0.0
		
		for row in 0..<width! {
			for col in 0..<height! {
				
//				sum = sum + Int64((image[row][col]).p)
				subtraction = Int64((pixelData[row][col])) - Int64( mean);
				sum = sum + subtraction * subtraction;
				
			}
			
		}
		
		sd = Double(sum) / Double(width! * height!)
		
		sd = sqrt(sd)
		
		return sd

	
	}
	
}
