//
//  API_Timeline+CoreDataProperties.swift
//  EngineX
//
//  Created by Fry an Egg on 9/19/22.
//
//

import Foundation
import CoreData


extension API_Timeline {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<API_Timeline> {
        return NSFetchRequest<API_Timeline>(entityName: "API_Timeline")
    }

    @NSManaged public var endpoint: String?
    @NSManaged public var firstDate: Date?
    @NSManaged public var lastDate: Date?
    @NSManaged public var total_hits: Int32
    @NSManaged public var totalCount: Int64
    @NSManaged public var summaries: NSSet?

}

// MARK: Generated accessors for summaries
extension API_Timeline {

    @objc(addSummariesObject:)
    @NSManaged public func addToSummaries(_ value: API_Summary)

    @objc(removeSummariesObject:)
    @NSManaged public func removeFromSummaries(_ value: API_Summary)

    @objc(addSummaries:)
    @NSManaged public func addToSummaries(_ values: NSSet)

    @objc(removeSummaries:)
    @NSManaged public func removeFromSummaries(_ values: NSSet)

}

extension API_Timeline : Identifiable {

}
