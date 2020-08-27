//
//  SwiftUIViewController.swift
//  ikea
//
//  Created by Danlin Wang on 24/07/2020.
//  Copyright © 2020 Danlin Wang. All rights reserved.
//

import SwiftUI
import Firebase
import MobileCoreServices

struct ContentView: View {
    
    //let db = Firestore.firestore()
    
    @State var show = false
    @State var alert = false
    @State var uploadAlert = false
    @State var duplicateAlert = false
    
    @State var fileName = ""
    
    var body: some View {
        
        Button(action: {
            
            self.show.toggle()
            
        }) {
            
            Text("Document Picker")
            
        }
            
        .sheet(isPresented: $show) {
            DocumentPicker(alert: self.$alert, uploadAlert: self.$uploadAlert, duplicateAlert: self.$duplicateAlert, fileName: self.$fileName)
        }
       
        .alert(isPresented: $alert) {
            var message: String? = nil
            if self.uploadAlert {
                message = "Uploaded successfully"
            } else if self.duplicateAlert {
                message = "There is already a file named \(fileName).scn in the database. Delete the file from Browse Catalogue first or rename the file, and upload it again."
            }
            
            return Alert(title: Text("Message"), message: Text(message!), dismissButton: .default(Text("Dismiss")))
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    
    func makeCoordinator() -> DocumentPicker.Coordinator {
        return DocumentPicker.Coordinator(parent1: self)
    }
    
    @Binding var alert: Bool
    @Binding var uploadAlert: Bool
    @Binding var duplicateAlert: Bool
    
    @Binding var fileName: String
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<DocumentPicker>) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(documentTypes: [String(kUTTypeData)], in: .open)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: UIViewControllerRepresentableContext<DocumentPicker>) {
        
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        
        var parent: DocumentPicker
        
        init(parent1: DocumentPicker) {
            parent = parent1
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            let db = Firestore.firestore()
            let bucket = Storage.storage().reference()
            
            if let item = urls.first?.deletingPathExtension().lastPathComponent, let modelUploader = Auth.auth().currentUser?.email {
                
                self.parent.fileName = item
                
                let modelName = "\(item)-\(modelUploader)"
                let storageReference = "scene/\(modelName)"
                
                //check if the model already exists in firebase firestore
                let docReference = db.collection(K.FBase.collectionName).document(modelName)
                
                docReference.getDocument { (document, error) in
                    if let document = document {
                        if document.exists {
                            self.parent.alert.toggle()
                            self.parent.duplicateAlert.toggle()
                        } else {
                            docReference.setData([K.FBase.nameField: item, K.FBase.uploaderField: modelUploader]) { (err) in
                                if let e = err {
                                    print(e.localizedDescription)
                                } else {
                                    print("Successfully saved data")
                                }
                            }
                            
                            bucket.child(storageReference).putFile(from: urls.first!, metadata: nil) { (_, err) in
                                if let e = err {
                                    print(e.localizedDescription)
                                    return
                                }
                                
                                print("success")
                                self.parent.alert.toggle()
                                self.parent.uploadAlert.toggle()
                            }
                        }
                    }
                }
            }
        }
    }
}
