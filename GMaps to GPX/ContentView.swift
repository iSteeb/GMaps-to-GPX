//
//  ContentView.swift
//  GMaps to GPX
//
//  Created by Steven Duzevich on 11/4/2023.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @State private var URL = ""
    @State var showExporter = false
    @State var document: GPXDocument = GPXDocument()
    
    var body: some View {
        VStack {
            HStack {
                TextField("URL", text: $URL)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                PasteButton(payloadType: String.self) { strings in
                    guard let first = strings.first else { return }
                    URL = first
                }
                .padding()
            }
            
            Button {
                justDoEverything(URL: URL)
            } label: {
                Text("Go!")
            }
        }
        .fileExporter(isPresented: $showExporter, document: document, contentType: .plainText) { result in
            switch result {
            case .success(let url):
                print("Saved to \(url)")
            case .failure(let error):
                print(error.localizedDescription)
            }
            showExporter = false
            print("Done!")
            print(showExporter)
        }
    }
    
    func justDoEverything(URL: String) {
        var request = URLRequest(url: Foundation.URL(string: URL)!)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = false
        let session = URLSession.init(configuration: URLSessionConfiguration.default)
        session.dataTask(with: request) {data,response,error in
            if let data = data {
                // sanitise contents
                var contents = String(data: data, encoding: .utf8)!
                contents = contents.replacingOccurrences(of: "\n", with: "")
                contents = contents.replacingOccurrences(of: "\u{00a0}", with: " ")
                
                // isolate whole json string
                let approxStart = contents.range(of: "window.APP_INITIALIZATION_STATE")
                let start = contents.index((approxStart?.upperBound)!, offsetBy: 1)
                let end = contents.range(of: ";window.APP_FLAGS", range: start..<contents.endIndex)?.lowerBound
                let range = start..<end!
                contents = String(contents[range])
                
                // get location details from isolated contents
                var detailsJSON = try! JSONSerialization.jsonObject(with: contents.data(using: .utf8)!, options: []) as! NSArray
                detailsJSON = detailsJSON[3] as! NSArray
                let brokenJSON = (detailsJSON[2] as! String).dropFirst(5)
                detailsJSON = try! JSONSerialization.jsonObject(with: brokenJSON.data(using: .utf8)!, options: []) as! NSArray
                detailsJSON = detailsJSON[0] as! NSArray
                detailsJSON = detailsJSON[1] as! NSArray
                
                // isolate necessary location data
                var locationsData: [(String, String, String)] = []
                for location in detailsJSON {
                    let locationData = (location as! NSArray)[14] as! NSArray
                    let name = locationData[11] as! String
                    let latitude = String(describing: (locationData[9] as! NSArray)[2] as! NSNumber)
                    let longitude = String(describing: (locationData[9] as! NSArray)[3] as! NSNumber)
                    locationsData.append((name, latitude, longitude))
                }
                document.text = writeGPX(data: locationsData)
                showExporter = true
                print("to save!")
                print(showExporter)
            }
        }.resume()
    }
    
    func writeGPX(data: [(String, String, String)]) -> String {
        let xmlHeader = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        let gpxHeader = "<gpx xmlns=\"http://www.topografix.com/GPX/1/1\" version=\"1.1\" creator=\"GPX from Maps\">\n"
        let gpxFooter = "</gpx>\n"
        var gpxBody = ""
        for location in data {
            gpxBody += "\t<wpt lat=\"\(location.1)\" lon=\"\(location.2)\">\n"
            gpxBody += "\t\t<name>\(location.0)</name>\n"
            gpxBody += "\t</wpt>\n"
        }
        let gpx = xmlHeader + gpxHeader + gpxBody + gpxFooter
        return gpx
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


