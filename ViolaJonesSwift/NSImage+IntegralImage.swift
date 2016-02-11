//
//  NSImage+IntegralImage.swift
//  ViolaJonesSwift
//
//  Created by Mamunul on 2/10/16.
//  Copyright © 2016 Mamunul. All rights reserved.
//

import Foundation
import AppKit


extension NSImage {
	
	func pixelData(isGrayScale:Bool) -> [[GrayPixel]] {
		
		var bmp = self.representations[0] as! NSBitmapImageRep
		var data: UnsafeMutablePointer<UInt8> = bmp.bitmapData
		var r, g, b, a: UInt8
		var pixels: [[GrayPixel]] = []
		
		for row in 0..<bmp.pixelsHigh {
			
			var rowPixels = [GrayPixel]()
			
			for col in 0..<bmp.pixelsWide {
				r = data.memory
				data = data.advancedBy(1)
				if !isGrayScale{
					g = data.memory
					data = data.advancedBy(1)
					b = data.memory
					data = data.advancedBy(1)
					a = data.memory
					data = data.advancedBy(1)
				}
				
				let p = GrayPixel(p: r, row: row, col: col)
				
				rowPixels.append(p)

			}
			
			pixels.append(rowPixels)
		}
		
//		print("\(bmp.pixelsHigh):\(bmp.pixelsWide)")
		return pixels
	}
}

struct GrayPixel {
	var p: Float

	var row: Int
	var col: Int
	init(p: UInt8, row: Int, col: Int) {
		self.p = Float(p)
	
		self.row = row
		self.col = col
	}
//	var color: NSColor {
//		return NSColor(red: CGFloat(r/255.0), green: CGFloat(g/255.0), blue: CGFloat(b/255.0), alpha: CGFloat(a/255.0))
//	}
//	var description: String {
//		return "RGBA(\(r), \(g), \(b), \(a))"
//	}
	
	
	
}
struct RGBPixel {
	var r: Float
	var g: Float
	var b: Float
	var a: Float
	var row: Int
	var col: Int
	init(r: UInt8, g: UInt8, b: UInt8, a: UInt8, row: Int, col: Int) {
		self.r = Float(r)
		self.g = Float(g)
		self.b = Float(b)
		self.a = Float(a)
		self.row = row
		self.col = col
	}
	var color: NSColor {
		return NSColor(red: CGFloat(r/255.0), green: CGFloat(g/255.0), blue: CGFloat(b/255.0), alpha: CGFloat(a/255.0))
	}
	var description: String {
		return "RGBA(\(r), \(g), \(b), \(a))"
	}
	
	
	
}