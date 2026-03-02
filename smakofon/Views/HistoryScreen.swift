//
//  HistoryScreen.swift
//  smakofon
//
//  Vehicle Journal – list of all logged plates with export & delete.
//

import SwiftUI

struct HistoryScreen: View {

    @State private var viewModel = HistoryViewModel()
    @State private var showExport = false
    @State private var showDeleteAll = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.entries.isEmpty {
                    ContentUnavailableView(
                        "No Plates Logged",
                        systemImage: "car.side.fill",
                        description: Text("Detected license plates will appear here.")
                    )
                } else {
                    plateList
                }
            }
            .navigationTitle("Vehicle Journal")
            .toolbar { toolbarItems }
            .sheet(isPresented: $showExport) {
                if let url = viewModel.csvURL {
                    ActivitySheet(items: [url])
                        .presentationDetents([.medium])
                }
            }
            .confirmationDialog(
                "Delete All Entries?",
                isPresented: $showDeleteAll,
                titleVisibility: .visible
            ) {
                Button("Delete All", role: .destructive) {
                    withAnimation { viewModel.deleteAll() }
                }
            } message: {
                Text("This action cannot be undone.")
            }
            .onAppear { viewModel.fetchEntries() }
        }
    }

    // MARK: - List

    private var plateList: some View {
        List {
            ForEach(viewModel.entries) { entry in
                PlateLogRow(entry: entry)
            }
            .onDelete { offsets in
                withAnimation { viewModel.deleteEntries(at: offsets) }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    viewModel.exportCSV()
                    showExport = true
                } label: {
                    Label("Export CSV", systemImage: "square.and.arrow.up")
                }

                Button(role: .destructive) {
                    showDeleteAll = true
                } label: {
                    Label("Delete All", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .disabled(viewModel.entries.isEmpty)
        }
    }
}

// MARK: - Row

struct PlateLogRow: View {
    let entry: PlateLogEntry

    var body: some View {
        HStack(spacing: 14) {
            Text(entry.plateNumber)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.formattedDate)
                    .font(.subheadline)

                HStack(spacing: 10) {
                    if entry.coordinate != nil {
                        Label(
                            String(format: "%.4f, %.4f", entry.latitude, entry.longitude),
                            systemImage: "location.fill"
                        )
                    }
                    Label(
                        String(format: "%.0f%%", entry.confidence * 100),
                        systemImage: "checkmark.seal.fill"
                    )
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - UIActivityViewController wrapper

struct ActivitySheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}
