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

    class func GET(url:String,params:[String:Any]?,success: @escaping SuccessBlock) {
        let param = params
        if param != nil {
            Printy("\n param:")
            Printy(YType.stringWithJson(element: param as Any))
        }

        let access_token = UserDefaults.standard.value(forKey: "access_token")
        var urlString = url
        if access_token != nil {
            if urlString.contains("?") == true {
                urlString = urlString + "&access_token=" + ((access_token as? String)!)
            } else {
                urlString = urlString + "?access_token=" + ((access_token as? String)!)
            }
        }
        Printy("url===:" + urlString)
        let urlPath:URL = URL(string: urlString)!
        let headers:HTTPHeaders = ["Content-Type":"application/json;charset=utf-8"]
        let request = AF.request(urlPath,method: .get,parameters: params,encoding: JSONEncoding.default, headers: headers)
        request.responseJSON { (response) in
            DispatchQueue.global().async(execute: {
                Printy(response.result)
                switch response.result {
                case let .success(result):
                    do {
                        let resultDict:[String:Any] = result as! [String:Any]
                        DispatchQueue.main.async(execute: {

                            if resultDict.keys.contains("resp_code") == false {
                                return
                            }
                            /** 返回码 (Int 类型code 会报崩)
                             * 0 成功
                             * 1 查询错误
                             * 401 退出登录 8888 顶号
                             * 400 及其他402... 请求型错误
                             */
                            let code = resultDict["resp_code"]
                            var resp_code = 0
                            if code is String {
                                resp_code = Int(code as! String)!
                            } else if code is Int {
                                resp_code = code as! Int
                            }
//                            let resp_code: Int = (resultDict["resp_code"] as! Int)
                            switch resp_code {
                            case 0:
                                // 返回 resultDict["datas"]  ""
                                // 返回 resultDict["datas"]  [String:Any] 对象
                                // 返回 resultDict["datas"]  [stri] 数组
                                success(resultDict)
                            case 1:
                                SVProgressHUD.showError(withStatus: (resultDict["resp_msg"] as! String))
                            case 401,8888:
                                UserInfo.clearLoginInfo()
                                if resp_code == 401 {
                                    SVProgressHUD.showInfo(withStatus: "登录已过期，请重新登录！")
                                } else {
                                    SVProgressHUD.showInfo(withStatus: (resultDict["resp_msg"] as! String))
                                }
                                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+2.0) {
                                    let loginVC = ZXLoginViewController()
                                    let naviVC = YNavigationViewController.init(rootViewController: loginVC)
                                    KScreenWindow?.rootViewController = naviVC

                                }
                            case 500:
                                SVProgressHUD.showInfo(withStatus: "网络不给力，请再试一次吧")
                            default:
                                SVProgressHUD.showError(withStatus: (resultDict["resp_msg"] as! String))
                            }
                        })
                    }
                case let .failure(error):
//                    SVProgressHUD.dismiss()
                    SVProgressHUD.showInfo(withStatus: "网络不给力，请再试一次吧")
                    Printy(error)
                }

            })
        }
    }
    class func POST(url:String,params:[String:Any]?,success: @escaping SuccessBlock) {
        let access_token = UserDefaults.standard.value(forKey: "access_token")
        var urlString = url
        if access_token != nil && urlString.contains("oauth/token") == false {
            urlString = urlString + "?access_token=" + ((access_token as? String)!)
        }
        Printy("url===:" + urlString)
        let urlPath:URL = URL(string: urlString)!
        if params != nil {
            Printy("\n params:")
            Printy(YType.stringWithJson(element: params as Any))
        }
        let headers:HTTPHeaders = ["Content-Type":"application/json;charset=UTF-8"]
        let request = AF.request(urlPath,method: .post,parameters: params,encoding: JSONEncoding.default, headers: headers)
        request.responseJSON { (response) in
            DispatchQueue.global().async(execute: {
                Printy(response.result)
                switch response.result {
                case let .success(result):
                    do {
                        let resultDict:[String:Any] = result as! [String:Any]
                        DispatchQueue.main.async(execute: {
                            // 登录时存储 access_token
                            if resultDict.keys.contains("access_token") && url.contains("oauth/token") == true { UserDefaults.standard.set(resultDict["access_token"], forKey: "access_token")
                                success(resultDict)
                                return
                            }

                            if (resultDict.keys.contains("resp_code") == false && url.contains("newPay") == false) {
                                return
                            }
                            /** 返回码 (Int 类型code 会报崩)
                             * 0 成功
                             * 1 查询错误
                             * 401 退出登录
                             * 400 及其他402... 请求型错误
                             */
                            let code = resultDict["resp_code"]
                            var resp_code = 0
                            if code is String {
                                resp_code = Int(code as! String)!
                            } else if code is Int {
                                resp_code = code as! Int
                            }
                            // 发起支付接口 code
                            if (url.contains("newPay") == true) {
                                resp_code = resultDict["code"] as! Int
                            }

//                            let resp_code: Int = (resultDict["resp_code"] as! Int)
                            switch resp_code {
                            case 0:
                                // 返回 resultDict["datas"]  ""
                                // 返回 resultDict["datas"]  [String:Any] 对象
                                // 返回 resultDict["datas"]  [stri] 数组

                                // 验证码登录
                                if url.contains("user/login") == true {
                                    let datas:[String:Any] = resultDict["datas"] as! [String:Any]
                                    UserDefaults.standard.set(datas["access_token"], forKey: "access_token")
                                }

                                success(resultDict)
                            case 1:
                                if url.contains("org/apply") == true {
                                    success(resultDict)
                                } else {
                                    SVProgressHUD.showError(withStatus: (resultDict["resp_msg"] as! String))
                                }
                            case 401,8888:
                                UserInfo.clearLoginInfo()
                                if resp_code == 401 {
                                    SVProgressHUD.showInfo(withStatus: "登录已过期，请重新登录！")
                                } else {
                                    SVProgressHUD.showInfo(withStatus: (resultDict["resp_msg"] as! String))
                                }
                                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+2.0) {
                                    let loginVC = ZXLoginViewController()
                                    let naviVC = YNavigationViewController.init(rootViewController: loginVC)
                                    KScreenWindow?.rootViewController = naviVC

                                }
                            case 500:
                                SVProgressHUD.showInfo(withStatus: "网络不给力，请再试一次吧")
                            default:
                                SVProgressHUD.showError(withStatus: (resultDict["resp_msg"] as! String))
                            }
                        })
                    }
                case let .failure(error):
//                    SVProgressHUD.dismiss()
                    SVProgressHUD.showInfo(withStatus: "网络不给力，请再试一次吧")
                    Printy(error)
                }

            })

        }
    }
    class func POST2(url:String,params:Array<[String:String]>,success: @escaping SuccessBlock) {
        let access_token = UserDefaults.standard.value(forKey: "access_token")
        var urlString = url
        if access_token != nil && urlString.contains("oauth/token") == false {
            urlString = urlString + "?access_token=" + ((access_token as? String)!)
        }
        Printy("url===:" + urlString)
        let urlPath:URL = URL(string: urlString)!
        Printy("\n params:")
        Printy(YType.stringWithJson(element: params as Any))

        let data = try? JSONSerialization.data(withJSONObject: params, options: [])
        var urlRequest = URLRequest(url: urlPath)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = data
        urlRequest.allHTTPHeaderFields = ["application/json":"Accept","application/json;charset=UTF-8":"Content-Type"]

        let request = AF.request(urlRequest)
        request.responseJSON { (response) in
            DispatchQueue.global().async(execute: {
                Printy(response.result)
                switch response.result {
                case let .success(result):
                    do {
                        let resultDict:[String:Any] = result as! [String:Any]
                        DispatchQueue.main.async(execute: {
                            if resultDict.keys.contains("resp_code") == false {
                                return
                            }
                            /** 返回码 (Int 类型code 会报崩)
                             * 0 成功
                             * 1 查询错误
                             * 401 退出登录
                             * 400 及其他402... 请求型错误
                             */
                            let code = resultDict["resp_code"]
                            var resp_code = 0
                            if code is String {
                                resp_code = Int(code as! String)!
                            } else if code is Int {
                                resp_code = code as! Int
                            }
//                            let resp_code: Int = (resultDict["resp_code"] as! Int)
                            switch resp_code {
                            case 0:
                                success(resultDict)
                            case 1:
                                SVProgressHUD.showError(withStatus: (resultDict["resp_msg"] as! String))
                            case 401,8888:
                                UserInfo.clearLoginInfo()
                                if resp_code == 401 {
                                    SVProgressHUD.showInfo(withStatus: "登录已过期，请重新登录！")
                                } else {
                                    SVProgressHUD.showInfo(withStatus: (resultDict["resp_msg"] as! String))
                                }
                                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+2.0) {
                                    let loginVC = ZXLoginViewController()
                                    let naviVC = YNavigationViewController.init(rootViewController: loginVC)
                                    KScreenWindow?.rootViewController = naviVC

                                }
                            case 500:
                                SVProgressHUD.showInfo(withStatus: "网络不给力，请再试一次吧")
                            default:
                                SVProgressHUD.showError(withStatus: (resultDict["resp_msg"] as! String))
                            }
                        })
                    }
                case let .failure(error):
                    SVProgressHUD.showInfo(withStatus: "网络不给力，请再试一次吧")
//                    SVProgressHUD.dismiss()
                    Printy(error)
                }

            })

        }
    }
    class func IMGS(url:String,params:[String:Any],images:[UIImage],success: @escaping SuccessBlock) {
        let request3 = AF.upload(multipartFormData: { (mutilPartData) in
               for image in images {
                   let imgData = UIImage.imageCompress(image: image)
                   mutilPartData.append(imgData, withName: "files", fileName: String(String.getCurrentTimeStamp()) + ".jpg", mimeType: "image/jpg/png/jpeg")
               }
        }, to: url, usingThreshold: UInt64.init(), method: .post, headers: [], interceptor: nil, fileManager: FileManager())
        request3.uploadProgress { (progress) in
//            SVProgressHUD.showInfo(withStatus: "正在上传图片")
        }
        request3.uploadProgress { (progress) in
            
        }
        request3.responseJSON { (response) in
            Printy(response)
            DispatchQueue.global().async(execute: {
                switch response.result {
                case let .success(result):
                    do {
                        let resultDict:[String:Any] = result as! [String:Any]
                        DispatchQueue.main.async(execute: {
                            // type 1:部分上传成功,2:全部图片上传失败,0:全部上传成功
                            let resp_code: Int = (resultDict["resp_code"] as! Int)
                            switch resp_code {
                            case 0:
                                success(resultDict)
                            case 1:
                                SVProgressHUD.showError(withStatus: (resultDict["resp_msg"] as! String))
                            case 500:
                                SVProgressHUD.showInfo(withStatus: "网络不给力，请再试一次吧")
                            default:
                                SVProgressHUD.showError(withStatus: (resultDict["resp_msg"] as! String))
                            }
                        })
                    }
                case let .failure(error):
                    SVProgressHUD.showInfo(withStatus: "网络不给力，请再试一次吧")
//                    SVProgressHUD.dismiss()
                    Printy(error)
                }
            })
        }
    }
    class func IMGPath(url:String,params:[String:Any],imageString:String,success: @escaping SuccessBlock) {
        let request3 = AF.upload(multipartFormData: { (mutilPartData) in
            let list:[String] = imageString.components(separatedBy: ";")
            for i in 0..<list.count {
                if list[i].count > 0 {
                    mutilPartData.append(URL(fileURLWithPath: list[i]), withName: "files", fileName: String(String.getCurrentTimeStamp()) + "_" + String(i) + ".jpg", mimeType: "image/jpg/png/jpeg")
                }
           }
            // 参数
            for key in params.keys {
                let value = params[key] as! String
                let vData:Data = value.data(using: .utf8)!
                mutilPartData.append(vData, withName: key)
            }
        }, to: url, usingThreshold: UInt64.init(), method: .post, headers: [], interceptor: nil, fileManager: FileManager())
        request3.responseJSON { (response) in
            Printy(response)
            DispatchQueue.global().async(execute: {
                switch response.result {
                case let .success(result):
                    do {
                        let resultDict:[String:Any] = result as! [String:Any]
                        DispatchQueue.main.async(execute: {
                            // type 1:部分上传成功,2:全部图片上传失败,0:全部上传成功
                            let resp_code: Int = (resultDict["resp_code"] as! Int)
                            switch resp_code {
                            case 0:
                                success(resultDict)
                            case 1:
                                SVProgressHUD.showError(withStatus: (resultDict["resp_msg"] as! String))
                            case 500:
                                SVProgressHUD.showInfo(withStatus: "网络不给力，请再试一次吧")
                            default:
                                SVProgressHUD.showError(withStatus: (resultDict["resp_msg"] as! String))
                            }
                        })
                    }
                case let .failure(error):
//                    SVProgressHUD.dismiss()
                    SVProgressHUD.showInfo(withStatus: "网络不给力，请再试一次吧")
                    Printy(error)
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
                // 本地nfc上传
                ZXMessageUtil.shared.startUploadNfc()
                break
            case .reachable(.ethernetOrWiFi): //wifi
                self.isNetworking = true
                // 本地nfc上传
                ZXMessageUtil.shared.startUploadNfc()
                break
            }
        })
    }

}
