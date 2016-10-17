//
//  TradeLog.swift
//  
//
//  Created by 渡部郷太 on 8/23/16.
//
//

import Foundation
import CoreData


public enum TradeAction : String {
    case ORDER = "ORDER"
    case CANCEL = "CANCEL"
    case OPEN_LONG_POSITION = "OPEN_LONG_POSITION"
    case OPEN_SHORT_POSITION = "OPEN_SHORT_POSITION"
    case CLOSE_LONG_POSITION = "CLOSE_LONG_POSITION"
    case CLOSE_SHORT_POSITION = "CLOSE_SHORT_POSITION"
    case UNWIND_LONG_POSITION = "UNWIND_LONG_POSITION"
    case UNWIND_SHORT_POSITION = "UNWIND_SHORT_POSITION"
}


class TradeLog: NSManagedObject {
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    convenience init(action: TradeAction, traderName: String, account: Account, order: Order, positionId: String) {
        self.init(entity: TradeLogRepository.getInstance().tradeLogDescription, insertInto: nil)
        
        self.id = UUID().uuidString
        self.userId = account.userId
        self.apiKey = account.privateApi.apiKey
        self.positionId = positionId
        self.traderName = traderName
        self.tradeAction = action.rawValue
        self.orderAction = order.action.rawValue
        self.orderId = NSNumber(value: order.orderId)
        self.currencyPair = order.currencyPair.rawValue
        self.price = NSNumber(value: order.price)
        self.amount = NSNumber(value: order.amount)
        self.timestamp = NSNumber(value: Date().timeIntervalSince1970)
    }

// Insert code here to add functionality to your managed object subclass

}
