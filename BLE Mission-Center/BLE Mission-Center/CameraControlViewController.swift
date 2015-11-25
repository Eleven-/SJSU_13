//
//  CameraControlViewController.swift
//  BLE Mission-Center
//
//  Created by 悠二 on 11/22/15.
//  Copyright © 2015 Yuji. All rights reserved.
//

import UIKit

class CameraControlViewController: UIViewController, BLECenterDelegate {

    @IBOutlet weak var cameraPhotoView: UIImageView!
    
    @IBAction func reset(sender: AnyObject) {
        BLEManager.defaultManager.commandCenter?.resetCamera()
    }

    @IBAction func takePicture(sender: AnyObject) {
        BLEManager.defaultManager.commandCenter?.requestForImage()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        BLEManager.defaultManager.initalizeManager()
        BLEManager.defaultManager.delegate = self
    }
    
    func didRecivedWholeJPEGCamera(parser: CubeSatCommandCenter, JPEGData: NSData) {
        let img = UIImage(data: JPEGData)
        print("JPEGDATA: \(JPEGData)")
        cameraPhotoView.image = img
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
