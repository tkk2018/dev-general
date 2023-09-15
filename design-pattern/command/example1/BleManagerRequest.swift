//
//  BleManagerRequest.swift
//  mtblespy
//
//  Created by dev on 15/09/2023.
//

import Foundation
import CoreBluetooth

class BleManagerRequest {
    enum Kind {
        case connect
        case disconnect
        case discoverServices
        case discoverCharacteristics
        case readCharacteristic
        case writeCharacteristic
        case setNotificationCharacteristic
        case readRssi
    }

    let peripheralIdentifier: CBUUID

    let kind: Kind

    var connectTimeout: TimeInterval?

    init(peripheral identifier: CBUUID, kind: Kind) {
        self.peripheralIdentifier = identifier
        self.kind = kind
    }
}

class ConnectRequest: BleManagerRequest {
    var connectOption: [String: Any]?

    convenience init(peripheral identifier: UUID, options: [String: Any]? = nil) {
        self.init(peripheral: CBUUID(nsuuid: identifier), options: options)
    }

    init(peripheral identifier: CBUUID, options: [String: Any]?) {
        self.connectOption = options
        super.init(peripheral: identifier, kind: .connect)
    }
}

class DisconnectRequest: BleManagerRequest {
    convenience init(peripheral uuid: UUID) {
        self.init(peripheral: CBUUID(nsuuid: uuid))
    }

    init(peripheral uuid: CBUUID) {
        super.init(peripheral: uuid, kind: .disconnect)
    }
}

class DiscoverServicesRequest: BleManagerRequest {
    let serviceUuids: [CBUUID]?

    var connectOptions: [String: Any]?

    convenience init(peripheral identifier: UUID, serviceUuid: CBUUID? = nil) {
        self.init(peripheral: CBUUID(nsuuid: identifier), serviceUuids: serviceUuid != nil ? [serviceUuid!] : nil)
    }

    init(peripheral identifier: CBUUID, serviceUuids: [CBUUID]? = nil) {
        self.serviceUuids = serviceUuids
        super.init(peripheral: identifier, kind: .discoverServices)
    }
}

class DiscoverCharacteristicsRequest: BleManagerRequest {
    var service: CBUUID?

    let characteristics: [CBUUID]?

    var connectionOptions: [String: Any]?

    var undiscoveredServices: [CBUUID]

    convenience init(peripheral identifier: UUID) {
        self.init(peripheral: CBUUID(nsuuid: identifier), service: nil, characteristics: nil)
    }

    convenience init(peripheral identifier: UUID, service: CBUUID? = nil) {
        self.init(
            peripheral: CBUUID(nsuuid: identifier),
            service: service,
            characteristics: nil
        )
    }

    convenience init(peripheral identifier: UUID, service: CBUUID, charateristics: [CBUUID]? = nil) {
        self.init(
            peripheral: CBUUID(nsuuid: identifier),
            service: service,
            characteristics: charateristics
        )
    }

    private init(peripheral identifier: CBUUID, service: CBUUID? = nil, characteristics: [CBUUID]? = nil) {
        self.service = service
        self.characteristics = characteristics
        self.undiscoveredServices = []
        super.init(peripheral: identifier, kind: .discoverCharacteristics)
    }
}

class ReadCharacteristicRequest: BleManagerRequest {
    let service: CBUUID

    let characteristic: CBUUID

    var connectionOptions: [String: Any]?

    convenience init(peripheral identifier: UUID, service: CBUUID, characteristic: CBUUID) {
        self.init(
            peripheral: CBUUID(nsuuid: identifier),
            service: service,
            characteristic: characteristic
        )
    }

    init(peripheral identifier: CBUUID, service: CBUUID, characteristic: CBUUID) {
        self.service = service
        self.characteristic = characteristic
        super.init(peripheral: identifier, kind: .readCharacteristic)
    }
}

class WriteCharacteristicRequest: BleManagerRequest {
    let service: CBUUID

    let characteristic: CBUUID

    let data: Data

    let writeType: CBCharacteristicWriteType

    var connectionOptions: [String: Any]?

    convenience init(
        peripheral identifier: UUID,
        service: CBUUID,
        characteristic: CBUUID,
        data: Data,
        writeType: CBCharacteristicWriteType
    ) {
        self.init(
            peripheral: CBUUID(nsuuid: identifier),
            service: service,
            characteristic: characteristic,
            data: data,
            writeType: writeType
        )
    }

    init(
        peripheral identifier: CBUUID,
        service: CBUUID,
        characteristic: CBUUID,
        data: Data,
        writeType: CBCharacteristicWriteType
    ) {
        self.service = service
        self.characteristic = characteristic
        self.data = data
        self.writeType = writeType
        super.init(peripheral: identifier, kind: .writeCharacteristic)
    }
}

class SetNotifyCharateristicRequest: BleManagerRequest {
    let service: CBUUID

    let characteristic: CBUUID

    let enabled: Bool

    var connectionOptions: [String: Any]?

    convenience init(
        peripheral identifier: UUID,
        service: CBUUID,
        characteristic: CBUUID,
        enabled: Bool
    ) {
        self.init(
            peripheral: CBUUID(nsuuid: identifier),
            service: service,
            characteristic: characteristic,
            enabled: enabled
        )
    }

    init(
        peripheral identifier: CBUUID,
        service: CBUUID,
        characteristic: CBUUID,
        enabled: Bool
    ) {
        self.service = service
        self.characteristic = characteristic
        self.enabled = enabled
        super.init(peripheral: identifier, kind: .setNotificationCharacteristic)
    }
}

class ReadRssiRequest: BleManagerRequest {
    var connectOptions: [String: Any]?

    convenience init(peripheral identifier: UUID) {
        self.init(peripheral: CBUUID(nsuuid: identifier))
    }

    init(peripheral identifier: CBUUID) {
        super.init(peripheral: identifier, kind: .readRssi)
    }
}
