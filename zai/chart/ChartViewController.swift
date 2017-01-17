//
//  Chart.swift
//  zai
//
//  Created by 渡部郷太 on 1/4/17.
//  Copyright © 2017 watanabe kyota. All rights reserved.
//

import Foundation
import UIKit

import Charts


class ChartViewController : UIViewController, CandleChartDelegate, PositionDelegate, FundDelegate, BitCoinDelegate, BestQuoteViewDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barTintColor = Color.keyColor
        
        let api = getAccount()!.activeExchange.api
        self.fund = Fund(api: api)
        self.bitcoin = BitCoin(api: api)
        
        self.bestQuoteView = BestQuoteView(view: bestQuoteTableView)
        self.bestQuoteView.delegate = self
        
        self.chartHeaderLabel.text = "1分足"
        self.chartHeaderLabel.backgroundColor = Color.keyColor2
        
        self.candleStickChartView.legend.enabled = false
        self.candleStickChartView.chartDescription?.enabled = false
        self.candleStickChartView.maxVisibleCount = 60
        self.candleStickChartView.pinchZoomEnabled = false
        
        self.candleStickChartView.xAxis.labelPosition = XAxis.LabelPosition.bottom
        self.candleStickChartView.xAxis.drawGridLinesEnabled = false
        self.candleStickChartView.xAxis.labelCount = 5
        self.candleStickChartView.xAxis.granularityEnabled = true
        
        self.candleStickChartView.leftAxis.enabled = false
        
        self.candleStickChartView.rightAxis.labelCount = 5
        self.candleStickChartView.rightAxis.drawGridLinesEnabled = true
        self.candleStickChartView.rightAxis.drawAxisLineEnabled = true
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let config = getConfig()
        self.fund.monitoringInterval = config.autoUpdateInterval
        self.fund.delegate = self
        self.bitcoin.monitoringInterval = config.autoUpdateInterval
        self.bitcoin.delegate = self
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.fund.delegate = nil
        self.bitcoin.delegate = nil
    }
    
    // CandleChartDelegate
    func recievedChart(chart: CandleChart, shifted: Bool) {
        guard let chartView = self.candleStickChartView else {
            return
        }
        var entries = [CandleChartDataEntry]()
        var emptyEntries = [CandleChartDataEntry]()
        let formatter = XValueFormatter()
        for i in 0 ..< chart.candles.count {
            let candle = chart.candles[i]
            if candle.isEmpty {
               let average = chart.average
                let entry = CandleChartDataEntry(x: Double(i), shadowH: average, shadowL: average, open: average, close: average)
                emptyEntries.append(entry)
            } else {
                let entry = CandleChartDataEntry(x: Double(i), shadowH: candle.highPrice!, shadowL: candle.lowPrice!, open: candle.openPrice!, close: candle.lastPrice!)
                entries.append(entry)
            }
            
            formatter.times[i] = formatHms(timestamp: candle.startDate)
        }
        let dataSet = CandleChartDataSet(values: entries, label: "data")
        dataSet.axisDependency = YAxis.AxisDependency.left;
        dataSet.shadowColorSameAsCandle = true
        dataSet.shadowWidth = 0.7
        dataSet.decreasingColor = Color.askQuoteColor
        dataSet.decreasingFilled = true
        dataSet.increasingColor = Color.bidQuoteColor
        dataSet.increasingFilled = true
        dataSet.neutralColor = UIColor.black
        dataSet.setDrawHighlightIndicators(false)
        
        let emptyDataSet = CandleChartDataSet(values: emptyEntries, label: "empty")
        emptyDataSet.axisDependency = YAxis.AxisDependency.left;
        emptyDataSet.shadowColorSameAsCandle = true
        emptyDataSet.shadowWidth = 0.7
        emptyDataSet.decreasingColor = Color.askQuoteColor
        emptyDataSet.decreasingFilled = true
        emptyDataSet.increasingColor = Color.bidQuoteColor
        emptyDataSet.increasingFilled = true
        emptyDataSet.neutralColor = UIColor.white
        emptyDataSet.setDrawHighlightIndicators(false)
        
        chartView.xAxis.valueFormatter = formatter
        chartView.rightAxis.valueFormatter = YValueFormatter()
        
        var dataSets = [IChartDataSet]()
        if dataSet.entryCount > 0 {
            dataSets.append(dataSet)
        }
        if emptyDataSet.entryCount > 0 {
            dataSets.append(emptyDataSet)
        }
        chartView.data = CandleChartData(dataSets: dataSets)
    }
    
    // PositionDelegate
    func opendPosition(position: Position) {
        return
    }
    func unwindPosition(position: Position) {
        return
    }
    func closedPosition(position: Position) {
        return
    }
    
    // FundDelegate
    func recievedJpyFund(jpy: Int) {
        DispatchQueue.main.async {
            self.fundLabel.text = formatValue(jpy)
        }
    }
    
    // BitCoinDelegate
    func recievedBestJpyBid(price: Int, amount: Double) {
        let quote = Quote(price: Double(price), amount: amount, type: .BID)
        self.bestQuoteView.setBestBid(quote: quote)
    }
    
    func recievedBestJpyAsk(price: Int, amount: Double) {
        let quote = Quote(price: Double(price), amount: amount, type: .ASK)
        self.bestQuoteView.setBestAsk(quote: quote)
    }
    
    // BestQuoteViewDelegate
    func orderBuy(quote: Quote) {
        let price = quote.price
        let amount = min(quote.amount, 1.0)
        
        guard let trader = getAccount()?.activeExchange.trader else {
            return
        }
        
        trader.createLongPosition(.BTC_JPY, price: price, amount: amount) { (err, position) in
            if let e = err {
                print(e.message)
            } else {
                position?.delegate = self
            }
        }
    }

    func orderSell(quote: Quote) {
        let price = quote.price
        let amount = min(quote.amount, 1.0)
        
        guard let trader = getAccount()?.activeExchange.trader else {
            return
        }
        let app = UIApplication.shared.delegate as! AppDelegate
        if app.config.sellMaxProfitPosition {
            trader.unwindMaxProfitPosition(price: price, amount: amount) { (err, position) in
                if err != nil {
                    position?.delegate = self
                }
            }
        } else {
            trader.unwindMinProfitPosition(price: price, amount: amount) { (err, position) in
                if err != nil {
                    position?.delegate = self
                }
            }
        }
    }
    
    
    fileprivate var fund: Fund!
    fileprivate var bitcoin: BitCoin!
    var candleChart: CandleChart!
    var bestQuoteView: BestQuoteView!
    
    @IBOutlet weak var chartHeaderLabel: UILabel!
    @IBOutlet weak var candleStickChartView: CandleStickChartView!
    @IBOutlet weak var fundLabel: UILabel!
    @IBOutlet weak var bestQuoteTableView: UITableView!
    
}