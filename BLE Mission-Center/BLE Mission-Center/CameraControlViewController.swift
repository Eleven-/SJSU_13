//
//  CameraControlViewController.swift
//  BLE Mission-Center
//
//  Created by 悠二 on 11/22/15.
//  Copyright © 2015 Yuji. All rights reserved.
//

import UIKit

class CameraControlViewController: UIViewController, BLECenterDelegate {

    @IBOutlet weak var compressionRatioStepper: UIStepper! {
        didSet {
            compressionRatioStepper.value = 1.0
        }
    }
    
    @IBOutlet weak var compressRatioLabel: UILabel!
    @IBOutlet weak var cameraPhotoView: UIImageView!
    
    @IBAction func reset(sender: AnyObject) {
        BLEManager.defaultManager.commandCenter?.resetCamera()
    }

    @IBAction func changeCompressRatio(sender: UIStepper) {
        var ratio: compressRatio!
        switch sender.value {
        case 0: compressRatioLabel.text = "0%"
            ratio = compressRatio.zero
        case 1:
            compressRatioLabel.text = "25%"
            ratio = compressRatio._25_percent
        case 2:
            compressRatioLabel.text = "36%"
            ratio = compressRatio._36_percent
        case 3:
            compressRatioLabel.text = "50%"
            ratio = compressRatio._50_percent
        case 4:
            compressRatioLabel.text = "75%"
            ratio = compressRatio._75_percent
        default: break
        }
        BLEManager.defaultManager.commandCenter?.setCompressionRation(ratio)
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
