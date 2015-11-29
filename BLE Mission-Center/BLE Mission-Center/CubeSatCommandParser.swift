//
//  CubeSatCommandParser.swift
//  BLE Mission-Center
//
//  Created by 悠二 on 11/23/15.
//  Copyright © 2015 Yuji. All rights reserved.
//

import Foundation
import CoreBluetooth

class CubeSatCommandCenter {
    var temp: NSMutableData = NSMutableData()
    var cameraDelegate: CubeSatCommandCenterCameraDelegate?
    var attitudeDelegate: CubeSatCommandCenterAttitudeDelegate?
    private var isGettingImg: Bool = false
    private var LPCIsBusy: Bool = false {
        didSet {
            NSLog("LPC status : %@", LPCIsBusy ? "Busy" : "IDLE")
        }
    }
    
    private var readCharacteristic: CBCharacteristic
    private var writeCharacteristic: CBCharacteristic
    private var peripheral: CBPeripheral
    private let readJPEGCommand: NSData     = [UInt8(ReadCurrentJPEGFileContent)].dataValue()
    private let resetCameraCommand: NSData  = [UInt8(RESET)].dataValue()
    private var lastSendedCommand: UInt8?
    
    private var commandsToSent = [NSData]()
    
    init(readCharacteristic: CBCharacteristic, writeCharacteristic: CBCharacteristic) {
        self.readCharacteristic     = readCharacteristic
        self.writeCharacteristic    = writeCharacteristic
        self.peripheral             = readCharacteristic.service.peripheral
    }
    
    func requestForImage() {
        self.isGettingImg = true
        if !LPCIsBusy {
            writeCharacteristic.service.peripheral.writeValue(readJPEGCommand, forCharacteristic: writeCharacteristic, type: .WithResponse)
            lastSendedCommand = UInt8(ReadCurrentJPEGFileContent)
            NSLog("request 4 img, lastSendedCommand %i", lastSendedCommand!)
            LPCIsBusy = true
        }
//        writeCharacteristic.service.peripheral.writeValue(readJPEGCommand, forCharacteristic: writeCharacteristic, type: .WithResponse)
//        lastSendedCommand = UInt8(ReadCurrentJPEGFileContent)
//        LPCIsBusy = true
    }
    
    func resetCamera() {
        if !LPCIsBusy {
//            writeCharacteristic.service.peripheral.writeValue(resetCameraCommand, forCharacteristic: writeCharacteristic, type: .WithResponse)
            writeToCubeSat(resetCameraCommand)
            lastSendedCommand = UInt8(RESET)
            NSLog("resetCamera, lastSendedCommand %i", lastSendedCommand!)
            LPCIsBusy = true
        }
    }
    
    func parseData(data: NSData?) {
        NSLog("received data: %@", (data?.description)!)
        if let payload = data {
            if isGettingImg {
                serializeImgData(payload)
                return
            }
            
            let bytes = payload.byte_array
            
            let commandByte = bytes[0]
            if lastSendedCommand != nil {
                if bytes[0] == lastSendedCommand  {
                    LPCIsBusy = false
                }
            }
            switch commandByte {
            
            // If cmd = CmdGetAttitude
            case AttitudeViewController.CmdGetAttitude:
                
                // convert next 2 bytes/char of data to variable
                var data = [bytes[2], bytes[1]].dataValue()
                
                // convert the 2 bytes of data to UInt16
                let attitudeValue = data.castToUInt16
                
                print(attitudeValue)
                
                self.attitudeDelegate?.didGetAttitude(self, attitude: attitudeValue)
                
            default: writeCommand([commandByte])
            }
        }
        

    }
    
    private func serializeImgData(payload: NSData) {
        temp.appendData(payload)
        if temp.description.stringByReplacingOccurrencesOfString(" ", withString: "").containsString("ffd9") {
            isGettingImg = false
            let bytes = temp.byte_array
            var tmp = [UInt8]()
            for (index, byte) in bytes.enumerate() {
                tmp.append(byte)
                if byte == 0xff && bytes[index + 1] == 0xd9 {
                    tmp.append(bytes[index + 1])
//                    temp = tmp.dataValue().mutableCopy() as! NSMutableData
                    self.cameraDelegate?.didRecivedWholeJPEGCamera(self, JPEGData: tmp.dataValue())
                    NSLog("Image recieved: data: %@", tmp.dataValue().description)
                    break
                }
            }
            writeToCubeSat([lastSendedCommand].dataValue())
        } else {
            LPCIsBusy = false
            requestForImage()
        }
    }
    
    func writeCommand(bytes: [UInt8]) {
        self.writeToCubeSat(bytes.dataValue())
    }
    
    private func writeToCubeSat(data: NSData) {
        writeCharacteristic.service.peripheral.writeValue(data, forCharacteristic: writeCharacteristic, type: .WithResponse)
    }
}

protocol CubeSatCommandCenterCameraDelegate {
    func didRecivedWholeJPEGCamera(parser: CubeSatCommandCenter, JPEGData: NSData)
}


protocol CubeSatCommandCenterAttitudeDelegate {
    func didGetAttitude(commandCenter: CubeSatCommandCenter, attitude att: UInt16)
}