//
//  RegisterViewController.swift
//  ikea
//
//  Created by Danlin Wang on 01/08/2020.
//  Copyright © 2020 Danlin Wang. All rights reserved.
//

import UIKit
import Firebase
import PopupDialog

class RegisterViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBAction func registerPressed(_ sender: UIButton) {
        if let email = emailTextField.text, let password = passwordTextField.text {
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let e = error {
                    let title: String? = nil
                    let message = e.localizedDescription
                    let popup = PopupDialog(title: title, message: message)
                    let button = DefaultButton(title: "OK", dismissOnTap: true) {
                        print(message)
                    }
                    popup.addButton(button)
                    self.present(popup, animated: true, completion: nil)
                } else {
                    
                    self.performSegue(withIdentifier: K.registerSegue, sender: self)
                    
                }
            }
        }
    }
    
}
