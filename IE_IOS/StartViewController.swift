//
//  StartViewController.swift
//  IE_IOS
//
//  Created by 翁祥恩 on 2024/6/20.
//

import UIKit
import Foundation
import CoreML


class StartViewController: UIViewController {
    
    var model: CoreML_CPGANet_AE20FT?
    var modelexpe: CoreML_CPGANet_expe?
    var sharedVariable: String = "Hello, SecondVC!"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("App activate!!")
        
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: false)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func startButton(_ sender: UIButton) {
        performSegue(withIdentifier: "MainMenu", sender: self)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tabBarController = segue.destination as? UITabBarController {
            if let viewControllers = tabBarController.viewControllers {
                (model, modelexpe) = createModel()
                if let destinationVC = viewControllers[0] as? ViewController {
                    (model, modelexpe) = createModel()
                    destinationVC.receivedVariable = sharedVariable
                    destinationVC.model = model
                    destinationVC.modelexpe = modelexpe
                }
                if let destinationVC = viewControllers[1] as? CameraViewController {
                    destinationVC.receivedVariable = sharedVariable
                    destinationVC.model = model
                    destinationVC.modelexpe = modelexpe
                }
            }
            tabBarController.selectedIndex = 3 // Switch to the third tab
        }
//        if let destinationVC = segue.destination as? ViewController {
//            (model, modelexpe) = createModel()
//            destinationVC.model = model
//            destinationVC.modelexpe = modelexpe
//            destinationVC.receivedVariable = sharedVariable
//        }
    }
    
    func createModel() -> (CoreML_CPGANet_AE20FT?, CoreML_CPGANet_expe?){
        
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndGPU
        
        // Load CoreML model
        guard let model = try? CoreML_CPGANet_AE20FT(configuration: config) else {
            fatalError("Failed to load CoreML model.")
        }
        guard let modelexpe = try? CoreML_CPGANet_expe(configuration: config) else {
            fatalError("Failed to load CoreML model.")
        }
        return (model, modelexpe)
    }
    
    @objc func fireTimer() {
        print("Timer fired!")
        performSegue(withIdentifier: "MainMenu", sender: self)
    }
    
}

//@available(iOS 17.0, *)
//@Observable
//class ObservedModel {
//    var model: CoreML_CPGANet_AE20FT?
//    var modelexpe: CoreML_CPGANet_expe?
//    
//    init() {
//        self.model = try? CoreML_CPGANet_AE20FT()
//        self.modelexpe = try? CoreML_CPGANet_expe()
//    }
//}
