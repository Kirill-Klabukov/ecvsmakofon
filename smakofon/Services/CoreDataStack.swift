//
//  CoreDataStack.swift
//  smakofon
//
//  Programmatic CoreData stack – no .xcdatamodeld required.
//

import CoreData

final class CoreDataStack: @unchecked Sendable {

    static let shared = CoreDataStack()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    // MARK: - Init

    private init() {
        let model = Self.createModel()
        container = NSPersistentContainer(name: "Smakofon", managedObjectModel: model)
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("CoreData failed to load: \(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // MARK: - Model definition

    private static func createModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let entity = NSEntityDescription()
        entity.name = "PlateLogEntity"
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType

        let plateNumberAttr = NSAttributeDescription()
        plateNumberAttr.name = "plateNumber"
        plateNumberAttr.attributeType = .stringAttributeType

        let timestampAttr = NSAttributeDescription()
        timestampAttr.name = "timestamp"
        timestampAttr.attributeType = .dateAttributeType

        let latitudeAttr = NSAttributeDescription()
        latitudeAttr.name = "latitude"
        latitudeAttr.attributeType = .doubleAttributeType
        latitudeAttr.defaultValue = 0.0

        let longitudeAttr = NSAttributeDescription()
        longitudeAttr.name = "longitude"
        longitudeAttr.attributeType = .doubleAttributeType
        longitudeAttr.defaultValue = 0.0

        let confidenceAttr = NSAttributeDescription()
        confidenceAttr.name = "confidence"
        confidenceAttr.attributeType = .doubleAttributeType
        confidenceAttr.defaultValue = 0.0

        entity.properties = [
            idAttr, plateNumberAttr, timestampAttr,
            latitudeAttr, longitudeAttr, confidenceAttr
        ]
        model.entities = [entity]
        return model
    }
}
