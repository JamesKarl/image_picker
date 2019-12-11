//
//  TesViewController.swift
//  image_picker
//
//  Created by 田耀琦 on 2019/12/10.
//

import UIKit

class TesViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.purple
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        var vc:UIViewController = self.presentingViewController!;
        while !(vc is FlutterViewController) {
            vc = vc.presentingViewController!;
        }
        vc.dismiss(animated: true, completion: nil);
    }
    
    
}
