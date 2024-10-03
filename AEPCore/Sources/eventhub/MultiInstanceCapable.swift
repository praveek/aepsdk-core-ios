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

/// A marker protocol indicating that an `Extension` supports multiple instances.
///
/// Types conforming to both `Extension` and `MultiInstanceCapable` can be instantiated multiple times.
/// This protocol does not define any methods or properties; it serves solely to mark extensions
/// that are capable of supporting multiple concurrent instances.
///
/// Conform to `MultiInstanceCapable` to have your extension recognized as capable of supporting multiple instances
/// and to enable its registration across various SDK instances.
///
@objc(AEPMultiInstanceCapable)
public protocol MultiInstanceCapable {}
