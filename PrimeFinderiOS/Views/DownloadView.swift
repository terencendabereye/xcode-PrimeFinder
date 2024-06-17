//
//  DownloadView.swift
//  PrimeFinder
//
//  Created by Terence  Ndabereye  on 27/05/2024.
//

import SwiftUI
import SwiftData
import QuickLook
import WebKit

struct DownloadView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Query(sort: \DownloadTask.order) var downloads: [DownloadTask]
    @State var isSheetPresented = false
    @State var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack{
                if !downloads.isEmpty {
                    List{
                        ForEach(downloads){
                            download in
                            @Bindable var download = download
                            NavigationLink(value: download) {
                                DownloadItemView(download: download)
                            }
                        }
                        .onMove(perform: { from, to in
                            var tmp = downloads.sorted(by: {$0.order>=$1.order})
                            tmp.move(fromOffsets: from, toOffset: to)
                            for (i,v) in tmp.enumerated() {
                                v.order = i
                            }
                            try? modelContext.save()
                        })
                        .onDelete { indices in
                            for v in indices {
                                do {
                                    let deleteTarget = downloads[v]
                                    deleteTarget.delete()
                                    modelContext.delete(deleteTarget)
                                    try modelContext.save()
                                } catch {
                                    print("Failed to save")
                                }
                            }
                        }
                    }
                    .navigationDestination(for: DownloadTask.self) { downloadTask in
                        EditDownloadItemView(download: downloadTask, navigationPath: $navigationPath)
                    }
                    .navigationDestination(for: WebKitURL.self) { webkitURL in
                        WebView(url: webkitURL.targetURL)
                    }
                } else {
                    ContentUnavailableView(label: {
                        Label("No downloads", systemImage: "tray.fill")
                    }, description: {
                        Text("Your downloads will go here")
                    }, actions: {
                        Button("Add download", systemImage: "plus") {
                            addNewDownload()
                        }
                    })
                }
            }
            .navigationTitle("Downloads")
            .toolbar {
                ToolbarItem {
                    EditButton()
                }
                ToolbarItem(placement: .automatic) {
                    Button("Add Download", systemImage: "plus") {
                        addNewDownload()
                    }
                    .sheet(isPresented: $isSheetPresented, content: {
                        NewDownloadView(newDownloadTask: DownloadTask())
                    })
                }
                ToolbarItem(placement: .keyboard) {
                    Button("Dismiss"){
                        dismiss()
                    }
                }
            }
        }
    }
    private func addNewDownload() {
        isSheetPresented = true
    }
}

#Preview {
    DownloadView()
}

struct NewDownloadView: View {
    enum FocuseField {
        case source, name
    }
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Bindable var newDownloadTask: DownloadTask
    @State var source: URL?
    @State var name: String = ""
    @State var resumable: Bool = true
    @State var allowBackground: Bool = true
    @State var startImmediately: Bool = true
    @State var sourceString: String = ""
    @FocusState var focusField: FocuseField?
    
    private var urlStyle: URL.FormatStyle {
        return URL.FormatStyle(scheme: .always, path: .omitWhen(.path, matches: ["/"]), query: .omitWhen(.query, matches: [""]))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section{
                    TextField("Source", text: $sourceString)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .submitLabel(.continue)
                        .textContentType(.URL)
                        
                        .onSubmit(of: .text) {
                            focusField = .name
                        }
                        .focused($focusField, equals: .source)
                    
                    TextField("Task Name", text: $name)
                        .focused($focusField, equals: .name)
                        .submitLabel(.continue)
                        .onSubmit {
                            focusField = .none
                        }
                    
                    Toggle("Resumable", isOn: $resumable)
                    Toggle("Background", isOn: $allowBackground)
                    Toggle("Start Immediately", isOn: $startImmediately)
                    Button("Confirm", action: handleNewDownload)
                        .buttonStyle(PlainButtonStyle())
                        .foregroundStyle(.tint)
                        .tint(.accent)
                } footer: {
                    Text("Swipe down to cancel")
                }
            }
            .navigationTitle("New Download")
            .onAppear{
                focusField = .source
            }
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .keyboard) {
                    Button("dismiss") {
                        focusField = .none
                    }
                }
            })
        }
    }
    
    func handleNewDownload() {
        let re = #/(http://|https://.+)/#
        sourceString = sourceString.replacingOccurrences(of: "http://", with: "https://")
        if !sourceString.contains(re) {
            sourceString = "https://" + sourceString
        }
        
        if sourceString.hasSuffix("/"){
            sourceString.removeLast()
        }
        
        guard let source = URL(string: sourceString) else {
            print("Failed to make URL from \(sourceString)")
            return
        }
//        let newDownloadTask = DownloadTask()
        newDownloadTask.name = name

        newDownloadTask.resumable = resumable
        newDownloadTask.source = source
        
        modelContext.insert(newDownloadTask)
        do {
            try modelContext.save()
        } catch {
            print("Failed to save")
        }
        
        if startImmediately {
            newDownloadTask.run()
        }
        
        dismiss()
    }
}



struct DownloadItemView: View {
    
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.modelContext) var modelContext
    @Bindable var download: DownloadTask
    @State var showAlert: Bool = false
    @State var mbs: Double = 0
    @State var isSavePresented = false
//    @State var isQuicklookPresented = false
    @State var goToURL: URL?
    @FocusState var isFocused: Bool
    @State var buttonSymbol: String = "questionmark"
    
    var body: some View {
        HStack {
            Gauge(value: clamp(download.progress, min: 0.0, max: 1.0), label: {
                switch download.state {
                case .downloading:
                    let bytesExpected = (download.downloadTask?.countOfBytesExpectedToReceive ?? 0) / 1_048_576
                    Text(String(format: "%.1fMB", download.progress * Double(bytesExpected)))
                        .scaledToFit()
                    //                            .animation(.interpolatingSpring, value: download.progress)
                    //                            .contentTransition(.numericText())
                case .finished:
                    Image(systemName: "checkmark")
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(.green)
                        .scaledToFill()
                        .contentTransition(.symbolEffect(.replace.byLayer.downUp))
                case .cancelled:
                    Image(systemName: "xmark")
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(.red)
                        .scaledToFill()
                        .contentTransition(.symbolEffect(.replace.byLayer.downUp))
                case .paused:
                    let bytesExpected = (download.downloadTask?.countOfBytesExpectedToReceive ?? 0) / 1_048_576
                    Text(String(format: "%.1fMB", download.progress * Double(bytesExpected)))
                        .scaledToFit()
                        .opacity(0.5)
                case .failed:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .symbolRenderingMode(.multicolor)
                        .scaledToFill()
                        .contentTransition(.symbolEffect(.replace.byLayer.downUp))
                        .alert("Error", isPresented: $showAlert, actions: {}, message: {
                            Text(download.error?.localizedDescription ?? "error")
                        })
                        .onTapGesture {
                            showAlert.toggle()
                        }
                default:
                    Image(systemName: "ellipsis")
                        .symbolRenderingMode(.monochrome)
                        .scaledToFill()
                        .contentTransition(.symbolEffect(.replace.byLayer.downUp))
                        .symbolEffect(.variableColor.reversing.iterative, options: .speed(0.5))
                }
            })
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(.accentColor)
            .sensoryFeedback(.levelChange, trigger: download.progress)
            
            VStack {
                Text(download.name)
                    .frame(alignment: .center)
                    .focused($isFocused)
                    .renameAction($isFocused)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let source = download.source {
                    Text("\(source.description)")
                        .foregroundStyle(.tint)
                        .font(.footnote)
                        .tint(.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            Spacer()
            Button(action: {
                if let url = download.savedURL {
                    print(url)
                }
                switch download.state {
                case .downloading:
                    download.pause()
                default:
                    download.run()
                }
            }, label: {
                Image(systemName: buttonSymbol)
                    .font(.title)
                    .task(id: download.state) {
                        switch download.state {
                        case .notStarted:
                            buttonSymbol = "arrow.down.circle.fill"
                        case .downloading:
                            buttonSymbol = "pause.circle.fill"
                        case .paused:
                            buttonSymbol = "arrow.down.circle.fill"
                        case .finished:
                            buttonSymbol = "arrow.down.circle.fill"
                        case .cancelled:
                            buttonSymbol = "arrow.circlepath"
                        case .failed:
                            buttonSymbol = "arrow.circlepath"
                        default:
                            buttonSymbol = "arrow.down.circle.fill"
                        }
                    }
            })
            .buttonStyle(PlainButtonStyle())
            .foregroundStyle(.accent)
            .onChange(of: scenePhase) { oldValue, newValue in
                if newValue == .background && download.state == .downloading {
                    // app entering background
                    // prevent background downloads
                    if !download.allowBackground{
                        download.pause()
                    }
                }
            }
            
        }
        .contextMenu(menuItems: {
            Button("Copy download address", systemImage: "doc.on.doc") {
                let pasteboard = UIPasteboard.general
                guard let url = download.source?.absoluteString else {return}
                pasteboard.string = url
            }
            if let fileURL = download.savedURL {
                Button("Save", systemImage: "square.and.arrow.down"){
                    goToURL = fileURL
                    isSavePresented = true
                }
                ShareLink(item: fileURL)
                Button("Delete file", systemImage: "trash", role: .destructive) {
                    download.delete()
                }
            }
            Button("Cancel", systemImage: "xmark", role: .cancel) {
                download.cancelDownload()
            }
        })
        .fileMover(isPresented: $isSavePresented, file: goToURL ?? URL(string: "http://apple.com")!, onCompletion: { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                print(error)
            }
        })
        .sensoryFeedback((download.state == .downloading) ? .start : .stop, trigger: download.state)
    }
}

struct EditDownloadItemView: View {
    @Bindable var download: DownloadTask
    @State var quickLookURL: URL?
    @Binding var navigationPath: NavigationPath
    @State var fileSize: Double = 0
    var body: some View {
        Form {
            Section{
                TextField("Name", text: $download.name)
                Toggle("Resumable", isOn: $download.resumable)
                Toggle("Background", isOn: $download.allowBackground )
                Button(action: {
                    if let url = download.savedURL {
                        print(url)
                    }
                    switch download.state {
                    case .downloading:
                        download.pause()
                    default:
                        download.run()
                    }
                }, label: {
                    switch download.state {
                    case .notStarted:
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.title)
                    case .downloading:
                        Image(systemName: "pause.circle.fill")
                            .font(.title)
                    case .paused:
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.title)
                    case .finished:
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.title)
                    case .cancelled:
                        Image(systemName: "arrow.circlepath")
                            .font(.title)
                    case .failed:
                        Image(systemName: "arrow.circlepath")
                            .font(.title)
                    case .waiting:
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.title)
                    }
                })
                .buttonStyle(PlainButtonStyle())
                .foregroundStyle(.accent)
                
            }

            Section {
                let bytesExpected = (download.downloadTask?.countOfBytesExpectedToReceive ?? 0) / 1_048_576
                let currentBytes = download.progress * Double(bytesExpected)
                
                if download.busy {
                    ProgressView(value: currentBytes, total: Double(bytesExpected)) {
                        Text(String(format: "%.1fMB of %.1fMB", Double(currentBytes), Double(bytesExpected)))
                    }
                } else {
                    LabeledContent("Size", value: String(format: "%.2f MB", fileSize))
                        .task {
                            do {
                                guard let savedURL = download.savedURL else {return}
                                let currentPath = try getCurrentURL(oldURL: savedURL)
                                let attributes = try FileManager.default.attributesOfItem(atPath: currentPath.path())
                                let bytes = attributes[.size] as! Int
                                fileSize = Double(bytes) / 1_000_000.0
                            } catch {
                                print(error)
                            }
                        }
                }
                
                LabeledContent("Debug Error") {
                    VStack {
//                        Text(download.error?.localizedDescription ?? "nil")
                        Text(download.downloadTask?.error.debugDescription ?? " nil" )
                    }
                }
            }
            Section{
                if download.savedURL != nil {
                    Button("Show", systemImage: "eye") {
                        do {
                            guard let url = download.savedURL else { return }
                            let pathExtension = url.pathExtension
//                            print(pathExtension)
                            let found = try getCurrentURL(oldURL: url)
                            
                            if pathExtension == "html" || pathExtension == "htm" {
                                navigationPath.append(WebKitURL(targetURL: found))
                            } else {
                                download.savedURL = found
                                quickLookURL = download.savedURL
                            }
                        } catch {
                            print(error)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundStyle(.accent)
                    .quickLookPreview($quickLookURL)
                }
            }
        }
        .navigationTitle(download.name)
    }
}

struct WebKitURL: Hashable {
    var targetURL: URL
}
func getCurrentURL(oldURL: URL) throws -> URL {
    enum GetURLError: Error {
        case DirectoryWasEmpty
        case FileNotFound
    }
    let dir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    guard let fileName = oldURL.pathComponents.last else { throw GetURLError.DirectoryWasEmpty }
    let contents = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
    let found = contents.filter {$0.lastPathComponent == fileName}
    guard let found = found.first else { throw GetURLError.FileNotFound }
    return found
}

