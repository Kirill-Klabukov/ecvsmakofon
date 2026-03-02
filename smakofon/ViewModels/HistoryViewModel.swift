//
//  HistoryViewModel.swift
//  smakofon
//
//  Drives the Vehicle Journal screen – CRUD + CSV export.
//

import SwiftUI
import Observation

@Observable
final class HistoryViewModel {

    var entries: [PlateLogEntry] = []
    var csvURL: URL?

    @ObservationIgnored private let logService: LogService

    init(logService: LogService = LogService()) {
        self.logService = logService
    }

    // MARK: - Public

    func fetchEntries() {
        entries = logService.fetchAllPlates()
    }

    func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            logService.deletePlate(id: entries[index].id)
        }
        entries.remove(atOffsets: offsets)
    }

    func deleteAll() {
        logService.deleteAllPlates()
        entries.removeAll()
    }

    func exportCSV() {
        csvURL = logService.exportCSV()
    }
}
