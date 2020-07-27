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
    
    @State var show = false
    @State var alert = false
    
    var body: some View {
        
        Button(action: {
            
            self.show.toggle()
            
        }) {
            
            Text("Document Picker")
            
        }
            
        .sheet(isPresented: $show) {
            DocumentPicker(alert: self.$alert)
        }
       
        .alert(isPresented: $alert) {
            Alert(title: Text("Message"), message: Text("Uploaded successfully"), dismissButton: .default(Text("Dismiss")))
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
            
            let bucket = Storage.storage().reference()
            
            if let item = urls.first?.deletingPathExtension().lastPathComponent {
                let storageReference = "scene/\(item)"
                
                bucket.child(storageReference).putFile(from: urls.first!, metadata: nil) { (_, err) in
                    if err != nil {
                        print(err?.localizedDescription)
                        return
                    }
                    
                    print("success")
                    self.parent.alert.toggle()
                }
            }
            
        }
        
    }
}
