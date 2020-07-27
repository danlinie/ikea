//
//  ViewController.swift
//  ikea
//
//  Created by Danlin Wang on 08/06/2020.
//  Copyright © 2020 Danlin Wang. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, ARSCNViewDelegate {

    let itemsArray: [String] = ["cup", "vase", "boxing", "table"]
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var itemsCollectionView: UICollectionView!
    var selectedItem: String?
    
    var hudDisplay: MBProgressHUD!
    var localTranslationPosition: CGPoint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        self.hudDisplay = MBProgressHUD.showAdded(to: self.sceneView, animated: true)
        self.hudDisplay.label.text = "Detecting Plane..."

        self.itemsCollectionView.dataSource = self
        self.itemsCollectionView.delegate = self
        self.sceneView.delegate = self
        
        self.registerGestureRecognizers()
        self.sceneView.autoenablesDefaultLighting = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let configuration = ARWorldTrackingConfiguration()
        
        //configuration.planeDetection = [.horizontal, .vertical]
        
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
        //let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(rotate))
        //longPressGestureRecognizer.minimumPressDuration = 0.1
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panned))
        self.sceneView.addGestureRecognizer(panGestureRecognizer)
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(move))
        self.sceneView.addGestureRecognizer(longPressGestureRecognizer)
        
        //self.sceneView.addGestureRecognizer(longPressGestureRecognizer)
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
        
        DispatchQueue.main.async {
            self.hudDisplay.label.text = "Plane Detected"
            self.hudDisplay.hide(animated: true, afterDelay: 1.0)
        }
    }
    
    @objc func rotate(sender: UILongPressGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let holdLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(holdLocation)
        if !hitTest.isEmpty {
            
            let result = hitTest.first!
            if sender.state == .began {
                let rotation = SCNAction.rotateBy(x: 0, y: CGFloat(360.degreesToRadians), z: 0, duration: 1)
                let forever = SCNAction.repeatForever(rotation)
                result.node.runAction(forever)
            } else if sender.state == .ended {
                result.node.removeAllActions()
            }
        }
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
    
    func addItem(hitTestResult: ARHitTestResult) {
        if let selectedItem = self.selectedItem {
            let scene = SCNScene(named: "Assets/\(selectedItem).scn")
            let node = (scene?.rootNode.childNode(withName: selectedItem, recursively: false))!
            let transform = hitTestResult.worldTransform
            let thirdColumn = transform.columns.3
            node.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
            if selectedItem == "table" {
                self.centerPivot(for: node)
            }
            self.sceneView.scene.rootNode.addChildNode(node)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemsArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "item", for: indexPath) as! itemCell
        cell.itemLabel.text = self.itemsArray[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.contentView.backgroundColor = UIColor.green
        self.selectedItem = itemsArray[indexPath.row]
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.contentView.backgroundColor = UIColor.orange
    }
}

extension Int {
    var degreesToRadians: Double {return Double(self) * .pi/180}
}
