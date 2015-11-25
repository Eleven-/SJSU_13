//
//  BLEManager.swift
//  BLE Mission-Center
//
//  Created by 悠二 on 11/22/15.
//  Copyright © 2015 Yuji. All rights reserved.
//

import Foundation
import CoreBluetooth

class BLEManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, CubeSatCommandCenterCameraDelegate {
    static var defaultManager = BLEManager()
    private var centralManager: CBCentralManager!
    private var readCharacteristic: CBCharacteristic?
    private var writeCharacteristic: CBCharacteristic?
    private var peripheral: CBPeripheral?
    var delegate: BLECenterDelegate?
    
    var commandCenter: CubeSatCommandCenter?
    
    func initalizeManager() {
        centralManager = CBCentralManager(delegate: self, queue: dispatch_get_main_queue(), options: nil)
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
//        BLELog("Found Peripheral with UUID: %@, withName: \(peripheral.name)", peripheral.identifier.UUIDString)
        if let peripheralName = peripheral.name {
            if peripheralName.hasPrefix("CubeSat") {
                BLELog("Discovered peripheral with name %@", peripheralName)
                self.peripheral = peripheral
                central.connectPeripheral(self.peripheral!, options: nil)
                BLELog("Attempting to connect peripheral[named: %@, UUID: %@]", peripheral.name!, peripheral.identifier.UUIDString)
            }
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        BLELog("Connected to peripheral with [named: %@, UUID: %@]", peripheral.name!, peripheral.identifier.UUIDString)
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        BLELog("Discovering for services for peripheral with [named: %@, UUID: %@]", peripheral.name!, peripheral.identifier.UUIDString)
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        BLELog("Discovered services for peripheral[named: %@, UUID: %@]",  peripheral.name!, peripheral.identifier.UUIDString)
        if let services = peripheral.services {
            for service in services {
                BLELog("Found service with UUID: %@", service.UUID.UUIDString)
                peripheral.discoverCharacteristics(nil, forService: service)
                BLELog("Discovering Characteristics for service[UUD: %@]", service.UUID.UUIDString)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        BLELog("Discovered Characteristics for service[UUID: %@]", service.UUID.UUIDString)
        if let err = error {
            BLELog("Error Occurs: %@", err)
            return
        }
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                BLELog("Found characteristics with [UUID: %@]", characteristic.UUID.UUIDString)
                if characteristic.UUID.UUIDString == WriteCharacteristicUUID {
                    BLELog("Fond write characteristic[UUID: %@]", characteristic.UUID.UUIDString)
                    self.writeCharacteristic = characteristic
                }
                if characteristic.UUID.UUIDString == ReadCharacteristicUUID {
                    BLELog("Fond read characteristic[UUID: %@]", characteristic.UUID.UUIDString)
                    self.readCharacteristic = characteristic
                    peripheral.setNotifyValue(true, forCharacteristic: readCharacteristic!)
                    BLELog("Subscribing to characteristic[UUID: %@]", characteristic.UUID.UUIDString)
                }
            }
        }
    }
    
    func didRecivedWholeJPEGCamera(parser: CubeSatCommandCenter, JPEGData: NSData) {
        BLELog("JPEG received: %@", JPEGData.description)
        self.delegate?.didRecivedWholeJPEGCamera(parser, JPEGData: JPEGData)
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        BLELog("Notification State of characteristic[UUID: %@] is updated", characteristic.UUID.UUIDString)
        if let err = error {
            BLELog("Error Occurs: %@", err)
        }
        if readCharacteristic != nil && writeCharacteristic != nil {
            commandCenter = CubeSatCommandCenter(readCharacteristic: readCharacteristic!, writeCharacteristic: writeCharacteristic!)
            commandCenter?.cameraDelegate = self
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        BLELog("Value of characteristic[UUID: %@] updated, newValue: %@", characteristic.UUID.UUIDString, characteristic.value!)
        if characteristic == readCharacteristic {
            commandCenter?.parseData(readCharacteristic?.value)
        }
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        var text = ""
        switch central.state {
        case CBCentralManagerState.PoweredOff:
            text = "Power Off"
        case CBCentralManagerState.PoweredOn:
            text = "Power on";
            centralManager.scanForPeripheralsWithServices(nil, options: nil)
        case CBCentralManagerState.Resetting:
            text = "Restting"
        case CBCentralManagerState.Unauthorized:
            text = "Unauthorized"
        case CBCentralManagerState.Unknown:
            text = "Unknown"
        case CBCentralManagerState.Unsupported:
            text = "Unsuppoerted"
        }
        BLELog("Central Manager Did Update State: %@", text)
    }
}

private func BLELog(format: String, _ args: CVarArgType...) {
    NSLogv("BLEManager: \(format)", getVaList(args))
}

protocol BLECenterDelegate {
    func didRecivedWholeJPEGCamera(parser: CubeSatCommandCenter, JPEGData: NSData)
}

