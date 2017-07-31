//
//  ImageRenderer.swift
//  ShaDai
//
//  Created by lsylove on 2017. 7. 31..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

import AVFoundation
import AVKit

class ImageRenderer {
    func render(cgImage: CGImage) -> CVPixelBuffer? {
        
        let image = cgImage
        
        let imageWidth = Int(image.width)
        let imageHeight = Int(image.height)
        
        let attributes : [NSObject:AnyObject] = [
            kCVPixelBufferCGImageCompatibilityKey : true as AnyObject,
            kCVPixelBufferCGBitmapContextCompatibilityKey : true as AnyObject
        ]
        
        var _pxbuffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault,
                            imageWidth,
                            imageHeight,
                            kCVPixelFormatType_32ARGB,
                            attributes as CFDictionary?,
                            &_pxbuffer)
        
        guard let pxbuffer = _pxbuffer else {
            return nil
        }
        
        let flags = CVPixelBufferLockFlags(rawValue: 0)
        CVPixelBufferLockBaseAddress(pxbuffer, flags)
        let pxdata = CVPixelBufferGetBaseAddress(pxbuffer)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        let _context = CGContext(data: pxdata,
                                 width: imageWidth,
                                 height: imageHeight,
                                 bitsPerComponent: 8,
                                 bytesPerRow: CVPixelBufferGetBytesPerRow(pxbuffer),
                                 space: rgbColorSpace,
                                 bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        guard let context = _context else {
            CVPixelBufferUnlockBaseAddress(pxbuffer, flags)
            return nil
        }
        
        context.draw(image, in: CGRect.init(x: 0, y: 0, width: imageWidth, height: imageHeight))
        CVPixelBufferUnlockBaseAddress(pxbuffer, flags)

        return pxbuffer
    }
    
    func render(ciImage: CIImage, extent: CGSize) -> CVPixelBuffer {
        
        let image = ciImage
        if let pxbuffer = image.pixelBuffer {
            return pxbuffer
        }
        
        let attributes : [NSObject:AnyObject] = [
            kCVPixelBufferCGImageCompatibilityKey : true as AnyObject,
            kCVPixelBufferCGBitmapContextCompatibilityKey : true as AnyObject
        ]
        
        var _pxbuffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault,
                            Int(extent.width),
                            Int(extent.height),
                            kCVPixelFormatType_32ARGB,
                            attributes as CFDictionary?,
                            &_pxbuffer)
        
        guard let pxbuffer = _pxbuffer else {
            fatalError("[debug] CI image buffer somehow failed to be initialized")
        }
        
        let flags = CVPixelBufferLockFlags(rawValue: 0)
        CVPixelBufferLockBaseAddress(pxbuffer, flags)
        
        let context = CIContext()
        context.render(ciImage, to: pxbuffer)
        
        CVPixelBufferUnlockBaseAddress(pxbuffer, flags)
        
        return pxbuffer
    }
    
    func renderUIView(view: UIView) -> CGImage? {
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        let image = renderer.image { context in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: false)
        }

        return image.cgImage
    }
    
    func renderSnapshot(playerItem: AVPlayerItem) -> CGImage? {
        let asset: AVURLAsset? = (playerItem.asset as? AVURLAsset)
        
        let imageGenerator = AVAssetImageGenerator(asset: asset!)
        imageGenerator.requestedTimeToleranceAfter = kCMTimeZero
        imageGenerator.requestedTimeToleranceBefore = kCMTimeZero
        
        let thumb: CGImage? = try? imageGenerator.copyCGImage(at: playerItem.currentTime(), actualTime: nil)
        return thumb
    }
    
    var cachedShape: CVPixelBuffer?
    var cachedSnapshot: CVPixelBuffer?
    var cachedSize: CGSize?
    
    func render(shapeView: UIView?, playerView: PlayerView?) -> CVPixelBuffer {
        let processedShape: CVPixelBuffer?
        let processedSnapshot: CVPixelBuffer?
        
        let size = playerView?.playerLayer.videoRect.size ?? cachedSize!
        cachedSize = size
        
        if let shapeView = shapeView {
            let shape = renderUIView(view: shapeView)
            let reshape = resize(image: shape!, extent: size)
            processedShape = render(cgImage: reshape!)
            cachedShape = processedShape
            
            if let playerView = playerView {
                let snapshot = renderSnapshot(playerItem: playerView.player!.currentItem!)
                let resnap = resize(image: snapshot!, extent: size)
                processedSnapshot = render(cgImage: resnap!)
                cachedSnapshot = processedSnapshot
            } else {
                processedSnapshot = cachedSnapshot
                
            }
        } else if let playerView = playerView {
            let snapshot = renderSnapshot(playerItem: playerView.player!.currentItem!)
            let resnap = resize(image: snapshot!, extent: size)
            processedSnapshot = render(cgImage: resnap!)
            cachedSnapshot = processedSnapshot
            
            processedShape = cachedShape
            
        } else {
            fatalError("[debug] renderer has to render at least one of views!")
        }
        
        guard let readyShape = processedShape, let readySnapshot = processedSnapshot else {
            fatalError("[debug] cannot render null value")
        }
        
        let shapeImage = CIImage(cvPixelBuffer: readyShape)
        let snapshotImage = CIImage(cvPixelBuffer: readySnapshot)
        
        let composition = CIFilter(name: "CISourceOverCompositing")!
        composition.setValue(shapeImage, forKey: kCIInputImageKey)
        composition.setValue(snapshotImage, forKey: kCIInputBackgroundImageKey)
        
        let buffer = render(ciImage: composition.outputImage!, extent: size)
        return buffer
    }
    
    func resize(image: CGImage, extent: CGSize) -> CGImage? {
        
        guard let colorSpace = image.colorSpace else {
            return nil
        }
        guard let context = CGContext(data: nil,
                                      width: Int(extent.width),
                                      height: Int(extent.height),
                                      bitsPerComponent: image.bitsPerComponent,
                                      bytesPerRow: Int(extent.width) * image.bitsPerComponent / 2,
                                      space: colorSpace,
                                      bitmapInfo: image.alphaInfo.rawValue) else {
            return nil
        }
        
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: Int(extent.width), height: Int(extent.height)))
        
        return context.makeImage()
        
    }
}
