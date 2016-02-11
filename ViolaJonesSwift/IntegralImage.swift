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
	var image:[[GrayPixel]]

	
	init(image:NSImage){
		
		self.image = image.pixelData(true)
		
		height = (Int)(image.size.height)
		width = (Int)(image.size.width)
		
		processImage()
	}
	
	
	func processImage(){
	
		let mean = getMean()
		let sd = getStandardDeviation(mean)
		
		
		print("sd:\(sd)")
		
		normalizeImage(sd, mean: mean)
	
		integralImage()

	}
	
	
	
	private func integralImage(){
		
		for row in 0..<width! {
			for col in 0..<height! {
				
				var a = 0.0, b = 0.0, c = 0.0
				
				if row > 0 {
				
						a = Double((image[row-1][col]).p)
				}
				
				if col > 0 {
				
					b = Double(image[row][col - 1].p)
				}
				
				if row > 0 && col > 0 {
				
					c = Double(image[row - 1][col - 1].p)
				
				}
				
				
				image[row][col].p = image[row][col].p + Float(a) + Float(b) - Float(c)
			}
		}

	
	}
	
	private func normalizeImage(sd:Double, mean:Int64){
		
		for row in 0..<width! {
			for col in 0..<height! {
				
				
				if Int(sd) == 0 {
					
					image[row][col].p = Float(image[row][col].p) - Float(mean)
				
				}else{
				
					image[row][col].p = (Float(image[row][col].p) - Float(mean)) / Float(2 * sd);
				
				}
				
			}
		}
	

	
	}
	
	private func getMean() ->Int64{
	
		
		var sum:Int64 = 0
		var mean:Int64 = 0
		
		for row in 0..<width! {
			for col in 0..<height! {

				sum = sum + Int64((image[row][col]).p)
				
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
				subtraction = Int64((image[row][col]).p) - Int64( mean);
				sum = sum + subtraction * subtraction;
				
			}
			
		}
		
		sd = Double(sum) / Double(width! * height!)
		
		sd = sqrt(sd)
		
		return sd

	
	}
	
}
