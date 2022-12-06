//
//  GameViewController.swift
//  g-foodmaster
//
//  Created by LZW on 2022/5/24.
//

import UIKit
import QuartzCore
import SceneKit
import CoreML
//import SwiftMath


class GameViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    var imageView:UIImageView!
    var imagePickerController:UIImagePickerController!
    var classifier:yolov5!
    var wrongflag = 0
    @IBAction func takeaphoto(_ sender: UIButton) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                print("No Camera Detected")
                return
            }

        self.imagePickerController = UIImagePickerController()
            
        self.imagePickerController.sourceType = .camera
        self.imagePickerController.delegate = self

            show(self.imagePickerController, sender: self)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let image = info[.originalImage] as! UIImage //获取拍摄的照片
        let image_resized = MaxResizeImage(sourceImage: image, resize: CGSize(width: 640, height: 640))
        let imgbuffer = buffer(from: image_resized)
        UIImageWriteToSavedPhotosAlbum(image_resized, nil, nil, nil)
        self.dismiss(animated: true, completion: nil)
        
        let input = yolov5Input(image:imgbuffer!)
        var output:yolov5Output!
        do{
            output = try self.classifier.prediction(input:input)}
        catch{
            print(error)
            self.wrongflag = 1
        }
        
        
        var message:String!
        if let i = output{
            let featurename = i.featureNames
            var yolodict = [String:MLFeatureValue]()
            for aname in featurename{
                yolodict.updateValue(i.featureValue(for: aname)!, forKey:aname )
            }
            message = "\(yolodict)"
        }
        else{
            message = "Photo Unavaliable"
        }
        if wrongflag==1{message = "Sth Wrong"}
        
        let alert = UIAlertController(title: "Food Recognition", message: message, preferredStyle: .alert)
        
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
    }
    
    public func MaxResizeImage(sourceImage:UIImage, resize:CGSize)->UIImage
    {
        let sourceSize = sourceImage.size
        let maxResizeFactor = max(resize.width / sourceSize.width, resize.height / sourceSize.height)
        if (maxResizeFactor > 1) {return sourceImage}
        let width = maxResizeFactor * sourceSize.width
        let height = maxResizeFactor * sourceSize.height
        UIGraphicsBeginImageContext(resize)
        sourceImage.draw( in: CGRect (x: 0, y: 0, width: width, height: height))
        let  resizeImage: UIImage  =  UIGraphicsGetImageFromCurrentImageContext ()!
        UIGraphicsEndImageContext ()
        return  resizeImage;
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]
            
            // get its material
            let material = result.node.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = UIColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = UIColor.red
            
            SCNTransaction.commit()
        }
    }
    func buffer(from image: UIImage) -> CVPixelBuffer? {
      let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
      var pixelBuffer : CVPixelBuffer?
      let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
      guard (status == kCVReturnSuccess) else {
        return nil
      }

      CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
      let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

      let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
      let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

      context?.translateBy(x: 0, y: image.size.height)
      context?.scaleBy(x: 1.0, y: -1.0)

      UIGraphicsPushContext(context!)
      image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
      UIGraphicsPopContext()
      CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

      return pixelBuffer
    }
    
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
}
