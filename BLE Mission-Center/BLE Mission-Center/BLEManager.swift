//
//  BLEManager.swift
//  BLE Mission-Center
//
//  Created by 悠二 on 11/22/15.
//  Copyright © 2015 Yuji. All rights reserved.
//

import Foundation
import CoreBluetooth

class BLEManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, CubeSatCommandCenterAttitudeDelegate, CubeSatCommandCenterCameraDelegate {
    
    static var defaultManager = BLEManager()
    private var centralManager: CBCentralManager!
    private var readCharacteristic: CBCharacteristic?
    private var writeCharacteristic: CBCharacteristic?
    private var peripheral: CBPeripheral?
    var cameraDelegate: BLECenterCameraDelegate?
    var attDelegate: BLECenterAttitudeDelegate?
    
    var commandCenter: CubeSatCommandCenter?
    
    
    func didGetAttitude(commandCenter: CubeSatCommandCenter, attitude att: UInt16) {
        self.attDelegate?.didGetAttitude(commandCenter, attitude: att)
    }
    
    func didRecivedWholeJPEGCamera(parser: CubeSatCommandCenter, JPEGData: NSData) {
        self.cameraDelegate?.didRecivedWholeJPEGCamera(parser, JPEGData: JPEGData)
    }
    
    func LPCStatusDidUpdate(center: CubeSatCommandCenter, Status: String) {
        self.cameraDelegate?.LPCStatusDidUpdate(center, Status: Status)
    }
    
    func currentProcessDidUpdate(center: CubeSatCommandCenter, process: String) {
        self.cameraDelegate?.currentProcessDidUpdate(center, process: process)
    }
    
    
    func initalizeManager() {
        centralManager = CBCentralManager(delegate: self, queue: dispatch_get_main_queue(), options: nil)
    }
    
    func resetBLE() {
        if self.peripheral != nil {
            self.centralManager.cancelPeripheralConnection(self.peripheral!)
            self.peripheral = nil
        }
        self.readCharacteristic = nil
        self.writeCharacteristic = nil
        self.commandCenter = nil
        centralManager.scanForPeripheralsWithServices(nil, options: nil)
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
//        BLELog("Found Peripheral with UUID: %@, withName: \(peripheral.name)", peripheral.identifier.UUIDString)
        if let peripheralName = peripheral.name {
            if peripheral.identifier.UUIDString == CubeSatUUID {
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
                    BLELog("Found write characteristic[UUID: %@]", characteristic.UUID.UUIDString)
                    self.writeCharacteristic = characteristic
                }
                if characteristic.UUID.UUIDString == ReadCharacteristicUUID {
                    BLELog("Found read characteristic[UUID: %@]", characteristic.UUID.UUIDString)
                    self.readCharacteristic = characteristic
                    peripheral.setNotifyValue(true, forCharacteristic: readCharacteristic!)
                    BLELog("Subscribing to characteristic[UUID: %@]", characteristic.UUID.UUIDString)
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        BLELog("Notification State of characteristic[UUID: %@] is updated", characteristic.UUID.UUIDString)
        if let err = error {
            BLELog("Error Occurs: %@", err)
        }
        if readCharacteristic != nil && writeCharacteristic != nil {
            commandCenter = CubeSatCommandCenter(readCharacteristic: readCharacteristic!, writeCharacteristic: writeCharacteristic!)
            commandCenter?.cameraDelegate = self
            commandCenter?.attitudeDelegate = self
            cameraDelegate?.BLEDidUpdateStatus(self, didChangeStatus: "Ready")
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

protocol BLECenterCameraDelegate {
    func didRecivedWholeJPEGCamera(parser: CubeSatCommandCenter, JPEGData: NSData)
    func LPCStatusDidUpdate(center: CubeSatCommandCenter, Status: String)
    func currentProcessDidUpdate(center: CubeSatCommandCenter, process: String)
    func BLEDidUpdateStatus(manager: BLEManager, didChangeStatus status: String)
//    func didFinishedSettUp()
}


protocol BLECenterAttitudeDelegate {
    func didGetAttitude(commandCenter: CubeSatCommandCenter, attitude att: UInt16)
}

private func BLELog(format: String, _ args: CVarArgType...) {
    NSLogv("BLEManager: \(format)", getVaList(args))
}
