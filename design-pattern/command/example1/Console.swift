//
//  Console.swift
//
//  Created by dev on 14/07/2021.
//

import Foundation
import os.log
import Combine
import SwiftUI

public class Console {
    public static let shared = Console()

    public static func log(
        file: String = #file, // full path with the file extension
        function: String = #function, // function signature same as the function suggestion
        line: NSNumber = #line,
        formatter: ConsoleLogFormatter? = CallerFormatter(),
        timestamp: Date = Date()
    ) {
        #if DEBUG
        Console.shared.log(file: file, function: function, line: line, formatter: formatter, timestamp: timestamp)
        #endif
    }

    public static func log(
        file: String = #file, // full path with the file extension
        function: String = #function, // function signature same as the function suggestion
        line: NSNumber = #line,
        formatter: ConsoleLogFormatter? = CallerFormatter(),
        logType: OSLogType,
        osLog: OSLog,
        timestamp: Date = Date()
    ) {
        #if DEBUG
        Console.shared.log(file: file, function: function, line: line, formatter: formatter, logType: logType, osLog: osLog, timestamp: timestamp)
        #endif
    }

    public static func log(
        _ item: @autoclosure () -> Any?,
        file: String = #file,
        function: String = #function,
        line: NSNumber = #line,
        formatter: ConsoleLogFormatter? = CallerFormatter(),
        timestamp: Date = Date()
    ) {
        #if DEBUG
        Console.shared.log(item: item(), file: file, function: function, line: line, formatter: formatter)
        #endif
    }

    public static func log(
        _ item: @autoclosure () -> Any?,
        file: String = #file,
        function: String = #function,
        line: NSNumber = #line,
        formatter: ConsoleLogFormatter? = CallerFormatter(),
        logType: OSLogType,
        osLog: OSLog,
        timestamp: Date = Date()
    ) {
        #if DEBUG
        Console.shared.log(item: item(), file: file, function: function, line: line, formatter: formatter, logType: logType, osLog: osLog, timestamp: timestamp)
        #endif
    }

    public var option_os_log: OSLog = .default

    public var option_os_log_type: OSLogType = .default

    public let dispatcher: DispatchQueue = DispatchQueue(label: "console-worker-queue")

    public var enabled: Bool = false

    public var history: FIFOArray<ConsoleLog>?

    public convenience init () {
        self.init(history: nil)
    }

    public init(history: FIFOArray<ConsoleLog>?) {
        self.history = history
    }

    public func log(
        file: String = #file, // full path with the file extension
        function: String = #function, // function signature same as the function suggestion
        line: NSNumber = #line,
        formatter: ConsoleLogFormatter? = CallerFormatter(),
        timestamp: Date = Date()
    ) {
        #if DEBUG
        self.log("", file: file, function: function, line: line, formatter: formatter, logType: self.option_os_log_type, osLog: self.option_os_log, timestamp: timestamp)
        #endif
    }

    public func log(
        file: String = #file, // full path with the file extension
        function: String = #function, // function signature same as the function suggestion
        line: NSNumber = #line,
        formatter: ConsoleLogFormatter? = CallerFormatter(),
        logType: OSLogType,
        osLog: OSLog,
        timestamp: Date = Date()
    ) {
        #if DEBUG
        self.log("", file: file, function: function, line: line, formatter: formatter, logType: logType, osLog: osLog, timestamp: timestamp)
        #endif
    }

    public func log(
        _ item: @autoclosure () -> Any?,
        file: String = #file, // full path with the file extension
        function: String = #function, // function signature same as the function suggestion
        line: NSNumber = #line,
        formatter: ConsoleLogFormatter? = CallerFormatter(),
        timestamp: Date = Date()
    ) {
        #if DEBUG
        self.log(item: item(), file: file, function: function, line: line, formatter: formatter, logType: self.option_os_log_type, osLog: self.option_os_log, timestamp: timestamp)
        #endif
    }

    public func log(
        _ item: @autoclosure () -> Any?,
        file: String = #file,
        function: String = #function,
        line: NSNumber = #line,
        formatter: ConsoleLogFormatter? = CallerFormatter(),
        logType: OSLogType,
        osLog: OSLog,
        timestamp: Date = Date()
    ) {
        #if DEBUG
        self.log(item: item(), file: file, function: function, line: line, formatter: formatter, logType: logType, osLog: osLog, timestamp: timestamp)
        #endif
    }

    func log(
        item: Any?,
        file: String = #file,
        function: String = #function,
        line: NSNumber = #line,
        formatter: ConsoleLogFormatter? = CallerFormatter(),
        timestamp: Date = Date()
    ) {
        self.log(item: item, file: file, function: function, line: line, formatter: formatter, logType: self.option_os_log_type, osLog: option_os_log, timestamp: timestamp )
    }

    func log(
        item: Any?,
        file: String = #file,
        function: String = #function,
        line: NSNumber = #line,
        formatter: ConsoleLogFormatter? = CallerFormatter(),
        logType: OSLogType,
        osLog: OSLog,
        timestamp: Date = Date()
    ) {
        let message: String = nil == item ? "nil" : String(describing: item!)
        let formatted = formatter?.format(message, file: file, function: function, line: line, timestamp: timestamp) ?? message
        if (self.enabled) {
            os_log("%@", log: osLog, type: logType, formatted)
        }
        if (nil != self.history) {
            self.dispatcher.async {
                let entry = ConsoleLog(
                    file: file,
                    function: function,
                    line: line,
                    osLog: osLog,
                    logType: logType,
                    message: message,
                    timestamp: timestamp,
                    formattedMessage: formatted
                )
                self.history?.append(entry)
            }
        }
    }

    public func clear() {
        self.dispatcher.async {
            self.history?.removeAll()
        }
    }

    deinit {
        self.history?.removeAll()
    }
}

public protocol ConsoleLogFormatter {
    init()
    func format(_ item: Any?, file: String, function: String, line: NSNumber, timestamp: Date) -> String
}

public class CallerFormatter: ConsoleLogFormatter, CustomDebugStringConvertible {
    public var debugDescription: String {
        return id?.uuidString ?? "nil"
    }

    public static var prefix: String = "[ APP ] "

    let prefix: String

    let id: UUID?

    public required convenience init() {
        self.init(id: nil)
    }

    public convenience init(id: UUID?) {
        self.init(id: id, prefix: CallerFormatter.prefix)
    }

    public init(id: UUID?, prefix: String) {
        self.id = id
        self.prefix = prefix
    }

    // remove path and file extension
    public func filename(file: String) -> String {
        return String(file.split(separator: "/").last!.split(separator: ".").first!)
    }

    public func format(_ item: Any?, file: String, function: String, line: NSNumber, timestamp: Date) -> String {
        let filename = self.filename(file: file)
        let prefix = "\(CallerFormatter.prefix)\(filename).\(function):\(line)"
        let suffix = nil == self.id ? "" : " [\(self.id?.uuidString ?? "")]"
        if let item = item as? String, item.count == 0 {
            return "\(prefix) \(suffix)"
        }
        return "\(prefix) - \(item ?? "nil") \(suffix)"
    }
}

public class FIFOArray<T> {
    public var maxSize: Int

    public var items: [T] = []

    public init(maxSize: Int) {
        self.maxSize = maxSize
    }

    public func append(_ item: T) {
        if (self.items.count >= self.maxSize) {
            self.removeFirstSafe()
        }
        self.items.append(item)
    }

    public func remove(at: Int) {
        self.items.remove(at: at)
    }

    public func removeAll() {
        self.items.removeAll()
    }

    public func removeLast() {
        self.items.removeLast()
    }

    public func popLast() -> T? {
        return self.items.popLast()
    }

    public func removeFirstSafe() {
        if (0 < self.items.count) {
            self.items.removeFirst()
        }
    }
}

extension FIFOArray: RandomAccessCollection {
    public var startIndex: Int {
        return items.startIndex
    }

    public var endIndex: Int {
        return items.endIndex
    }

    public subscript(i: Int) -> T {
        return items[i]
    }
}

public struct ConsoleLog {
    public let file: String

    public let function: String

    public let line: NSNumber

    public let osLog: OSLog

    public let logType: OSLogType

    public let message: String

    public let timestamp: Date

    public let formattedMessage: String

    public func readableMessage() -> String {
        return self.message.isEmpty ? self.formattedMessage : self.message
    }

    public var filename: String {
        return String(self.file.split(separator: "/").last!.split(separator: ".").first!)
    }
}

extension ConsoleLog: Identifiable {
    public var id: Date {
        return self.timestamp
    }
}

extension Console: TextOutputStream {
    public func write(_ string: String) {
        Console.log(string, formatter: nil) // because the file, function and line will become here.
    }
}

/* SwiftUI View  */

public class ConsoleViewModel: ObservableObject {
    @Published var console: Console

    public init(console: Console) {
        self.console = console
    }

    public func clear() {
        self.console.clear()
        // SwiftUI cannot detect the list of object of published object!?
        self.objectWillChange.send()
    }
}

public struct ConsoleView: View {
    @ObservedObject var viewModel: ConsoleViewModel

    @State var cancellable: AnyCancellable?

    public init(viewModel: ConsoleViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        return NavigationView {
            VStack {
                if (nil == self.viewModel.console.history) {
                    EmptyView()
                }
                else {
                    List(self.viewModel.console.history!) { item in
                        NavigationLink(destination: LogDetailView(log: item), label: {
                            ConsoleRow(log: item)
                        })
                    }
                }
            }
            .navigationBarTitle(Text("Console Log"), displayMode: .inline)
            .navigationBarItems(
                trailing: Button("Clear") {
                    self.viewModel.clear()
                }
            )
        }
    }
}

struct ConsoleRow: View {
    @State var log: ConsoleLog

    public var body: some View {
        HStack {
            VStack(alignment: HorizontalAlignment.leading) {
                Text(self.log.timestamp.format("YYYY-MM-dd HH:mm:ss", locale: Locale.current)).font(.system(size: 12, weight: Font.Weight.bold, design: Font.Design.rounded))
                Text(self.log.readableMessage()).font(.system(size: 12, weight: Font.Weight.regular, design: Font.Design.rounded))
            }
        }
    }
}

struct LogDetailView: View {
    @State var log: ConsoleLog

    public var body: some View {
        VStack(alignment: HorizontalAlignment.leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("Datetime:").font(.system(size: 12, weight: Font.Weight.bold, design: Font.Design.rounded))
                    Text(self.log.timestamp.format("YYYY-MM-dd HH:mm:ss", locale: Locale.current)).font(.system(size: 12, weight: Font.Weight.regular, design: Font.Design.rounded))
                }
                HStack {
                    Text("File:").font(.system(size: 12, weight: Font.Weight.bold, design: Font.Design.rounded))
                    Text(self.log.filename).font(.system(size: 12, weight: Font.Weight.regular, design: Font.Design.rounded))
                }
                HStack {
                    Text("Function:").font(.system(size: 12, weight: Font.Weight.bold, design: Font.Design.rounded))
                    Text(self.log.function).font(.system(size: 12, weight: Font.Weight.regular, design: Font.Design.rounded))
                }
                HStack {
                    Text("Line:").font(.system(size: 12, weight: Font.Weight.bold, design: Font.Design.rounded))
                    Text(self.log.line.description).font(.system(size: 12, weight: Font.Weight.regular, design: Font.Design.rounded))
                }
            }

            Divider()

            Text(self.log.message).font(.system(size: 16, weight: Font.Weight.medium, design: Font.Design.rounded))

            Spacer()
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
        .padding()
    }
}
