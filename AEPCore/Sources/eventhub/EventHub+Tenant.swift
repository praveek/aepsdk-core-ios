//
/*
 Copyright 2024 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

// Todo: The tenantIDs should be persisted internally by the SDK for cleanup and migration purposes. 
final class EventHubManager {
    // Store for tenant-specific EventHub instances
    private static var tenantStore: [Tenant: EventHub] = [
        .default: EventHub(tenant: .default)
    ]

    // Dispatch queue for thread safety
    private static let accessQueue = DispatchQueue(label: "com.eventHubManager.queue")

    // Create or retrieve an EventHub instance for a specific tenant
    static func createInstance(tenant: Tenant) -> EventHub {
        return accessQueue.sync {
            if let hub = tenantStore[tenant] {
                return hub
            } else {
                let newHub = EventHub(tenant: tenant)
                tenantStore[tenant] = newHub
                return newHub
            }
        }
    }

    // Retrieve an EventHub instance for a specific tenant or return the default instance
    static func instance(tenant: Tenant = .default) -> EventHub? {
        return accessQueue.sync {
            tenantStore[tenant]
        }
    }
}

extension EventHub {
    static func instance(tenant: Tenant = .default) -> EventHub? {
        return EventHubManager.instance(tenant: tenant)
    }

    static func create(tenant: Tenant) -> EventHub {
        return EventHubManager.createInstance(tenant: tenant)
    }
}
