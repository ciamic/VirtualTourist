//
//  CancellablePromise.swift
//
//  Copyright (c) 2017 michelangelo
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
import Alamofire
import PromiseKit

class CancellablePromise<Data>: Promise<Data> {
    
    private var task: DataRequest?
    private var fulfill: ((Data) -> Void)?
    private var reject: ((Error) -> Void)?
    
    init(withRequest request: URLRequest) {
        var fulfill: ((Data) -> Void)?
        var reject: ((Error) -> Void)?
        
        super.init { f, r in
            fulfill = f
            reject = r
        }
        
        self.fulfill = fulfill
        self.reject  = reject
        
        task = Alamofire.request(request).validate().responseJSON { data in
            
            switch data.result {
            case .failure(let error):
                if error.isCancelledError {
                    return
                }
                self.reject?(error)
                return
                
            case .success(let value):
                self.fulfill?(value as! Data)
            }
        
        }
        
        /* old version with URLSession. Now Alamofire is used instead.
        self.task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                if error.isCancelledError {
                    return
                }
                self.reject?(error)
                return
            }
            guard let data = data else {
                self.reject?(NSError(domain: "no data", code: 0, userInfo: nil))
                return
            }
            self.fulfill?(data)
        }
        self.task?.resume()
        */
        
    }
    
    required public init(resolvers: (@escaping (Data) -> Void, @escaping (Error) -> Void) throws -> Void) {
        super.init(resolvers: resolvers)
    }
    
    required public init(value: Data) {
        super.init(value: value)
    }
    
    required public init(error: Error) {
        super.init(error: error)
    }
    
    public func cancel() {
        guard !self.isRejected else { return }
        self.task?.cancel()
        self.reject?(NSError.cancelledError())
    }
    
}
