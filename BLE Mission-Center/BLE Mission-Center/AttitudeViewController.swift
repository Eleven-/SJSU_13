//
//  AttitudeViewController.swift
//  BLE Mission-Center
//
//  Created by Kathryn W. Ng on 11/24/15.
//  Copyright © 2015 Yuji. All rights reserved.
//

import UIKit

class AttitudeViewController: UIViewController {

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
        self.SetAttitudeButton.setTitle("Get Attitude", forState: UIControlState.Normal)
        
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

    @IBAction func getAttitude(sender: UIButton) {
        
        // self.GetDegreesLabel.text =String(self.Score);
        
    }
}
