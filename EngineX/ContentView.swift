//
//  ContentView.swift
//  EngineX
//
//  Created by Dave Lathrop on 7/22/22.
//

import SwiftUI
import CoreData

struct ContentView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    // NGINX
    @State private var selectedWebServers = Set<NGINX_WebServer>()
    @State private var selectedTimeSlices = Set<NGINX_TimeSlice>()
    @State private var selectedEndpoints = Set<NGINX_Endpoint>()
    @State private var selectedIPAddresses = Set<NGINX_IP_Address>()
    @State private var selectedServers = Set<NGINX_Server>()
    // API
    @State private var selectedTimelines = Set<API_Timeline>()
    @State private var selectedAccounts = Set<API_Account>()
    @State private var selectedIntervals = Set<API_Interval>()
    
    @State private var IP_Addresses = [String:Any]()
    @State private var Servers = [String:Any]()
    @State private var Endpoints = [String:Any]()
    // from API
    @State private var startDate = Date()
    @State private var expand_graph = false
    @State private var cropLeft = 0
    @State private var cropRight = 0
    @State private var scale_y = 10
    let graphStyles = ["Endpoints", "Accounts", "Endpoints AND Accounts"]
    @State private var graphStyle = "Endpoints"
    
    @State private var showCounts = true
    @State private var showTotals = false
    @State private var showResponseTimes = false
    
    @State private var showWebservers = false
    @State private var showEndpoints = true
    @State private var showIPAddresses = false
    @State private var showServers = false
    
    @State private var toggleToAPI = true
    
    // NGINX Fetch Requests
    @FetchRequest(sortDescriptors: [SortDescriptor(\.date, order: .forward)])
    private var timeSlices: FetchedResults<NGINX_TimeSlice>
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.count, order: .forward)])
    private var points: FetchedResults<NGINX_Point>
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.webserver, order: .forward)])
    private var files: FetchedResults<NGINX_File>
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name, order: .forward)])
    private var webServers: FetchedResults<NGINX_WebServer>
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.path, order: .forward)])
    private var endpoints: FetchedResults<NGINX_Endpoint>
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.address, order: .forward)])
    private var ip_addresses: FetchedResults<NGINX_IP_Address>
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name, order: .forward)])
    private var servers: FetchedResults<NGINX_Server>
    
    // API Fetch Requests
    @FetchRequest(sortDescriptors: [SortDescriptor(\.endpoint, order: .forward)])
    private var timelines: FetchedResults<API_Timeline>
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.account_name, order: .forward)])
    private var accounts: FetchedResults<API_Account>
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.start_time, order: .forward)])
    private var metadata: FetchedResults<API_File_MetaData>
    
    var body: some View {
        VStack {
            if toggleToAPI {
                if !expand_graph {
                HStack {
                    VStack{
                        Spacer()
                        HStack {
                            Toggle("Switch to API", isOn: $toggleToAPI)
                            Button("Load API Data") { load_api_data_file() }
                            Button("Load Account Data"){ load_account_summary_data_file()}
                            Button("Load Folder"){ load_full_interval_folder()}
                            Text("Endpoints")
                            Button("Delete API Data (!!!)", action:remove_API_Objects ) // parseNGINX)
                        }
                        List(selection: $selectedTimelines) {
                            ForEach(timelines, id: \.self) { timeline in
                                HStack {
                                    Text(timeline.endpoint!)
                                    Text(String(timeline.totalCount))
                                    Spacer()
                                }
                           }
                        }
                    }
                    VStack{
                        HStack {
                            Text("Accounts")
                        }
                        List(selection: $selectedAccounts) {
                            ForEach(accounts, id: \.self) { account in
                                HStack {
                                    Text(account.account_id!)
                                    Text(account.account_name!)
                                }
                           }
                        }
                    }
                }
                }
            }
            else {
            if !expand_graph {
            HStack {
                Toggle("Switch to API", isOn: $toggleToAPI)
                    .toggleStyle(.checkbox)
                Button("Load NGINX") { load_nginx_file() }
                Button("Erase") { erase_nginx_store() }
            }
            HStack {
                VStack {
                    Text("Web Servers")
                    List (selection: $selectedWebServers){
                        ForEach(webServers, id: \.self) { ws in
                            //NavigationLink {
                            //    Text("Item at \(point.tag!)") // , formatter: itemFormatter
                            //} label: {
                            let name = ws.name ?? "none"
                            Text(name) // , formatter: itemFormatter
                            //}
                        }
                    }
                }
                VStack {
                    Text("Endpoints")
                    List (selection: $selectedEndpoints){
                        ForEach(endpoints, id: \.self) { ep in
                            let path = ep.path ?? "none"
                            Text(path) // , formatter: itemFormatter
                        }
                    }
                }
                VStack {
                    Text("IP Addresses")
                    List (selection: $selectedIPAddresses){
                        ForEach(ip_addresses, id: \.self) { ipa in
                            let address = ipa.address ?? "none"
                            Text(address)
                        }
                    }
                }
                VStack {
                    Text("Servers")
                    List (selection: $selectedServers){
                        ForEach(servers, id: \.self) { server in
                            let server_name = server.name ?? "none"
                            Text(server_name)
                        }
                    }
                }
                VStack {
                    
                    Toggle("Graph Totals", isOn: $showTotals)
                        .toggleStyle(.checkbox)
                    Toggle("Graph Counts", isOn: $showCounts)
                        .toggleStyle(.checkbox)
                    Toggle("Graph Response Time", isOn: $showResponseTimes)
                        .toggleStyle(.checkbox)
                    
                    Text("*******************")
                    
                    Toggle("Show Webservers", isOn: $showWebservers)
                        .toggleStyle(.checkbox)
                    Toggle("Show Endpoints", isOn: $showEndpoints)
                        .toggleStyle(.checkbox)
                    Toggle("Show IP Addresses", isOn: $showIPAddresses)
                        .toggleStyle(.checkbox)
                    Toggle("Show Servers", isOn: $showServers)
                        .toggleStyle(.checkbox)
                    
                    DatePicker(selection: $startDate, in: ...Date(), displayedComponents: .date) {
                        Text("Date")
                    }
                }
            }
            }
            }
            HStack {
                Spacer()
                Picker("Graph:", selection: $graphStyle) {
                    ForEach(graphStyles, id: \.self) {
                            Text($0)
                    }
                }.pickerStyle(.menu)
                    .frame(minWidth: 250, maxWidth: 250, minHeight: 30, maxHeight: 30)
                
                Toggle("Expand Graph", isOn: $expand_graph)
                    .toggleStyle(.checkbox)
                
                Spacer()
            }
            if toggleToAPI {
                Group {
                    API_ChartViewRepresentable(ep_timelines:selectedTimelines.map{$0}, accounts:selectedAccounts.map{$0}, accountIntervals: selectedIntervals.map{$0}, metadata:metadata.map{$0}, graphStyle:graphStyle)
                        .frame(minWidth: 300, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
                        //.onAppear(perform: refreshSummaries)
                        //.gesture(dragGesture)
                }
            }
            else {
                Group {
                    ChartViewRepresentable( timeSlices:timeSlices.map{$0}, webServers:selectedWebServers.map{$0}, endpoints:selectedEndpoints.map{$0}, ip_addresses:selectedIPAddresses.map{$0}, startDate:startDate, showCounts:showCounts, showTotals:showTotals, showResponseTimes:showResponseTimes, showWebservers:showWebservers, showEndpoints:showEndpoints, showIPAddresses:showIPAddresses, showServers:showServers)
                        .frame(minWidth: 300, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
                        //.onAppear(perform: refreshSummaries)
                        //.gesture(dragGesture)
                }
            }
        }
    }
    
    private func load_nginx_file () {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            let url = panel.url
            let filename = url?.lastPathComponent ?? "<none>"
            print ("url", panel.url)
            // open file at panel.url
            let home = FileManager.default.homeDirectoryForCurrentUser
            let playgroundPath = "Desktop/Files.playground"
            let playgroundUrl = home.appendingPathComponent(playgroundPath)
            print (infoAbout(url: panel.url!))
            do {
                let data = try Data(contentsOf: panel.url!)
                let parser = NGINX_Parser(string: String(decoding: data, as: UTF8.self))
                parser.parseAll(viewContext, url:url!)
            } catch {
                print("load failed")
            }
        }
    }
    
    func erase_nginx_store() {
        
        // Create Fetch Request for Batch Delete
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "NGINX_TimeSlice")
        // Create Batch Delete Request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try viewContext.execute(batchDeleteRequest)
        } catch {
            print("Delete Error NGINX_TimeSlice")
        }
        
        let fetchRequest2 = NSFetchRequest<NSFetchRequestResult>(entityName: "NGINX_Point")
        // Create Batch Delete Request
        let batchDeleteRequest2 = NSBatchDeleteRequest(fetchRequest: fetchRequest2)
        do {
            try viewContext.execute(batchDeleteRequest2)
        } catch {
            print("Delete Error NGINX_Point")
        }
        
        let fetchRequest3 = NSFetchRequest<NSFetchRequestResult>(entityName: "NGINX_File")
        // Create Batch Delete Request
        let batchDeleteRequest3 = NSBatchDeleteRequest(fetchRequest: fetchRequest3)
        do {
            try viewContext.execute(batchDeleteRequest3)
        } catch {
            print("Delete Error NGINX_File")
        }
    
        let fetchRequest4 = NSFetchRequest<NSFetchRequestResult>(entityName: "NGINX_WebServer")
        // Create Batch Delete Request
        let batchDeleteRequest4 = NSBatchDeleteRequest(fetchRequest: fetchRequest4)
        do {
            try viewContext.execute(batchDeleteRequest4)
        } catch {
            print("Delete Error NGINX_WebServer")
        }
    
        let fetchRequest5 = NSFetchRequest<NSFetchRequestResult>(entityName: "NGINX_Endpoint")
        // Create Batch Delete Request
        let batchDeleteRequest5 = NSBatchDeleteRequest(fetchRequest: fetchRequest5)
        do {
            try viewContext.execute(batchDeleteRequest5)
        } catch {
            print("Delete Error NGINX_Endpoint")
        }
        
        let fetchRequest6 = NSFetchRequest<NSFetchRequestResult>(entityName: "NGINX_IP_Address")
        // Create Batch Delete Request
        let batchDeleteRequest6 = NSBatchDeleteRequest(fetchRequest: fetchRequest6)
        do {
            try viewContext.execute(batchDeleteRequest6)
        } catch {
            print("Delete Error NGINX_IP_Address")
        }
        
        let fetchRequest7 = NSFetchRequest<NSFetchRequestResult>(entityName: "NGINX_Server")
        // Create Batch Delete Request
        let batchDeleteRequest7 = NSBatchDeleteRequest(fetchRequest: fetchRequest7)
        do {
            try viewContext.execute(batchDeleteRequest7)
        } catch {
            print("Delete Error NGINX_Server")
        }
            
            do {
                try viewContext.save()
            } catch {
                print( "viewContext.save() failed!")
            }
        
    }
    
    private func load_api_data_file () {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            let url = panel.url
            let filename = url?.lastPathComponent ?? "<none>"
            print ("url", panel.url)
            // open file at panel.url
            let home = FileManager.default.homeDirectoryForCurrentUser
            let playgroundPath = "Desktop/Files.playground"
            let playgroundUrl = home.appendingPathComponent(playgroundPath)
            print (infoAbout(url: panel.url!))
            DispatchQueue.main.async {
                Task {
                    do {
                        let data = try Data(contentsOf: panel.url!)
                        let summaries = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as! [String:Any]
                        process_API_JSON(summaries:summaries)
                    }
                    catch {
                        print("load failed")
                    }
                }
            }
        }
    }
    
    
    func process_API_JSON(summaries:[String: Any]) {
        print("process_API_JSON", Date.now)
        UserDefaults.standard.set(true, forKey: "is_data_loaded")
        UserDefaults.standard.synchronize()
        // struct for coalescing endpoint timelines
        var endpointTimelines = [String:Any]()
         
        let accountIDs = summaries.keys
        for account_id in accountIDs {
            if account_id == "global_stats" {
                print("persist global_stats")
                let metadata = summaries["global_stats"] as? [String:Any] ?? [:]
                let metadatObject = API_File_MetaData(context: viewContext)
                
                let dateFormatter = ISO8601DateFormatter()
                let iso_start_time = metadata["start_time"] as? String ?? ""
                let start_time = dateFormatter.date(from:iso_start_time) ?? Date.distantFuture
                metadatObject.start_time = start_time
                
                let iso_end_time = metadata["end_time"] as? String ?? ""
                let end_time = dateFormatter.date(from:iso_end_time) ?? Date.distantFuture
                metadatObject.end_time = end_time
                
                let interval = summaries["interval"] as? Int ?? 0
                metadatObject.interval = Int64(interval)
                
                let comment = summaries["comment"] as? String ?? ""
                metadatObject.comment = comment
                
                let link = summaries["link"] as? String ?? ""
                metadatObject.link = link
                
                continue
            }
            
            // should only persist account if doesn't already exist
            let accountObject = fetchOrCreateAPI_Account(account_id, context:viewContext )
            let account_intervals = summaries[account_id] as? [[String:Any]] ?? [[String:Any]]()
            for account_interval in account_intervals {
           
                let summaryObject = API_Interval(context: viewContext)
                
                let total_apis = account_interval["total_apis"] as? Int64 ?? 0
                summaryObject.total_apis = total_apis
                
                let account_sfdc = account_interval["account_sfdc"] as? String ?? ""
                summaryObject.account_sfdc = account_sfdc
                
                let dateFormatter = ISO8601DateFormatter()
                
                let iso_start = account_interval["start_time"] as? String ?? ""
                guard let start_time = dateFormatter.date(from:iso_start) else {
                    print("No Start Time:")
                    print("summary=", account_interval)
                    continue
                }
                
                summaryObject.start_time = start_time
                
                let iso_end = account_interval["end_time"] as? String ?? ""
                let end_time = dateFormatter.date(from:iso_end)!
                summaryObject.end_time = end_time
                
                let sliceInterval = end_time.timeIntervalSince(start_time)
                
                let account_name = account_interval["account_name"] as? String ?? ""
                summaryObject.account_name = account_name
                accountObject.account_name = account_name
               
                let account_id = account_interval["account_id"] as! Int64
                let id_string = String(account_id)
                summaryObject.account_id = id_string
                
                let account_uuid = account_interval["account_uuid"] as? String ?? ""
                summaryObject.account_uuid = account_uuid
                 
                // add to account object
                accountObject.addToIntervals(summaryObject)
                
                let endpoints = account_interval["endpoint_summary"] as?[String:Any] ?? [:]
                let keys = endpoints.keys
                for key in keys {
                    
                    let endpointSummary = API_Summary(context: viewContext)
                    let endpoint = key ?? "not a string"
                    endpointSummary.endpoint = endpoint
                    endpointSummary.account = account_name
                    
                    let epData = endpoints[key] as? [String:Any] ?? [:]
                    
                    let count = epData["count"] as? Int64 ?? 0
                    endpointSummary.count = count
                    
                    let max_payload_size = epData["max_payload_size"] as? Double ?? 0.0
                    endpointSummary.max_payload_size = max_payload_size
                    
                    let avg_payload_size = epData["avg_payload_size"] as? Double ?? 0.0
                    endpointSummary.avg_payload_size = avg_payload_size
                    
                    endpointSummary.startDate = start_time
                    endpointSummary.endDate = end_time
                    
                    // add to summary
                    //endpointSummary.interval = summaryObject
                    summaryObject.addToEndpoint_summary(endpointSummary)
                    
                    // add to endpoint timeline
                    var timeline = endpointTimelines[endpoint] as? [API_Summary] ?? [API_Summary]()
                    timeline.append(endpointSummary)
                    endpointTimelines[endpoint] = timeline
                }
            }
        }
        
        // create endpoint timeline objects
        let epKeys = endpointTimelines.keys
        print ("epKeys count", epKeys.count, Date.now)
        for epKey in epKeys {
            
            // fetch API_Timeline or create ...
            let timelineObject = fetchOrCreateAPI_Timeline(epKey, context: viewContext)
            //let timelineObject = API_Timeline(context: viewContext)
            
            let timeline = endpointTimelines[epKey] as? [API_Summary] ?? [API_Summary]()
            var total_hits = timelineObject.total_hits
            for es in timeline {
                //es.timeline = timelineObject
                timelineObject.addToSummaries(es)
                total_hits += Int32(es.count)
            }
            
            // get requestType and rootComponent from epKey
            let epString = epKey as NSString
            let range = epString.range(of: "::")
            let requestType = epString.substring(from: range.location + range.length)
            let ep = epString.substring(to: range.location)
            let components = ep.components(separatedBy: "/")
            let rootComponent = components[2]
            //print("requestType", requestType, "ep", rootComponent)
            
            // this is number of slices with a hit
            timelineObject.totalCount += Int64(timeline.count)
            
            // total number of hits
            timelineObject.total_hits = Int32(total_hits)
            
            print(epKey, " count=", timeline.count)
            
        }
         
        PersistenceController.shared.save()
    }
    
    func fetchOrCreateAPI_Account(_ account_id:String, context:NSManagedObjectContext ) -> API_Account {
        let fetchRequest: NSFetchRequest<API_Account>
        fetchRequest = API_Account.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "account_id LIKE %@", account_id)
        do {
            let api_accounts = try viewContext.fetch(fetchRequest)
            if api_accounts.count > 0 { // should only be one
                print("FOUND ACCOUNT", account_id)
                return api_accounts.first!
            }
        }
        catch {
            print("catch api_accounts fetch error")
        }
        // return new object
        print("persist account", account_id, Date.now)
        let accountObject = API_Account(context: viewContext)
        accountObject.account_id = String(account_id)
        return accountObject
    }
    
    func fetchOrCreateAPI_Timeline(_ endpoint:String, context:NSManagedObjectContext ) -> API_Timeline {
        let fetchRequest: NSFetchRequest<API_Timeline>
        fetchRequest = API_Timeline.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "endpoint LIKE %@", endpoint)
        do {
            let api_timelines = try viewContext.fetch(fetchRequest)
            if api_timelines.count > 0 { // should only be one
                print("FOUND Timeline", endpoint, api_timelines.count)
                return api_timelines.first!
            }
        }
        catch {
            print("catch api_accounts fetch error")
        }
        // return new object
        let timelineObject = API_Timeline(context: viewContext)
        timelineObject.endpoint = String(endpoint)
        timelineObject.total_hits = 0
        timelineObject.totalCount = 0
        return timelineObject
    }
    
    func remove_API_Objects() {
        
        UserDefaults.standard.set(false, forKey: "is_data_loaded")
        UserDefaults.standard.synchronize()
        print("removeAllObjects")
        // Create Fetch Request for Batch Delete
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "API_Summary")
        // Create Batch Delete Request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try viewContext.execute(batchDeleteRequest)
        } catch {
            print("Delete Error")
        }
        
        let fetchRequest2 = NSFetchRequest<NSFetchRequestResult>(entityName: "API_Interval")
        // Create Batch Delete Request
        let batchDeleteRequest2 = NSBatchDeleteRequest(fetchRequest: fetchRequest2)
        do {
            try viewContext.execute(batchDeleteRequest2)
        } catch {
            print("Delete Error 2")
        }
        
        let fetchRequest3 = NSFetchRequest<NSFetchRequestResult>(entityName: "API_Timeline")
        // Create Batch Delete Request
        let batchDeleteRequest3 = NSBatchDeleteRequest(fetchRequest: fetchRequest3)
        do {
            try viewContext.execute(batchDeleteRequest3)
        } catch {
            print("Delete Error 3")
        }
        
        let fetchRequest4 = NSFetchRequest<NSFetchRequestResult>(entityName: "API_Account")
        let batchDeleteRequest4 = NSBatchDeleteRequest(fetchRequest: fetchRequest4)
        do {
            try viewContext.execute(batchDeleteRequest4)
        } catch {
            print("Delete Error 4")
        }
        
        let fetchRequest5 = NSFetchRequest<NSFetchRequestResult>(entityName: "API_File_MetaData")
        let batchDeleteRequest5 = NSBatchDeleteRequest(fetchRequest: fetchRequest5)
        do {
            try viewContext.execute(batchDeleteRequest5)
        } catch {
            print("Delete Error 5")
        }
        
        do {
            try viewContext.save()
        } catch {
            print( "managedObjectContext.save() failed!")
        }
    }
    

    private func load_full_interval_folder () {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        if panel.runModal() == .OK {
            DispatchQueue.main.async {
                Task {
                    do {
                        print("folderpath=", panel.url )
                        //let data = try Data(contentsOf: panel.url!)
                        //let account_summary = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as! [[String:Any]]
                        //process_account_json(account_summary:account_summary)
                    }
                    catch {
                        print("load failed")
                    }
                }
            }
        }
    }
    
    private func load_account_summary_data_file () {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            DispatchQueue.main.async {
                Task {
                    do {
                        let data = try Data(contentsOf: panel.url!)
                        let account_summary = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as! [[String:Any]]
                        process_account_json(account_summary:account_summary)
                    }
                    catch {
                        print("load failed")
                    }
                }
            }
        }
    }

    private func process_account_json (account_summary:[[String:Any]]) {
        print("account_summary:", account_summary[0])
        let account_name = "account_name"
        for account_interval in account_summary {
            
            let summaryObject = API_Interval(context: viewContext)
            
            let total_apis = account_interval["total_apis"] as? Int64 ?? 0
            summaryObject.total_apis = total_apis
            
            let account_sfdc = account_interval["account_sfdc"] as? String ?? ""
            summaryObject.account_sfdc = account_sfdc
            
            let dateFormatter = ISO8601DateFormatter()
            
            let iso_start = account_interval["start_time"] as? String ?? ""
            guard let start_time = dateFormatter.date(from:iso_start) else {
                print("No Start Time:")
                print("summary=", account_interval)
                continue
            }
            
            summaryObject.start_time = start_time
            
            let iso_end = account_interval["end_time"] as? String ?? ""
            let end_time = dateFormatter.date(from:iso_end)!
            summaryObject.end_time = end_time
            
            let sliceInterval = end_time.timeIntervalSince(start_time)
            
            let account_name = account_interval["account_name"] as? String ?? ""
            summaryObject.account_name = account_name
            //accountObject.account_name = account_name
           
            let account_id = account_interval["account_id"] as! Int64
            let id_string = String(account_id)
            summaryObject.account_id = id_string
            
            let account_uuid = account_interval["account_uuid"] as? String ?? ""
            summaryObject.account_uuid = account_uuid
             
            // add to accopunt object
            //accountObject.addToIntervals(summaryObject)
            
            let endpoints = account_interval["endpoint_summary"] as?[String:Any] ?? [:]
            let keys = endpoints.keys
            for key in keys {
                
                let endpointSummary = API_Summary(context: viewContext)
                let endpoint = key as? String ?? "not a string"
                endpointSummary.endpoint = endpoint
                endpointSummary.account = account_name
                
                let epData = endpoints[key] as? [String:Any] ?? [:]
                
                let count = epData["count"] as? Int64 ?? 0
                endpointSummary.count = count
                
                let max_payload_size = epData["max_payload_size"] as? Double ?? 0.0
                endpointSummary.max_payload_size = max_payload_size
                
                let avg_payload_size = epData["avg_payload_size"] as? Double ?? 0.0
                endpointSummary.avg_payload_size = avg_payload_size
                
                endpointSummary.startDate = start_time
                endpointSummary.endDate = end_time
                
                // add to summary
                //endpointSummary.interval = summaryObject
                summaryObject.addToEndpoint_summary(endpointSummary)
                
                // add to endpoint timeline
                //var timeline = endpointTimelines[endpoint] as? [API_Summary] ?? [API_Summary]()
                //timeline.append(endpointSummary)
                //endpointTimelines[endpoint] = timeline
            }
        }
    }
}

// prints filemanager data
private func infoAbout(url: URL) -> String {
    let fileManager = FileManager.default
    do {
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        var report: [String] = ["\(url.path)", ""]
        for (key, value) in attributes {
          // ignore NSFileExtendedAttributes as it is a messy dictionary
          if key.rawValue == "NSFileExtendedAttributes" { continue }
          report.append("\(key.rawValue):\t \(value)")
        }
        return report.joined(separator: "\n")
    } catch {
        return "No information available for \(url.path)"
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
