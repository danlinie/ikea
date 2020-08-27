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
    
    //var itemsArray: [String] = []
    var itemsArray = [String : String]()
    var modelNameArray: [String] = []
    
    var selectedItem: String?
    var localTranslationPosition: CGPoint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hudDisplay = MBProgressHUD.showAdded(to: self.sceneView, animated: true)
        self.hudDisplay.label.text = "Detecting Plane..."
        
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
        
        DispatchQueue.main.async {
            self.hudDisplay.label.text = "Plane Detected"
            self.hudDisplay.hide(animated: true, afterDelay: 1.0)
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
    
    func listAllModels() {
            print("List all models")
            let storageReference = Storage.storage().reference().child("admin")
            storageReference.listAll { (result, err) in
                if let err = err {
                    print(err.localizedDescription)
                }
                
                for item in result.items {
                    
                    item.getMetadata { (metadata, err) in
                        if let err = err {
                            print(err.localizedDescription)
                        }
                        
                        if let metadata = metadata {
                            if let name = metadata.name, let lastUpdatedTime = metadata.updated {
                                let name = String(name.split(separator: ".")[0])
                                let updatedTime = self.convertDateFormate(date: lastUpdatedTime)
                                self.itemsArray[name] = updatedTime
                                self.modelNameArray.append(name)
                                
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                }
                            }
                        }
                    }
                    
                    //let name = item.name.split(separator: ".")[0]
                    //self.itemsArray.append(String(name))
                }
                /*
                 DispatchQueue.main.async {
                     self.tableView.reloadData()
                 }
                 */
                
            }
        }
    
    func addItem(hitTestResult: ARHitTestResult) {
        if let item = self.selectedItem {
                
            //downloadFile(item: selectedItem)
            
            let reference = Storage.storage().reference().child("admin/\(item).scn")
            
            reference.getData(maxSize: 10 * 1024 * 1024) { (data, err) in
                if let err = err {
                    print(err.localizedDescription)
                }
                
                if let data = data {
                    let documentDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                    
                    if let documentDirectory = documentDirectories.first {
                        let fileURL = documentDirectory.appendingPathComponent("\(item).scn")
                        
                        if !FileManager.default.fileExists(atPath: fileURL.path) {
                            self.writeData(data: data, fileURL: fileURL)
                            print("Firebase File Saved")
                            
                            do {
                                let scene = try SCNScene(url: fileURL, options: nil)
                                for child in scene.rootNode.childNodes {
                                    if let nodeName = child.name {
                                        print(nodeName)
                                        if let node = scene.rootNode.childNode(withName: nodeName, recursively: true) {
                                            print("node created")
                                            node.position = SCNVector3(hitTestResult.worldTransform.columns.3.x, hitTestResult.worldTransform.columns.3.y, hitTestResult.worldTransform.columns.3.z)
                                            self.sceneView.scene.rootNode.addChildNode(node)
                                        }
                                    }
                                }
                            } catch {
                                print(error.localizedDescription)
                            }
                        } else {
                            print("File exists")
                            if let lastModificationDate = self.getFileModificationDate(fileURL: fileURL.path) {
                                let creationDate = self.convertDateFormate(date: lastModificationDate)
                                
                                if let updateDate = self.itemsArray[item] {
                                    let result = self.compareDates(creationDate: creationDate, lastUpdateDate: updateDate)
                                    
                                    if result {
                                        self.deleteFile(item: item)
                                        self.writeData(data: data, fileURL: fileURL)
                                        print("Firebase File Saved")
                                    }
                                    
                                    do {
                                        let scene = try SCNScene(url: fileURL, options: nil)
                                        for child in scene.rootNode.childNodes {
                                            if let nodeName = child.name {
                                                print(nodeName)
                                                if let node = scene.rootNode.childNode(withName: nodeName, recursively: true) {
                                                    print("node created")
                                                    node.position = SCNVector3(hitTestResult.worldTransform.columns.3.x, hitTestResult.worldTransform.columns.3.y, hitTestResult.worldTransform.columns.3.z)
                                                    self.sceneView.scene.rootNode.addChildNode(node)
                                                }
                                            }
                                        }
                                    } catch {
                                        print(error.localizedDescription)
                                    }
                                    
                                }
                            }
                        }
                        
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return modelNameArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath)
        let name = modelNameArray[indexPath.row]
        if let updatedDate = itemsArray[name] {
            cell.textLabel?.text = "\(name) (last updated: \(updatedDate))"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let name = tableView.cellForRow(at: indexPath)?.textLabel?.text {
            selectedItem = String(name.split(separator: " ")[0])
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
    
    func convertDateFormate(date: Date) -> String {
        var lastUpdatedDate: String
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        lastUpdatedDate = dateFormatter.string(from: date)
        return lastUpdatedDate
    }
    
    func writeData(data: Data, fileURL: URL) {
        hudDisplay = MBProgressHUD.showAdded(to: self.view, animated: true)
        hudDisplay.label.text = "Downloading model"
        
        let dataNS: NSData? = data as NSData
        try! dataNS?.write(to: fileURL, options: .atomic)
        
        DispatchQueue.main.async {
            self.hudDisplay.hide(animated: true, afterDelay: 0.3)
        }
    }
    
    func getFileModificationDate(fileURL: String) -> Date? {
        var fileModificationDate: Date? = nil
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL)
            fileModificationDate = attributes[FileAttributeKey("NSFileModificationDate")] as? Date
            
        } catch {
            print("Error in retrieving file modification date.")
        }
        return fileModificationDate
    }
    
    func deleteFile(item: String) {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        if let filePath = (url.appendingPathComponent("\(item).scn")?.path) {
            let fileManager = FileManager.default
            do {
                try fileManager.removeItem(atPath: filePath)
                print("Document successfully removed!")
            } catch {
                print("Error in deleting the model")
            }
        }
    }
    
    func compareDates(creationDate: String, lastUpdateDate: String) -> Bool {
        
        var result = false
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let createdDate = dateFormatter.date(from: creationDate)
        let updatedDate = dateFormatter.date(from: lastUpdateDate)
        
        if let createDate = createdDate, let updateDate = updatedDate {
            let comparisonResult = createDate.compare(updateDate)
            if comparisonResult == ComparisonResult.orderedAscending {
                result = true
            }
        }
        
        return result
    }
}
