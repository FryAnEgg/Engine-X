//
//  NGINX_Parser.swift
//  EngineX
//
//  Created by Dave Lathrop on 8/8/22.
//

import Foundation
import CoreData



class NGINX_Parser {
    let string : String
    var index : String.Index
    var slices = [Date:Any]()
    
    var rtValue = Double(0.0)
    var uhtValue = Double(0.0)
    var uctValue = Double(0.0)
    var urtValue = Double(0.0)
    var httpCode = Int(0)
    
    init(string: String) {
        self.string = string
        self.index = string.startIndex
    }
    
    func parseAll (_ managedObjectContext:NSManagedObjectContext, url:URL) {
        
        let filename = url.lastPathComponent
        let ws_url = url.deletingLastPathComponent()
        let ws = ws_url.lastPathComponent
        print("ws", ws,"filename", filename)
        let startParse =  Date()
        print("start", startParse)
        
        // check for NGINX_WebServer
        let webServer = fetchWebServer(ws, context:managedObjectContext )
        
        var itemCount = 0
        while let id = self.nextRecord() {
            itemCount += 1
            if itemCount%5000 == 0 {
                print("****************************", itemCount)
            }
            parseRecord(id, log:itemCount%5000 == 0)
        }
        print ("done", itemCount)
        
        var endpointAccounting = [String]()
        var ipaAccounting = [String]()
        var serverAccounting = [String]()
        
        // check out result
        for key in slices.keys.sorted(by: <) {
            
            // first check if this timeslice is in db
            // find NGINX_TimeSlice with key date
            let timeSlice = NGINX_TimeSlice(context: managedObjectContext)
            
            let slice = slices[key] as? [String:Any] ?? [String:Any]()
            
            timeSlice.count = slice["count"] as? Int64 ?? Int64(0)
            timeSlice.success_count = slice["count_200"] as? Int64 ?? Int64(0)
            timeSlice.error_count = slice["count_err"] as? Int64 ?? Int64(0)
            timeSlice.rt_total = slice["rt_total"] as? Double ?? 0.0
            timeSlice.uht_total = slice["uht_total"] as? Double ?? 0.0
            timeSlice.uct_total = slice["uct_total"] as? Double ?? 0.0
            timeSlice.urt_total = slice["urt_total"] as? Double ?? 0.0
            timeSlice.date = key
            timeSlice.webServer = ws
            print("create timeslice object", key)
            
            let eps = slice["endpoints"] as? [String:Any] ?? [String:Any]()
            let epKeys = eps.keys
            for epKey in epKeys {
                // find existing ep or create
                let ep = eps[epKey] as? [String:Any] ?? [String:Any]()
                let epo = NGINX_Point(context: managedObjectContext)
                if !endpointAccounting.contains(epKey) {
                    endpointAccounting.append(epKey)
                }
                epo.name_tag = epKey
                epo.count = ep["count"] as? Int64 ?? Int64(0)
                epo.rt_total = ep["rt_total"] as? Double ?? 0.0
                epo.uct_total = ep["uct_total"] as? Double ?? 0.0
                epo.uht_total = ep["uht_total"] as? Double ?? 0.0
                epo.urt_total = ep["urt_total"] as? Double ?? 0.0
                epo.success_count = ep["count_200"] as? Int64 ?? 0
                epo.error_count = ep["count_err"] as? Int64 ?? 0
                timeSlice.addToEndpoints(epo)
            }
            
            let ipas = slice["ip_addresses"] as? [String:Any] ?? [String:Any]()
            let ipaKeys = ipas.keys
            for ipaKey in ipaKeys {
                let ipa = ipas[ipaKey] as? [String:Any] ?? [String:Any]()
                let ipao = NGINX_Point(context: managedObjectContext)
                if !ipaAccounting.contains(ipaKey) {
                    ipaAccounting.append(ipaKey)
                }
                ipao.name_tag = ipaKey
                ipao.count = ipa["count"] as? Int64 ?? Int64(0)
                ipao.rt_total = ipa["rt_total"] as? Double ?? 0.0
                ipao.uct_total = ipa["uct_total"] as? Double ?? 0.0
                ipao.uht_total = ipa["uht_total"] as? Double ?? 0.0
                ipao.urt_total = ipa["urt_total"] as? Double ?? 0.0
                ipao.success_count = ipa["count_200"] as? Int64 ?? Int64(0)
                ipao.error_count = ipa["count_err"] as? Int64 ?? Int64(0)
                timeSlice.addToIp_addresses(ipao)
            }
            
            let servers = slice["servers"] as? [String:Any] ?? [String:Any]()
            let serverKeys = servers.keys
            for serverKey in serverKeys {
                let server = servers[serverKey] as? [String:Any] ?? [String:Any]()
                let servero = NGINX_Point(context: managedObjectContext)
                if !serverAccounting.contains(serverKey) {
                    serverAccounting.append(serverKey)
                }
                servero.name_tag = serverKey
                servero.count = server["count"] as? Int64 ?? Int64(0)
                servero.rt_total = server["rt_total"] as? Double ?? 0.0
                servero.uct_total = server["uct_total"] as? Double ?? 0.0
                servero.uht_total = server["uht_total"] as? Double ?? 0.0
                servero.urt_total = server["urt_total"] as? Double ?? 0.0
                servero.success_count = server["count_200"] as? Int64 ?? Int64(0)
                servero.error_count = server["count_err"] as? Int64 ?? Int64(0)
                timeSlice.addToServers(servero)
            }
            
            //print("key", key, count, String(format: "%.2f", rt_avg), String(format: "%.2f", uht_avg), String(format: "%.2f", uct_avg), String(format: "%.2f", urt_avg))
            print("eps", eps.keys.count, "ipas", ipas.keys.count, "serv", servers.keys.count)
            print(eps.keys)
        }
        
        for endpoint in endpointAccounting {
            let ngxEP = fetchOrCreateEndpoint(endpoint, context:managedObjectContext)
        }
        for ipa in ipaAccounting {
            let ngxIPA = fetchOrCreateIPAddress(ipa, context: managedObjectContext)
        }
        for server in serverAccounting {
            let ngxServer = fetchOrCreateServer(server, context: managedObjectContext)
        }
        
        do {
            try managedObjectContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        print("saved to PC")
    }
    
    func nextRecord() -> Substring? {
        if self.index == self.string.endIndex {
            return nil
        }
        //  || $0 == " "
        let endIndex = self.string[self.index...].firstIndex(where: { $0 == "\n"}) ?? self.string.endIndex
        let returnValue = self.string[self.index..<endIndex]
        
        self.index = self.string[endIndex...].firstIndex(where: { $0 != "\n" && $0 != " " }) ?? self.string.endIndex
        
        return returnValue
    }
    
    func parseRecord(_ string:Substring, log:Bool) {
        
        var ss_index = string.startIndex
        var endIndex = string[ss_index...].firstIndex(where: { $0 == " "}) ?? self.string.endIndex
        let ipaddress = string[ss_index..<endIndex]
        
        ss_index = string.index(endIndex, offsetBy: 6)
        endIndex = string[ss_index...].firstIndex(where: { $0 == "]"}) ?? self.string.endIndex
        let dateString = string[ss_index..<endIndex]
        
        ss_index = string.index(endIndex, offsetBy: 3)
        endIndex = string[ss_index...].firstIndex(where: { $0 == " "}) ?? self.string.endIndex
        let requestType = string[ss_index..<endIndex]
        
        ss_index = string.index(endIndex, offsetBy: 1)
        endIndex = string[ss_index...].firstIndex(where: { $0 == " "}) ?? self.string.endIndex
        var endpoint = string[ss_index..<endIndex]
        
        let url_components = endpoint.components(separatedBy: "/")
        if url_components[0] == "" {
            if url_components.count >= 4 {
                if url_components[1] == "api" && url_components[2] == "v4" {
                    endpoint = requestType + " api/v4/" + url_components[3].components(separatedBy: "?")[0]
                }
                else {
                    if url_components.count >= 3 {
                        endpoint = requestType + " " + url_components[1] + "/" + url_components[2].components(separatedBy: "?")[0]
                    }
                    else {
                        let fepComonents = url_components[0].components(separatedBy: "?")
                        endpoint = requestType + " ?" + fepComonents[0]
                    }
                }
            } else {
                endpoint = requestType + " " + url_components[1].components(separatedBy: "?")[0]
            }
        }
        else {
            endpoint = "** NO SLASH **"
        }
        
        ss_index = string.index(endIndex, offsetBy: 1)
        endIndex = string[ss_index...].firstIndex(where: { $0 == "\""}) ?? self.string.endIndex
        let httpVersion = string[ss_index..<endIndex]
        
        ss_index = string.index(endIndex, offsetBy: 2)
        endIndex = string[ss_index...].firstIndex(where: { $0 == " "}) ?? self.string.endIndex
        let httpCodeString = string[ss_index..<endIndex] ?? "0"
        httpCode = Int(httpCodeString) ?? 0
        
        ss_index = string.index(endIndex, offsetBy: 1)
        endIndex = string[ss_index...].firstIndex(where: { $0 == " "}) ?? self.string.endIndex
        let subCode = string[ss_index..<endIndex]
        
        var serverName = ""
        let minusTagRange = string.range(of:"\"-\"")
        if minusTagRange != nil {
            ss_index = string.index(endIndex, offsetBy: 6)
            endIndex = string[ss_index...].firstIndex(where: { $0 == "\""}) ?? self.string.endIndex
            serverName = String(string[ss_index..<endIndex])
            
        } else {
            ss_index = string.index(endIndex, offsetBy: 2)
            endIndex = string[ss_index...].firstIndex(where: { $0 == "\""}) ?? self.string.endIndex
            let server = string[ss_index..<endIndex]
            if log {
                print ("server2", server)
            }
        }
        
        let rtRange = string.range(of: " rt=\"")! as Range
        let rtIndex = string.index(rtRange.lowerBound, offsetBy: 5)
        ss_index = string.index(rtRange.lowerBound, offsetBy: 4)
        //ss_index = string.index(endIndex, offsetBy: 6)
        endIndex = string[rtIndex...].firstIndex(where: { $0 == "\""}) ?? self.string.endIndex
        let rt = string[rtIndex..<endIndex]
        rtValue = Double(rt) ?? 0.00
        
        ss_index = string.index(endIndex, offsetBy: 7)
        endIndex = string[ss_index...].firstIndex(where: { $0 == "\""}) ?? self.string.endIndex
        let uct = string[ss_index..<endIndex]
        uctValue = Double(uct) ?? 0.00
        
        ss_index = string.index(endIndex, offsetBy: 7)
        endIndex = string[ss_index...].firstIndex(where: { $0 == "\""}) ?? self.string.endIndex
        let uht = string[ss_index..<endIndex]
        uhtValue = Double(uht) ?? 0.00
        
        ss_index = string.index(endIndex, offsetBy: 7)
        endIndex = string[ss_index...].firstIndex(where: { $0 == "\""}) ?? self.string.endIndex
        let urt = string[ss_index..<endIndex]
        urtValue = Double(urt) ?? 0.00
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d/MMM/yyyy:hh:mm:ss Z"
        guard let date = dateFormatter.date(from: String(dateString)) else {
            print("bad date", dateString)
            print("++++++++++++")
            print(string)
            print("++++++++++++")
            return
        }
        
        // can we get the timezone??
        // for timezone: parse out the date string for the timezone, and then set the timezone of the date
        
        let outputFormatter = DateFormatter()
        outputFormatter.timeZone = TimeZone.current
        let outString = outputFormatter.string(from: date)
        
        if log {
            print ("ipaddress", ipaddress)
            print ("dateString", dateString)
            print ("requestType", requestType)
            print ("endpoint", endpoint)
            print ("httpVersion", httpVersion)
            print ("httpCode", httpCode)
            print ("subCode", subCode)
            print ("rt", rt)
            print ("uct", uct)
            print ("uht", uht)
            print ("urt", urt)
            print ("date", date)
        }
        
        var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        // zero out min and sec
        //components.minute = 0
        components.second = 0
        
        if let round_date = Calendar.current.date(from: components) {
            var slice = slices[round_date] as? [String:Any]
            if slice == nil {
                slice = [String:Any]()
                slice?["count"] = Int64(1)
                if Int(httpCode) >= 100 && Int(httpCode) < 400 {
                    slice?["count_200"] = 1
                } else {
                    slice?["count_err"] = 1
                }
                slices[round_date] = slice
                slice?["rt"] = rtValue
                slice?["uct"] = uctValue
                slice?["uht"] = uhtValue
                slice?["urt"] = urtValue
            }
            // update slice fields
            var sliceCount = slice?["count"] as? Int64 ?? Int64(0)
            sliceCount += 1
            slice?["count"] = sliceCount
            if Int(httpCode) >= 100 && Int(httpCode) < 400 {
                var sliceCount = slice?["count_200"] as? Int ?? 0
                sliceCount += 1
                slice?["count_200"] = sliceCount
            } else {
                var sliceCount = slice?["count_err"] as? Int ?? 0
                sliceCount += 1
                slice?["count_err"] = sliceCount
            }
            let rt_total = slice?["rt_total"] as? Double ?? 0.00
            slice?["rt_total"] = rtValue + rt_total
            let uct_total = slice?["uct_total"] as? Double ?? 0.00
            slice?["uct_total"] = uctValue + uct_total
            let uht_total = slice?["uht_total"] as? Double ?? 0.00
            slice?["uht_total"] = uhtValue + uht_total
            let urt_total = slice?["urt_total"] as? Double ?? 0.00
            slice?["urt_total"] = urtValue + urt_total
            
            // endpoints
            var eps = slice!["endpoints"] as? [String:Any] ?? [String:Any]()
            
            if let ep = eps[String(endpoint)] as? [String:Any] {
                let newEP = updateNodeDirectory(ep)
                eps[String(endpoint)] = newEP
            }
            else { // new ep
                var ep = [String:Any]()
                ep["count"] = Int64(1)
                if Int(httpCode) >= 100 && Int(httpCode) < 400 {
                    ep["count_200"] = 1
                } else {
                    ep["count_err"] = 1
                }
                ep["rt"] = rtValue
                ep["uct"] = uctValue
                ep["uht"] = uhtValue
                ep["urt"] = urtValue
                eps[String(endpoint)] = ep
            }
            
            // ip_address
            var ipas = slice!["ip_addresses"] as? [String:Any] ?? [String:Any]()
            if var ipa = ipas[String(ipaddress)] as? [String:Any] {
                let newIPA = updateNodeDirectory(ipa)
                ipas[String(ipaddress)] = newIPA
            }
            else { // new ipa
                var ipa = [String:Any]()
                ipa["count"] = Int64(1)
                if Int(httpCode) >= 100 && Int(httpCode) < 400 {
                    ipa["count_200"] = 1
                } else {
                    ipa["count_err"] = 1
                }
                ipa["rt"] = rtValue
                ipa["uct"] = uctValue
                ipa["uht"] = uhtValue
                ipa["urt"] = urtValue
                ipas[String(ipaddress)] = ipa
            }
            
            // server
            var servers = slice!["servers"] as? [String:Any] ?? [String:Any]()
            if var server = servers[String(serverName)] as? [String:Any] {
                let newServer = updateNodeDirectory(server)
                servers[String(serverName)] = newServer
            }
            else { // new ipa
                var server = [String:Any]()
                server["count"] = Int64(1)
                if Int(httpCode) >= 100 && Int(httpCode) < 400 {
                    server["count_200"] = 1
                } else {
                    server["count_err"] = 1
                }
                server["rt"] = rtValue
                server["uct"] = uctValue
                server["uht"] = uhtValue
                server["urt"] = urtValue
                servers[String(serverName)] = server
            }
            
            slice!["endpoints"] = eps
            slice!["ip_addresses"] = ipas
            slice!["servers"] = servers
            
            slices[round_date] = slice
        }
    }
    
    func updateNodeDirectory(_ node:[String:Any]) -> [String:Any] {
        
        var newNode = [String:Any]()
        
        var nodeCount = node["count"] as? Int64 ?? Int64(0)
        nodeCount += 1
        newNode["count"] = nodeCount
        if Int(httpCode) >= 100 && Int(httpCode) < 400 {
            nodeCount = node["count_200"] as? Int64 ?? Int64(0)
            nodeCount += 1
            newNode["count_200"] = nodeCount
        } else {
            nodeCount = node["count_err"] as? Int64 ?? Int64(0)
            nodeCount += 1
            newNode["count_err"] = nodeCount
        }
        let rt_total = node["rt_total"] as? Double ?? 0.00
        newNode["rt_total"] = rtValue + rt_total
        
        let uct_total = node["uct_total"] as? Double ?? 0.00
        newNode["uct_total"] = uctValue + uct_total
        
        let uht_total = node["uht_total"] as? Double ?? 0.00
        newNode["uht_total"] = uhtValue + uht_total
        
        let urt_total = node["urt_total"] as? Double ?? 0.00
        newNode["urt_total"] = urtValue + urt_total
        
        return newNode
    }
    
    // - Fetches
    func fetchOrCreateEndpoint(_ ep:String, context:NSManagedObjectContext ) -> NGINX_Endpoint {
        let fetchRequest: NSFetchRequest<NGINX_Endpoint>
        fetchRequest = NGINX_Endpoint.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "path LIKE %@", ep)
        do {
            let endpointz = try context.fetch(fetchRequest)
            if endpointz.count > 0 {
                return endpointz.first!
            }
        }
        catch {
            print("catch fetch error")
        }
        let endpoint = NGINX_Endpoint(context:context)
        endpoint.path = ep
        return endpoint
    }
    
    func fetchOrCreateIPAddress(_ address:String, context:NSManagedObjectContext ) -> NGINX_IP_Address {
        let fetchRequest: NSFetchRequest<NGINX_IP_Address>
        fetchRequest = NGINX_IP_Address.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "address LIKE %@", address)
        do {
            let ipaz = try context.fetch(fetchRequest)
            if ipaz.count > 0 {
                return ipaz.first!
            }
        }
        catch {
            print("catch fetch error")
        }
        let ipa = NGINX_IP_Address(context:context)
        ipa.address = address
        return ipa
    }
    
    func fetchOrCreateServer(_ name:String, context:NSManagedObjectContext ) -> NGINX_Server {
        let fetchRequest: NSFetchRequest<NGINX_Server>
        fetchRequest = NGINX_Server.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name LIKE %@", name)
        do {
            let ipaz = try context.fetch(fetchRequest)
            if ipaz.count > 0 {
                return ipaz.first!
            }
        }
        catch {
            print("catch fetch error")
        }
        let server = NGINX_Server(context:context)
        server.name = name
        return server
    }
    
    func fetchWebServer(_ ws:String, context:NSManagedObjectContext ) -> NGINX_WebServer {
        let fetchRequest: NSFetchRequest<NGINX_WebServer>
        fetchRequest = NGINX_WebServer.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name LIKE %@", ws)
        //fetchRequest.predicate = NSPredicate(format: "name LIKE %@", ws)
        do {
            let webservers = try context.fetch(fetchRequest)
            if webservers.count > 0 {
                return webservers.first!
            }
        }
        catch {
            print("catch fetch error")
        }
        let webServer = NGINX_WebServer(context:context)
        webServer.name = ws
        print ("new webserver", ws)
        return webServer
    }
}
