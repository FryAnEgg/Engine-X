//
//  NGINX_WebServer+CoreDataProperties.swift
//  EngineX
//
//  Created by Dave Lathrop on 8/5/22.
//
//

import Foundation
import CoreData


extension NGINX_WebServer {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NGINX_WebServer> {
        return NSFetchRequest<NGINX_WebServer>(entityName: "NGINX_WebServer")
    }

    @NSManaged public var name: String?

}

extension NGINX_WebServer : Identifiable {

}
