//
//  NS_GraphView.swift
//  EngineX (macOS)
//
//  Created by Dave Lathrop on 4/8/22.
//

import Cocoa
import SwiftUI
import PDFKit

enum GraphStyle {
    case total_sum, errors, response_time
}

@available(macOS 12.0, *)
struct ChartViewRepresentable: NSViewRepresentable {

    typealias NSViewType = NS_GraphView
    
    var timeSlices:[NGINX_TimeSlice]
    var webServers:[NGINX_WebServer]
    var endpoints:[NGINX_Endpoint]
    var ip_addresses:[NGINX_IP_Address]
    var startDate: Date
    
    var showCounts:Bool
    var showTotals:Bool
    var showResponseTimes:Bool
    var showWebservers:Bool
    var showEndpoints:Bool
    var showIPAddresses:Bool
    var showServers:Bool
    
    var cropLeft : Int = 0
    var cropRight : Int = 0
    var scale_y : Int = 0
    var graphStyle : String = ""
    
    func makeNSView(context: Context) -> NS_GraphView {
        return NS_GraphView(timeSlices:timeSlices, webServers:webServers, endpoints:endpoints, ip_addresses:ip_addresses, startDate:startDate, showCounts:showCounts, showTotals:showTotals, showResponseTimes:showResponseTimes, showWebservers:showWebservers, showEndpoints:showEndpoints, showIPAddresses:showIPAddresses, showServers:showServers)
    }
    
    func updateNSView(_ nsView: NS_GraphView, context: Context) {
        nsView.timeSlices = timeSlices
        nsView.webServers = webServers
        nsView.endpoints = endpoints
        nsView.ip_addresses = ip_addresses
        nsView.startDate = startDate
        
        nsView.showCounts=showCounts
        nsView.showTotals=showTotals
        nsView.showResponseTimes=showResponseTimes
        nsView.showWebservers=showWebservers
        nsView.showEndpoints=showEndpoints
        nsView.showIPAddresses=showIPAddresses
        nsView.showServers=showServers
        
    }
}


@available(macOS 12.0, *)

class NS_GraphView: NSView, NSTextFieldDelegate, NSControlTextEditingDelegate {
    
    var timeSlices:[NGINX_TimeSlice] {
        didSet {
            self.needsDisplay = true
        }
    }
    var webServers:[NGINX_WebServer] {
        didSet {
            self.needsDisplay = true
            let frame = self.frame
            print("frame", frame)
        }
    }
    var startDate: Date {
        didSet {
            self.needsDisplay = true
        }
    }
    var endpoints: [NGINX_Endpoint] {
        didSet {
            self.needsDisplay = true
        }
    }
    var ip_addresses: [NGINX_IP_Address] {
        didSet {
            self.needsDisplay = true
        }
    }
    
    var showTotals:Bool
    var showCounts:Bool
    
    var showResponseTimes:Bool
    var showWebservers:Bool
    var showEndpoints:Bool
    var showIPAddresses:Bool
    var showServers:Bool
    
    let dateFormatter = DateFormatter()
    let timeFormatter = DateFormatter()
    var max_y = Int64(0)
    var max_rt = Double(0)
    
    var graphStyle = GraphStyle.response_time
    
    var scale_y : Int = 0
    
    let colors = [NSColor.systemBlue, NSColor.systemBrown, NSColor.systemGray, NSColor.systemGreen, NSColor.systemIndigo, NSColor.systemOrange, NSColor.systemPink, NSColor.systemPurple, NSColor.systemRed, NSColor.systemTeal, NSColor.systemYellow , NSColor.clear , NSColor.black , NSColor.blue , NSColor.brown , NSColor.cyan , NSColor.darkGray , NSColor.gray , NSColor.green , NSColor.lightGray , NSColor.magenta , NSColor.orange , NSColor.purple , NSColor.red , NSColor.white , NSColor.yellow]
    
    var endDate : Date = Date.distantPast
    var hoursDisplayed = 0.0
    var startHour = 0
    var g_frame = CGRect(x: 0, y: 0, width: 0, height: 0)
    var tick_pixels_x = 0.0
    
    var clickLocation = CGPoint(x: 0.0, y: 0.0)
    var clickDate = Date.distantFuture
    
    var draggedRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    var dateRangeStart = Date.distantFuture
    var dateRangeEnd = Date.distantPast
    
    var overlayView = NSView(frame: NSRect(x: 0.0, y: 0.0, width: 100.0, height: 100.0))
    var editOn = false
   
    var titleAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: CGFloat(24.0))]
    var attributedTitle = NSAttributedString(string: "", attributes: nil)
    var titleTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
    
    
    init(timeSlices:[NGINX_TimeSlice], webServers:[NGINX_WebServer], endpoints:[NGINX_Endpoint], ip_addresses:[NGINX_IP_Address], startDate: Date, showCounts:Bool, showTotals:Bool, showResponseTimes:Bool, showWebservers:Bool, showEndpoints:Bool, showIPAddresses:Bool, showServers:Bool) {
        
        self.timeSlices = timeSlices
        self.webServers = webServers
        self.endpoints = endpoints
        self.ip_addresses = ip_addresses
        self.startDate = Date.distantFuture
        
        self.showCounts=showCounts
        self.showTotals=showTotals
        self.showResponseTimes=showResponseTimes
        self.showWebservers=showWebservers
        self.showEndpoints=showEndpoints
        self.showIPAddresses=showIPAddresses
        self.showServers=showServers
        
        super.init(frame:.zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // AppKit gesture recognizers
    @objc func dragGesture(recognizer: NSPanGestureRecognizer) {
        let translation = recognizer.translation(in:self)
        let mousePoint = recognizer.location(in:self)
       
        let odp = CGPoint(x: mousePoint.x - translation.x, y: mousePoint.y - translation.y)
        
        let index = (odp.x - g_frame.minX) / tick_pixels_x
        let index_2 = (odp.x + translation.x - g_frame.minX) / tick_pixels_x
        
        if index <= index_2 {
            dateRangeStart = startDate.addingTimeInterval(index*3600)
            dateRangeEnd = startDate.addingTimeInterval(index_2*3600)
        }
        else {
            dateRangeStart = startDate.addingTimeInterval(index*3600)
            dateRangeEnd = startDate.addingTimeInterval(index_2*3600)
        }
        let overlayColor = CGColor(red: 0.5, green: 0.5, blue: 0.0, alpha: 0.333)
        overlayView.layer!.backgroundColor = overlayColor
        
        if translation.x >= 0 {
            if translation.y >= 0 {
                overlayView.frame = CGRect(x: odp.x, y: odp.y, width: translation.x, height: translation.y)
            } else {
                overlayView.frame = CGRect(x: odp.x, y: odp.y + translation.y, width: translation.x, height: translation.y)
            }
        } else {
            if translation.y >= 0 {
                overlayView.frame = CGRect(x: odp.x + translation.x, y: odp.y, width: translation.x, height: translation.y)
            } else {
                overlayView.frame = CGRect(x: odp.x + translation.x, y: odp.y + translation.y, width: translation.x, height: translation.y)
            }
        }
    }
    
    @objc func singleTapGesture(recognizer: NSClickGestureRecognizer) {
        clickLocation = recognizer.location(in: self)
        let index = (clickLocation.x - g_frame.minX) / tick_pixels_x
        //clickDate = startDate.addingTimeInterval(index*3600)
        //self.needsDisplay = true
        //self.printView()
        if editOn {
        } else {
        }
        editOn = !editOn
        self.needsDisplay = true
    }
    
    @objc func doubleTapGesture(recognizer: NSClickGestureRecognizer) {
        clickLocation = recognizer.location(in: self)
        let index = (clickLocation.x - g_frame.minX) / tick_pixels_x
        //clickDate = startDate.addingTimeInterval(index*3600)
        //self.needsDisplay = true
        self.printView()
    }
    
    @objc func magGesture(recognizer: NSMagnificationGestureRecognizer) {
        print("magGesture")
        print(recognizer.magnification, recognizer.location(in:self))
    }
    
    override func draw(_ dirtyRect: NSRect) {
        
        super.draw(dirtyRect)
        if timeSlices.count == 0 {
            print ("nothing to draw")
            return
        }
        
        //startDate = Date.distantFuture
        //endDate = Date.distantPast
        //for timeSlice in timeSlices {
        //    if startDate > timeSlice.date! {
        //        startDate = timeSlice.date!
        //        print("new startDate", timeSlice.date!)
        //    }
        //    if endDate < timeSlice.date! {
        //        endDate = timeSlice.date!
        //    }
        //}
        
        if startDate == endDate || timeSlices.count == 0 {
            return
        }
        // get and save graphics context
        guard let context = NSGraphicsContext.current else { return }
        context.saveGraphicsState()
        
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .medium
        
        // for graphing rect
        let inset_right = 10.0
        let inset_left = 50.0
        let inset_top = 10.0
        let inset_bot = 80.0
        max_y = Int64(0)
        max_rt = Double(0)
        
        hoursDisplayed = (endDate.timeIntervalSince(startDate)) / 3600.0 // hours
        
        g_frame = CGRect(x: frame.minX+inset_left, y: frame.minY+inset_bot, width: frame.width-inset_right-inset_left, height: frame.height-inset_top-inset_bot)
        
        var total_sum = [Date:Int64]()
        var total_error_sum = [Date:Int64]()
        var total_rt_sum = [Date:Double]()
        
        var ep_rt_sum = [Date:Double]()
        var ep_count_sum = [Date:Int64]()
        var ep_error_sum = [Date:Int64]()
        
        var ip_rt_sum = [Date:Double]()
        var ipa_count_sum = [Date:Int64]()
        var ipa_error_sum = [Date:Int64]()
       
        for timeSlice in timeSlices {
            
            if showTotals {
                total_sum[timeSlice.date!] = timeSlice.count
                if Int64(timeSlice.count) > max_y {
                    max_y = timeSlice.count
                }
                total_error_sum[timeSlice.date!] = timeSlice.error_count
                // response time
                let t_count = timeSlice.count
                let rt_avg = timeSlice.rt_total / Double(t_count)
                total_rt_sum[timeSlice.date!] = rt_avg
                if rt_avg > max_rt {
                    max_rt = rt_avg
                }
            }
            
            if showEndpoints && endpoints.count > 0 {
                let endpoint = endpoints[0] as NGINX_Endpoint
                let epkey = endpoint.path! as String
                for endpointpoint in timeSlice.endpoints! {
                    let epo = endpointpoint as? NGINX_Point
                    let eptag = epo!.name_tag
                    if epkey == eptag! as String {
                        // count
                        let t_count = epo?.count
                        ep_count_sum[timeSlice.date!] = epo?.count
                        if Int64(epo!.count) > max_y {
                            max_y = epo!.count
                        }
                        // rt_avg
                        let rt_avg = epo!.rt_total / Double(t_count!)
                        ep_rt_sum[timeSlice.date!] = rt_avg
                        if rt_avg > max_rt {
                            max_rt = rt_avg
                        }
                        // errors
                        ep_error_sum[timeSlice.date!] = epo?.error_count
                    }
                }
            }
            
            if showIPAddresses && ip_addresses.count > 0 {
                let ipa = ip_addresses[0] as NGINX_IP_Address
                let ipakey = ipa.address! as String
                for ipapoint in timeSlice.ip_addresses! {
                    let ipao = ipapoint as? NGINX_Point
                    let ipatag = ipao!.name_tag
                    if ipakey == ipatag! as String {
                        // count
                        let t_count = ipao?.count
                        ipa_count_sum[timeSlice.date!] = ipao?.count
                        if Int64(ipao!.count) > max_y {
                            max_y = ipao!.count
                        }
                        // rt_avg
                        let rt_avg = ipao!.rt_total / Double(t_count!)
                        ip_rt_sum[timeSlice.date!] = rt_avg
                        if rt_avg > max_rt {
                            max_rt = rt_avg
                        }
                        // errors
                        ipa_error_sum[timeSlice.date!] = ipao?.error_count
                    }
                }
            }
        }
        
        // figure title
        var title = ""
        if showEndpoints && endpoints.count > 0 {
            title = title + ": " + endpoints[0].path!
        }
        if showIPAddresses && ip_addresses.count > 0 {
            title = title + ": " + ip_addresses[0].address!
        }
        
        // do the graphing
        
        // draw time axis
        drawTimeAxis(gFrame: g_frame)
        
        if showResponseTimes {
            draw_y_axis_double(gFrame:g_frame)
            if showEndpoints {
                draw_double_graph(timeline:ep_rt_sum, g_frame: g_frame, max_y: max_rt, color:NSColor.purple, bar_width:1.5)
            }
            if showIPAddresses {
                draw_double_graph(timeline:ip_rt_sum, g_frame: g_frame, max_y: max_rt, color:NSColor.blue, bar_width:1.5)
            }
        }
        
        if showCounts || showTotals {
            draw_y_axis(gFrame:g_frame)
        }
        if showTotals {
            draw_graph(timeline:total_sum, g_frame: g_frame, max_y: max_y, color:NSColor.blue, bar_width:1)
            draw_graph(timeline:total_error_sum, g_frame: g_frame, max_y: max_y, color:NSColor.red, bar_width:1.5)
        }
        if showCounts {
            if showEndpoints {
                draw_graph(timeline:ep_count_sum, g_frame: g_frame, max_y: max_y, color:NSColor.blue, bar_width:1)
                draw_graph(timeline:ep_error_sum, g_frame: g_frame, max_y: max_y, color:NSColor.orange, bar_width:1.5)
            }
            if showIPAddresses {
                draw_graph(timeline:ipa_count_sum, g_frame: g_frame, max_y: max_y, color:NSColor.cyan, bar_width:1)
                draw_graph(timeline:ipa_error_sum, g_frame: g_frame, max_y: max_y, color:NSColor.yellow, bar_width:1.5)
            }
        }
        
        drawTitle(title:title)
        
        //draw_top_five(selectedTime, title:"Top Accounts")
        
        /*
        if graphStyle == "Endpoints" {
            
        }
        if graphStyle == "Accounts" {
            draw_graph(timeline:account_sum, g_frame: g_frame, max_y: max_y, color:NSColor.red, bar_width:1)
            drawTitle(title:"All Accounts" + " - All Endpoints")
            //drawTitle(title:account_title + " - All Endpoints")
            draw_top_five(selectedTime, title:"Top Endpoints")
        }
        
        if graphStyle == "Endpoints AND Accounts" {
            draw_graph(timeline:union_sum, g_frame: g_frame, max_y: max_y, color:NSColor.purple, bar_width:1)
            drawTitle(title:account_title + " - " + "All Other Endpoints") //
        }
        
        if clickLocation.x > 0.0 && clickLocation.y > 0.0 {
            let pin = NSBezierPath()
            let rectangle = CGRect(x: clickLocation.x-2.0, y: clickLocation.y-2.0, width: 4, height: 4)
            pin.appendOval(in: rectangle)
            NSColor.systemOrange.set()
            pin.fill()
            // draw selectedTime
            //draw_top_five(selectedTime)
        }
         */
        context.restoreGraphicsState()
    }
    
    func drawTitle(title:String) {
        attributedTitle = NSAttributedString(string: title, attributes: titleAttributes)
        let titleStringSize = attributedTitle.size()
        let titleLocation = CGPoint(x: frame.midX-titleStringSize.width/2, y: frame.maxY - 50.0)
        let titleStringRect = CGRect(x: titleLocation.x,
                                     y: titleLocation.y, width: titleStringSize.width,
                                     height: titleStringSize.height)

        if editOn {
            let editFrame = CGRect(x: titleStringRect.minX - 5, y: titleStringRect.minY - 5, width: titleStringRect.width + 10, height: titleStringRect.height + 10)
            titleTextField.frame = editFrame
            titleTextField.attributedStringValue = attributedTitle
        }
        else {
            titleTextField.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        }
        attributedTitle.draw(in: titleStringRect)
    }
    
    func draw_top_five(_ breakdown:[String:Int64], title:String) {
        let font = NSFont.boldSystemFont(ofSize: CGFloat(12))
        let itemAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font]
        var itemLocation = CGPoint(x: frame.midX+frame.width/4.0, y: frame.maxY - 30.0)
        // sort dictionary by value
        let sortedTuples = breakdown.sorted { (first, second) -> Bool in
            return first.value > second.value
        }
        
        let dateAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: CGFloat(14))]
        //let date_label = "Endpoints" // dateFormatter.string(from: clickDate)
        let attributedDate = NSAttributedString(string: title, attributes: dateAttributes)
        let dateStringSize = attributedDate.size()
        let dateStringRect = CGRect(x: itemLocation.x,
                                     y: itemLocation.y, width: dateStringSize.width,
                                     height: dateStringSize.height)
        attributedDate.draw(in: dateStringRect)
        itemLocation =  CGPoint(x:itemLocation.x, y:itemLocation.y-18.0)
        
        //let time_label = timeFormatter.string(from: dateRangeStart) + " to " + timeFormatter.string(from: dateRangeEnd)
        let time_label = "Selected Range"
        let attributedTime = NSAttributedString(string: time_label, attributes: dateAttributes)
        let timeStringSize = attributedTime.size()
        let timeStringRect = CGRect(x: itemLocation.x,
                                     y: itemLocation.y, width: timeStringSize.width,
                                     height: timeStringSize.height)
        
        attributedTime.draw(in: timeStringRect)
        itemLocation =  CGPoint(x:itemLocation.x, y:itemLocation.y-18.0)
        
        var t_index = 0
        for bd in sortedTuples {
            let itemString = "( " + String(bd.value) + " ) " + bd.key
            let attributedItem = NSAttributedString(string: itemString, attributes: itemAttributes)
            let itemStringSize = attributedItem.size()
            let itemStringRect = CGRect(x: itemLocation.x,
                                         y: itemLocation.y, width: itemStringSize.width,
                                         height: itemStringSize.height)
            attributedItem.draw(in: itemStringRect)
            itemLocation =  CGPoint(x:itemLocation.x, y:itemLocation.y-16.0)
            t_index+=1
            if t_index >= 5 {
                break
            }
        }
    }
    
    func drawTimeAxis(gFrame:CGRect) {
        
        NSColor.red.set() // choose color
        let x_axis = NSBezierPath() // container for line(s)
        x_axis.lineWidth = 1.0
        x_axis.move(to: NSMakePoint(gFrame.minX, gFrame.minY)) // start point
        x_axis.line(to: NSMakePoint(gFrame.maxX, gFrame.minY)) // destination
        // draw axis ticks every hour, every day
        tick_pixels_x = gFrame.width / hoursDisplayed
        let tickCount = Int(hoursDisplayed)
        
        var tickLabelFrequency = 3
        if tick_pixels_x < 12.0 { tickLabelFrequency = 6 }
        for index in 0...tickCount {
            let tickX = g_frame.minX + Double(index)*tick_pixels_x
            x_axis.move(to: NSMakePoint(tickX, gFrame.minY)) // start point
            x_axis.line(to: NSMakePoint(tickX, gFrame.minY-5.0)) // destination
            
            // draw tick hour label
            var hour = startHour + index
            if ( hour % tickLabelFrequency == 0 ) {
                var hourString = ""
                while hour >= 24 { hour -= 24}
                if hour == 0 {
                    hourString = "12am"
                    // draw day start mark
                    x_axis.move(to: NSMakePoint(tickX, gFrame.minY-27)) // start point
                    x_axis.line(to: NSMakePoint(tickX, gFrame.minY-56.0)) // destination
                }
                
                else if hour < 12 { hourString = String(hour) + "am" }
                else if hour == 12 {
                    hourString = "12pm"
                    // center date string here
                    // draw x axis label
                    let ti = 3600.0 * Double(index)
                    let tickDate = startDate.addingTimeInterval(ti)
                    let date_label = dateFormatter.string(from: tickDate)
                    let font = NSFont.boldSystemFont(ofSize: CGFloat(18.0))
                    let titleAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font]
                    let attributedTitle = NSAttributedString(string: date_label, attributes: titleAttributes)
                    let titleStringSize = attributedTitle.size()
                    let dateLocation = CGPoint(x: tickX-titleStringSize.width/2, y: g_frame.minY - 50.0)
                    let titleStringRect = CGRect(x: dateLocation.x,
                                                 y: dateLocation.y, width: titleStringSize.width,
                                                 height: titleStringSize.height)
                    attributedTitle.draw(in: titleStringRect)
                }
                else { hourString = String(hour - 12) + "pm"}
                
                let font = NSFont.systemFont(ofSize: CGFloat(12.0))
                let titleAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font]
                let attributedTitle = NSAttributedString(string: hourString, attributes: titleAttributes)
                let titleStringSize = attributedTitle.size()
                let dateLocation = CGPoint(x: tickX-titleStringSize.width/2, y: g_frame.minY - 21.0)
                let titleStringRect = CGRect(x: dateLocation.x,
                                             y: dateLocation.y, width: titleStringSize.width,
                                             height: titleStringSize.height)
                attributedTitle.draw(in: titleStringRect)
            }
        }
        x_axis.stroke()  // draw line(s) in color
        
    }
    
    func draw_y_axis (gFrame:CGRect) {
        // y-axis
        let y_axis = NSBezierPath() // container for line(s)
        let y_levels = NSBezierPath()
        y_axis.lineWidth = 1.0
        y_levels.lineWidth = 1.0
        y_axis.move(to: NSMakePoint(gFrame.minX, gFrame.minY)) // start point
        y_axis.line(to: NSMakePoint(gFrame.minX, gFrame.maxY)) // destination
        // draw axis ticks
        
        var hits_per_tick = 1.0 //Double(max_y) / 10.0
        var y_ticks_set = false
        while !y_ticks_set {
            if (Double(max_y) / hits_per_tick) <= 12.0 {
                y_ticks_set = true
            }
            else {
                hits_per_tick *= 10.0
            }
        }
        
        let tickPixelsY = 0.9 * gFrame.height / ((Double(max_y) / hits_per_tick ))
        let tickCountY = max_y / Int64(hits_per_tick)
        
        for index in 0...tickCountY {
            let tickY = gFrame.minY + Double(index)*tickPixelsY
            y_axis.move(to: NSMakePoint(gFrame.minX, tickY)) // start point
            y_axis.line(to: NSMakePoint(gFrame.minX-5.0, tickY)) // destination
            
            y_levels.move(to: NSMakePoint(gFrame.minX, tickY)) // start point
            y_levels.line(to: NSMakePoint(gFrame.maxX, tickY)) // destination
            
            
            let font = NSFont.systemFont(ofSize: CGFloat(12.0))
            let titleAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font]
            let attributedTitle = NSAttributedString(string: String(index*Int64(hits_per_tick)), attributes: titleAttributes)
            let titleStringSize = attributedTitle.size()
            let countLocation = CGPoint(x: gFrame.minX-25.0-titleStringSize.width/2, y: tickY-titleStringSize.height/2)
            let titleStringRect = CGRect(x: countLocation.x,
                                         y: countLocation.y, width: titleStringSize.width,
                                         height: titleStringSize.height)
            attributedTitle.draw(in: titleStringRect)
        }
        
        y_axis.stroke()
        NSColor.gridColor.set()
        y_levels.stroke()
        
        // draw x axis label
        //let date_label = dateFormatter.string(from: startDate)
        //let font = NSFont.boldSystemFont(ofSize: CGFloat(12.0))
        //let titleAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font]
        //let attributedTitle = NSAttributedString(string: date_label, attributes: titleAttributes)
        //let titleStringSize = attributedTitle.size()
        //let dateLocation = CGPoint(x: g_frame.midX-titleStringSize.width/2, y: g_frame.minY - 32.0)
        //let titleStringRect = CGRect(x: dateLocation.x,
        //                             y: dateLocation.y, width: titleStringSize.width,
        //                             height: titleStringSize.height)
        //attributedTitle.draw(in: titleStringRect)
        
        // draw y axis
        /*
        let t: CGAffineTransform = CGAffineTransform(translationX: basePoint.x, y: basePoint.y)
        let r: CGAffineTransform = CGAffineTransform(rotationAngle: angle)
        context.concatenate(t)
        context.concatenate(r)
        self.draw(at: CGPoint(x: textSize.width / 2, y: -textSize.height / 2), withAttributes: attributes)
        context.concatenate(r.inverted())
        context.concatenate(t.inverted())
         */
    }
    
    func draw_y_axis_double(gFrame:CGRect) {
        let y_axis = NSBezierPath() // container for line(s)
        let y_levels = NSBezierPath()
        y_axis.lineWidth = 1.0
        y_levels.lineWidth = 1.0
        y_axis.move(to: NSMakePoint(gFrame.minX, gFrame.minY)) // start point
        y_axis.line(to: NSMakePoint(gFrame.minX, gFrame.maxY)) // destination
        // draw axis ticks
        
        var hits_per_tick = 1.0 //Double(max_y) / 10.0
        
        // adapt axis scale to max_rt value
        var y_ticks_set = false
        while !y_ticks_set {
            if (max_rt / hits_per_tick) <= 6.0 {
                y_ticks_set = true
            }
            else {
                hits_per_tick *= 0.0
            }
        }
        
        let tickPixelsY = 0.9 * gFrame.height / ((max_rt / hits_per_tick ))
        let tickCountY = Int(max_rt / hits_per_tick)
        
        for index in 0...tickCountY {
            let tickY = gFrame.minY + Double(index)*tickPixelsY
            y_axis.move(to: NSMakePoint(gFrame.minX, tickY)) // start point
            y_axis.line(to: NSMakePoint(gFrame.minX-5.0, tickY)) // destination
            
            y_levels.move(to: NSMakePoint(gFrame.minX, tickY)) // start point
            y_levels.line(to: NSMakePoint(gFrame.maxX, tickY)) // destination
            
            
            let font = NSFont.systemFont(ofSize: CGFloat(12.0))
            let titleAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font]
            let attributedTitle = NSAttributedString(string: String(index*Int(hits_per_tick)) + ".0 sec", attributes: titleAttributes)
            let titleStringSize = attributedTitle.size()
            let countLocation = CGPoint(x: gFrame.minX-25.0-titleStringSize.width/2, y: tickY-titleStringSize.height/2)
            let titleStringRect = CGRect(x: countLocation.x,
                                         y: countLocation.y, width: titleStringSize.width,
                                         height: titleStringSize.height)
            attributedTitle.draw(in: titleStringRect)
        }
        
        y_axis.stroke()
        NSColor.gridColor.set()
        y_levels.stroke()
    }
    
    
    func draw_graph(timeline:[Date:Int64],
                    g_frame:CGRect,
                    max_y:Int64,
                    color:NSColor,
                    bar_width:CGFloat
                    )
    {
        // start line graph
        let x_conversion = g_frame.width / hoursDisplayed
        let y_conversion = 0.9 * g_frame.height / Double(max_y)
        var calendar = Calendar.current
        startHour = calendar.component(.hour, from: startDate)
        
        let timezone = calendar.timeZone
        print ("current TZ startHour", startHour, timezone)
        // set timeZone to PDT
        let tz = TimeZone(abbreviation: "PDT")
        if tz != nil {
            calendar.timeZone = tz!
        }
        startHour = calendar.component(.hour, from: startDate)
        print ("pacific startHour", startHour, calendar.timeZone.abbreviation())

        //let timeZones = TimeZone.knownTimeZoneIdentifiers
        //print ("timeZones", timeZones)
        //let timezones_2 = TimeZone.abbreviationDictionary
        //print ("timezones_2", timezones_2)

        var lastInterval = -1.0
        let linePath = NSBezierPath()
        linePath.lineWidth = 1.0
        linePath.move(to: NSMakePoint(g_frame.minX, g_frame.minY)) // start point
        var drawToPoint = NSMakePoint(g_frame.minX, g_frame.minY)
        
        let sortedKeys = Array(timeline.keys).sorted(by: <)
        
        for dateKey in sortedKeys {
            
            let clickInterval = clickDate.timeIntervalSince(dateKey)
            let bClicked = clickInterval < 450 && clickInterval > -450
            
            var sum = timeline[dateKey] ?? 0
            let interval = (dateKey.timeIntervalSince(startDate)) / 3600.0 // hours
            if lastInterval < 0.0 {lastInterval=interval}
            
            if interval >= 0 { // }&& interval <= 3600 { // time is in graphing range ???
                let barPath = NSBezierPath() // container for bars
                if (dateKey <= dateRangeEnd &&  dateKey >= dateRangeStart) {
                    barPath.lineWidth = bar_width * 3
                } else {
                    barPath.lineWidth = bar_width
                    color.set()
                }
                if sum > 0 {
                    let s_point = NSMakePoint(g_frame.minX+(x_conversion*interval), g_frame.minY)
                    barPath.move(to: s_point) // start point
                    drawToPoint = NSMakePoint (g_frame.minX + (x_conversion*interval), g_frame.minY + (y_conversion*Double(sum)))
                    barPath.line(to: drawToPoint) // destination
                    let rectangle = CGRect(x: drawToPoint.x-1.0, y: drawToPoint.y-1.0, width: 2, height: 2)
                    barPath.appendOval(in: rectangle)
                    barPath.stroke()
                }
                
                if lastInterval == interval {
                    let prePoint = NSMakePoint (g_frame.minX + x_conversion*(interval-1.0), g_frame.minY)
                    linePath.line(to: prePoint)
                }
                if interval-lastInterval > 1.1 {
                    let prePoint = NSMakePoint (g_frame.minX + x_conversion*(lastInterval+1.0), g_frame.minY)
                    linePath.line(to: prePoint)
                    let prePoint2 = NSMakePoint (g_frame.minX + x_conversion*(interval-1.0), g_frame.minY)
                    linePath.line(to: prePoint2)
                }
                
                linePath.line(to: drawToPoint)
                
                lastInterval = interval
                
                if (sum == max_y || bClicked) {
                    // draw endpoint  and count label
                    let textPoint = CGPoint(x: drawToPoint.x+7.0, y: drawToPoint.y-7.0)
                    let labelString = "(" + String(sum) + ") "
                    let font = NSFont.boldSystemFont(ofSize: CGFloat(12.0))
                    let titleAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor:NSColor.black]
                    let attributedTitle = NSAttributedString(string: labelString, attributes: titleAttributes)
                    let titleStringSize = attributedTitle.size()
                    attributedTitle.draw(at: textPoint)
                }
            }
        }
        // continue to frame line and fill
        linePath.line(to: NSMakePoint(drawToPoint.x, g_frame.minY))
        linePath.line(to: NSMakePoint(g_frame.minX, g_frame.minY)) // back to start point
        color.withAlphaComponent(0.33).set()
    }

    func draw_double_graph (timeline:[Date:Double],
                       g_frame:CGRect,
                       max_y:Double,
                       color:NSColor,
                       bar_width:CGFloat
                       )
    {
        // start line graph
        let x_conversion = g_frame.width / hoursDisplayed
        let y_conversion = 0.9 * g_frame.height / Double(max_y)
        var calendar = Calendar.current
        startHour = calendar.component(.hour, from: startDate)
        
        let timezone = calendar.timeZone
        // print ("current startHour", startHour, timezone)
        
        // set timeZone to PDT
        let tz = TimeZone(abbreviation: "PDT")
        if tz != nil {
            calendar.timeZone = tz!
        }
        
        startHour = calendar.component(.hour, from: startDate)
        print ("pacific startHour", startHour, calendar.timeZone.abbreviation())
      
        var lastInterval = -1.0
        let linePath = NSBezierPath()
        linePath.lineWidth = 1.0
        linePath.move(to: NSMakePoint(g_frame.minX, g_frame.minY)) // start point
        var drawToPoint = NSMakePoint(g_frame.minX, g_frame.minY)
        
        let sortedKeys = Array(timeline.keys).sorted(by: <)
        
        for dateKey in sortedKeys {
            
            let clickInterval = clickDate.timeIntervalSince(dateKey)
            let bClicked = clickInterval < 450 && clickInterval > -450
            
            var sum = timeline[dateKey] ?? 0
            let interval = (dateKey.timeIntervalSince(startDate)) / 3600.0 // hours
            if lastInterval < 0.0 {lastInterval=interval}
            
            if interval >= 0 { // }&& interval <= 3600 { // time is in graphing range ???
                let barPath = NSBezierPath() // container for bars
                if (dateKey <= dateRangeEnd &&  dateKey >= dateRangeStart) {
                    barPath.lineWidth = bar_width * 3
                } else {
                    barPath.lineWidth = bar_width
                    color.set()
                    
                }
                let s_point = NSMakePoint(g_frame.minX+(x_conversion*interval), g_frame.minY)
                barPath.move(to: s_point) // start point
                drawToPoint = NSMakePoint (g_frame.minX + (x_conversion*interval), g_frame.minY + (y_conversion*Double(sum)))
                barPath.line(to: drawToPoint) // destination
                let rectangle = CGRect(x: drawToPoint.x-1.0, y: drawToPoint.y-1.0, width: 2, height: 2)
                barPath.appendOval(in: rectangle)
                
                barPath.stroke()
               
                if (sum == max_y || bClicked) {
                    // draw endpoint  and count label
                    let textPoint = CGPoint(x: drawToPoint.x+7.0, y: drawToPoint.y-7.0)
                    let labelString = "(" + String(sum) + ") "
                    let font = NSFont.boldSystemFont(ofSize: CGFloat(12.0))
                    let titleAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor:NSColor.black]
                    let attributedTitle = NSAttributedString(string: labelString, attributes: titleAttributes)
                    let titleStringSize = attributedTitle.size()
                    attributedTitle.draw(at: textPoint)
                }
            }
        }
        color.withAlphaComponent(0.33).set()
    }
    
    /*
    func fetchUnion(){
        // Create a fetch request with a string filter
        // for an entity’s name
        let fetchRequest: NSFetchRequest<Request_Interval>
        fetchRequest = Request_Interval.fetchRequest()

        fetchRequest.predicate = NSPredicate(
            format: "name LIKE %@", "Robert"
        )

         // Create the component predicates
         let namePredicate = NSPredicate(
             format: "name LIKE %@", "Robert"
         )

         let planetPredicate = NSPredicate(
             format: "country = %@", "Earth"
         )

         // Create an "and" compound predicate, meaning the
         // query requires all the predicates to be satisfied.
         // In other words, for an object to be returned by
         // an "and" compound predicate, all the component
         // predicates must be true for the object.
         fetchRequest.predicate = NSCompoundPredicate(
             andPredicateWithSubpredicates: [
                 namePredicate,
                 planetPredicate
             ]
         )
         
        
        // Get a reference to a NSManagedObjectContext
        //let context = persistentContainer.viewContext

        // Perform the fetch request to get the objects
        // matching the predicate
        //let objects = try context.fetch(fetchRequest)
    }
     */
    
    func printView () {
        //if accounts.count == 0 && ep_timelines.count == 0 {
        //    print ("nothing to print")
        //    return
        //}
        NSPrintInfo.shared.orientation = .landscape
        NSPrintInfo.shared.scalingFactor = 0.44
        NSPrintInfo.shared.leftMargin = 10
        NSPrintInfo.shared.rightMargin = 10
        //print("printInfo", NSPrintInfo.shared)
        
        let op = NSPrintOperation(view: self)
        DispatchQueue.main.async {
            op.run()
        }
    }
    
    // NSTextFieldDelegate
    func controlTextDidBeginEditing(_ obj: Notification) {
        print("controlTextDidBeginEditing")
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        print("controlTextDidEndEditing")
        let userInfo = obj.userInfo
        let textField = userInfo!["NSFieldEditor"] as? NSTextField
    }
    
    func controlTextDidChange(notification: NSNotification) {
        print("controlTextDidChange")
         // if let txtFld = notification.object as? NSTextField {
             //witch txtFld.tag {
             //case 201:
             //   self.label.stringValue = txtFld.stringValue
             //case 202:
             //   self.label2.stringValue = txtFld.stringValue
             //default://
             //   break
             //}
          //}
       }
}
