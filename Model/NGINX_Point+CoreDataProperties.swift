//
//  NGINX_Point+CoreDataProperties.swift
//  EngineX
//
//  Created by Dave Lathrop on 8/22/22.
//
//

import Foundation
import CoreData


extension NGINX_Point {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NGINX_Point> {
        return NSFetchRequest<NGINX_Point>(entityName: "NGINX_Point")
    }

    @NSManaged public var count: Int64
    @NSManaged public var error_count: Int64
    @NSManaged public var rt_total: Double
    @NSManaged public var success_count: Int64
    @NSManaged public var name_tag: String?
    @NSManaged public var uct_total: Double
    @NSManaged public var uht_total: Double
    @NSManaged public var urt_total: Double

}

extension NGINX_Point : Identifiable {

}
