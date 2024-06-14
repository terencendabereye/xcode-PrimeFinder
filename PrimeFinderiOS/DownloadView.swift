//
//  DownloadView.swift
//  PrimeFinder
//
//  Created by Terence  Ndabereye  on 27/05/2024.
//

import SwiftUI
import SwiftData

struct DownloadView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @State var downloads: [DownloadTask] = [
        .init(name: "sample", source: URL(string: "https://example.com"))
    ]
    @State var isSheetPresented = false
    
    
    var body: some View {
        NavigationStack {
            VStack{
                if !downloads.isEmpty{
                    List($downloads, editActions: [.all]) { download in
                        NavigationLink {
                            EditDownloadItemView(download: download)
                        } label: {                            DownloadItemView(download: download.wrappedValue)
                        }
                    }
                } else {
                    ContentUnavailableView(label: {
                        Label("No downloads", systemImage: "tray.fill")
                    }, description: {
                        Text("Your downloads will go here")
                    }, actions: {
                        Button("Add download", systemImage: "plus") {
                            isSheetPresented = true
                        }
                    })
                }
            }
            .navigationTitle("Downloads")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Add Download", systemImage: "plus") {
                        // add item
                        isSheetPresented = true
                    }
                    .sheet(isPresented: $isSheetPresented, content: {
                        NewDownloadView(downloads: $downloads)
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
}

#Preview {
    DownloadView()
}

struct NewDownloadView: View {
    enum FocuseField {
        case source, name
    }
    
    @Environment(\.dismiss) var dismiss
    @Binding var downloads: [DownloadTask]
    @State var source: URL?
    @State var name: String = ""
    @State var resumable: Bool = true
    @State var allowBackground: Bool = true
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
        let newDownloadTask = DownloadTask()
        newDownloadTask.name = name

        newDownloadTask.resumable = resumable
        newDownloadTask.source = source
        
        newDownloadTask.run()
        
        
        downloads.append(newDownloadTask)
        dismiss()
    }
}



struct DownloadItemView: View {
    
    @Environment(\.scenePhase) var scenePhase
    @Bindable var download: DownloadTask
    @State var showAlert: Bool = false
    @State var mbs: Double = 0
    @State var isSavePresented = false
//    @State var isQuicklookPresented = false
    @State var goToURL: URL?
    @FocusState var isFocused: Bool
    
    var body: some View {
        HStack {
            Gauge(value: download.progress, label: {
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
                    if #available(iOS 18.0, *) {
                        Image(systemName: "ellipsis")
                            .symbolRenderingMode(.monochrome)
                            .scaledToFill()
                            .contentTransition(.symbolEffect(.replace.byLayer.downUp))
                            .symbolEffect(.wiggle.up, options: .speed(0.5).repeat(.periodic(delay: 0.4)))
                    } else {
                        Image(systemName: "ellipsis")
                            .symbolRenderingMode(.monochrome)
                            .scaledToFill()
                            .contentTransition(.symbolEffect(.replace.byLayer.downUp))
                            .symbolEffect(.variableColor.reversing.iterative, options: .speed(0.5))
                    }
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
                if let source = download.source {
                    Text("\(source.description)")
                        .foregroundStyle(.tint)
                        .font(.footnote)
                        .tint(.secondary)
                        .lineLimit(1)
                    
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
                default:
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title)
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
//                                Button("Quicklook", systemImage: "eye") {
//                                    isQuicklookPresented = true
//                                }
            Button("Copy download address", systemImage: "doc.on.doc") {
                let pasteboard = UIPasteboard.general
                guard let url = download.source?.absoluteString else {return}
                pasteboard.string = url
            }
            if let fileURL = download.savedURL {
                Button("Save", systemImage: "square.and.arrow.down"){
                    //TODO: Save
                    goToURL = fileURL
                    isSavePresented = true
                }
            }
            Button("Delete", systemImage: "trash", role: .destructive) {
                download.delete()
//                download.removeAll(where: {$0.id == download.id})
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
        .sensoryFeedback(.success, trigger: download.state)
    }
}

struct EditDownloadItemView: View {
    @Binding var download: DownloadTask
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
            }
            Section {
                let bytesExpected = (download.downloadTask?.countOfBytesExpectedToReceive ?? 0) / 1_048_576
                let currentBytes = download.progress * Double(bytesExpected)
                
                ProgressView(value: currentBytes, total: Double(bytesExpected)) {
                    Text(String(format: "%.1fMB of %.1fMB", Double(currentBytes), Double(bytesExpected)))
                }
                
                LabeledContent("Debug Error") {
                    VStack {
//                        Text(download.error?.localizedDescription ?? "nil")
                        Text(download.downloadTask?.error.debugDescription ?? " nil" )
                    }
                }
                
            }
            
        }
        .navigationTitle(download.name)
    }
}
