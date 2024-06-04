//
//  MyNotesApp.swift
//  MyNotes
//
//  Created by Terence  Ndabereye  on 05/06/2024.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@main
struct MyNotesApp: App {
    var body: some Scene {
        DocumentGroup(editing: .itemDocument, migrationPlan: MyNotesMigrationPlan.self) {
            ContentView()
        }
    }
}

extension UTType {
    static var itemDocument: UTType {
        UTType(importedAs: "com.example.item-document")
    }
}

struct MyNotesMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] = [
        MyNotesVersionedSchema.self,
    ]

    static var stages: [MigrationStage] = [
        // Stages of migration between VersionedSchema, if required.
    ]
}

struct MyNotesVersionedSchema: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] = [
        Item.self,
    ]
}
