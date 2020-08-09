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
    let configuration = ARWorldTrackingConfiguration()
    
    var modelName: String?
    var modelRef: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        
        sceneView.autoenablesDefaultLighting = true
        sceneView.delegate = self
        
        if let modelRef = modelRef {
            if !searchFile(modelRef: modelRef) {
                downloadFiles(modelRef: modelRef)
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: sceneView)
            
            let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
            
            if let hitResult = results.first {
                addModel(atLocation: hitResult, modelRef: self.modelRef!)
            }
        }
    }
    
    func addModel(atLocation: ARHitTestResult, modelRef: String) {
        let documentDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        if let documentDirectory = documentDirectories.first {
            
            let fileURL = documentDirectory.appendingPathComponent("\(modelRef).scn")
            
            do {
                let scene = try SCNScene(url: fileURL, options: nil)
                
                if let node = scene.rootNode.childNode(withName: modelName!, recursively: true) {
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
    
    func downloadFiles(modelRef: String) {
        
        self.hudDisplay = MBProgressHUD.showAdded(to:self.view, animated:true)
        self.hudDisplay.label.text = "Downloading model"
        
        let reference = Storage.storage().reference().child("scene/\(modelRef)")
        
        reference.getData(maxSize: 10 *  1024 * 1024) { (data, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            
            if let data = data {
                let documentDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                
                if let documentDirectory = documentDirectories.first {
                    let fileURL = documentDirectory.appendingPathComponent("\(modelRef).scn")
                    
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
    
    @IBAction func removeModel(_ sender: UIBarButtonItem) {
        restartSession()
    }
    
    func restartSession() {
        self.sceneView.session.pause()
        self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func searchFile(modelRef: String) -> Bool {
        print("searching documents")
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        let filePath = (url.appendingPathComponent("\(modelRef).scn")?.path)!
        print(filePath)
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: filePath)
    }
    
}
