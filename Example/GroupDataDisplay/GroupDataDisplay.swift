//
//  GroupDataDisplay.swift
//  GroupDataDisplay
//
//  Created by ZHK on 2021/1/6.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents
import LLCoreData
import CoreData

struct Provider: IntentTimelineProvider {
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
}

struct GroupDataDisplayEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        Text(text())
    }
    
    func text() -> String {
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = Continent.entity()
        let result = try! LLCoreData.context.fetch(request)
        return "\(result.count)"
    }
}

@main
struct GroupDataDisplay: Widget {
    let kind: String = "GroupDataDisplay"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            GroupDataDisplayEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
    
    init() {
        do {
            if #available(iOS 13.0, *) {
                try LLCoreData.registContainer(name: "Database",
                                               configuration: "Cloud",
                                               cloud: "iCloud.org.cocoapods.demo.LLCoreData-Example",
                                               group: "group.com.lymatrix")
            } else {
                try LLCoreData.registContainer(name: "Database", with: "group.com.lymatrix")
            }
        } catch {
            print(error)
        }
    }
}

struct GroupDataDisplay_Previews: PreviewProvider {
    static var previews: some View {
        GroupDataDisplayEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
