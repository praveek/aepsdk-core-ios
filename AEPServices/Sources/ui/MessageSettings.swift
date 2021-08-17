/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation
import UIKit

///
/// The `MessageSettings` class defines how a message should be constructed, how and where it should be displayed,
/// and how the user can interact with it.
///
/// `MessageSettings` uses a builder pattern for construction. The `parent` can only be set during initialization.
///
@objc(AEPMessageSettings)
@objcMembers
public class MessageSettings: NSObject {
    /// Object that owns the message created using these settings.
    public let parent: Any?
    
    /// Width of the view in which the message is displayed. Represented in percentage of the total screen width.
    public private(set) var width: Int?
    
    /// Height of the view in which the message is displayed. Represented in percentage of the total screen height.
    public private(set) var height: Int?
    
    /// Defines the vertical alignment of the message.  See `MessageAlignment`.
    public private(set) var verticalAlign: MessageAlignment?
    
    /// Defines the vertical inset respective to the `verticalAlign`. Represented in percentage of the total screen height.
    public private(set) var verticalInset: Int?
    
    /// Defines the horizontal alignment of the message.  See `MessageAlignment`.
    public private(set) var horizontalAlign: MessageAlignment?
    
    /// Defines the horizontal inset respective to the `horizontalAlign`. Represented in percentage of the total screen width.
    public private(set) var horizontalInset: Int?
    
    /// If true, a displayed message will prevent the user from other UI interactions
    public private(set) var uiTakeover: Bool?
    
    /// A mapping of gestures and their associated behaviors.
    /// The URL will be executed as javascript in the message's underlying webview.
    /// See `MessageGesture`
    public private(set) var gestures: [MessageGesture: URL]?
    
    /// Defines the animation to be used when the message is displayed. See `MessageAnimation`.
    public private(set) var dismissAnimation: MessageAnimation?
    
    /// Defines the animation to be used when the message is dismissed. See `MessageAnimation`.
    public private(set) var displayAnimation: MessageAnimation?

    
    public init(parent: Any? = nil) {
        self.parent = parent
    }
    
    @discardableResult public func setWidth(_ width: Int?) -> MessageSettings {
        self.width = width
        return self
    }

    @discardableResult public func setHeight(_ height: Int?) -> MessageSettings {
        self.height = height
        return self
    }

    @discardableResult public func setVerticalAlign(_ vAlign: MessageAlignment?) -> MessageSettings {
        self.verticalAlign = vAlign ?? .center
        return self
    }

    @discardableResult public func setHorizontalAlign(_ hAlign: MessageAlignment?) -> MessageSettings {
        self.horizontalAlign = hAlign ?? .center
        return self
    }

    @discardableResult public func setVerticalInset(_ vInset: Int?) -> MessageSettings {
        self.verticalInset = vInset
        return self
    }

    @discardableResult public func setHorizontalInset(_ hInset: Int?) -> MessageSettings {
        self.horizontalInset = hInset
        return self
    }

    @discardableResult public func setUiTakeover(_ uiTakeover: Bool?) -> MessageSettings {
        self.uiTakeover = uiTakeover ?? false
        return self
    }

    @discardableResult public func setGestures(_ gestures: [MessageGesture: URL]?) -> MessageSettings {
        self.gestures = gestures
        return self
    }

    @discardableResult public func setDisplayAnimation(_ animation: MessageAnimation?) -> MessageSettings {
        self.displayAnimation = animation ?? MessageAnimation.none
        return self
    }

    @discardableResult public func setDismissAnimation(_ animation: MessageAnimation?) -> MessageSettings {
        self.dismissAnimation = animation ?? MessageAnimation.none
        return self
    }
}
