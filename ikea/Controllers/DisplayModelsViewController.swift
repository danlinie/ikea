//
//  DisplayModelsViewController.swift
//  ikea
//
//  Created by Danlin Wang on 02/08/2020.
//  Copyright © 2020 Danlin Wang. All rights reserved.
//

import UIKit
import Firebase

class DisplayModelsViewController: UIViewController, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    let db = Firestore.firestore()
    var models: [Model] = []
    var modelName: String?
    var modelRef: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        loadModels()
    }
    
    func loadModels() {
        db.collection(K.FBase.collectionName).addSnapshotListener { (querySnapshot, error) in
            self.models = []
            
            if let e = error {
                print(e.localizedDescription)
            } else {
                if let snapshotDocuments = querySnapshot?.documents {
                    for doc in snapshotDocuments {
                        let data = doc.data()
                        if let modelRef = data[K.FBase.nameField] as? String , let modelUploader = data[K.FBase.uploaderField] as? String {
                            if modelUploader == Auth.auth().currentUser?.email {
                                let modelName = String(modelRef.split(separator: ".")[0])
                                let newModel = Model(uploader: modelUploader, name: modelName)
                                self.models.append(newModel)
                            }
                            
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                                if self.models.count != 0 {
                                    let indexPath = IndexPath(row: self.models.count - 1, section: 0)
                                    self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func renderPressed(_ sender: Any) {
        self.performSegue(withIdentifier: K.renderSegue, sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == K.renderSegue {
            
            let destinationVC = segue.destination as! Loading3DModelsController
            
            destinationVC.modelName = modelName
            destinationVC.modelRef = modelRef
        }
    }
    
}

//MARK: - UITableViewDataSource protocol is responsible for populating the table view

extension DisplayModelsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = models[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath)
        cell.textLabel?.text = model.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let name = tableView.cellForRow(at: indexPath)?.textLabel?.text {
            modelName = name
            modelRef = name + "." + (Auth.auth().currentUser?.email)!
        }
        
    }
    
}
