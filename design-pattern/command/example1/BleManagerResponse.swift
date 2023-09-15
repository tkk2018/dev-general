//
//  BleManagerResponse.swift
//  mtblespy
//
//  Created by dev on 15/09/2023.
//

import Foundation
import CoreBluetooth

struct ConnectResponse {
    let peripheral: CBPeripheral
    let request: ConnectRequest
}

struct DisconnectResponse {
    let peripheral: CBPeripheral
    let error: Swift.Error?
}

struct DiscoverServicesResponse {
    let request: DiscoverServicesRequest
    let peripheral: CBPeripheral
}

struct DiscoverCharacteristicsResponse {
    let request: DiscoverCharacteristicsRequest
    let service: CBService
}

struct ReadCharacteristicResponse {
    let request: ReadCharacteristicRequest
    let characteristic: CBCharacteristic
}

struct WriteCharacteristicResponse {
    let request: WriteCharacteristicRequest
    let characteristic: CBCharacteristic
}

struct SetNotifyCharacteristicResponse {
    let request: SetNotifyCharateristicRequest
    let characteristic: CBCharacteristic
}

struct NotifyCharacteristicValue {
    let peripheral: CBPeripheral
    let characteristic: CBCharacteristic
    let error: Error?
}

struct ReadRssiValue {
    let peripheral: CBPeripheral
    let rssi: Int
}



