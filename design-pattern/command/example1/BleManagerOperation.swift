//
//  BleManagerOperation.swift
//  mtblespy
//
//  Created by dev on 15/09/2023.
//

import Foundation
import CoreBluetooth

protocol RequestCallback {
    associatedtype T
    var completionHandler: ((Result<T, Swift.Error>) -> Void)? { get set }

    func onFailure(_ error: Swift.Error)

    func onSuccess(_ result: T)
}

protocol Operation: BleManagerRequest, RequestCallback {
}

protocol BluetoothOperation: Operation {
    func execute(_ centralManager: CBCentralManager) throws
}

protocol BluetoothGattOperation: Operation {
    func requireServicesUuids() -> [CBUUID]?

    func requireCharacteristicUuids() -> [CBUUID]?

    func execute(_ centralManager: CBCentralManager) throws
}

class ConnectOperation: ConnectRequest, BluetoothOperation {
    var completionHandler: ((Result<ConnectResponse, Swift.Error>) -> Void)?

    func execute(_ centralManager: CBCentralManager) throws {
        guard let peripheral = centralManager.retrievePeripheral(withIdentifier: self.peripheralIdentifier) else {
            throw BluetoothGattManagerError.peripheralNotFound
        }

        guard peripheral.state == .disconnected else {
            if (peripheral.state == .connected) {
                self.onSuccess(ConnectResponse(peripheral: peripheral, request: self))
            }
            return
        }

        centralManager.connect(peripheral, options: self.connectOption)
    }

    func onSuccess(_ result: ConnectResponse) {
        self.completionHandler?(.success(result))
    }

    func onFailure(_ error: Error) {
        self.completionHandler?(.failure(error))
    }
}

class DisconnectOperation: DisconnectRequest, BluetoothOperation {
    var completionHandler: ((Result<DisconnectResponse, Swift.Error>) -> Void)?

    func execute(_ centralManager: CBCentralManager) throws {
        guard let peripheral = centralManager.retrievePeripheral(withIdentifier: self.peripheralIdentifier) else {
            throw BluetoothGattManagerError.peripheralNotFound
        }

        switch peripheral.state {
        case .connecting:
            fallthrough
        case .connected:
            centralManager.cancelPeripheralConnection(peripheral)
            return
        case .disconnecting:
            return
        case .disconnected:
            self.onSuccess(DisconnectResponse(peripheral: peripheral, error: nil))
            return
        @unknown default:
            fatalError("What should I do if I do not know what will happen? Apple!?")
        }
    }

    func onSuccess(_ result: DisconnectResponse) {
        self.completionHandler?(.success(result))
    }

    func onFailure(_ error: Error) {
        self.completionHandler?(.failure(error))
    }
}

class DiscoverServicesOperation: DiscoverServicesRequest, BluetoothGattOperation {
    var completionHandler: ((Result<DiscoverServicesResponse, Swift.Error>) -> Void)?

    func requireServicesUuids() -> [CBUUID]? {
        return serviceUuids
    }

    func requireCharacteristicUuids() -> [CBUUID]? {
        return nil
    }

    func execute(_ centralManager: CBCentralManager) throws {
        guard let peripheral = centralManager.retrievePeripheral(withIdentifier: self.peripheralIdentifier) else {
            throw BluetoothGattManagerError.peripheralNotFound
        }

        guard peripheral.state == .connected else {
            if (peripheral.state == .disconnected) {
                centralManager.connect(peripheral, options: nil)
            }
            return
        }

        peripheral.discoverServices(self.serviceUuids)
    }

    func onSuccess(_ result: DiscoverServicesResponse) {
        self.completionHandler?(.success(result))
    }

    func onFailure(_ error: Error) {
        self.completionHandler?(.failure(error))
    }
}

class DiscoverCharacteristicsOperation: DiscoverCharacteristicsRequest, BluetoothGattOperation {
    var completionHandler: ((Result<DiscoverCharacteristicsResponse, Swift.Error>) -> Void)?

    func requireServicesUuids() -> [CBUUID]? {
        if let service = self.service {
            return [service]
        }
        else {
            return nil
        }
    }

    func requireCharacteristicUuids() -> [CBUUID]? {
        if let characteristics = self.characteristics {
            return characteristics
        }
        else {
            return nil
        }
    }

    func execute(_ centralManager: CBCentralManager) throws {
        guard let peripheral = centralManager.retrievePeripheral(withIdentifier: self.peripheralIdentifier) else {
            throw BluetoothGattManagerError.peripheralNotFound
        }

        guard peripheral.state == .connected else {
            if (peripheral.state == .disconnected) {
                centralManager.connect(peripheral, options: nil)
            }
            return
        }

        guard let discoveredServices = peripheral.services else {
            throw BluetoothGattManagerError.serviceNotDiscovered
        }

        if let require = self.service,
           let service = discoveredServices.first(where: { $0.uuid == require })
        {
            peripheral.discoverCharacteristics(self.characteristics, for: service)
        }
        else {
            // find from all services
            self.undiscoveredServices = discoveredServices.map { $0.uuid }
            discoveredServices.forEach { service in
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    func onSuccess(_ result: DiscoverCharacteristicsResponse) {
        self.completionHandler?(.success(result))
    }

    func onFailure(_ error: Error) {
        self.completionHandler?(.failure(error))
    }
}

class ReadCharacteristicOperation: ReadCharacteristicRequest, BluetoothGattOperation {
    var completionHandler: ((Result<ReadCharacteristicResponse, Swift.Error>) -> Void)?

    func requireServicesUuids() -> [CBUUID]? {
        return [service]
    }

    func requireCharacteristicUuids() -> [CBUUID]? {
        return [characteristic]
    }

    func execute(_ centralManager: CBCentralManager) throws {
        guard let peripheral = centralManager.retrievePeripheral(withIdentifier: self.peripheralIdentifier) else {
            throw BluetoothGattManagerError.peripheralNotFound
        }

        guard peripheral.state == .connected else {
            if (peripheral.state == .disconnected) {
                centralManager.connect(peripheral, options: nil)
            }
            return
        }

        guard let services = peripheral.services,
              let service: CBService = services.first(where: { service in service.uuid == self.service }) else {
            peripheral.discoverServices([self.service])
//            throw BluetoothGattManagerError.serviceNotFound
            return
        }

        guard let characteristics: [CBCharacteristic] = service.characteristics,
              let characteristic: CBCharacteristic = characteristics.first(where: { characteristic in characteristic.uuid == self.characteristic })
        else {
            peripheral.discoverCharacteristics([self.characteristic], for: service)
//            throw BluetoothGattManagerError.characteristicNotFound
            return
        }

        peripheral.readValue(for: characteristic)
    }

    func onSuccess(_ result: ReadCharacteristicResponse) {
        self.completionHandler?(.success(result))
    }

    func onFailure(_ error: Error) {
        self.completionHandler?(.failure(error))
    }
}

class WriteCharacteristicOperation: WriteCharacteristicRequest, BluetoothGattOperation {
    var completionHandler: ((Result<WriteCharacteristicResponse, Swift.Error>) -> Void)?

    func requireServicesUuids() -> [CBUUID]? {
        return [service]
    }

    func requireCharacteristicUuids() -> [CBUUID]? {
        return [characteristic]
    }

    func execute(_ centralManager: CBCentralManager) throws {
        guard let peripheral = centralManager.retrievePeripheral(withIdentifier: self.peripheralIdentifier)
        else {
            throw BluetoothGattManagerError.peripheralNotFound
        }

        guard peripheral.state == .connected
        else {
            if (peripheral.state == .disconnected) {
                centralManager.connect(peripheral, options: nil)
            }
            return
        }

        guard let services = peripheral.services,
              let service: CBService = services.first(where: { service in service.uuid == self.service })
        else {
            peripheral.discoverServices([self.service])
//            throw BluetoothGattManagerError.serviceNotFound
            return
        }

        guard let characteristics: [CBCharacteristic] = service.characteristics,
              let characteristic: CBCharacteristic = characteristics.first(where: { characteristic in characteristic.uuid == self.characteristic })
        else {
            peripheral.discoverCharacteristics([self.characteristic], for: service)
//            throw BluetoothGattManagerError.characteristicNotFound
            return
        }

        peripheral.writeValue(self.data, for: characteristic, type: self.writeType)
    }

    func onSuccess(_ result: WriteCharacteristicResponse) {
        self.completionHandler?(.success(result))
    }

    func onFailure(_ error: Error) {
        self.completionHandler?(.failure(error))
    }
}

class SetNotifyCharateristicOperation: SetNotifyCharateristicRequest, BluetoothGattOperation {
    var completionHandler: ((Result<SetNotifyCharacteristicResponse, Swift.Error>) -> Void)?

    func requireServicesUuids() -> [CBUUID]? {
        return [service]
    }

    func requireCharacteristicUuids() -> [CBUUID]? {
        return [characteristic]
    }

    func execute(_ centralManager: CBCentralManager) throws {
        guard let peripheral = centralManager.retrievePeripheral(withIdentifier: self.peripheralIdentifier)
        else {
            throw BluetoothGattManagerError.peripheralNotFound
        }

        guard peripheral.state == .connected else {
            if (peripheral.state == .disconnected) {
                centralManager.connect(peripheral, options: nil)
            }
            return
        }

        guard let services = peripheral.services,
              let service: CBService = services.first(where: { service in service.uuid == self.service }) else {
            peripheral.discoverServices([self.service])
//            throw BluetoothGattManagerError.serviceNotFound
            return
        }

        guard let characteristics: [CBCharacteristic] = service.characteristics,
              let characteristic: CBCharacteristic = characteristics.first(where: { characteristic in characteristic.uuid == self.characteristic })
        else {
            peripheral.discoverCharacteristics([self.characteristic], for: service)
//            throw BluetoothGattManagerError.characteristicNotFound
            return
        }

        peripheral.setNotifyValue(self.enabled, for: characteristic)
    }

    func onSuccess(_ result: SetNotifyCharacteristicResponse) {
        self.completionHandler?(.success(result))
    }

    func onFailure(_ error: Error) {
        self.completionHandler?(.failure(error))
    }
}

class ReadRssiOperation: ReadRssiRequest, BluetoothGattOperation {
    var completionHandler: ((Result<ReadRssiValue, Swift.Error>) -> Void)?

    func requireServicesUuids() -> [CBUUID]? {
        return nil
    }

    func requireCharacteristicUuids() -> [CBUUID]? {
        return nil
    }

    func execute(_ centralManager: CBCentralManager) throws {
        guard let peripheral = centralManager.retrievePeripheral(withIdentifier: self.peripheralIdentifier) else {
            throw BluetoothGattManagerError.peripheralNotFound
        }

        guard peripheral.state == .connected else {
            if (peripheral.state == .disconnected) {
                centralManager.connect(peripheral, options: nil)
            }
            return
        }

        peripheral.readRSSI()
    }

    func onSuccess(_ result: ReadRssiValue) {
        self.completionHandler?(.success(result))
    }

    func onFailure(_ error: Error) {
        self.completionHandler?(.failure(error))
    }
}
