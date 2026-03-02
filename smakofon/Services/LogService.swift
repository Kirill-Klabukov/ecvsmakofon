//
//  LogService.swift
//  smakofon
//
//  CRUD operations on plate-log records persisted in CoreData.
//  Converts between NSManagedObject and PlateLogEntry value types.
//

import Foundation
import CoreData

final class LogService {

    private let stack: CoreDataStack

    init(coreDataStack: CoreDataStack = .shared) {
        self.stack = coreDataStack
    }

    // MARK: - Create

    func savePlate(
        number: String,
        confidence: Double,
        latitude: Double,
        longitude: Double
    ) {
        let context = stack.viewContext
        guard let entity = NSEntityDescription.entity(
            forEntityName: "PlateLogEntity", in: context
        ) else { return }

        let object = NSManagedObject(entity: entity, insertInto: context)
        object.setValue(UUID(),    forKey: "id")
        object.setValue(number,    forKey: "plateNumber")
        object.setValue(Date(),    forKey: "timestamp")
        object.setValue(latitude,  forKey: "latitude")
        object.setValue(longitude, forKey: "longitude")
        object.setValue(confidence,forKey: "confidence")

        do {
            try context.save()
        } catch {
            print("[LogService] save failed: \(error)")
        }
    }

    // MARK: - Read

    func fetchAllPlates() -> [PlateLogEntry] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "PlateLogEntity")
        request.sortDescriptors = [
            NSSortDescriptor(key: "timestamp", ascending: false)
        ]

        do {
            let results = try stack.viewContext.fetch(request)
            return results.compactMap(Self.mapToEntry)
        } catch {
            print("[LogService] fetch failed: \(error)")
            return []
        }
    }

    // MARK: - Delete

    func deletePlate(id: UUID) {
        let context = stack.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "PlateLogEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            if let object = try context.fetch(request).first {
                context.delete(object)
                try context.save()
            }
        } catch {
            print("[LogService] delete failed: \(error)")
        }
    }

    func deleteAllPlates() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "PlateLogEntity")
        let batchDelete = NSBatchDeleteRequest(fetchRequest: request)
        batchDelete.resultType = .resultTypeObjectIDs

        do {
            let result = try stack.viewContext.execute(batchDelete) as? NSBatchDeleteResult
            if let ids = result?.result as? [NSManagedObjectID] {
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: [NSDeletedObjectsKey: ids],
                    into: [stack.viewContext]
                )
            }
        } catch {
            print("[LogService] deleteAll failed: \(error)")
        }
    }

    // MARK: - Export

    func exportCSV() -> URL? {
        let entries = fetchAllPlates()
        guard !entries.isEmpty else { return nil }

        let iso = ISO8601DateFormatter()
        var csv = "Plate Number,Timestamp,Latitude,Longitude,Confidence\n"

        for e in entries {
            csv += "\(e.plateNumber),"
            csv += "\(iso.string(from: e.timestamp)),"
            csv += "\(e.latitude),"
            csv += "\(e.longitude),"
            csv += String(format: "%.2f", e.confidence)
            csv += "\n"
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("smakofon_plates_export.csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("[LogService] CSV export failed: \(error)")
            return nil
        }
    }

    // MARK: - Mapping

    private static func mapToEntry(_ object: NSManagedObject) -> PlateLogEntry? {
        guard let id          = object.value(forKey: "id")          as? UUID,
              let plateNumber = object.value(forKey: "plateNumber") as? String,
              let timestamp   = object.value(forKey: "timestamp")   as? Date
        else { return nil }

        return PlateLogEntry(
            id: id,
            plateNumber: plateNumber,
            timestamp: timestamp,
            latitude:   object.value(forKey: "latitude")   as? Double ?? 0,
            longitude:  object.value(forKey: "longitude")  as? Double ?? 0,
            confidence: object.value(forKey: "confidence")  as? Double ?? 0
        )
    }
}
