//
//  CameraViewController.swift
//  IE_IOS
//
//  Created by 翁祥恩 on 2024/6/20.
//

import UIKit

class CameraViewController: UIViewController {

    @IBOutlet var modelSwitch: UISwitch!
    @IBOutlet var labelRuntime: UILabel!
    @IBOutlet weak var cameraImage: UIImageView!
    
    var showImage: UIImage?
    var model: CoreML_CPGANet_AE20FT?
    var modelexpe: CoreML_CPGANet_expe?
    var receivedVariable: String?
    var enhanceState = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        print("App activate!!")
        print(model ?? "No model received")
        print(modelexpe ?? "No modelexpe received")
        print(receivedVariable ?? "No value received")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
//        showImage = nil
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func cameraPressButton(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.sourceType = .camera
            imagePicker.delegate = self
//            imagePicker.videoQuality = .typeIFrame1280x720
            
            present(imagePicker, animated: true, completion: nil)
        } else {
            // Handle the case where the camera is not available (e.g., simulator)
            let alert = UIAlertController(title: "Error", message: "Camera not available", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func albumPressButton(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
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
    
    func useCoreMLModel() {
        // Prepare input image
        guard var img = showImage else{
            return
        }
        
        if enhanceState {
            cameraImage.image = showImage
            enhanceState = false
            return
        }
        img = fixOrientation(of: img)
        
        guard let pixelBuffer = pixelBufferFromImage(image: img) else {
            fatalError("Failed to create pixel buffer from image.")
        }
        let i = modelSwitch.isOn ? 1 : 0
        modelPrediction(index: i, pixelBuffer: pixelBuffer)
        
        enhanceState = true
    }
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
                cameraImage.image = imageFromPixelBuffer(pixelBuffer: prediction.colorOutput)
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
                cameraImage.image = imageFromPixelBuffer(pixelBuffer: prediction.colorOutput)
            } catch {
                fatalError("Failed to make prediction: \(error.localizedDescription)")
            }
        default:
            print("???")
        }
    }
    func imageFromPixelBuffer(pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        if let cgImage = context.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))) {
            return UIImage(cgImage: cgImage)
        }
        
        return nil
    }

    func fixOrientation(of image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else {
            return image
        }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return normalizedImage
    }

}
extension CameraViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        switch picker.sourceType{
        case .camera:
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                cameraImage.image = image
                showImage = image
            }
        case .photoLibrary:
            print("\(info)")
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                cameraImage.image = image
                showImage = image
            }
        default:
            return
        }
        picker.dismiss(animated: true, completion: nil)
        
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
