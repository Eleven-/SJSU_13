//
//  CameraControlViewController.swift
//  BLE Mission-Center
//
//  Created by 悠二 on 11/22/15.
//  Copyright © 2015 Yuji. All rights reserved.
//

import UIKit

class CameraControlViewController: UIViewController, BLECenterDelegate, CubeSatCommandCenterCameraDelegate {

    @IBOutlet weak var compressionRatioStepper: UIStepper! {
        didSet {
            compressionRatioStepper.value = 1.0
        }
    }
    
    @IBOutlet weak var compressRatioLabel: UILabel!
    @IBOutlet weak var cameraPhotoView: UIImageView!
    
    @IBOutlet weak var LPCStatus: UILabel!
    
    @IBOutlet weak var currentProcess: UILabel!
    
    
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
        BLEManager.defaultManager.commandCenter?.setCompressionRatio(ratio)
    }
    
    @IBAction func enterPowerSaving(sender: UISwitch) {
        BLEManager.defaultManager.commandCenter?.enterPowerSaving(sender.on)
    }
    
    @IBAction func setResulotion(sender: UISegmentedControl) {
        var resolusion: Resolution!
        switch sender.selectedSegmentIndex {
        case 0:
            resolusion = Resolution._160x120
        case 1:
            resolusion = Resolution._320x240
        case 2:
            resolusion = Resolution._640x480
        default: break
        }
        BLEManager.defaultManager.commandCenter?.setResolution(resolusion)
    }
    
    
    
    @IBAction func takePicture(sender: AnyObject) {
        BLEManager.defaultManager.commandCenter?.requestForImage()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        BLEManager.defaultManager.initalizeManager()
        BLEManager.defaultManager.delegate = self
        BLEManager.defaultManager.commandCenter?.cameraDelegate = self
    }
    
    func didRecivedWholeJPEGCamera(parser: CubeSatCommandCenter, JPEGData: NSData) {
        let img = UIImage(data: JPEGData)
        print("JPEGDATA: \(JPEGData)")
        cameraPhotoView.image = img
    }
    
    func LPCStatusDidUpdate(center: CubeSatCommandCenter, Status: String) {
        LPCStatus.text = Status
        print(Status)
    }
    
    func currentProcessDidUpdate(center: CubeSatCommandCenter, process: String) {
        currentProcess.text = process
        print(process)
    }
 
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
