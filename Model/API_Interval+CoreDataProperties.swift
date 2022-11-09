//
//  API_Interval+CoreDataProperties.swift
//  EngineX
//
//  Created by Fry an Egg on 9/19/22.
//
//

import Foundation
import CoreData


extension API_Interval {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<API_Interval> {
        return NSFetchRequest<API_Interval>(entityName: "API_Interval")
    }

    @NSManaged public var account_id: String?
    @NSManaged public var account_name: String?
    @NSManaged public var account_sfdc: String?
    @NSManaged public var account_uuid: String?
    @NSManaged public var end_time: Date?
    @NSManaged public var start_time: Date?
    @NSManaged public var total_apis: Int64
    @NSManaged public var endpoint_summary: NSSet?

}

// MARK: Generated accessors for endpoint_summary
extension API_Interval {

    @objc(addEndpoint_summaryObject:)
    @NSManaged public func addToEndpoint_summary(_ value: API_Summary)

    @objc(removeEndpoint_summaryObject:)
    @NSManaged public func removeFromEndpoint_summary(_ value: API_Summary)

    @objc(addEndpoint_summary:)
    @NSManaged public func addToEndpoint_summary(_ values: NSSet)

    @objc(removeEndpoint_summary:)
    @NSManaged public func removeFromEndpoint_summary(_ values: NSSet)

}

extension API_Interval : Identifiable {

}
