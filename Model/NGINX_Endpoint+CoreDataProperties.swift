//
//  NGINX_Endpoint+CoreDataProperties.swift
//  EngineX
//
//  Created by Dave Lathrop on 8/20/22.
//
//

import Foundation
import CoreData


extension NGINX_Endpoint {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NGINX_Endpoint> {
        return NSFetchRequest<NGINX_Endpoint>(entityName: "NGINX_Endpoint")
    }

    @NSManaged public var display_name: String?
    @NSManaged public var requestType: String?
    @NSManaged public var path: String?

}

extension NGINX_Endpoint : Identifiable {

}
