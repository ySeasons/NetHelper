//
//  NetHelper.swift
//  ZXCenter
//
//  Created by Seasons on 2019/5/17.
//  Copyright © 2019 zhongxiao. All rights reserved.
//

import Foundation

import Alamofire

typealias SuccessBlock = ([String:Any]) -> Void
typealias FailureBlock = (AnyObject) -> Void
typealias ProgressBlock = (Float) -> Void

class NetHelper: NSObject {
    static let shared = NetHelper()
    //MARK: - GET
    class func GET(url:String,params:[String:Any]?,success: @escaping SuccessBlock) {
        let urlPath:URL = URL(string: url)!
        let headers:HTTPHeaders = ["Content-Type":"application/json;charset=utf-8"]
        let request = AF.request(urlPath,method: .get,parameters: params,encoding: JSONEncoding.default, headers: headers)
        request.responseJSON { (response) in
            DispatchQueue.global().async(execute: {
                switch response.result {
                case let .success(result):
                    do {
                        let resultDict:[String:Any] = result as! [String:Any]
                        DispatchQueue.main.async(execute: {
                            success(resultDict)
                        })
                    }
                case let .failure(error):
                    print(error)
                }
            })
        }
    }
    //MARK: - POST (字典参数)
    class func POST(url:String,params:[String:Any]?,success: @escaping SuccessBlock) {
        let urlPath:URL = URL(string: url)!
        let headers:HTTPHeaders = ["Content-Type":"application/json;charset=utf-8"]
        let request = AF.request(urlPath,method: .post,parameters: params,encoding: JSONEncoding.default, headers: headers)
        request.responseJSON { (response) in
            DispatchQueue.global().async(execute: {
                switch response.result {
                case let .success(result):
                    do {
                        let resultDict:[String:Any] = result as! [String:Any]
                        DispatchQueue.main.async(execute: {
                            success(resultDict)
                        })
                    }
                case let .failure(error):
                    print(error)
                }
            })

        }
    }
    //MARK: - POST (数组参数)
    class func POST2(url:String,params:Array<[String:String]>,success: @escaping SuccessBlock) {
        let urlPath:URL = URL(string: url)!
        let data = try? JSONSerialization.data(withJSONObject: params, options: [])
        var urlRequest = URLRequest(url: urlPath)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = data
        urlRequest.allHTTPHeaderFields = ["application/json":"Accept","application/json;charset=UTF-8":"Content-Type"]

        let request = AF.request(urlRequest)
        request.responseJSON { (response) in
            DispatchQueue.global().async(execute: {
                switch response.result {
                case let .success(result):
                    do {
                        let resultDict:[String:Any] = result as! [String:Any]
                        DispatchQueue.main.async(execute: {
                            success(resultDict)
                        })
                    }
                case let .failure(error):
                    print(error)
                }

            })

        }
    }
    //MARK: - 多图上传 (UIImage图片 数组)
    class func IMGS(url:String,params:[String:Any],images:[UIImage],success: @escaping SuccessBlock) {
        let request3 = AF.upload(multipartFormData: { (mutilPartData) in
            var i:Int = 0
            for image:UIImage in images {
                let imgData:Data = UIImageJPEGRepresentation(image, 1)!
                let fileName = String(Date(timeIntervalSinceNow: 0).timeIntervalSince1970) + "_" + String(i) + ".jpg"
                mutilPartData.append(imgData, withName: "files", fileName: fileName, mimeType: "image/jpg/png/jpeg")
                i += 1
            }
            // 参数处理
            for key in params.keys {
                let value = params[key] as! String
                let vData:Data = value.data(using: .utf8)!
                mutilPartData.append(vData, withName: key)
            }
        }, to: url, usingThreshold: UInt64.init(), method: .post, headers: [], interceptor: nil, fileManager: FileManager())
        request3.uploadProgress { (progress) in
        }
        request3.responseJSON { (response) in
            DispatchQueue.global().async(execute: {
                switch response.result {
                case let .success(result):
                    do {
                        let resultDict:[String:Any] = result as! [String:Any]
                        DispatchQueue.main.async(execute: {
                            success(resultDict)
                        })
                    }
                case let .failure(error):
                    print(error)
                }
            })
        }
    }
    //MARK: - 多图上传 (地址图片 数组)
    class func IMGPath(url:String,params:[String:Any],images:[String],success: @escaping SuccessBlock) {
        let request3 = AF.upload(multipartFormData: { (mutilPartData) in
            //图片处理
            var i:Int = 0
            for path:String in images {
                let fileName = String(Date(timeIntervalSinceNow: 0).timeIntervalSince1970) + "_" + String(i) + ".jpg"
                mutilPartData.append(URL(fileURLWithPath: path), withName: "files", fileName: fileName , mimeType: "image/jpg/png/jpeg")
                i += 1
             }
            // 参数处理
            for key in params.keys {
                let value = params[key] as! String
                let vData:Data = value.data(using: .utf8)!
                mutilPartData.append(vData, withName: key)
            }
        }, to: url, usingThreshold: UInt64.init(), method: .post, headers: [], interceptor: nil, fileManager: FileManager())
        request3.responseJSON { (response) in
            DispatchQueue.global().async(execute: {
                switch response.result {
                case let .success(result):
                    do {
                        let resultDict:[String:Any] = result as! [String:Any]
                        DispatchQueue.main.async(execute: {
                            success(resultDict)
                        })
                    }
                case let .failure(error):
                    print(error)
                }
            })
        }
    }
    var isNetworking = false
    func startNetworking() {
        let manager = NetworkReachabilityManager(host: "www.baidu.com")
        manager?.startListening(onQueue: .main, onUpdatePerforming: { (state) in
            switch state {
            case .notReachable:
                self.isNetworking = false
                break
            case .unknown:
                self.isNetworking = false
                break
            case .reachable(.cellular): // 蜂窝
                self.isNetworking = true
                break
            case .reachable(.ethernetOrWiFi): //wifi
                self.isNetworking = true
                break
            }
        })
    }

}
