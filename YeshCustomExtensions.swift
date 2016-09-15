//Yeshu
//
//  YeshCustomExtensions.swift
//  YeshCustomExtensios
//
//  Created by Yeswanth Kanumuri on 9/15/16.
//  Copyright © 2016 Yeswanth Kanumuri. All rights reserved.
//

import UIKit
import Foundation
// NSString extension
extension String {
    static func className(aClass: AnyClass) -> String {
        return NSStringFromClass(aClass).componentsSeparatedByString(".").last!
    }
    
    func substring(from: Int) -> String {
        return self.substringFromIndex(self.startIndex.advancedBy(from))
    }
    
    var length: Int {
        return self.characters.count
    }
}
// UIView extensions
extension UIView {
    func alphaFromPoint(point: CGPoint) -> CGFloat {
        var pixel: [UInt8] = [0, 0, 0, 0]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let alphaInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue)
        let context = CGBitmapContextCreate(&pixel, 1, 1, 8, 4, colorSpace, alphaInfo.rawValue)
        
        CGContextTranslateCTM(context, -point.x, -point.y);
        
        self.layer.renderInContext(context!)
        
        let floatAlpha = CGFloat(pixel[3])
        return floatAlpha
    }
    
    func getColourFromPoint(point:CGPoint) -> UIColor {
        let colorSpace:CGColorSpace = CGColorSpaceCreateDeviceRGB()!
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue)
        var pixelData:[UInt8] = [0, 0, 0, 0]
        let context = CGBitmapContextCreate(&pixelData, 1, 1, 8, 4, colorSpace, bitmapInfo.rawValue)
        CGContextTranslateCTM(context, -point.x, -point.y);
        self.layer.renderInContext(context!)
        
        let red:CGFloat = CGFloat(pixelData[0])/CGFloat(255.0)
        let green:CGFloat = CGFloat(pixelData[1])/CGFloat(255.0)
        let blue:CGFloat = CGFloat(pixelData[2])/CGFloat(255.0)
        let alpha:CGFloat = CGFloat(pixelData[3])/CGFloat(255.0)
        let color:UIColor = UIColor(red: red, green: green, blue: blue, alpha: alpha)
        return color
    }
    
    
    
}
extension UIImage {
    func trim(trimRect trimRect :CGRect) -> UIImage {
        if CGRectContainsRect(CGRect(origin: CGPointZero, size: self.size), trimRect) {
            if let imageRef = CGImageCreateWithImageInRect(self.CGImage, trimRect) {
                return UIImage(CGImage: imageRef)
            }
        }
        
        UIGraphicsBeginImageContextWithOptions(trimRect.size, true, self.scale)
        self.drawInRect(CGRect(x: -trimRect.minX, y: -trimRect.minY, width: self.size.width, height: self.size.height))
        let trimmedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let image = trimmedImage else { return self }
        
        return image
    }
}

extension UIColor {
    
    convenience init(hex: String) {
        self.init(hex: hex, alpha:1)
    }
    
    convenience init(hex: String, alpha: CGFloat) {
        var hexWithoutSymbol = hex
        if hexWithoutSymbol.hasPrefix("#") {
            hexWithoutSymbol = hex.substring(1)
        }
        
        let scanner = NSScanner(string: hexWithoutSymbol)
        var hexInt:UInt32 = 0x0
        scanner.scanHexInt(&hexInt)
        
        var r:UInt32!, g:UInt32!, b:UInt32!
        switch (hexWithoutSymbol.length) {
        case 3: // #RGB
            r = ((hexInt >> 4) & 0xf0 | (hexInt >> 8) & 0x0f)
            g = ((hexInt >> 0) & 0xf0 | (hexInt >> 4) & 0x0f)
            b = ((hexInt << 4) & 0xf0 | hexInt & 0x0f)
            break;
        case 6: // #RRGGBB
            r = (hexInt >> 16) & 0xff
            g = (hexInt >> 8) & 0xff
            b = hexInt & 0xff
            break;
        default:
            // TODO:ERROR
            break;
        }
        
        self.init(
            red: (CGFloat(r)/255),
            green: (CGFloat(g)/255),
            blue: (CGFloat(b)/255),
            alpha:alpha)
    }
    
    
    var hexString: String {
        let components = CGColorGetComponents(self.CGColor)
        
        let red = Float(components[0])
        let green = Float(components[1])
        let blue = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(red * 255), lroundf(green * 255), lroundf(blue * 255))
    }
}


extension UIImageView {
    
    func setRandomDownloadImage(width: Int, height: Int) {
        if self.image != nil {
            self.alpha = 1
            return
        }
        self.alpha = 0
        let url = NSURL(string: "https://ssl.webpack.de/lorempixel.com/\(width)/\(height)/")!
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.requestCachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        let session = NSURLSession(configuration: configuration)
        let task = session.dataTaskWithURL(url, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            if error != nil {
                return
            }
            
            if let response = response as? NSHTTPURLResponse {
                if response.statusCode / 100 != 2 {
                    return
                }
                if let data = data, let image = UIImage(data: data) {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.image = image
                        UIView.animateWithDuration(0.3, animations: { () -> Void in
                            self.alpha = 1
                        }) { (finished: Bool) -> Void in
                        }
                    })
                }
            }
        })
        task.resume()
    }
    
    func clipParallaxEffect(baseImage: UIImage?, screenSize: CGSize, displayHeight: CGFloat) {
        if let baseImage = baseImage {
            if displayHeight < 0 {
                return
            }
            let aspect: CGFloat = screenSize.width / screenSize.height
            let imageSize = baseImage.size
            let imageScale: CGFloat = imageSize.height / screenSize.height
            
            let cropWidth: CGFloat = floor(aspect < 1.0 ? imageSize.width * aspect : imageSize.width)
            let cropHeight: CGFloat = floor(displayHeight * imageScale)
            
            let left: CGFloat = (imageSize.width - cropWidth) / 2
            let top: CGFloat = (imageSize.height - cropHeight) / 2
            
            let trimRect : CGRect = CGRectMake(left, top, cropWidth, cropHeight)
            self.image = baseImage.trim(trimRect: trimRect)
            self.frame = CGRectMake(0, 0, screenSize.width, displayHeight)
        }
    }
}

@IBDesignable
class CustomButtonAlpha: UIButton {
    
    @IBInspectable var treshold: CGFloat = 1.0 {
        didSet {
            if treshold > 1.0 {
                treshold = 1.0
            }
            if treshold < 0.0 {
                treshold = 0.0
            }
        }
    }
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        return self.alphaFromPoint(point) > treshold
    }
}