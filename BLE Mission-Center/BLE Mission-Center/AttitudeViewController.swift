//
//  AttitudeViewController.swift
//  BLE Mission-Center
//
//  Created by Kathryn W. Ng on 11/24/15.
//  Copyright © 2015 Yuji. All rights reserved.
//

import UIKit
import CoreBluetooth

class AttitudeViewController: UIViewController, UITextFieldDelegate, CubeSatCommandCenterAttitudeDelegate {
    
    static let CmdGetAttitude: UInt8  = 0x41        //decimal 65
    static let CmdSetAttitude: UInt8  = 0x42        //decimal 66
    static let CmdPowerOffAttitude: UInt8  = 0x43   //decimal 67
    static let CmdSunPointerAttitude: UInt8  = 0x44 //decimal 68
    
    @IBOutlet weak var SetAttitudeLabel: UILabel!
    //@IBOutlet weak var GetAttitudeLabel: UILabel!
    
    @IBOutlet weak var SetDegreesField: UITextField!
    @IBOutlet weak var GetDegreesLabel: UILabel!
    
    @IBOutlet weak var SetAttitudeButton: UIButton!
    @IBOutlet weak var GetAttitudeButton: UIButton!
    @IBOutlet weak var PowerOffAttButton: UIButton!
    @IBOutlet weak var SunPointerButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        BLEManager.defaultManager.commandCenter?.attitudeDelegate = self
        // Do any additional setup after loading the view
    
        
        //Increase Font size
        GetDegreesLabel.font = UIFont.systemFontOfSize(80)
        SetAttitudeLabel.font = UIFont.systemFontOfSize(25)
        
        SetDegreesField.font = UIFont.systemFontOfSize(25)
        
        // viewcontroller is text field delegate for closing keyboard
        self.SetDegreesField.delegate = self
        
        SetAttitudeButton.layer.cornerRadius = 5;
        SetAttitudeButton.layer.borderWidth = 1;
        SetAttitudeButton.layer.borderColor = UIColor.blueColor().CGColor
        
        GetAttitudeButton.layer.cornerRadius = 5;
        GetAttitudeButton.layer.borderWidth = 1;
        GetAttitudeButton.layer.borderColor = UIColor.blueColor().CGColor
        
        PowerOffAttButton.layer.cornerRadius = 5;
        PowerOffAttButton.layer.borderWidth = 1;
        PowerOffAttButton.layer.borderColor = UIColor.blueColor().CGColor
   
        SunPointerButton.layer.cornerRadius = 5;
        SunPointerButton.layer.borderWidth = 1;
        SunPointerButton.layer.borderColor = UIColor.blueColor().CGColor

    
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
        
        //AttitudeActivityIndicator.startAnimating()
        
        NSLog("getAttitude button %X", AttitudeViewController.CmdGetAttitude)
        
    }
    
    //Push button sendSetAttitude cmd 0x41 and 2 chars =  uint16_6
    @IBAction func sendSetAttitude(sender: UIButton) {
        
        
        let value = self.SetDegreesField.text
        
        // convert input SetDegrees Field to Uint16
        var intValue = UInt16(value!)
        
        print(intValue)
    
        // Convert Uint16 into Uint8 array - note 3 bytes
        var array = NSData(bytes: &intValue, length: sizeofValue(intValue)).byte_array
        NSLog("Set Attitude Degrees Array = \(array)")
        
        //Add the cmdSetAttitude at beginning of array
        array.insert(AttitudeViewController.CmdSetAttitude, atIndex: 0)
        
        // remove empty last byte
        array.removeLast()
        if array[2] == 0x00 {
            array[2] = 0xff
        }
        
        // Send following data to Bluetooth
        // [cmd, AttitudeDegrees_byte1, AttitudeDegrees_byte2]
        BLEManager.defaultManager.commandCenter?.writeCommand(array)
        
        //print Array - decimal
        NSLog("setAttitude button %X", AttitudeViewController.CmdSetAttitude)
        NSLog("Sent Array = \(array)")
        
    }
    
    // When Attitude degress is received, update the Label with degrees
    func didGetAttitude(commandCenter: CubeSatCommandCenter, attitude att: UInt16) {
        
        NSLog("didGetAttitude %x", att)
        
        
        //degrees += "°"
        
        self.GetDegreesLabel.text = "\(att)"
        
    }
   
    // closes the keyboard when pressing return on textfield or outside textfield
    func textFieldShouldReturn(userText: UITextField!) -> Bool {
        userText.resignFirstResponder()
        return true;
    }

    @IBAction func powerOffAtt(sender: UIButton) {
        BLEManager.defaultManager.commandCenter?.writeCommand([AttitudeViewController.CmdPowerOffAttitude])
        
        NSLog("powerOffAttitude button %X", AttitudeViewController.CmdPowerOffAttitude)
    }
    
    
    @IBAction func sunPointerAtt(sender: UIButton) {
        
        BLEManager.defaultManager.commandCenter?.writeCommand([AttitudeViewController.CmdSunPointerAttitude])
        
        NSLog("sunPointerAttitude button %X", AttitudeViewController.CmdSunPointerAttitude)
        
    }
    
}
