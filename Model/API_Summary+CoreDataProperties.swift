//
//  API_Summary+CoreDataProperties.swift
//  EngineX
//
//  Created by Fry an Egg on 10/14/22.
//
//

import Foundation
import CoreData


extension API_Summary {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<API_Summary> {
        return NSFetchRequest<API_Summary>(entityName: "API_Summary")
    }

    @NSManaged public var avg_payload_size: Double
    @NSManaged public var count: Int64
    @NSManaged public var endDate: Date?
    @NSManaged public var endpoint: String?
    @NSManaged public var max_payload_size: Double
    @NSManaged public var startDate: Date?
    @NSManaged public var account: String?

}

extension API_Summary : Identifiable {

}
