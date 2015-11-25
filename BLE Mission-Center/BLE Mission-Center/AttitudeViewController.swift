//
//  AttitudeViewController.swift
//  BLE Mission-Center
//
//  Created by Kathryn W. Ng on 11/24/15.
//  Copyright © 2015 Yuji. All rights reserved.
//

import UIKit
import CoreBluetooth

class AttitudeViewController: UIViewController, CubeSatCommandCenterAttitudeDelegate {
    
    static let CmdSetAttitude: UInt8  = 0x42
    static let CmdGetAttitude: UInt8  = 0x41
    
    @IBOutlet weak var SetAttitudeLabel: UILabel!
    @IBOutlet weak var GetAttitudeLabel: UILabel!
    
    @IBOutlet weak var SetDegreesField: UITextField!
    @IBOutlet weak var GetDegreesLabel: UILabel!
    
    
    @IBOutlet weak var SetAttitudeButton: UIButton!
    @IBOutlet weak var GetAttitudeButton: UIButton!
    
    @IBOutlet weak var AttitudeActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var AttitudeIndicatorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        // self.SetAttitudeButton.setTitle("Get Attitude", forState: UIControlState.Normal)
        //BLEManager.defaultManager.initalizeManager()
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    // Push button sendGetAttitude cmd 0x42
    @IBAction func getAttitude(sender: UIButton) {
        BLEManager.defaultManager.commandCenter?.writeCommand([AttitudeViewController.CmdGetAttitude])
        
        NSLog("getAttitude button %X", AttitudeViewController.CmdGetAttitude)
        
    }
    
    //Push button sendSetAttitude cmd 0x41 and 2 chars =  uint16_6
    @IBAction func sendSetAttitude(sender: UIButton) {
        
        
        let value = self.SetDegreesField.text
        // convert input SetDegrees Field to Uint16
        var intValue = UInt16(value!)
        
        // Convert Uint16 into Uint8 array
        var array = NSData(bytes: &intValue, length: sizeofValue(intValue)).byte_array
        
        //Add the cmdSetAttitude at beginning of array
        array.insert(AttitudeViewController.CmdSetAttitude, atIndex: 0)
        
        // Send following data to Bluetooth
        // [cmd, AttitudeDegrees_byte1, AttitudeDegrees_byte2]
        BLEManager.defaultManager.commandCenter?.writeCommand(array)
        
        //print Array
        NSLog("setAttitude button %X", AttitudeViewController.CmdSetAttitude)
        NSLog("Array = \(array)")
        
    }
    
    // When Attitude degress is received, update the Label with degrees
    func didGetAttitude(commandCenter: CubeSatCommandCenter, attitude att: UInt16) {
        
        self.GetDegreesLabel.text = String(att)
    }
    

}
