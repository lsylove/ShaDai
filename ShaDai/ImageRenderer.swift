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
    
    func render(ciImage: CIImage) -> CVPixelBuffer {
        
        let image = ciImage
        let extent = image.extent
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
    
    private var cachedShape: CVPixelBuffer?
    
    private var cachedSnapshot: CVPixelBuffer?
    
    var size = CGSize()
    
    func render(shapeView: UIView?, playerView: PlayerView?) -> CVPixelBuffer {
        var processedShape: CVPixelBuffer?
        var processedSnapshot: CVPixelBuffer?
        
        let group = DispatchGroup()
        
        if let shapeView = shapeView {
            
            group.enter()
            DispatchQueue.global().async {
                
                guard let shape = self.renderUIView(view: shapeView) else {
                    fatalError("[debug] nil image processing! (for shape)")
                }
                
                processedShape = self.render(cgImage: shape)
                self.cachedShape = processedShape
                
                group.leave()
            }
        }

        if let playerView = playerView {
            guard let snapshot = renderSnapshot(playerItem: playerView.player!.currentItem!),
                let resnap = resize(image: snapshot, extent: self.size) else {
                    fatalError("[debug] nil image processing! (for snapshot)")
            }
            
            processedSnapshot = render(cgImage: resnap)
            cachedSnapshot = processedSnapshot
            
            processedShape = cachedShape
            
        } else {
            processedSnapshot = cachedSnapshot
        }
        
        group.wait()
        
        guard let readyShape = processedShape, let readySnapshot = processedSnapshot else {
            fatalError("[debug] cannot render null value")
        }
        
        let shapeImage = CIImage(cvPixelBuffer: readyShape)
        let snapshotImage = CIImage(cvPixelBuffer: readySnapshot)
        
        let composition = shapeImage.compositingOverImage(snapshotImage)
        
        let buffer = render(ciImage: composition)
        return buffer
    }
    
    func resize(image: CGImage, extent: CGSize) -> CGImage? {
        
        UIGraphicsBeginImageContext(extent)
        UIImage(cgImage: image).draw(in: CGRect(origin: .zero, size: extent))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage?.cgImage
    }
    
//    func crop(image: CGImage, prev: CGSize, target: CGSize) -> CGImage? {
//        
//        return image
//        let newX = (prev.width - target.width) / 2.0
//        let newY = (prev.height - target.height) / 2.0
//        
//        let newFrame = CGRect(origin: CGPoint(x: newX, y: newY), size: target)
//        let imageRef = image.cropping(to: newFrame)
//        return imageRef
//    }
}
