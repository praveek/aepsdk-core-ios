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
import AEPServices

// Adding these convenience APIs for testing purposes. Further investigation is needed for public APIs.
public extension MobileCore {
    static func registerExtensions(tenantID: String, _ extensions: [NSObject.Type], _ completion: (() -> Void)? = nil) {
        // Register native extensions
        let registeredCounter = AtomicCounter()
        let tenantAwareExtensions = extensions.filter {
            let isSupported = ($0.self is TenantAwareExtension.Type)
            if !isSupported {
                Log.error(label: LOG_TAG, "\($0.self) extension will not be registered as it is not tenant-aware.")
            }
            return isSupported
        } // All extensions that conform to TenantAware protocol
        let allExtensions = [Configuration.self] + tenantAwareExtensions
        let nativeExtensions = allExtensions.filter({$0.self is Extension.Type}) as? [Extension.Type] ?? []

        let eventHub = EventHub.create(tenant: .id(tenantID))
        nativeExtensions.forEach {
            eventHub.registerExtension($0) { _ in
                if registeredCounter.incrementAndGet() == allExtensions.count {
                    eventHub.start()
                    completion?()
                    return
                }
            }
        }
    }

    static func dispatch(tenantID: String, event: Event) {
        let eventHub = EventHub.instance(tenant: .id(tenantID))
        eventHub?.dispatch(event: event)
    }

    /// Configure the SDK by downloading the remote configuration file hosted on Adobe servers
    /// specified by the given application ID. The configuration file is cached once downloaded
    /// and used in subsequent calls to this API. If the remote file is updated after the first
    /// download, the updated file is downloaded and replaces the cached file.
    /// - Parameter appId: A unique identifier assigned to the app instance by Adobe Launch
    static func configureWith(tenantID: String, appId: String) {
        let event = Event(name: CoreConstants.EventNames.CONFIGURE_WITH_APP_ID, type: EventType.configuration, source: EventSource.requestContent,
                          data: [CoreConstants.Keys.JSON_APP_ID: appId])
        MobileCore.dispatch(tenantID: tenantID, event: event)
    }

    /// Configure the SDK by reading a local file containing the JSON configuration. On application relaunch,
    /// the configuration from the file at `filePath` is not preserved and this method must be called again if desired.
    /// - Parameter filePath: Absolute path to a local configuration file.
    static func configureWith(tenantID: String, filePath: String) {
        let event = Event(name: CoreConstants.EventNames.CONFIGURE_WITH_FILE_PATH, type: EventType.configuration, source: EventSource.requestContent,
                          data: [CoreConstants.Keys.JSON_FILE_PATH: filePath])
        MobileCore.dispatch(tenantID: tenantID, event: event)
    }

    /// Update the current SDK configuration with specific key/value pairs. Keys not found in the current
    /// configuration are added. Configuration updates are preserved and applied over existing or new
    /// configuration even across application restarts.
    ///
    /// Using `nil` values is allowed and effectively removes the configuration parameter from the current configuration.
    /// - Parameter configDict: configuration key/value pairs to be updated or added.
    static func updateConfigurationWith(tenantID: String, configDict: [String: Any]) {
        let event = Event(name: CoreConstants.EventNames.CONFIGURATION_UPDATE, type: EventType.configuration, source: EventSource.requestContent,
                          data: [CoreConstants.Keys.UPDATE_CONFIG: configDict])
        MobileCore.dispatch(tenantID: tenantID, event: event)
    }

    /// Clears the changes made by ``updateConfigurationWith(configDict:)`` and ``setPrivacyStatus(_:)`` to the initial configuration
    /// provided by either ``configureWith(appId:)`` or ``configureWith(filePath:)``
    static func clearUpdatedConfiguration(tenantID: String) {
        let event = Event(name: CoreConstants.EventNames.CLEAR_UPDATED_CONFIGURATION, type: EventType.configuration, source: EventSource.requestContent, data: [CoreConstants.Keys.CLEAR_UPDATED_CONFIG: true])
        MobileCore.dispatch(tenantID: tenantID, event: event)
    }

    /// Sets the `PrivacyStatus` for this SDK. The set privacy status is preserved and applied over any new
    /// configuration changes from calls to configureWithAppId or configureWithFileInPath,
    /// even across application restarts.
    /// - Parameter status: `PrivacyStatus` to be set for the SDK
    static func setPrivacyStatus(tenantID: String, _ status: PrivacyStatus) {
        updateConfigurationWith(tenantID: tenantID, configDict: [CoreConstants.Keys.GLOBAL_CONFIG_PRIVACY: status.rawValue])
    }

    /// Gets the currently configured `PrivacyStatus` and returns it via `completion`
    /// - Parameter completion: Invoked with the current `PrivacyStatus`
    static func getPrivacyStatus(tenantID: String, completion: @escaping (PrivacyStatus) -> Void) {
        let event = Event(name: CoreConstants.EventNames.PRIVACY_STATUS_REQUEST, type: EventType.configuration, source: EventSource.requestContent, data: [CoreConstants.Keys.RETRIEVE_CONFIG: true])

        let eventHub = EventHub.create(tenant: .id(tenantID))
        eventHub.registerResponseListener(triggerEvent: event, timeout: CoreConstants.API_TIMEOUT) { responseEvent in
            guard let privacyStatusString = responseEvent?.data?[CoreConstants.Keys.GLOBAL_CONFIG_PRIVACY] as? String else {
                return completion(PrivacyStatus.unknown)
            }
            completion(PrivacyStatus(rawValue: privacyStatusString) ?? PrivacyStatus.unknown)
        }

        MobileCore.dispatch(tenantID: tenantID, event: event)
    }
}
