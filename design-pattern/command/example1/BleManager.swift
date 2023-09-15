//
//  BluetoothGattManager.swift
//
//  Created by dev on 24/08/2021.
//

import Foundation
import CoreBluetooth
import Combine

public struct PeripheralConnectionState {
    let peripheral: CBPeripheral
    let error: Error?
}

public class BleManager: NSObject {
    static var defaultServices = [
        CBUUID(string: "1800"),
        CBUUID(string: "180A")
    ]

    let centralManager: CBCentralManager

    let dispatcher: DispatchQueue

    var initialized: Bool

    var initializer: ((ConnectOperation) -> [any BluetoothGattOperation])?

    var initializeQueue: [any BluetoothGattOperation]

    var currentInitializeOperation: (any BluetoothGattOperation)?

    var queue: [any Operation]

    var currentOperation: (any Operation)?

    var tempPeripheral: CBPeripheral?

    var connectedPeripheral: CBPeripheral?

    var centralManagerStatePublisher = PassthroughSubject<CBManagerState, Never>()

    /**
     Publish the connection state of peripheral
     */
    var connectionStatePublisher = PassthroughSubject<PeripheralConnectionState, Never>()

    /**
     Publish the value of the notification characteristic
     */
    var notificationCharacteristicPublisher = PassthroughSubject<NotifyCharacteristicValue, Never>()

    var waitForReady = false

    var disposed = false

    convenience init(queue: DispatchQueue = DispatchQueue(label: "bluetooth-gatt-manager")) {
        let centralManager = CBCentralManager(delegate: nil, queue: queue)
        self.init(centralManager: centralManager, queue: queue)
        self.centralManager.delegate = self
    }

    init(centralManager: CBCentralManager, queue: DispatchQueue) {
        self.centralManager = centralManager
        self.dispatcher = queue
        self.initialized = false
        self.initializeQueue = []
        self.queue = []
        super.init()
    }

    func peripheral(withIdentifier uuid: CBUUID) -> CBPeripheral? {
        return self.centralManager
            .retrieveConnectedPeripherals(withServices: BleManager.defaultServices)
            .first(where: { peripheral in
                return CBUUID(nsuuid: peripheral.identifier) == uuid
            })
    }

    func enqueue(operation: any Operation) {
        self.enqueue(operations: [operation])
    }

    func enqueue(operations: [any Operation]) {
        self.dispatcher.async { [weak self] in
            guard let self = self else {
                return
            }
            self.queue.append(contentsOf: operations)
            if (currentOperation == nil) {
                self.next()
            }
        }
    }

    // The caller need to cancel the disconnectPublisher if don't want to receive disconnect signal.
    func dispose() {
        self.dispatcher.async { [weak self] in
            guard let self = self else {
                return
            }
            self.disposed = true
            self.currentOperation = nil
            self.queue.removeAll()
            if let temp = self.tempPeripheral {
                self.centralManager.cancelPeripheralConnection(temp)
                self.tempPeripheral = nil
            }

            if let connected = self.connectedPeripheral {
                self.centralManager.cancelPeripheralConnection(connected)
                self.connectedPeripheral = nil
            }
        }
    }

    private func execute(opt: any Operation) {
        do {
            if (try self.centralManager.availability()) {
                // TODO:
//                guard let peripheral = self.centralManager.retrievePeripheral(withIdentifier: request.peripheralIdentifier) else {
//                    throw BluetoothGattManagerError.peripheralNotFound
//                }
//
//                if let used = self.tempPeripheral,
//                   peripheral.identifier != used.identifier
//                {
//                    throw BluetoothGattManagerError.alreadyUsed(for: used)
//                }
//
//                if let used = self.connectedPeripheral,
//                   peripheral.identifier != used.identifier
//                {
//                    throw BluetoothGattManagerError.alreadyUsed(for: used)
//                }

                if let opt = opt as? any BluetoothOperation {
                    try opt.execute(self.centralManager)
                }
                else if let opt = opt as? any BluetoothGattOperation {
                    try opt.execute(self.centralManager)
                }

//                switch request.kind {
//                case .connect:
//                    let req  = request as! ConnectOperation
//                    try self.execute(request: req)
//                case .disconnect:
//                    let req = request as! DisconnectOperation
//                    try self.execute(request: req)
//                case .discoverServices:
//                    let req = request as! DiscoverServicesOperation
//                    try self.execute(request: req)
//                case .discoverCharacteristics:
//                    let req = request as! DiscoverCharacteristicsOperation
//                    try self.execute(request: req)
//                case .readCharacteristic:
//                    let req = request as! ReadCharacteristicOperation
//                    try self.execute(request: req)
//                case .writeCharacteristic:
//                    let req = request as! WriteCharacteristicOperation
//                    try self.execute(request: req)
//                case .setNotificationCharacteristic:
//                    let req = request as! SetNotifyCharateristicOperation
//                    try self.execute(request: req)
//                case .readRssi:
//                    let req = request as! ReadRssiOperation
//                    try self.execute(request: req)
//                }
            }
            else {
                self.waitForReady = true
            }
        }
        catch let e {
            self.handleError(opt: opt, error: e)
        }
    }

//    private func execute(request: ConnectOperation) throws {
//        guard let peripheral = self.centralManager.retrievePeripheral(withIdentifier: request.peripheralIdentifier) else {
//            throw BluetoothGattManagerError.peripheralNotFound
//        }
//
//        guard peripheral.state == .disconnected else {
//            if (peripheral.state == .connected) {
//                self.centralManager(self.centralManager, didConnect: peripheral)
//            }
//            return
//        }
//
//        self.centralManager.connect(peripheral, options: request.connectOption)
//        self.tempPeripheral = peripheral
//    }

//    private func execute(request: DisconnectOperation) throws {
//        guard let peripheral = self.centralManager.retrievePeripheral(withIdentifier: request.peripheralIdentifier) else {
//            throw BluetoothGattManagerError.peripheralNotFound
//        }
//
//        switch peripheral.state {
//        case .connecting:
//            fallthrough
//        case .connected:
//            self.centralManager.cancelPeripheralConnection(peripheral)
//            return
//        case .disconnecting:
//            return
//        case .disconnected:
//            request.completionHandler?(.success(request))
//            return
//        @unknown default:
//            fatalError("What should I do if I do not know what will happen? Apple!?")
//        }
//    }

//    private func execute(request: DiscoverServicesOperation) throws {
//        guard let peripheral = self.centralManager.retrievePeripheral(withIdentifier: request.peripheralIdentifier) else {
//            throw BluetoothGattManagerError.peripheralNotFound
//        }
//
//        guard peripheral.state == .connected else {
//            if (peripheral.state == .disconnected) {
//                self.centralManager.connect(peripheral, options: nil)
//            }
//            return
//        }
//
//        peripheral.discoverServices(request.serviceUuids)
//    }

//    private func execute(request: DiscoverCharacteristicsOperation) throws {
//        guard let peripheral = self.centralManager.retrievePeripheral(withIdentifier: request.peripheralIdentifier) else {
//            throw BluetoothGattManagerError.peripheralNotFound
//        }
//
//        guard peripheral.state == .connected else {
//            if (peripheral.state == .disconnected) {
//                self.centralManager.connect(peripheral, options: nil)
//            }
//            return
//        }
//
//        guard let discoveredServices = peripheral.services else {
//            self.handleError(request: request, error: BluetoothGattManagerError.serviceNotDiscovered)
//            return
//        }

//        if let require = request.service,
//           let service = discoveredServices.first(where: { $0.uuid == require })
//        {
//            peripheral.discoverCharacteristics(request.characteristics, for: service)
//        }
//        else {
//            // find from all services
//            request.undiscoveredServices = discoveredServices.map { $0.uuid }
//            discoveredServices.forEach { service in
//                peripheral.discoverCharacteristics(nil, for: service)
//            }
//        }
//    }

//    private func execute(request: ReadCharacteristicOperation) throws {
//        guard let peripheral = self.centralManager.retrievePeripheral(withIdentifier: request.peripheralIdentifier) else {
//            throw BluetoothGattManagerError.peripheralNotFound
//        }
//
//        guard peripheral.state == .connected else {
//            if (peripheral.state == .disconnected) {
//                self.centralManager.connect(peripheral, options: nil)
//            }
//            return
//        }

//        guard let services = peripheral.services,
//              let service: CBService = services.first(where: { service in service.uuid == request.service }) else {
//            peripheral.discoverServices([request.service])
////            self.handleError(request: request, error: BluetoothGattManagerError.serviceNotFound)
//            return
//        }

//        guard let characteristics: [CBCharacteristic] = service.characteristics,
//              let characteristic: CBCharacteristic = characteristics.first(where: { characteristic in characteristic.uuid == request.characteristic }) else {
//            peripheral.discoverCharacteristics([request.characteristic], for: service)
////            self.handleError(request: request, error: BluetoothGattManagerError.characteristicNotFound)
//            return
//        }
//
//        peripheral.readValue(for: characteristic)
//    }

//    private func execute(request: WriteCharacteristicOperation) throws {
//        guard let peripheral = self.centralManager.retrievePeripheral(withIdentifier: request.peripheralIdentifier) else {
//            throw BluetoothGattManagerError.peripheralNotFound
//        }
//
//        guard peripheral.state == .connected else {
//            if (peripheral.state == .disconnected) {
//                self.centralManager.connect(peripheral, options: nil)
//            }
//            return
//        }
//
//        guard let services = peripheral.services,
//              let service: CBService = services.first(where: { service in service.uuid == request.service }) else {
//            peripheral.discoverServices([request.service])
////            self.handleError(request: request, error: BluetoothGattManagerError.serviceNotFound)
//            return
//        }
//
//        guard let characteristics: [CBCharacteristic] = service.characteristics,
//              let characteristic: CBCharacteristic = characteristics.first(where: { characteristic in characteristic.uuid == request.characteristic }) else {
//            peripheral.discoverCharacteristics([request.characteristic], for: service)
////            self.handleError(request: request, error: BluetoothGattManagerError.characteristicNotFound)
//            return
//        }
//
//        peripheral.writeValue(request.data, for: characteristic, type: request.writeType)
//    }

//    private func execute(request: SetNotifyCharateristicOperation) throws {
//        guard let peripheral = self.centralManager.retrievePeripheral(withIdentifier: request.peripheralIdentifier) else {
//            throw BluetoothGattManagerError.peripheralNotFound
//        }
//
//        guard peripheral.state == .connected else {
//            if (peripheral.state == .disconnected) {
//                self.centralManager.connect(peripheral, options: nil)
//            }
//            return
//        }
//
//        guard let services = peripheral.services,
//              let service: CBService = services.first(where: { service in service.uuid == request.service }) else {
//            peripheral.discoverServices([request.service])
////            self.handleError(request: request, error: BluetoothGattManagerError.serviceNotFound)
//            return
//        }
//
//        guard let characteristics: [CBCharacteristic] = service.characteristics,
//              let characteristic: CBCharacteristic = characteristics.first(where: { characteristic in characteristic.uuid == request.characteristic }) else {
//            peripheral.discoverCharacteristics([request.characteristic], for: service)
////            self.handleError(request: request, error: BluetoothGattManagerError.characteristicNotFound)
//            return
//        }
//
//        peripheral.setNotifyValue(request.enabled, for: characteristic)
//    }

//    private func execute(request: ReadRssiOperation) throws {
//        guard let peripheral = self.centralManager.retrievePeripheral(withIdentifier: request.peripheralIdentifier) else {
//            throw BluetoothGattManagerError.peripheralNotFound
//        }
//
//        guard peripheral.state == .connected else {
//            if (peripheral.state == .disconnected) {
//                self.centralManager.connect(peripheral, options: nil)
//            }
//            return
//        }
//
//        peripheral.readRSSI()
//    }

    private func next() {
        var operation: any Operation
        if (!self.initialized && connectedPeripheral != nil) {
            guard self.initializeQueue.count > 0 else {
                self.currentInitializeOperation = nil
                self.initialized = true
                self.next()
                return
            }
            let first = self.initializeQueue.removeFirst()
            operation = first
            self.currentInitializeOperation = first
        }
        else {
            guard self.queue.count > 0 else {
                self.currentOperation = nil
                return
            }
            operation = self.queue.removeFirst()
            self.currentOperation = operation
        }
        self.execute(opt: operation)
    }

    private func handleError(opt: any Operation, error: Swift.Error) {
        self.currentOperation = nil
        self.currentInitializeOperation = nil
        self.queue.removeAll()
        self.initializeQueue.removeAll()
        self.tempPeripheral = nil

        if let opt = opt as? any BluetoothOperation {
            opt.onFailure(error)
        }

//        switch request.kind {
//        case .connect:
//            let req = request as! ConnectOperation
//            req.completionHandler?(.failure(error))
//        case .disconnect:
//            let req = request as! DisconnectOperation
//            req.completionHandler?(.failure(error))
//        case .discoverServices:
//            let req = request as! DiscoverServicesOperation
//            req.completionHandler?(.failure(error))
//        case .readCharacteristic:
//            let req = request as! ReadCharacteristicOperation
//            req.completionHandler?(.failure(error))
//        case .writeCharacteristic:
//            let req = request as! WriteCharacteristicOperation
//            req.completionHandler?(.failure(error))
//        case .discoverCharacteristics:
//            let req = request as! DiscoverCharacteristicsOperation
//            req.completionHandler?(.failure(error))
//        case .setNotificationCharacteristic:
//            let req = request as! SetNotifyCharateristicOperation
//            req.completionHandler?(.failure(error))
//        case .readRssi:
//            let req = request as! ReadRssiOperation
//            req.completionHandler?(.failure(error))
//        }

        // disconnect due to gatt error
        if let peripheral = self.centralManager.retrievePeripheral(withIdentifier: opt.peripheralIdentifier) {
            if (peripheral.state == .connected || peripheral.state == .connecting) {
                self.centralManager.cancelPeripheralConnection(peripheral)
            }
        }
    }

    deinit {
        Console.log()
    }
}

extension BleManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.centralManagerStatePublisher.send(central.state)
        if self.waitForReady == true,
           let pending = self.currentOperation
        {
            self.execute(opt: pending)
        }
    }

    // handle connect
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Console.log("\(peripheral.identifier)")
        self.connectionStatePublisher.send(PeripheralConnectionState(peripheral: peripheral, error: nil))
        self.tempPeripheral = nil
        self.connectedPeripheral = peripheral
        peripheral.delegate = self
        guard let currentRequest = self.currentOperation,
              currentRequest.peripheralIdentifier == CBUUID(nsuuid: peripheral.identifier)
        else {
            return
        }
        if let connectRequest = currentRequest as? ConnectOperation {
            if let initializer = self.initializer,
               !self.initialized
            {
                self.initializeQueue = initializer(connectRequest)
            }
            else {
                self.initialized = true
                connectRequest.onSuccess(ConnectResponse(peripheral: peripheral, request: connectRequest))
            }
            self.next()
        }
        else {
            self.execute(opt: currentRequest)
        }
    }

    // handle fail to connect
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Swift.Error?) {
        Console.log(error.debugDescription)
        self.tempPeripheral = nil
        guard let currentRequest = self.currentOperation,
              currentRequest.peripheralIdentifier == CBUUID(nsuuid: peripheral.identifier)
        else {
            return
        }
        self.handleError(opt: currentRequest, error: error ?? BluetoothGattManagerError.failToConnectUnknown)
    }

    // handle disconnect
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Swift.Error?) {
        self.connectionStatePublisher.send(PeripheralConnectionState(peripheral: peripheral, error: nil))
        Console.log(error.debugDescription)
        self.initialized = false
        self.connectedPeripheral = nil
//        peripheral.delegate = nil // TODO: not sure whether this is neccessary
        if let currentRequest = self.currentOperation,
           currentRequest.peripheralIdentifier == CBUUID(nsuuid: peripheral.identifier)
        {
            if let disconnectRequest = currentRequest as? DisconnectOperation,
               nil == error
            {
                disconnectRequest.onSuccess(DisconnectResponse(peripheral: peripheral, error: nil))
                self.next()
            }
            else {
                self.handleError(opt: currentRequest, error: error ?? BluetoothGattManagerError.disconnectedUnknown)
            }
        }
    }
}

extension BleManager: CBPeripheralDelegate {
    public func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
    }

    // trigger after the peripheral.writeValue + withoutResponse
    public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        if let writeOperation = self.currentOperation as? WriteCharacteristicOperation {
            guard let services = peripheral.services,
                  let service: CBService = services.first(where: { service in service.uuid == writeOperation.service }),
                  let characteristics = service.characteristics,
                  let characteristic = characteristics.first(where: { characteristic in characteristic.uuid == writeOperation.characteristic })
            else {
                return
            }

            writeOperation.completionHandler?(
                .success(WriteCharacteristicResponse(request: writeOperation, characteristic: characteristic))
            )
            self.next()
        }
    }

    // handle discovered services
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Swift.Error?) {
        Console.log(error.debugDescription)
        let currentOperation = self.initialized ? self.currentOperation : self.currentInitializeOperation
        guard let currentOperation = currentOperation as? any BluetoothGattOperation else {
            return
        }

        guard error == nil else {
            self.handleError(opt: currentOperation, error: error!)
            return
        }

        guard let services = peripheral.services else {
            self.handleError(opt: currentOperation, error: BluetoothGattManagerError.serviceNotFound)
            return
        }

        if let requires = currentOperation.requireServicesUuids() {
            for require in requires {
                guard services.contains(where: { $0.uuid == require }) else {
                    self.handleError(opt: currentOperation, error: BluetoothGattManagerError.serviceNotFound)
                    return
                }
            }
        }

        if let discoverServicesRequest = currentOperation as? DiscoverServicesOperation {
            discoverServicesRequest.completionHandler?(
                .success(DiscoverServicesResponse(request: discoverServicesRequest, peripheral: peripheral))
            )
            self.next()
        }
        else {
            self.execute(opt: currentOperation)
        }
    }

    // handle discovered charateristics
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Swift.Error?) {
        Console.log(service.characteristics?.debugDescription ?? "nil")
        let currentOperation = self.initialized ? self.currentOperation : self.currentInitializeOperation
        guard let currentOperation = currentOperation as? any BluetoothGattOperation else {
            return
        }

        guard error == nil else {
            self.handleError(opt: currentOperation, error: error!)
            return
        }

        guard let services = peripheral.services else {
            self.handleError(opt: currentOperation, error: BluetoothGattManagerError.serviceNotFound)
            return
        }

        if let discoverCharacteristicsRequest = currentOperation as? DiscoverCharacteristicsOperation {
            if let index = discoverCharacteristicsRequest.undiscoveredServices.firstIndex(where: { uuid in uuid == service.uuid }) {
                discoverCharacteristicsRequest.undiscoveredServices.remove(at: index)
                // wait all the characteristics being discovered
                if (discoverCharacteristicsRequest.undiscoveredServices.count > 0) {
                    return
                }
            }
            discoverCharacteristicsRequest.completionHandler?(
                .success(DiscoverCharacteristicsResponse(request: discoverCharacteristicsRequest, service: service))
            )
            self.next()
        }
        else {
            if let requireService = currentOperation.requireServicesUuids()?.first {
                // check whether service + characteristics exist
                guard let service = services.first(where: { $0.uuid == requireService }) else {
                    self.handleError(opt: currentOperation, error: BluetoothGattManagerError.serviceNotFound)
                    return
                }

                if let requireCharacteristics = currentOperation.requireCharacteristicUuids() {
                    guard let characteristics = service.characteristics else {
                        self.handleError(opt: currentOperation, error: BluetoothGattManagerError.characteristicNotFound)
                        return
                    }

                    // TODO: can be optimize
                    for requireCharacteristic in requireCharacteristics {
                        guard characteristics.map({ $0.uuid }).contains(requireCharacteristic) else {
                            self.handleError(opt: currentOperation, error: BluetoothGattManagerError.characteristicNotFound)
                            return
                        }
                    }
                }
            }

            self.execute(opt: currentOperation)
        }
    }

    // handle charaterisctic read/notify value
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        Console.log(characteristic.debugDescription)
        // notify
        if characteristic.properties.contains(.notify) {
            self.notificationCharacteristicPublisher.send(
                NotifyCharacteristicValue(
                    peripheral: peripheral,
                    characteristic: characteristic,
                    error: error
                )
            )
        }
        let currentOperation = self.initialized ? self.currentOperation : self.currentInitializeOperation
        guard let readCharOperation = currentOperation as? ReadCharacteristicOperation else {
            return
        }
        if let e = error {
            self.handleError(opt: readCharOperation, error: e)
        }
        else {
            readCharOperation.completionHandler?(
                .success(ReadCharacteristicResponse(request: readCharOperation, characteristic: characteristic))
            )
            self.next()
        }
    }

    // handle peripheral.writeValue + withResponse
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Swift.Error?) {
        Console.log(characteristic.debugDescription)
        let currentOperation = self.initialized ? self.currentOperation : self.currentInitializeOperation
        guard let writeCharOperation = currentOperation as? WriteCharacteristicOperation else {
            return
        }
        if let e = error {
            self.handleError(opt: writeCharOperation, error: e)
        }
        else {
            writeCharOperation.completionHandler?(
                .success(WriteCharacteristicResponse(request: writeCharOperation, characteristic: characteristic))
            )
            self.next()
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        Console.log(characteristic.debugDescription)
        let currentOperation = self.initialized ? self.currentOperation : self.currentInitializeOperation
        guard let notifyCharOperation = currentOperation as? SetNotifyCharateristicOperation else {
            return
        }
        if let e = error {
            self.handleError(opt: notifyCharOperation, error: e)
        }
        else {
            notifyCharOperation.completionHandler?(
                .success(SetNotifyCharacteristicResponse(request: notifyCharOperation, characteristic: characteristic))
            )
            self.next()
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        Console.log(RSSI)
        let currentOperator = self.initialized ? self.currentOperation : self.currentInitializeOperation
        guard let readRssiOperator = currentOperator as? ReadRssiOperation else {
            return
        }
        if let e = error {
            self.handleError(opt: readRssiOperator, error: e)
        }
        else {
            readRssiOperator.completionHandler?(
                .success(ReadRssiValue(peripheral: peripheral, rssi: RSSI.intValue))
            )
            self.next()
        }
    }
}

enum BluetoothGattManagerError: Swift.Error {
    case peripheralNotFound
    case serviceNotDiscovered
    case serviceNotFound
    case characteristicNotFound
//    case remoteDisconnected
//    case timeout
    case failToConnectUnknown
    case disconnectedUnknown
//    case busy
    case alreadyUsed(for: CBPeripheral)
}

extension CBCentralManager {
    func retrievePeripheral(withIdentifier nsuuid: UUID) -> CBPeripheral? {
        return self.retrievePeripherals(withIdentifiers: Array(arrayLiteral: nsuuid)).first
    }

    func retrievePeripheral(withIdentifier uuid: CBUUID) -> CBPeripheral? {
        return self.retrievePeripherals(withIdentifiers: Array(arrayLiteral: UUID(uuidString: uuid.uuidString)!)).first
    }
}

// http://software-dl.ti.com/simplelink/esd/simplelink_cc2640r2_sdk/4.20.00.04/exports/docs/blestack/ble_user_guide/doxygen/ble/html/group___g_a_t_t___p_r_o_p___b_i_t_m_a_p_s___d_e_f_i_n_e_s.html
// https://docs.microsoft.com/en-us/dotnet/api/corebluetooth.cbcharacteristicproperties?view=xamarin-ios-sdk-12
//enum BluetoothGattProperties: UInt, CustomStringConvertible {
//    // Permits signed writes to the Characteristic Value.
//    case GATT_PROP_AUTHEN = 0x40
//
//    // Permits broadcasts of the Characteristic Value.
//    case GATT_PROP_BCAST = 0x01
//
//    // Additional characteristic properties are defined in the Characteristic Extended Properties Descriptor.
//    case GATT_PROP_EXTENDED = 0x80
//
//    // Permits indications of a Characteristic Value with acknowledgement.
//    case GATT_PROP_INDICATE = 0x20
//
//    // Permits notifications of a Characteristic Value without acknowledgement.
//    case GATT_PROP_NOTIFY = 0x10
//
//    // Permits reads of the Characteristic Value.
//    case GATT_PROP_READ = 0x02
//
//    // Permits writes of the Characteristic Value with response.
//    case GATT_PROP_WRITE = 0x08
//
//    // Permits writes of the Characteristic Value without response.
//    case GATT_PROP_WRITE_NO_RSP = 0x04
//
//    var description: String {
//        var properties = [String]()
//        if (self.rawValue & BluetoothGattProperties.GATT_PROP_AUTHEN.rawValue != 0) {
//            properties.append("GATT_PROP_AUTHEN")
//        }
//        if (self.rawValue & BluetoothGattProperties.GATT_PROP_BCAST.rawValue != 0) {
//            properties.append("GATT_PROP_BCAST")
//        }
//        if (self.rawValue & BluetoothGattProperties.GATT_PROP_EXTENDED.rawValue != 0) {
//            properties.append("GATT_PROP_EXTENDED")
//        }
//        if (self.rawValue & BluetoothGattProperties.GATT_PROP_INDICATE.rawValue != 0) {
//            properties.append("GATT_PROP_INDICATE")
//        }
//        if (self.rawValue & BluetoothGattProperties.GATT_PROP_NOTIFY.rawValue != 0) {
//            properties.append("GATT_PROP_NOTIFY")
//        }
//        if (self.rawValue & BluetoothGattProperties.GATT_PROP_READ.rawValue != 0) {
//            properties.append("GATT_PROP_READ")
//        }
//        if (self.rawValue & BluetoothGattProperties.GATT_PROP_WRITE.rawValue != 0) {
//            properties.append("GATT_PROP_WRITE")
//        }
//        if (self.rawValue & BluetoothGattProperties.GATT_PROP_WRITE_NO_RSP.rawValue != 0) {
//            properties.append("GATT_PROP_WRITE_NO_RSP")
//        }
//        return properties.joined(separator: ", ")
//    }
//}
