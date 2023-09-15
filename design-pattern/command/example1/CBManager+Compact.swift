//
//  CBManager+Compact.swift
//
//  Created by dev on 05/07/2021.
//

import Foundation
import CoreBluetooth

extension CBManager {
    static func getAuthorizationStatusCompact(manager: CBManager) -> CBManagerAuthorization {
        if #available(iOS 13.1, *) {
            return CBManager.authorization
        }
        return manager.authorization
    }

    func availability() throws -> Bool {
        switch self.state {
        case .unknown:
            fallthrough
        case .resetting:
            return false
        case .unsupported:
            throw CBManagerAvailabilityError.unsupported
        case .unauthorized:
            let authorizedStatus = CBManager.getAuthorizationStatusCompact(manager: self)
            switch authorizedStatus {
            case .restricted:
                throw CBManagerAvailabilityError.restricted
            case .denied:
                throw CBManagerAvailabilityError.denied
            // The cases below should never be triggered because the CBManagerState
            // is unauthorized. Meaning that it is a determinable state and is not allowed.
            case .notDetermined:
                throw CBManagerAvailabilityError.notDetermined
            case .allowedAlways:
                return true
            @unknown default:
                throw CBManagerAvailabilityError.unknownAuthorizationStatus(status: authorizedStatus)
            }
        case .poweredOff:
            throw CBManagerAvailabilityError.poweredOff
        case .poweredOn:
            return true
        @unknown default:
            throw CBManagerAvailabilityError.unknownState(state: state)
        }
    }
}

enum CBManagerAvailabilityError: Swift.Error {
    case notDetermined
    case unsupported
    case restricted
    case denied
    case poweredOff
    case unknownState(state: CBManagerState)
    case unknownAuthorizationStatus(status: CBManagerAuthorization)
}

extension CBManagerAvailabilityError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .unsupported:
            return "Application won't run without Bluetooth, which are not supported by your device."
        case .notDetermined:
            return "Bluetooth is not ready. Please try to restart the Bluetooth."
        case .restricted:
            return "Bluetooth permission is restricted. Please allow it for this application in the Settings > Privacy > Bluetooth."
        case .denied:
            return "Bluetooth permission is denied. Please allow it for this application in the Settings > Privacy > Bluetooth."
        case .poweredOff:
            return "Bluetooth is powered off. Please enable Bluetooth and \"Allow New Connections\" in the Settings."
        case .unknownState(let state):
            return "Bluetooth error with state=\(state.rawValue)."
        case .unknownAuthorizationStatus(let status):
            return "Bluetooth error with status=\(status.rawValue)."
        }
    }
}
