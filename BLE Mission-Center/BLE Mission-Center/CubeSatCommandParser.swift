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
    private var readCharacteristic: CBCharacteristic
    private var writeCharacteristic: CBCharacteristic
    private var peripheral: CBPeripheral
    private var lastSendedCommand: UInt8? {
        didSet {
            CmdLog("Last Command: 0x%x", lastSendedCommand!)
        }
    }
    
    private var LPCIsBusy: Bool = false {
        didSet {
            NSLog("LPC status : %@", LPCIsBusy ? "Busy" : "IDLE")
            self.cameraDelegate?.LPCStatusDidUpdate(self, Status: LPCIsBusy ? "Busy" : "IDLE")
        }
    }
    
    private var commandsToSent = [NSData]()
    
    private let readJPEGCommand: NSData     = [UInt8(ReadCurrentJPEGFileContent)].dataValue()
    private let resetCameraCommand: NSData  = [UInt8(RESET)].dataValue()
    private let takePictureCameraCommand: NSData = [UInt8(TakePicture)].dataValue()
    
    
    init(readCharacteristic: CBCharacteristic, writeCharacteristic: CBCharacteristic) {
        self.readCharacteristic     = readCharacteristic
        self.writeCharacteristic    = writeCharacteristic
        self.peripheral             = readCharacteristic.service.peripheral
    }
    
    func requestForImage() {
        if !LPCIsBusy {
            writeToCubeSat(takePictureCameraCommand)
            lastSendedCommand = UInt8(TakePicture)
            LPCIsBusy = true
        }
    }
    
    func requestForImageData() {
        self.isGettingImg = true
        if !LPCIsBusy {
            writeCharacteristic.service.peripheral.writeValue(readJPEGCommand, forCharacteristic: writeCharacteristic, type: .WithResponse)
            lastSendedCommand = UInt8(ReadCurrentJPEGFileContent)
            CmdLog("requesting for img")
            LPCIsBusy = true
            self.cameraDelegate?.currentProcessDidUpdate(self, process: "requesting image data")
        }
    }
    
    func resetCamera() {
        if !LPCIsBusy {
            writeToCubeSat(resetCameraCommand)
            lastSendedCommand = UInt8(RESET)
            CmdLog("reseting camera")
            LPCIsBusy = true
            self.cameraDelegate?.currentProcessDidUpdate(self, process: "Resetting Camera")
        }
    }
    
    func setCompressionRatio(ratio: compressRatio) {
        lastSendedCommand = ratio.rawValue
        writeCommand([ratio.rawValue])
        LPCIsBusy = true
        self.cameraDelegate?.currentProcessDidUpdate(self, process: "Setting compression ratio")
    }
    
    func setResolution(resolution: Resolution) {
        lastSendedCommand = resolution.rawValue
        writeCommand([resolution.rawValue])
        LPCIsBusy = true
        self.cameraDelegate?.currentProcessDidUpdate(self, process: "Setting resolution")
    }
    
    func enterPowerSaving(enterPowerSaving: Bool) {
        let command: UInt8 = enterPowerSaving ? 0b11100000 : 0b11110000
        lastSendedCommand = command
        writeCommand([command])
        LPCIsBusy = true
        self.cameraDelegate?.currentProcessDidUpdate(self, process: "Entering Power Saving mode")
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
            case UInt8(RESET): break
            case UInt8(TakePicture): requestForImageData()
                // If cmd = CmdGetAttitude
            case AttitudeViewController.CmdGetAttitude:
                
                // convert next 2 bytes/char of data to variable
                let data = [bytes[2], bytes[1]].dataValue()
                
                // convert the 2 bytes of data to UInt16
                let attitudeValue = data.castToUInt16
                
                self.attitudeDelegate?.didGetAttitude(self, attitude: attitudeValue)
            case AttitudeViewController.CmdSetAttitude:
                writeCommand([commandByte])
            default: self.cameraDelegate?.currentProcessDidUpdate(self, process: "Done")
            }
        }
        

    }
    
    private func serializeImgData(payload: NSData) {
        temp.appendData(payload)
        CmdLog("Received Image data with length %i", payload.length)
        CmdLog("Total bytes stored in memory: %i", temp.length)
        print(temp)
        if temp.description.stringByReplacingOccurrencesOfString(" ", withString: "").containsString("ffd9") {
            isGettingImg = false
            let bytes = temp.byte_array
            var tmp = [UInt8]()
            for (index, byte) in bytes.enumerate() {
                tmp.append(byte)
                if byte == 0xff && bytes[index + 1] == 0xd9 {
                    tmp.append(bytes[index + 1])
                    self.cameraDelegate?.didRecivedWholeJPEGCamera(self, JPEGData: tmp.dataValue())
                    CmdLog("Image recieved: data: %@", tmp.dataValue().description)
                    break
                }
            }
            writeToCubeSat([0xd0].dataValue())
            lastSendedCommand = 0xd0
        } else {
            LPCIsBusy = false
            requestForImageData()
        }
    }
    
    func writeCommand(bytes: [UInt8]) {
        self.writeToCubeSat(bytes.dataValue())
    }
    
    private func writeToCubeSat(data: NSData) {
        writeCharacteristic.service.peripheral.writeValue(data, forCharacteristic: writeCharacteristic, type: .WithResponse)
    }
}

private func CmdLog(format: String, _ args: CVarArgType...) {
    NSLogv("\nCubeSatCommandCenter: \(format)", getVaList(args))
}

enum compressRatio: UInt8 {
    case zero           = 0b11000001
    case _36_percent    = 0b11000000
    case _25_percent    = 0b11000010
    case _50_percent    = 0b11000100
    case _75_percent    = 0b11001000
}

enum Resolution: UInt8 {
    case _320x240   = 0b11010000
    case _640x480   = 0b11010001
    case _160x120   = 0b11010010
}

protocol CubeSatCommandCenterCameraDelegate {
    func didRecivedWholeJPEGCamera(parser: CubeSatCommandCenter, JPEGData: NSData)
    func LPCStatusDidUpdate(center: CubeSatCommandCenter, Status: String)
    func currentProcessDidUpdate(center: CubeSatCommandCenter, process: String)
}


protocol CubeSatCommandCenterAttitudeDelegate {
    func didGetAttitude(commandCenter: CubeSatCommandCenter, attitude att: UInt16)
}