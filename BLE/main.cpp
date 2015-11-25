//
//  mainx.cpp
//  BLE
//
//  Created by 悠二 on 10/16/15.
//  Copyright © 2015 Yuji. All rights reserved.
//

#include "mbed.h"
#include "BLE.h"
#include "UARTService.h"

//MARK: BLE Related setups***************************************************************///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//***************************************************************************************///
const static char     DEVICE_NAME[]        = "CubeSat";
static const uint16_t uuid16_list[]        = {0x1234};
uint16_t customServiceUUID  = 0xA000;
uint16_t readCharUUID       = 0xA001;
uint16_t writeCharUUID      = 0xA002;
BLE ble;
DigitalOut myled(LED1);

//***************************************************************************************///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//Serial*********************************************************************************///

Serial UART_in_out (P0_9, P0_11);
void interrupt_from_uart_detected();

//***************************************************************************************///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//Serial*********************************************************************************///

void connectionCallback     (const Gap::ConnectionCallbackParams_t      *params);
void disconnectionCallback  (const Gap::DisconnectionCallbackParams_t   *params);
void writeCharCallback      (const GattWriteCallbackParams              *params);

//Debug tools
volatile float ledRefreshRate = 1.0;

//MARK: BLE characteristics and services set up *****************************************///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//***************************************************************************************///
static uint8_t array_for_read[20]    = {0};
static uint8_t array_for_write[20]   = {0};

WriteOnlyArrayGattCharacteristic <uint8_t, sizeof(array_for_write)>
writeCharacteristic(writeCharUUID, array_for_write);

ReadOnlyArrayGattCharacteristic  <uint8_t, sizeof(array_for_read)>
readCharacteristic  (readCharUUID, array_for_read,
                     (GattCharacteristic::BLE_GATT_CHAR_PROPERTIES_NOTIFY|GattCharacteristic::BLE_GATT_CHAR_PROPERTIES_READ));

GattCharacteristic
*characteristics[] = {&writeCharacteristic, &readCharacteristic};

GattService
customService(customServiceUUID,
              characteristics,
              sizeof(characteristics) / sizeof(characteristics[0]));

//MARK: Ummmmm.... nothing?? ************************************************************///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//***************************************************************************************///

//MARK: Ummmmm.... nothing?? ************************************************************///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//***************************************************************************************///


//MARK: Main loop ***********************************************************************///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//***************************************************************************************///

int main(void)
{
    ble.init();
    ble.onDisconnection(disconnectionCallback);
    ble.onDataWritten(writeCharCallback);
    ble.gap().accumulateAdvertisingPayload(GapAdvertisingData::COMPLETE_LOCAL_NAME, (uint8_t *)DEVICE_NAME, sizeof(DEVICE_NAME)/sizeof(DEVICE_NAME[0]));
    ble.gap().setAdvertisingInterval(100);
    ble.addService(customService);
    ble.gap().startAdvertising();
    
    UART_in_out.baud(38400);
    UART_in_out.attach(&interrupt_from_uart_detected);
    
    // infinite loop
    while (1) {
        volatile float *rate = &ledRefreshRate;
        myled = 1;
        wait(*rate);
        myled = 0;
        wait(*rate);
    }
}
//******************************************************************************************
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//MARK: connection and disconnection callbacks *********************************************

void disconnectionCallback(const Gap::DisconnectionCallbackParams_t *params)
{
    ble.startAdvertising();
}

void connectionCallback(const Gap::ConnectionCallbackParams_t *params)
{
    ble.stopAdvertising();
}

//******************************************************************************************
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//MARK: Read & Write Callbacks ************************************************************
void writeCharCallback(const GattWriteCallbackParams *params) {
    const char * data = (char *) params->data;
    UART_in_out.puts(data);
}

//******************************************************************************************
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//                                                                                       ///
//MARK: UART Interruption & file transfer **************************************************

uint8_t data[20] = {};
uint8_t data_count = 0;


void interrupt_from_uart_detected() {
    uint8_t byte = UART_in_out.getc();
    data[data_count] = byte;
    data_count++;
    if (data_count == 20) {
        ble.updateCharacteristicValue(readCharacteristic.getValueHandle(), data, sizeof(data));
        data_count = 0; //reset counter
        return;
    }
}
//************************************************************************************************


