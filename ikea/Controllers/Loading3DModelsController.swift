//
//  Loading3DModelsController.swift
//  ikea
//
//  Created by Danlin Wang on 24/07/2020.
//  Copyright © 2020 Danlin Wang. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import Firebase

class Loading3DModelsController: UIViewController, ARSCNViewDelegate {
    
    var hudDisplay: MBProgressHUD!
    
    @IBOutlet weak var sceneView: ARSCNView!
    var modelName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        sceneView.autoenablesDefaultLighting = true
        sceneView.delegate = self
        
        if modelName != nil {
            print(modelName!)
            downloadFiles(modelName: modelName!)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: sceneView)
            
            let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
            
            if let hitResult = results.first {
                addModel(atLocation: hitResult, modelName:self.modelName!)
            }
        }
    }
    
    func addModel(atLocation: ARHitTestResult, modelName: String) {
        let documentDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        if let documentDirectory = documentDirectories.first {
            
            let fileURL = documentDirectory.appendingPathComponent("\(modelName).scn")
            
            do {
                let scene = try SCNScene(url: fileURL, options: nil)
                
                if let node = scene.rootNode.childNode(withName: modelName, recursively: true) {
                    node.position = SCNVector3(atLocation.worldTransform.columns.3.x, atLocation.worldTransform.columns.3.y, atLocation.worldTransform.columns.3.z)
                    self.sceneView.scene.rootNode.addChildNode(node)
                }
            } catch {
                print(error.localizedDescription)
            }
            
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {return}
    }
    
    func downloadFiles(modelName: String) {
        
        self.hudDisplay = MBProgressHUD.showAdded(to:self.view, animated:true)
        self.hudDisplay.label.text = "Downloading model"
        
        let reference = Storage.storage().reference().child("scene/\(modelName)")
        
        reference.getData(maxSize: 10 *  1024 * 1024) { (data, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            
            if let data = data {
                let documentDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                
                if let documentDirectory = documentDirectories.first {
                    let fileURL = documentDirectory.appendingPathComponent("\(modelName).scn")
                    
                    let dataNS: NSData? = data as NSData
                    
                    try! dataNS?.write(to: fileURL, options: .atomic)
                    
                    DispatchQueue.main.async {
                        self.hudDisplay.hide(animated: true, afterDelay: 1.0)
                    }
                    
                    print("Firebase File Saved")
                }
            }
        }
    }
    
}
