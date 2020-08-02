//
//  LoginViewController.swift
//  ikea
//
//  Created by Danlin Wang on 01/08/2020.
//  Copyright © 2020 Danlin Wang. All rights reserved.
//

import UIKit
import Firebase
import PopupDialog

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBAction func loginPressed(_ sender: UIButton) {
        if let email = emailTextField.text, let password = passwordTextField.text {
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
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
                    self.performSegue(withIdentifier: K.loginSegue, sender: self)
                }
            }
        }
    }
    
}
