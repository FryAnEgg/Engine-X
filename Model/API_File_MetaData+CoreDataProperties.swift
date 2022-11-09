//
//  API_File_MetaData+CoreDataProperties.swift
//  EngineX
//
//  Created by Fry an Egg on 9/19/22.
//
//

import Foundation
import CoreData


extension API_File_MetaData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<API_File_MetaData> {
        return NSFetchRequest<API_File_MetaData>(entityName: "API_File_MetaData")
    }

    @NSManaged public var start_time: Date?
    @NSManaged public var end_time: Date?
    @NSManaged public var interval: Int64
    @NSManaged public var link: String?
    @NSManaged public var comment: String?

}

extension API_File_MetaData : Identifiable {

}
