//
//  Account.swift
//  
//
//  Created by 渡部郷太 on 8/23/16.
//
//

import Foundation
import CoreData

import ZaifSwift


public class Account: NSManagedObject {

    public override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    convenience init(userId: String, api: PrivateApi) {
        self.init(entity: AccountRepository.getInstance().accountDescription, insertIntoManagedObjectContext: nil)
        
        self.userId = userId
        self.privateApi = api
    }
    
    func validateApiKey(cb: (ZaiError?, Bool) -> Void) {
        self.privateApi.getInfo() { (err, res) in
            if let e = err {
                switch e.errorType {
                case ZSErrorType.INFO_API_NO_PERMISSION:
                    cb(nil, true)
                default:
                    cb(ZaiError(errorType: .INVALID_API_KEYS, message: e.message), false)
                }
            } else {
                cb(nil, true)
            }
        }
    }
    
    func getMarketCapitalization(cb: ((ZaiError?, Int) -> Void)) {
        let fund = JPYFund(api: self.privateApi)
        fund.getMarketCapitalization(cb)
    }
    
    internal var privateApi: PrivateApi! = nil

}