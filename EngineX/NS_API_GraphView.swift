//
//  NS_GraphView.swift
//  API Analysis (macOS)
//
//  Created by Dave Lathrop on 4/8/22.
//

import Cocoa
import SwiftUI
import PDFKit

@available(macOS 12.0, *)
struct API_ChartViewRepresentable: NSViewRepresentable {
    
    typealias NSViewType = API_GraphView
    
    var ep_timelines:[API_Timeline]
    var accounts:[API_Account]
    var accountIntervals:[API_Interval]
    var metadata:[API_File_MetaData]
    
    var cropLeft : Int
    var cropRight : Int
    var scale_y : Int
    var graphStyle : String
    
    func makeNSView(context: Context) -> API_GraphView {
        
        if metadata.count == 0 {
            return API_GraphView(ep_timelines:ep_timelines, accounts:accounts, accountIntervals:accountIntervals, startDate: Date.distantFuture, endDate: Date.distantFuture, scale_y:scale_y, graphStyle:graphStyle)
        }
        let stats = metadata[0]
        let g_start_time = stats.start_time?.addingTimeInterval(Double(cropLeft)*6.0*3600.0)
        return API_GraphView(ep_timelines:ep_timelines, accounts:accounts, accountIntervals:accountIntervals, startDate: g_start_time!, endDate: stats.end_time!, scale_y:scale_y, graphStyle:graphStyle)
    }
    
    func updateNSView(_ nsView: API_GraphView, context: Context) {
        nsView.ep_timelines = ep_timelines
        nsView.accounts = accounts
        nsView.accountIntervals = accountIntervals
        if metadata.count > 0 {
            let stats = metadata[0]
            let g_start_time = stats.start_time?.addingTimeInterval(Double(cropLeft)*6.0*3600.0)
            nsView.startDate = g_start_time!
            let g_end_time = stats.end_time?.addingTimeInterval(Double(-cropRight)*3600.0)
            nsView.endDate = g_end_time!
        }
        nsView.graphStyle = graphStyle
    }
}


@available(macOS 12.0, *)

class API_GraphView: NSView, NSTextFieldDelegate, NSControlTextEditingDelegate {
    
    let dateFormatter = DateFormatter()
    let timeFormatter = DateFormatter()
    var max_y = Int64(0)
    
    var graphStyle : String
    var scale_y : Int
    
    let colors = [NSColor.systemBlue, NSColor.systemBrown, NSColor.systemGray, NSColor.systemGreen, NSColor.systemIndigo, NSColor.systemOrange, NSColor.systemPink, NSColor.systemPurple, NSColor.systemRed, NSColor.systemTeal, NSColor.systemYellow , NSColor.clear , NSColor.black , NSColor.blue , NSColor.brown , NSColor.cyan , NSColor.darkGray , NSColor.gray , NSColor.green , NSColor.lightGray , NSColor.magenta , NSColor.orange , NSColor.purple , NSColor.red , NSColor.white , NSColor.yellow]
    
    var ep_timelines : [API_Timeline] {
        didSet {
            self.needsDisplay = true
        }
    }
    var accounts : [API_Account] {
        didSet {
            self.needsDisplay = true
        }
    }
    var accountIntervals : [API_Interval] {
        didSet {
            self.needsDisplay = true
        }
    }
    
    var startDate : Date
    var endDate : Date
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
    
    init(ep_timelines:[API_Timeline], accounts:[API_Account], accountIntervals:[API_Interval], startDate:Date, endDate:Date, scale_y:Int, graphStyle:String) {
        self.ep_timelines = ep_timelines
        self.accounts = accounts
        self.accountIntervals = accountIntervals
        self.startDate = startDate
        self.endDate = endDate
        self.graphStyle = graphStyle
        self.scale_y = scale_y
        
        super.init(frame:.zero)
        wantsLayer = true
        layer?.backgroundColor = .white
        
        // gestures
        //let recognizer = NSClickGestureRecognizer(target: self, action: #selector(singleTapGesture))
        //recognizer.numberOfClicksRequired = 1
        //recognizer.numberOfTouchesRequired = 2
        //self.addGestureRecognizer(recognizer)
        
        let recognizer1 = NSClickGestureRecognizer(target: self, action: #selector(doubleTapGesture))
        recognizer1.numberOfClicksRequired = 2
        self.addGestureRecognizer(recognizer1)
        
        let dragRecognizer = NSPanGestureRecognizer(target: self, action: #selector(dragGesture))
        self.addGestureRecognizer(dragRecognizer)
        
        let magRcognizer = NSMagnificationGestureRecognizer(target: self, action: #selector(magGesture))
        self.addGestureRecognizer(magRcognizer)
        
        self.addSubview(overlayView)
        
        self.addSubview(titleTextField)
        //titleTextField.isBordered = true
        //titleTextField.isBezeled = true
        titleTextField.placeholderString = "Enter Graph Title"
        titleTextField.delegate = self
        
        //let document = PDFDocument()
        //document.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func dragGesture(recognizer: NSPanGestureRecognizer) {
        let translation = recognizer.translation(in:self)
        let mousePoint = recognizer.location(in:self)
        let downpoint = CGPoint(x: mousePoint.x - translation.x, y: mousePoint.y - translation.y)
        let index = (downpoint.x - g_frame.minX) / tick_pixels_x
        let index_2 = (downpoint.x + translation.x - g_frame.minX) / tick_pixels_x
        
        let recState = recognizer.state // check if ended, to redraw graph
        var is_zero_selection = false
        if recState == .ended {
            // set the selection range
            if abs(index-index_2) < 0.02  { // if size.x is too small, zero out selection
                is_zero_selection = true
                dateRangeStart = Date.distantFuture
                dateRangeEnd = Date.distantPast
                overlayView.frame = CGRect.zero
            }
            else if index < index_2 {
                dateRangeStart = startDate.addingTimeInterval(index*3600)
                dateRangeEnd = startDate.addingTimeInterval(index_2*3600)
            }
            else {
                dateRangeStart = startDate.addingTimeInterval(index*3600)
                dateRangeEnd = startDate.addingTimeInterval(index_2*3600)
            }
            self.needsDisplay = true
        }
       
        if !is_zero_selection {
            // set overlay state
            let overlayColor = CGColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 0.1)
            overlayView.layer!.backgroundColor = overlayColor
            
            if translation.x >= 0 {
                if translation.y >= 0 {
                    overlayView.frame = CGRect(x: downpoint.x, y: g_frame.minY, width: translation.x, height: g_frame.height)
                } else { // negative drag y
                    overlayView.frame = CGRect(x: downpoint.x, y: g_frame.minY, width: translation.x, height: g_frame.height)
                }
            } else { // negative drag x
                if translation.y >= 0 {
                    overlayView.frame = CGRect(x: downpoint.x + translation.x, y: g_frame.minY, width: translation.x, height: g_frame.height)
                } else { // negative drag y
                    overlayView.frame = CGRect(x: downpoint.x + translation.x, y: g_frame.minY, width: translation.x, height: g_frame.height)
                }
            }
        }
    }
    
    @objc func singleTapGesture(recognizer: NSClickGestureRecognizer) {
        clickLocation = recognizer.location(in: self)
        let index = (clickLocation.x - g_frame.minX) / tick_pixels_x
        //clickDate = startDate.addingTimeInterval(index*3600)
        //self.needsDisplay = true
        //self.printView()
        print("singleTapGesture")
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
        if accounts.count == 0 && ep_timelines.count == 0 {
            print ("nothing to draw")
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
        
        hoursDisplayed = (endDate.timeIntervalSince(startDate)) / 3600.0 // hours
        
        g_frame = CGRect(x: frame.minX+inset_left, y: frame.minY+inset_bot, width: frame.width-inset_right-inset_left, height: frame.height-inset_top-inset_bot)
        
        var union_sum = [Date:Int64]()
        var account_sum = [Date:Int64]()
        var account_title = ""
        var endpoint_sum = [Date:Int64]()
        var endpoint_title = ""
        var selectedTime = [String:Int64]()
        
        // calculate the graphs
        
        if graphStyle == "Endpoints AND Accounts" {
            var ep_array = [String]()
            for ep in ep_timelines {
                ep_array.append(ep.endpoint!)
                endpoint_title = ep.endpoint!
            }
            var max_local_sum = Int64(0)

            print("ep_array", ep_array)
            // prepare the sum timeline
            for account in  accounts {
                account_title = account.account_name!
                let sortedIntervals = account.intervals?.sortedArray(using: [NSSortDescriptor(key: "start_time", ascending: true)]) as! [API_Interval]
                
                for interval in sortedIntervals {
                    
                    let ep_summaries = interval.endpoint_summary?.allObjects as? [API_Summary]
                    for eps in ep_summaries! {
                        // filter for selected endpoints
                        if ep_array.contains(eps.endpoint!) {
                            // check if eps.endpoint is in selected endpoints
                            let count = eps.count
                            let value = union_sum[eps.startDate!] ?? 0
                            let sum = value + count
                            if sum > max_y { max_y = sum }
                            if eps.startDate! >= startDate &&  eps.startDate! <= endDate {
                                if sum > max_local_sum { max_local_sum = sum }
                            }
                            union_sum[eps.startDate!] = sum
                        }
                    }
                }
            }
        }
        
        if graphStyle == "Endpoints" {
            var max_local_sum = Int64(0)
            // sum hits, create timeline
            if ep_timelines.count == 1 {
                endpoint_title = ep_timelines[0].endpoint!
            }
            if ep_timelines.count > 1 {
                endpoint_title = "All Endpoints"
            }
            for timeline in ep_timelines {
                //endpoint_title = timeline.endpoint!
                let points = timeline.summaries?.allObjects as? [API_Summary] ?? []
                for point in points {
                    let value = endpoint_sum[point.startDate!] ?? 0
                    let count = point.count
                    let sum = value + count
                    if sum > max_y { max_y = sum }
                    if point.startDate! >= startDate &&  point.startDate! <= endDate {
                        if sum > max_local_sum { max_local_sum = sum }
                    }
                    endpoint_sum[point.startDate!] = sum
                   
                    if (point.startDate! <= dateRangeEnd &&  point.startDate! >= dateRangeStart) || dateRangeStart >= dateRangeEnd {
                        let accname = point.account ?? ""
                        let accsum = selectedTime[accname] ?? 0
                        selectedTime[accname] = accsum + count
                    }
                }
            }
        }
            
        if graphStyle == "Accounts" {
            var max_local_sum = Int64(0)
            // prepare the sum timeline
            for account in  accounts {
                account_title = account.account_name!
                let sortedIntervals = account.intervals?.sortedArray(using: [NSSortDescriptor(key: "start_time", ascending: true)]) as! [API_Interval]
                
                for interval in sortedIntervals {
                    let ep_summaries = interval.endpoint_summary?.allObjects as? [API_Summary]
                    for eps in ep_summaries! {
                        let count = eps.count
                        let value = account_sum[eps.startDate!] ?? 0
                        let sum = value + count
                        
                        if eps.startDate! >= startDate &&  eps.startDate! <= endDate {
                            if sum > max_y { max_y = sum }
                        }
                        
                        if eps.startDate! >= startDate &&  eps.startDate! <= endDate {
                            if sum > max_local_sum { max_local_sum = sum }
                        }
                        account_sum[eps.startDate!] = sum
                        
                        if (eps.startDate! <= dateRangeEnd &&  eps.startDate! >= dateRangeStart) || dateRangeStart >= dateRangeEnd {
                            let epsum = selectedTime[eps.endpoint!] ?? 0
                            selectedTime[eps.endpoint!] = epsum + count
                        }
                    }
                }
            }
        }
        
        // draw the graphs
        // let graphStyles = ["Endpoints", "Accounts", "Endpoints AND Accounts"]
        // draw axes
        drawAxes(g_frame: g_frame)
        
        if graphStyle == "Endpoints" {
            draw_graph(timeline:endpoint_sum, g_frame: g_frame, max_y: max_y, color:NSColor.blue, bar_width:1)
            drawTitle(title:endpoint_title)
            draw_top_five(selectedTime, title:"Top Accounts")
        }
        if graphStyle == "Accounts" {
            draw_graph(timeline:account_sum, g_frame: g_frame, max_y: max_y, color:NSColor.red, bar_width:1)
            drawTitle(title:account_title)
            //drawTitle(title:account_title + " - All Endpoints")
            draw_top_five(selectedTime, title:"Top Endpoints")
        }
        
        if graphStyle == "Endpoints AND Accounts" {
            print("union_sum", union_sum)
            draw_graph(timeline:union_sum, g_frame: g_frame, max_y: max_y, color:NSColor.purple, bar_width:1)
            drawTitle(title:account_title + " - " + endpoint_title) //
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
        let attributedDate = NSAttributedString(string: title, attributes: dateAttributes)
        let dateStringSize = attributedDate.size()
        let dateStringRect = CGRect(x: itemLocation.x,
                                     y: itemLocation.y, width: dateStringSize.width,
                                     height: dateStringSize.height)
        attributedDate.draw(in: dateStringRect)
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
    
    func drawAxes(g_frame:CGRect) {
        
        NSColor.red.set() // choose color
        let x_axis = NSBezierPath() // container for line(s)
        x_axis.lineWidth = 1.0
        x_axis.move(to: NSMakePoint(g_frame.minX, g_frame.minY)) // start point
        x_axis.line(to: NSMakePoint(g_frame.maxX, g_frame.minY)) // destination
        // draw axis ticks every hour, every day
        tick_pixels_x = g_frame.width / hoursDisplayed
        let tickCount = Int(hoursDisplayed)
        
        var tickLabelFrequency = 3
        if tick_pixels_x < 12.0 { tickLabelFrequency = 6 }
        for index in 0...tickCount {
            let tickX = g_frame.minX + Double(index)*tick_pixels_x
            x_axis.move(to: NSMakePoint(tickX, g_frame.minY)) // start point
            x_axis.line(to: NSMakePoint(tickX, g_frame.minY-5.0)) // destination
            
            // draw tick hour label
            var hour = startHour + index
            if ( hour % tickLabelFrequency == 0 ) {
                var hourString = ""
                while hour >= 24 { hour -= 24}
                if hour == 0 {
                    hourString = "12am"
                    // draw day start mark
                    x_axis.move(to: NSMakePoint(tickX, g_frame.minY-27)) // start point
                    x_axis.line(to: NSMakePoint(tickX, g_frame.minY-56.0)) // destination
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
        
        // y-axis
        let y_axis = NSBezierPath() // container for line(s)
        let y_levels = NSBezierPath()
        y_axis.lineWidth = 1.0
        y_levels.lineWidth = 1.0
        y_axis.move(to: NSMakePoint(g_frame.minX, g_frame.minY)) // start point
        y_axis.line(to: NSMakePoint(g_frame.minX, g_frame.maxY)) // destination
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
        
        let tickPixelsY = 0.9 * g_frame.height / ((Double(max_y) / hits_per_tick ))
        let tickCountY = max_y / Int64(hits_per_tick)
        
        for index in 0...tickCountY {
            let tickY = g_frame.minY + Double(index)*tickPixelsY
            y_axis.move(to: NSMakePoint(g_frame.minX, tickY)) // start point
            y_axis.line(to: NSMakePoint(g_frame.minX-5.0, tickY)) // destination
            
            y_levels.move(to: NSMakePoint(g_frame.minX, tickY)) // start point
            y_levels.line(to: NSMakePoint(g_frame.maxX, tickY)) // destination
            
            
            let font = NSFont.systemFont(ofSize: CGFloat(12.0))
            let titleAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font]
            let attributedTitle = NSAttributedString(string: String(index*Int64(hits_per_tick)), attributes: titleAttributes)
            let titleStringSize = attributedTitle.size()
            let countLocation = CGPoint(x: g_frame.minX-25.0-titleStringSize.width/2, y: tickY-titleStringSize.height/2)
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
        
        /* time zone code, will need to parse for +ZZZZ in log to determine local zone
        let timezone = calendar.timeZone
        print ("current startHour", startHour, timezone)
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
        */
       
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
                }
                color.set()
                let s_point = NSMakePoint(g_frame.minX+(x_conversion*interval), g_frame.minY)
                barPath.move(to: s_point) // start point
                drawToPoint = NSMakePoint (g_frame.minX + (x_conversion*interval), g_frame.minY + (y_conversion*Double(sum)))
                barPath.line(to: drawToPoint) // destination
                let rectangle = CGRect(x: drawToPoint.x-1.0, y: drawToPoint.y-1.0, width: 2, height: 2)
                barPath.appendOval(in: rectangle)
                
                barPath.stroke()
                
                //print ("lastInterval", interval, lastInterval)
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
                
                // draw max count
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
        // linePath.fill()
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
        if accounts.count == 0 && ep_timelines.count == 0 {
            print ("nothing to print")
            return
        }
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
