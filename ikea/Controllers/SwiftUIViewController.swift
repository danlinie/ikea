//
//  SwiftUIViewController.swift
//  ikea
//
//  Created by Danlin Wang on 24/07/2020.
//  Copyright © 2020 Danlin Wang. All rights reserved.
//

import UIKit
import SwiftUI

class SwiftUIViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBSegueAction func addSwiftUIView(_ coder: NSCoder) -> UIViewController? {
        return UIHostingController(coder: coder, rootView: ContentView())
    }
    
}
