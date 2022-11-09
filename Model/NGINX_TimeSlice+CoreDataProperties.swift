//
//  NGINX_TimeSlice+CoreDataProperties.swift
//  EngineX
//
//  Created by Dave Lathrop on 8/2/22.
//
//

import Foundation
import CoreData


extension NGINX_TimeSlice {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NGINX_TimeSlice> {
        return NSFetchRequest<NGINX_TimeSlice>(entityName: "NGINX_TimeSlice")
    }

    @NSManaged public var date: Date?
    @NSManaged public var interval: Int64
    @NSManaged public var webServer: String?
    @NSManaged public var count: Int64
    @NSManaged public var error_count: Int64
    @NSManaged public var success_count: Int64
    @NSManaged public var rt_total: Double
    @NSManaged public var uct_total: Double
    @NSManaged public var uht_total: Double
    @NSManaged public var urt_total: Double
    @NSManaged public var endpoints: NSSet?
    @NSManaged public var ip_addresses: NSSet?
    @NSManaged public var servers: NSSet?

}

// MARK: Generated accessors for endpoints
extension NGINX_TimeSlice {

    @objc(addEndpointsObject:)
    @NSManaged public func addToEndpoints(_ value: NGINX_Point)

    @objc(removeEndpointsObject:)
    @NSManaged public func removeFromEndpoints(_ value: NGINX_Point)

    @objc(addEndpoints:)
    @NSManaged public func addToEndpoints(_ values: NSSet)

    @objc(removeEndpoints:)
    @NSManaged public func removeFromEndpoints(_ values: NSSet)

}

// MARK: Generated accessors for ip_addresses
extension NGINX_TimeSlice {

    @objc(addIp_addressesObject:)
    @NSManaged public func addToIp_addresses(_ value: NGINX_Point)

    @objc(removeIp_addressesObject:)
    @NSManaged public func removeFromIp_addresses(_ value: NGINX_Point)

    @objc(addIp_addresses:)
    @NSManaged public func addToIp_addresses(_ values: NSSet)

    @objc(removeIp_addresses:)
    @NSManaged public func removeFromIp_addresses(_ values: NSSet)

}

// MARK: Generated accessors for servers
extension NGINX_TimeSlice {

    @objc(addServersObject:)
    @NSManaged public func addToServers(_ value: NGINX_Point)

    @objc(removeServersObject:)
    @NSManaged public func removeFromServers(_ value: NGINX_Point)

    @objc(addServers:)
    @NSManaged public func addToServers(_ values: NSSet)

    @objc(removeServers:)
    @NSManaged public func removeFromServers(_ values: NSSet)

}

extension NGINX_TimeSlice : Identifiable {

}
