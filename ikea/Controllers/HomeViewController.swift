//
//  HomeViewController.swift
//  ikea
//
//  Created by Danlin Wang on 25/07/2020.
//  Copyright © 2020 Danlin Wang. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        navigationController?.isNavigationBarHidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}
