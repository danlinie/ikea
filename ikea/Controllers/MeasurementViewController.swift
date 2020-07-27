//
//  MeasurementViewController.swift
//  ikea
//
//  Created by Danlin Wang on 29/06/2020.
//  Copyright © 2020 Danlin Wang. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class MeasurementViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var lengthLabel: UILabel!
    @IBOutlet weak var heightLabel: UILabel!
    @IBOutlet weak var widthLabel: UILabel!
    
    var dotNodes = [SCNNode]()
    var textNode = SCNNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
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
        
        if dotNodes.count >= 2 {
            for dot in dotNodes {
                dot.removeFromParentNode()
            }
            dotNodes = [SCNNode]()
        }
        
        if let touchLocation = touches.first?.location(in: sceneView) {
            let hitTestResults = sceneView.hitTest(touchLocation, types: .featurePoint)
            
            if let hitResult = hitTestResults.first {
                addDot(at: hitResult)
            }
        }
    }
    
    func addDot(at hitResult: ARHitTestResult) {
        let dotGeometry = SCNSphere(radius: 0.005)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        dotGeometry.materials = [material]
        
        let dotNode = SCNNode(geometry: dotGeometry)
        
        dotNode.position = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)
        
        sceneView.scene.rootNode.addChildNode(dotNode)
        
        dotNodes.append(dotNode)
        
        if dotNodes.count >= 2 {
            calculate()
        }
    }
    
    func calculate() {
        let start = dotNodes[0]
        let end = dotNodes[1]
        
        //distance = √ ((x2-x1)^2 + (y2-y1)^2 + (z2-z1)^2
        let length = end.position.x - start.position.x
        let height = end.position.y - start.position.y
        let width = end.position.z - start.position.z
        let diagonal = sqrt(pow(length, 2) + pow(height, 2) + pow(width, 2))
        
        DispatchQueue.main.async {
            self.lengthLabel.text = String(format: "%.2f", abs(length)) + "m"
            self.heightLabel.text = String(format: "%.2f", abs(height)) + "m"
            self.widthLabel.text = String(format: "%.2f", abs(length)) + "m"
        }
        
        updateText(text: "\(abs(diagonal))")
    }
    
    func updateText(text: String) {
        textNode.removeFromParentNode()
        
        let textGeometry = SCNText(string: text, extrusionDepth: 0.4)
        
        textGeometry.firstMaterial?.diffuse.contents = UIColor.red
        
        textNode = SCNNode(geometry: textGeometry)
        
        textNode.position = SCNVector3(0, 0.01, -0.1)
        textNode.scale = SCNVector3(0.002, 0.002, 0.002)
        
        sceneView.scene.rootNode.addChildNode(textNode)
    }
    
}
