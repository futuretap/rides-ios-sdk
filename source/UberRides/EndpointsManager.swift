//
//  EndpointsManager.swift
//  UberRides
//
//  Copyright © 2015 Uber Technologies, Inc. All rights reserved.
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

import CoreLocation

/**
 *  Protocol for all endpoints to conform to.
 */
protocol UberAPI {
    var body: Data? { get }
    var headers: [String: String]? { get }
    var host: String { get}
    var method: Method { get }
    var path: String { get }
    var query: [URLQueryItem] { get }
}

extension UberAPI {
    var body: Data? {
        return nil
    }
    
    var headers: [String: String]? {
        return nil
    }
    
    var host: String {
        if Configuration.getSandboxEnabled() {
            switch Configuration.getRegion() {
            case .china:
                return "https://sandbox-api.uber.com.cn"
            case .default:
                return "https://sandbox-api.uber.com"
            }
        } else {
            switch Configuration.getRegion() {
            case .china:
                return "https://api.uber.com.cn"
            case .default:
                return "https://api.uber.com"
            }
        }
    }
}

/**
 Enum for HTTPHeaders.
 */
enum Header: String {
    case Authorization = "Authorization"
    case ContentType = "Content-Type"
}

/// Convenience enum for managing versions of resources.
private enum Resources: String {
    case Estimates = "estimates"
    case Products = "products"
    case Request = "requests"
    
    fileprivate var version: String {
        switch self {
        case .Estimates: return "v1"
        case .Products: return "v1"
        case .Request: return "v1"
        }
    }
    
    fileprivate var basePath: String {
        return "/\(version)/\(rawValue)"
    }
}

/**
 Enum for HTTPMethods
 */
enum Method: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
}

/**
 Helper function to build array of NSURLQueryItems. A key-value pair with an empty string value is ignored.
 
 - parameter queries: tuples of key-value pairs
 - returns: an array of NSURLQueryItems
 */
func queryBuilder(_ queries: (name: String, value: String)...) -> [URLQueryItem] {
    var queryItems = [URLQueryItem]()
    for query in queries {
        if query.name.isEmpty || query.value.isEmpty {
            continue
        }
        queryItems.append(URLQueryItem(name: query.name, value: query.value))
    }
    return queryItems
}

/**
 API endpoints for the Products resource.
 
 - GetAll:     Returns information about the Uber products offered at a given location (lat, long).
 - GetProduct: Returns information about the Uber product specified by product ID.
 */
enum Products: UberAPI {
    case getAll(location: CLLocation)
    case getProduct(productID: String)
    
    var method: Method {
        switch self {
        case .getAll:
            fallthrough
        case .getProduct:
            return .GET
        }
    }
    
    var path: String {
        switch self {
        case .getAll:
            return Resources.Products.basePath
        case .getProduct(let productID):
            return "\(Resources.Products.basePath)/\(productID)"
        }
    }
    
    var query: [URLQueryItem] {
        switch self {
        case .getAll(let location):
            return queryBuilder(
            ("latitude", "\(location.coordinate.latitude)"),
            ("longitude", "\(location.coordinate.longitude)"))
        case .getProduct:
            return queryBuilder()
        }
    }
}

/**
 API Endpoints for the Estimates resource.
 
 - Price: Returns an estimated range for each product offered between two locations (lat, long).
 - Time:  Returns ETAs for all products offered at a given location (lat, long).
 */
enum Estimates: UberAPI {
    case price(startLocation: CLLocation, endLocation: CLLocation)
    case time(location: CLLocation, productID: String?)
    
    var method: Method {
        switch self {
        case .price:
            fallthrough
        case .time:
            return .GET
        }
    }
    
    var path: String {
        switch self {
        case .price:
            return "\(Resources.Estimates.basePath)/price"
        case .time:
            return "\(Resources.Estimates.basePath)/time"
        }
    }
    
    var query: [URLQueryItem] {
        switch self {
        case .price(let startLocation, let endLocation):
            return queryBuilder(
            ("start_latitude", "\(startLocation.coordinate.latitude)"),
            ("start_longitude", "\(startLocation.coordinate.longitude)"),
            ("end_latitude", "\(endLocation.coordinate.latitude)"),
            ("end_longitude", "\(endLocation.coordinate.longitude)"))
        case .time(let location, let productID):
            return queryBuilder(
            ("start_latitude", "\(location.coordinate.latitude)"),
            ("start_longitude", "\(location.coordinate.longitude)"),
            ("product_id", productID == nil ? "" : "\(productID!)"))
        }
    }
}


/**
 API endpoints for the Requests resource.
 
 - Estimate:   Gets an estimate for a ride given the desired product, start, and end locations.
 */
enum Requests: UberAPI {
    case estimate(rideParameters: RideParameters)
	
    var body: Data? {
        switch self {
        case .estimate(let rideParameters):
            return RideRequestDataBuilder(rideParameters: rideParameters).build() as Data?
		default:
			return nil
        }
    }
    
    var headers: [String : String]? {
        return [Header.ContentType.rawValue: "application/json"]
    }
    
    var method: Method {
        switch self {
        case .estimate:
            return .POST
        }
    }
    
    var path: String {
        switch self {
        case .estimate:
            return "\(Resources.Request.basePath)/estimate"
		default:
			fatalError("unimplemented")
		}
    }
    
    var query: [URLQueryItem] {
        return []
    }
}

