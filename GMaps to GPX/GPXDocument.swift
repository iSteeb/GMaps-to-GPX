//
//  GPXDocument.swift
//  GMaps to GPX
//
//  Created by Steven Duzevich on 11/4/2023.
//

import SwiftUI
import Foundation
import UniformTypeIdentifiers

struct GPXDocument: FileDocument {
    static var readableContentTypes = [UTType(filenameExtension: "gpx")!]

    var text = ""

    init(initialText: String = "") {
        text = initialText
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}
