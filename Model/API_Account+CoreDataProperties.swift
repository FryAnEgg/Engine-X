//
//  API_Account+CoreDataProperties.swift
//  EngineX
//
//  Created by Fry an Egg on 9/19/22.
//
//

import Foundation
import CoreData


extension API_Account {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<API_Account> {
        return NSFetchRequest<API_Account>(entityName: "API_Account")
    }

    @NSManaged public var account_id: String?
    @NSManaged public var account_name: String?
    @NSManaged public var intervals: NSSet?

}

// MARK: Generated accessors for intervals
extension API_Account {

    @objc(addIntervalsObject:)
    @NSManaged public func addToIntervals(_ value: API_Interval)

    @objc(removeIntervalsObject:)
    @NSManaged public func removeFromIntervals(_ value: API_Interval)

    @objc(addIntervals:)
    @NSManaged public func addToIntervals(_ values: NSSet)

    @objc(removeIntervals:)
    @NSManaged public func removeFromIntervals(_ values: NSSet)

}

extension API_Account : Identifiable {

}
