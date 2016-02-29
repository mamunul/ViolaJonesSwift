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
	
	func resizeImage(width: CGFloat, _ height: CGFloat) -> NSImage {
		let img = NSImage(size: CGSizeMake(width, height))
		
		img.lockFocus()
		let ctx = NSGraphicsContext.currentContext()
		ctx?.imageInterpolation = .High
		self.drawInRect(NSMakeRect(0, 0, width, height), fromRect: NSMakeRect(0, 0, size.width, size.height), operation: .CompositeCopy, fraction: 1)
		img.unlockFocus()
		
		return img
	}
	
	func pixelData(isGrayScale:Bool) -> [[GrayPixel]] {
		
		var bitmap = self.TIFFRepresentation
		
		var bmp = NSBitmapImageRep(data: bitmap!)!
		
	
//		var bmp = self.representations[0] as! NSBitmapImageRep
		
//		[img lockFocus] ;
//		let bmp = NSBitmapImageRep(focusedViewRect: NSMakeRect(0, 0, size.width, size.height))
//		NSBitmapImageRep *bitmapRep = NSBitmap [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0.0, 0.0, [self size].width, [img size].height)] ;
//		[img unlockFocus] ;
		
	
		var data: UnsafeMutablePointer<UInt8> = bmp.bitmapData
		var r, g, b, a: UInt8
		var pixels: [[GrayPixel]] = []
		
		var res:UInt8
		
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
					
				
					r = UInt8((Int( r) + Int(b) + Int(g))/3)
//
//					var res2 = g
					
					
					
//					print("r:\(r) g:\(g) b:\(b) res")
					
//					r = (r + g + b)
					
//					print("")
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