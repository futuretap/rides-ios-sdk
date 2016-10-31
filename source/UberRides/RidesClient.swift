//
//  RidesClient.swift
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

/// API client for the Uber Rides API.
@objc(UBSDKRidesClient) open class RidesClient: NSObject {
	
    /// NSURLSession used to make requests to Uber API. Default session configuration unless otherwise initialized.
    var session: URLSession
    
    /// Developer server token.
    fileprivate var serverToken: String? = Configuration.getServerToken()
    
    /**
     Initializer for the RidesClient. The RidesClient handles making reqeusts to the API
     for you.
     
     - parameter sessionConfiguration:  Configuration to use for NSURLSession. Defaults to defaultSessionConfiguration.
	
     - returns: An initialized RidesClient
     */
    @objc public init(sessionConfiguration: URLSessionConfiguration) {
        self.session = URLSession(configuration: sessionConfiguration)
    }

    /**
     Initializer for the RidesClient. The RidesClient handles making reqeusts to the API
     for you.
     Also uses NSURLSessionConfiguration.defaultSessionConfiguration() for the URL requests
     
     - returns: An initialized RidesClient
     */
    @objc public convenience override init() {
        self.init(sessionConfiguration: URLSessionConfiguration.default)
    }
    
	
    // MARK: Helper functions
    
    /**
    Helper function to execute request. All endpoints should use this function.
    
    - parameter endpoint:   endpoint that conforms to UberAPI.
    - parameter completion: completion block for when request is completed.
    */
    fileprivate func apiCall(_ endpoint: UberAPI, completion: @escaping (_ response: Response) -> Void) {
		
        let request = Request(session: session, endpoint: endpoint, serverToken: serverToken as NSString?)
        request.execute({
            response in
            completion(response)
        })
    }
	
    // MARK: Endpoints
    
    /**
    Convenience function for returning cheapest product at location.
    
    - parameter location:  coordinates of pickup location.
    - parameter completion: completion handler for returned product.
    */
    @objc open func fetchCheapestProduct(pickupLocation location: CLLocation, completion:@escaping (_ product: UberProduct?, _ response: Response) -> Void) {
        fetchProducts(pickupLocation: location, completion:{ products, response in
            let filteredProducts = products.filter({$0.priceDetails != nil && $0.priceDetails!.minimumFee > 0})
            if filteredProducts.count == 0 {
                completion(nil, response)
                return
            }
            
            // Find cheapest product by first comparing minimum value, then by cost per distance; compared in order such that products earlier in display order are favored.
            let cheapestMinimumValue = filteredProducts.reduce(filteredProducts[0].priceDetails!.minimumFee, {min($0, $1.priceDetails!.minimumFee)})
            let cheapestProducts = filteredProducts.filter({$0.priceDetails!.minimumFee == cheapestMinimumValue})
            let cheapest = cheapestProducts.reduce(cheapestProducts[0], {$1.priceDetails!.costPerDistance < $0.priceDetails!.costPerDistance ? $1 : $0})
            
            completion(cheapest, response)
        })
    }
    
    /**
     Get all products at specified location.
     
     - parameter location:  coordinates of pickup location
     - parameter completion: completion handler for returned products.
     */
    @objc open func fetchProducts(pickupLocation location: CLLocation, completion:@escaping (_ products: [UberProduct], _ response: Response) -> Void) {
        let endpoint = Products.getAll(location: location)
        apiCall(endpoint, completion: { response in
            var products: UberProducts?
            if response.error == nil {
                products = ModelMapper<UberProducts>().mapFromJSON(response.toJSONString())
                if let productList = products?.list {
                    completion(productList, response)
                    return
                }
            }
            completion([], response)
        })
    }
    
    /**
     Get information for specific product.
     
     - parameter productID:  string representing product ID.
     - parameter completion: completion handler for returned product.
     */
    @objc open func fetchProduct(_ productID: String, completion:@escaping (_ product: UberProduct?, _ response: Response) -> Void) {
        let endpoint = Products.getProduct(productID: productID)
        apiCall(endpoint, completion: { response in
            var product: UberProduct?
            if response.error == nil {
                product = ModelMapper<UberProduct>().mapFromJSON(response.toJSONString())
            }
            completion(product, response)
        })
    }
    
    /**
     Get time estimates for all products (or specific product) at specified pickup location.
     
     - parameter pickupLocation:  coordinates of pickup location
     - parameter productID:  optional string representing the productID.
     - parameter completion: completion handler for returned estimates.
     */
    @objc open func fetchTimeEstimates(pickupLocation location: CLLocation, productID: String? = nil, completion:@escaping (_ timeEstimates: [TimeEstimate], _ response: Response) -> Void) {
        let endpoint = Estimates.time(location: location, productID: productID)
        apiCall(endpoint, completion: { response in
            var timeEstimates: TimeEstimates?
            if response.error == nil {
                timeEstimates = ModelMapper<TimeEstimates>().mapFromJSON(response.toJSONString())
                if let estimateList = timeEstimates?.list {
                    completion(estimateList, response)
                    return
                }
            }
            completion([], response)
        })
    }
    
    /**
     Get price estimates for all products between specified pickup and dropoff locations.
     
     - parameter pickupLocation:   coordinates of pickup location.
     - parameter dropoffLocation:  coordinates of dropoff location
     - parameter completion:       completion handler for returned estimates.
     */
    @objc open func fetchPriceEstimates(pickupLocation: CLLocation, dropoffLocation: CLLocation, completion:@escaping (_ priceEstimates: [PriceEstimate], _ response: Response) -> Void) {
        let endpoint = Estimates.price(startLocation: pickupLocation,
                                       endLocation: dropoffLocation)
        apiCall(endpoint, completion: { response in
            var priceEstimates: PriceEstimates?
            if response.error == nil {
                priceEstimates = ModelMapper<PriceEstimates>().mapFromJSON(response.toJSONString())
                if let estimateList = priceEstimates?.list {
                    completion(estimateList, response)
                    return
                }
            }
            completion([], response)
        })
    }
	
	/**
     Estimate a ride request given the desired product, start, and end locations.
     
     - parameter rideParameters: RideParameters object containing necessary information.
     - parameter completion:  completion handler for returned estimate.
     */
    @objc open func fetchRideRequestEstimate(_ rideParameters: RideParameters, completion:@escaping (_ estimate: RideEstimate?, _ response: Response) -> Void) {
        let endpoint = Requests.estimate(rideParameters: rideParameters)
        apiCall(endpoint, completion: { response in
            var estimate: RideEstimate? = nil
            if response.error == nil {
                estimate = ModelMapper<RideEstimate>().mapFromJSON(response.toJSONString())
            }
            completion(estimate, response)
        })
    }
}
