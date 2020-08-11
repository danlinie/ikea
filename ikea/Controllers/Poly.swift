//
//  Poly.swift
//  ikea
//
//  Created by Danlin Wang on 11/08/2020.
//  Copyright © 2020 Danlin Wang. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import Firebase

class Poly: UIViewController, ARSCNViewDelegate, UITableViewDataSource, UITableViewDelegate {
    
    var hudDisplay: MBProgressHUD!
    
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var tableView: UITableView!
    let configuration = ARWorldTrackingConfiguration()
    
    var itemsArray: [String] = []
    var selectedItem: String?
    var localTranslationPosition: CGPoint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        self.sceneView.delegate = self
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.registerGestureRecognizers()
        self.sceneView.autoenablesDefaultLighting = true
        
        listAllModels()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func registerGestureRecognizers() {
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panned))
        self.sceneView.addGestureRecognizer(panGestureRecognizer)
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(move))
        self.sceneView.addGestureRecognizer(longPressGestureRecognizer)
        
        self.sceneView.addGestureRecognizer(pinchGestureRecognizer)
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    
    @objc func panned(sender: UIPanGestureRecognizer) {
        if sender.state == .changed {
            guard let sceneView = sender.view as? ARSCNView else {return}
            let panLocation = sender.location(in: sceneView)
            let translation = sender.translation(in: sceneView)
            let hitTest = sceneView.hitTest(panLocation, options: nil)
            
            if !hitTest.isEmpty {
                let results = hitTest.first!
                let node = results.node
                let rotation = Float(translation.x) * (Float)(Double.pi) / 180
                node.eulerAngles.y = rotation
            }
        }
    }
    
    @objc func move(sender: UILongPressGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else {return}
        let holdLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(holdLocation, options: nil)
        if let results = hitTest.first {
            if sender.state == .began {
                localTranslationPosition = holdLocation
            } else if sender.state == .changed {
                let deltaX = (Float)(holdLocation.x - localTranslationPosition.x) / 1000
                let deltaY = (Float)(holdLocation.y - localTranslationPosition.y) / 1000
                
                let node = results.node
                node.localTranslate(by: SCNVector3(deltaX, 0, deltaY))
                localTranslationPosition = holdLocation
            }
        }
    }
    
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        if !hitTest.isEmpty {
            self.addItem(hitTestResult: hitTest.first!)
        }
    }
    
    @objc func pinch(sender: UIPinchGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let pinchLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(pinchLocation)
        
        if !hitTest.isEmpty {
            
            let results = hitTest.first!
            let node = results.node
            let pinchAction = SCNAction.scale(by: sender.scale, duration: 0)
            node.runAction(pinchAction)
            sender.scale = 1.0
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {return}
    }
    
    func centerPivot(for node: SCNNode) {
        let min = node.boundingBox.min
        let max = node.boundingBox.max
        node.pivot = SCNMatrix4MakeTranslation(
            min.x + (max.x - min.x)/2,
            min.y + (max.y - min.y)/2,
            min.z + (max.z - min.z)/2
        )
    }
    
    func listAllModels() {
            print("List all models")
            let storageReference = Storage.storage().reference().child("admin")
            storageReference.listAll { (result, err) in
                if let err = err {
                    print(err.localizedDescription)
                }
                
                for item in result.items {
                    let name = item.name.split(separator: ".")[0]
                    self.itemsArray.append(String(name))
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    
        func addItem(hitTestResult: ARHitTestResult) {
            if let selectedItem = self.selectedItem {
                
                downloadFile(item: selectedItem)
                
                let documentDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                
                if let documentDirectory = documentDirectories.first {
                    let fileURL = documentDirectory.appendingPathComponent("\(selectedItem).scn")
                    
                    do {
                        let scene = try SCNScene(url: fileURL, options: nil)
                        let node = (scene.rootNode.childNode(withName: selectedItem, recursively: false))!
                        let transform = hitTestResult.worldTransform
                        let thirdColumn = transform.columns.3
                        node.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
                        if selectedItem == "table" {
                            self.centerPivot(for: node)
                        }
                        self.sceneView.scene.rootNode.addChildNode(node)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath)
        cell.textLabel?.text = itemsArray[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let name = tableView.cellForRow(at: indexPath)?.textLabel?.text {
            selectedItem = name
        }
    }
    
    func downloadFile(item: String) {
        
        let reference = Storage.storage().reference().child("admin/\(item).scn")
        
        reference.getData(maxSize: 10 *  1024 * 1024) { (data, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            
            if let data = data {
                let documentDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                
                if let documentDirectory = documentDirectories.first {
                    let fileURL = documentDirectory.appendingPathComponent("\(item).scn")
                    
                    if !FileManager.default.fileExists(atPath: fileURL.path) {
                        self.hudDisplay = MBProgressHUD.showAdded(to: self.view, animated: true)
                        self.hudDisplay.label.text = "Downloading model"
                        
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
    
    
    @IBAction func resetPressed(_ sender: UIBarButtonItem) {
        restartSession()
    }
    
    func restartSession() {
        self.sceneView.session.pause()
        self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
}
