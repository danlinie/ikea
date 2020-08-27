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
import PopupDialog

class Loading3DModelsController: UIViewController, ARSCNViewDelegate {
    
    var hudDisplay: MBProgressHUD!
    
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    
    var modelName: String?
    var modelRef: String?
    var localTranslationPosition: CGPoint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.autoenablesDefaultLighting = true
        sceneView.delegate = self
        
        registerGestureRecognizer()
        
        if let modelRef = modelRef {
            if !searchFile(modelRef: modelRef) {
                downloadFiles(modelRef: modelRef)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configuration.planeDetection = .horizontal

        sceneView.session.run(configuration)
        
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func registerGestureRecognizer() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panned))
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(move))
        
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        self.sceneView.addGestureRecognizer(pinchGestureRecognizer)
        self.sceneView.addGestureRecognizer(panGestureRecognizer)
        self.sceneView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        if let hitResult = hitTest.first {
            addModel(atLocation: hitResult, modelRef: self.modelRef!)
        }
    }
    
    func addModel(atLocation: ARHitTestResult, modelRef: String) {
        let documentDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        if let documentDirectory = documentDirectories.first {
            
            let fileURL = documentDirectory.appendingPathComponent("\(modelRef).scn")
            
            do {
                let scene = try SCNScene(url: fileURL, options: nil)
                
                if scene.rootNode.childNodes.count == 1 {
                    self.createScene(scene: scene, atLocation: atLocation)
                } else {
                    let title: String? = nil
                    let message = "Unable to render the asset because more than one child node are detected. Please check."
                    let popup = PopupDialog(title: title, message: message)
                    let button = DefaultButton(title: "OK", dismissOnTap: true) {
                        print(message)
                    }
                    popup.addButton(button)
                    self.present(popup, animated: true, completion: nil)
                }
            } catch {
                print(error.localizedDescription)
            }
            
        }
    }
    
    func createScene(scene: SCNScene, atLocation: ARHitTestResult) {
        for child in scene.rootNode.childNodes {
            if let nodeName = child.name {
                print(nodeName)
                if let node = scene.rootNode.childNode(withName: nodeName, recursively: true) {
                    print("node created")
                    node.position = SCNVector3(atLocation.worldTransform.columns.3.x, atLocation.worldTransform.columns.3.y, atLocation.worldTransform.columns.3.z)
                    self.sceneView.scene.rootNode.addChildNode(node)
                }
            }
        }
    }
    
    @objc func pinch(sender: UIPinchGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let pinchLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(pinchLocation)
        
        if let hitResult = hitTest.first {
            let node = hitResult.node
            let pinchAction = SCNAction.scale(by: sender.scale, duration: 0)
            node.runAction(pinchAction)
            sender.scale = 1.0
        }
    }
    
    @objc func panned(sender: UIPanGestureRecognizer) {
        if sender.state == .changed {
            let sceneView = sender.view as! ARSCNView
            let panLocation = sender.location(in: sceneView)
            let translation = sender.translation(in: sceneView)
            let hitTest = sceneView.hitTest(panLocation, options: nil)
            
            if let hitResult = hitTest.first {
                let node = hitResult.node
                let rotation = Float(translation.x) * (Float)(Double.pi) / 180
                node.eulerAngles.y = rotation
            }
        }
    }
    
    
    @objc func move(sender: UILongPressGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let holdLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(holdLocation, options: nil)
        if let hitResult = hitTest.first {
            if sender.state == .began {
                localTranslationPosition = holdLocation
            } else if sender.state == .changed {
                let deltaX = (Float)(holdLocation.x - localTranslationPosition.x) / 1000
                let deltaY = (Float)(holdLocation.y - localTranslationPosition.y) / 1000
                    
                let node = hitResult.node
                node.localTranslate(by: SCNVector3(deltaX, 0, deltaY))
                localTranslationPosition = holdLocation
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
