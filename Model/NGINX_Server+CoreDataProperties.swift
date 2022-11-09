//
//  NGINX_Server+CoreDataProperties.swift
//  EngineX
//
//  Created by Dave Lathrop on 8/22/22.
//
//

import Foundation
import CoreData


extension NGINX_Server {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NGINX_Server> {
        return NSFetchRequest<NGINX_Server>(entityName: "NGINX_Server")
    }

    @NSManaged public var name: String?

}

extension NGINX_Server : Identifiable {

}
