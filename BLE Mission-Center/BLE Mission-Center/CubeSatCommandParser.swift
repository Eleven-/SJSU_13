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
    var delegate: CubeSatCommandCenterDelegate?
    private var isGettingImg: Bool = false
    private var LPCIsBusy: Bool = false {
        didSet {
            NSLog("LPC status : %@", LPCIsBusy ? "Busy" : "IDLE")
        }
    }
    
    private var readCharacteristic: CBCharacteristic
    private var writeCharacteristic: CBCharacteristic
    private var peripheral: CBPeripheral
    private let readJPEGCommand: NSData = [UInt8(ReadCurrentJPEGFileContent)].dataValue()
    private let resetCameraCommand: NSData = [UInt8(RESET)].dataValue()
    private var lastSendedCommand: UInt8!
    
    private var commandsToSent = [NSData]()
    
    init(readCharacteristic: CBCharacteristic, writeCharacteristic: CBCharacteristic) {
        print(readCharacteristic)
        print(writeCharacteristic)
        self.readCharacteristic = readCharacteristic
        self.writeCharacteristic = writeCharacteristic
        self.peripheral = readCharacteristic.service.peripheral
    }
    
    func requestForImage() {
        self.isGettingImg = true
        if !LPCIsBusy {
            print(readJPEGCommand)
            writeCharacteristic.service.peripheral.writeValue(readJPEGCommand, forCharacteristic: writeCharacteristic, type: .WithResponse)
            lastSendedCommand = UInt8(ReadCurrentJPEGFileContent)
            NSLog("request 4 img, lastSendedCommand %i", lastSendedCommand)
            LPCIsBusy = true
        }
//        writeCharacteristic.service.peripheral.writeValue(readJPEGCommand, forCharacteristic: writeCharacteristic, type: .WithResponse)
//        lastSendedCommand = UInt8(ReadCurrentJPEGFileContent)
//        LPCIsBusy = true
    }
    
    func resetCamera() {
        if !LPCIsBusy {
            print(resetCameraCommand)
            writeCharacteristic.service.peripheral.writeValue(resetCameraCommand, forCharacteristic: writeCharacteristic, type: .WithResponse)
            lastSendedCommand = UInt8(RESET)
            NSLog("resetCamera, lastSendedCommand %i", lastSendedCommand)
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
            if bytes[0] == lastSendedCommand {
                LPCIsBusy = false
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
                    self.delegate?.didRecivedWholeJPEGCamera(self, JPEGData: tmp.dataValue())
                    NSLog("Image recieved: data: %@", tmp.dataValue().description)
                    break
                }
            }
        } else {
            LPCIsBusy = false
            requestForImage()
        }
//        if payload.description.stringByReplacingOccurrencesOfString(" ", withString: "").containsString("ffd9") {
//            let byteArray = payload.byte_array
//            var tmp = [UInt8]()
//            for (index, byte) in byteArray.enumerate() {
//                tmp.append(byte)
//                if byte == 0xff && byteArray[index + 1] == 0xd9 {
//                    tmp.append(byteArray[index + 1])
//                    break
//                }
//                temp.appendData(tmp.dataValue())
//            }
//            isGettingImg = false
//        } else {
//            temp.appendData(payload)
//            requestForImage()
//        }
    }
}

protocol CubeSatCommandCenterDelegate {
    func didRecivedWholeJPEGCamera(parser: CubeSatCommandCenter, JPEGData: NSData)
}