//
//  ViewController.swift
//  IE_IOS
//
//  Created by 翁祥恩 on 2024/6/13.
//

import UIKit
import CoreML
import Vision


class ViewController: UIViewController {
    
    @IBOutlet var labelRuntime: UILabel!
    @IBOutlet var Image: UIImageView!
    @IBOutlet var imagePicker: UIPickerView!
    @IBOutlet var IEButton: UIButton!
    
    var model: CoreML_CPGANet_AE20FT?
    var modelexpe: CoreML_CPGANet_expe?
    var receivedVariable: String?
    var enhanceState = false
    
    var img_gallery:Array<String>! = nil
    var model_gallery:Array<String>! = nil
    var pickerGallery:Array<Array<String>>! = nil
    
    var i = 0
    var j = 0
    var showImageName:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Demo activate!!")
        print(model ?? "No model received")
        print(modelexpe ?? "No modelexpe received")
        print(receivedVariable ?? "No value received")
        imagePicker.dataSource = self
        imagePicker.delegate = self
        
        img_gallery = ["cat_224x224", "IMG_4582", "IMG_4563", "test", "low00721", "low00722", "low00723", "low00724"]
        model_gallery = ["Low-light Image Enhancement", "Exposure Correction"]
        pickerGallery = [
            img_gallery!, model_gallery!
        ]
        showImageName = img_gallery[i]
        
        Image.image = UIImage(named: showImageName!)
    }

    
    @IBAction func buttonIE(_ sender: Any) {
//        guard IEButton.currentTitle=="Enhance" else{
//            let start = CFAbsoluteTimeGetCurrent()
////            (model, modelexpe) = createModel()
//            
//            let diff = CFAbsoluteTimeGetCurrent() - start
//            print("Took \(diff) seconds")
//            IEButton.setTitle("Enhance", for: .normal)
//            return
//        }
        let start = CFAbsoluteTimeGetCurrent()
        useCoreMLModel()
        let diff = CFAbsoluteTimeGetCurrent() - start
        print("Took \(diff) seconds")
        if enhanceState{
            labelRuntime.text = String(format: "Took %.4f seconds", diff)
        }
    }
    
    @IBAction func pressToSelectImage(_ sender: UIButton) {
        i+=1
        if i>=img_gallery.count{
            i = i%img_gallery.count
        }
        changeImage(index: i)
        imagePicker.selectRow(i, inComponent: 0, animated: true)
        print("Forward")
    }
    @IBAction func pressToSelectBackImg(_ sender: UIButton) {
        i-=1
        if i<0{
            i = 0
        }
        changeImage(index: i)
        imagePicker.selectRow(i, inComponent: 0, animated: true)
        print("Backward")
    }
    
    func changeImage(index: Int) {
        showImageName = img_gallery[index]
        print(showImageName!)
        Image.image = UIImage(named: showImageName!)
        enhanceState = false
    }
    
//    func createModel() -> (CoreML_CPGANet_AE20FT?, CoreML_CPGANet_expe?){
//        
//        // Load CoreML model
//        guard let model = try? CoreML_CPGANet_AE20FT() else {
//            fatalError("Failed to load CoreML model.")
//        }
//        guard let modelexpe = try? CoreML_CPGANet_expe() else {
//            fatalError("Failed to load CoreML model.")
//        }
//        return (model, modelexpe)
//    }
    
    func modelPrediction(index: Int, pixelBuffer: CVPixelBuffer){
        switch index{
        case 0:
            // Prepare input for CoreML model
            guard let input = try? CoreML_CPGANet_AE20FTInput(colorImage: pixelBuffer) else {
                fatalError("Failed to create input.")
            }
            
            // Make prediction
            do {
                let prediction = try model!.prediction(input: input)
                // Process prediction result
                print(prediction.colorOutput)
                Image.image = imageFromPixelBuffer(pixelBuffer: prediction.colorOutput)
            } catch {
                fatalError("Failed to make prediction: \(error.localizedDescription)")
            }
        case 1:
            // Prepare input for CoreML model
            guard let input = try? CoreML_CPGANet_expeInput(colorImage: pixelBuffer) else {
                fatalError("Failed to create input.")
            }
            
            // Make prediction
            do {
                let prediction = try modelexpe!.prediction(input: input)
                // Process prediction result
                print(prediction.colorOutput)
                Image.image = imageFromPixelBuffer(pixelBuffer: prediction.colorOutput)
            } catch {
                fatalError("Failed to make prediction: \(error.localizedDescription)")
            }
        default:
            print("???")
        }
    }
    
    
    func useCoreMLModel() {
        guard !enhanceState else{
            Image.image = UIImage(named: showImageName!)
            enhanceState = false
            return
        }
        
        // Prepare input image
        guard let img = UIImage(named: showImageName!) else {
            fatalError("Image not found in assets.")
        }
        guard let pixelBuffer = pixelBufferFromImage(image: img) else {
            fatalError("Failed to create pixel buffer from image.")
        }
        modelPrediction(index: j, pixelBuffer: pixelBuffer)
        
        enhanceState = true
    }
}


import UIKit
import CoreVideo

func pixelBufferFromImage(image: UIImage) -> CVPixelBuffer? {
    guard let cgImage = image.cgImage else {
        return nil
    }
    
    let width = cgImage.width
    let height = cgImage.height
    
    var pixelBuffer: CVPixelBuffer?
    let attrs = [
        kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
        kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
    ] as CFDictionary
    CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
    
    guard let buffer = pixelBuffer else {
        return nil
    }
    
    CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
    let pixelData = CVPixelBufferGetBaseAddress(buffer)
    
    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(data: pixelData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
    
    guard let ctx = context else {
        return nil
    }
    
    ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    
    CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
    
    return buffer
}

func imageFromPixelBuffer(pixelBuffer: CVPixelBuffer) -> UIImage? {
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    let context = CIContext()
    
    if let cgImage = context.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))) {
        return UIImage(cgImage: cgImage)
    }
    
    return nil
}

extension ViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerGallery[component].count
    }
}

extension ViewController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerGallery[component][row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        switch component{
        case 0:
            i = row
            showImageName = img_gallery[i]
            Image.image = UIImage(named: showImageName!)
            enhanceState = false
        case 1:
            j = row
            print(model_gallery[j])
            enhanceState = false
        default:
            print("????")
        }
        
    }
}
