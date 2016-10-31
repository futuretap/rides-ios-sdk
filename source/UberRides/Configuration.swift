//
//  Configuration.swift
//  UberRides
//
//  Copyright © 2016 Uber Technologies, Inc. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import WebKit

/**
 An enum to represent the region that the SDK should use for making requests
 
 - Default: The default region
 - China:   China, for apps that are based in China
 */
@objc public enum Region : Int {
    case `default`
    case china
}

/**
 Class responsible for handling all of the SDK Configuration options. Provides
 default values for Application-wide configuration properties. All properties are 
 configurable via the respective setter method
*/
@objc(UBSDKConfiguration) open class Configuration : NSObject {
    // MARK : Variables
    
    /// The .plist file to use, default is Info.plist
    open static var plistName = "Info"
    
    /// The bundle that contains the .plist file. Default is the mainBundle()
    open static var bundle = Bundle.main
    
    fileprivate static let serverTokenKey = "UberServerToken"
	
    fileprivate static var serverToken: String?
    fileprivate static var region : Region = .default
    fileprivate static var isSandbox : Bool = false
	
    /// The string value of the current region setting
    open static var regionString: String {
        switch region {
        case .china:
            return "china"
        case .default:
            return "default"
        }
    }
    
    /// The current version of the SDK as a string
    open static var sdkVersion: String {
        guard let version = Bundle(for: self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            return "Unknown"
        }
        return version
    }
    
    /**
     Resets all of the Configuration's values to default
     */
    open static func restoreDefaults() {
        plistName = "Info"
        bundle = Bundle.main
        setServerToken(nil)
        setRegion(Region.default)
        setSandboxEnabled(false)
    }
    
    // MARK: Getters
    
    /**
     Gets the Server Token of this app. Defaults to the value stored in your Appication's
     plist if not set (UberServerToken)
     Optional. Used by the Request Button to get time estimates without requiring
     login
     
     - returns: The string Representing your app's server token
    */
    open static func getServerToken() -> String? {
        if serverToken == nil {
            serverToken = getDefaultValue(serverTokenKey)
        }
        
        return serverToken
    }
    
    /**
     Gets the current region the SDK is using. Defaults to Region.Default
     
     - returns: The Region the SDK is using
     */
    open static func getRegion() -> Region {
        return region
    }
    
    /**
     Returns if sandbox is enabled or not
     
     - returns: true if Sandbox is enabled, false otherwise
     */
    open static func getSandboxEnabled() -> Bool {
        return isSandbox
    }
    
    //MARK: Setters
    
    /**
     Sets a string to use as the Server Token. Overwrites the default value provided by
     the plist. Setting to nil will result in using the default value
     
     - parameter serverToken: The Server Token String to use
    */
    open static func setServerToken(_ serverToken: String?) {
        self.serverToken = serverToken
    }
    
    /**
     Set the region your app is registered in. Used to determine what endpoints to
     send requests to.
     
     - parameter region: The region the SDK should use
     */
    open static func setRegion(_ region: Region) {
        self.region = region
    }
    
    /**
     Enables / Disables Sandbox mode. When the SDK is in sandbox mode, all requests
     will go to the sandbox environment.
     
     - parameter enabled: Whether or not sandbox should be enabled
     */
    open static func setSandboxEnabled(_ enabled: Bool) {
        isSandbox = enabled
    }
	
    // MARK: Private
    
    fileprivate static func getPlistDictionary() -> [String : AnyObject]? {
        guard let path = bundle.path(forResource: plistName, ofType: "plist"),
            let dictionary = NSDictionary(contentsOfFile: path) as? [String: AnyObject] else {
                return nil
        }
        return dictionary
    }
    
    fileprivate static func getDefaultValue(_ key: String) -> String? {
        guard let dictionary = getPlistDictionary(),
            let defaultValue = dictionary[key] as? String else {
                return nil
        }

        return defaultValue
    }
    
//    fileprivate static func parseCallbackURIs() -> [CallbackURIType : String] {
//        guard let plist = getPlistDictionary(), let callbacks = plist[callbackURIsKey] as? [[String : AnyObject]] else {
//            return [CallbackURIType : String]()
//        }
//        var callbackURIs = [CallbackURIType : String]()
//        
//        for callbackObject in callbacks {
//            guard let callbackTypeString = callbackObject[callbackURIsTypeKey] as? String, let uriString = callbackObject[callbackURIStringKey] as? String else {
//                continue
//            }
//            let callbackType = CallbackURIType.fromString(callbackTypeString)
//            callbackURIs[callbackType] = uriString
//        }
//        return callbackURIs
//    }
//    
    fileprivate static func fatalConfigurationError(_ variableName: String, key: String ) -> Never  {
        fatalError("Unable to get your \(variableName). Did you forget to set it in your \(plistName).plist? (Should be under \(key) key)")
    }
    
}
