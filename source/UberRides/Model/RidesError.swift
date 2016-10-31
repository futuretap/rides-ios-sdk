//
//  RidesError.swift
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

import ObjectMapper

// MARK: RidesError

/// Base class for errors that can be mapped from HTTP responses.
@objc(UBSDKRidesError) open class RidesError : NSObject {
    /// HTTP status code for error.
    open internal(set) var status: Int = -1
    
    /// Human readable message which corresponds to the client error.
    open internal(set) var title: String?
    
    /// Underscore delimited string.
    open internal(set) var code: String?
    
    /// Additional information about errors. Can be "fields" or "meta" as the key.
    open internal(set) var meta: [String: AnyObject]?
    
    /// List of additional errors. This can be populated instead of status/code/title.
    open internal(set) var errors: [RidesError]?

    override init() {
    }
    
    public required init?(map: Map) {
    }
}

extension RidesError: UberModel {
    public func mapping(map: Map) {
        code    <- map["code"]
        status  <- map["status"]
        errors  <- map["errors"]
        
        if map["message"].currentValue != nil {
            title <- map["message"]
        } else if map["title"].currentValue != nil {
            title <- map["title"]
        }
        
        if map["fields"].currentValue != nil {
            meta  <- map["fields"]
        } else if map["meta"].currentValue != nil {
            meta  <- map["meta"]
        }
        
        if map["error"].currentValue != nil {
            title <- map["error"]
        }
    }
}

// MARK: RidesError subclasses

/// Client error 4xx.
@objc(UBSDKRidesClientError) open class RidesClientError: RidesError {

    public required init?(map: Map) {
        super.init(map: map)
    }
}

/// Server error 5xx.
@objc(UBSDKRidesServerError) open class RidesServerError: RidesError {
    
    public required init?(map: Map) {
        super.init(map: map)
    }
}

/// Unknown error type.
@objc(UBSDKRidesUnknownError) open class RidesUnknownError: RidesError {
    
    override init() {
        super.init()
    }
    
    public required init?(map: Map) {
        super.init(map: map)
    }
}
