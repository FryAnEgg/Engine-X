//
//  NGINX_IP_Address+CoreDataProperties.swift
//  EngineX
//
//  Created by Dave Lathrop on 8/22/22.
//
//

import Foundation
import CoreData


extension NGINX_IP_Address {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NGINX_IP_Address> {
        return NSFetchRequest<NGINX_IP_Address>(entityName: "NGINX_IP_Address")
    }

    @NSManaged public var address: String?

}

extension NGINX_IP_Address : Identifiable {

}
