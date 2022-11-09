//
//  NGINX_File+CoreDataProperties.swift
//  EngineX
//
//  Created by Dave Lathrop on 8/2/22.
//
//

import Foundation
import CoreData


extension NGINX_File {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NGINX_File> {
        return NSFetchRequest<NGINX_File>(entityName: "NGINX_File")
    }

    @NSManaged public var filepath: String?
    @NSManaged public var webserver: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var total: Int64

}

extension NGINX_File : Identifiable {

}
