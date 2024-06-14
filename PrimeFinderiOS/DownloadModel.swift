//
//  DownloadModel.swift
//  PrimeFinderiOS
//
//  Created by Terence  Ndabereye  on 30/05/2024.
//

import Foundation
import SwiftUI
import SwiftData
import UserNotifications


class DownloadTaskDelegate: NSObject, URLSessionDownloadDelegate {
    let downloadTask: DownloadTask
    
    init(downloadTask: DownloadTask) {
        self.downloadTask = downloadTask
    }
    
    enum GenericError: Error {
        case GenericError
    }
    
    func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        self.downloadTask.state = .waiting
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: (any Error)?) {
        let _timeoutError  = NSURLErrorTimedOut
        let cancelError = NSURLErrorCancelled
        
        self.downloadTask.setError(error)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        DispatchQueue.main.async {
            let oldProgress = self.downloadTask.progress
            let newProgress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            
            self.downloadTask.progress = newProgress
            
            if newProgress-oldProgress >= 0.1 {
                self.downloadTask.progressDidChangeSignificantly()
            }
            
        }
        
    }
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        //MARK: Save
        if let error = downloadTask.error {
            print(error)
            self.downloadTask.busy = false
            self.downloadTask.state = .cancelled
        } else {
            self.downloadTask.busy = false
            self.downloadTask.state = .finished
        }
        

        do {
            guard let suggestedFilename = downloadTask.response?.suggestedFilename else {return}
            let dir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: self.downloadTask.savedURL, create: false)
            self.downloadTask.savedURL = dir.appending(component: suggestedFilename)
            guard let savedURL = self.downloadTask.savedURL else {return}
            try moveFileWithUniqueName(at: location, to: savedURL)
        } catch {
            self.downloadTask.setError(error)
            return
        }
        
        
        self.downloadTask.downloadDidFinish()

    }
    
    func moveFileWithUniqueName(at sourceURL: URL, to destinationURL: URL) throws {
        let fileManager = FileManager.default
        let destinationDirectoryURL = destinationURL.deletingLastPathComponent()
        let originalFileName = destinationURL.deletingPathExtension().lastPathComponent
        let fileExtension = destinationURL.pathExtension
        
        var uniqueDestinationURL = destinationURL
        var fileIndex = 1
        
        while fileManager.fileExists(atPath: uniqueDestinationURL.path) {
            let newFileName = "\(originalFileName)_\(fileIndex).\(fileExtension)"
            uniqueDestinationURL = destinationDirectoryURL.appendingPathComponent(newFileName)
            fileIndex += 1
        }
        
        try fileManager.moveItem(at: sourceURL, to: uniqueDestinationURL)
    }
    
}

//@Model
@Observable
class DownloadTask:Identifiable {
    public enum DownloadState: Codable {
        case notStarted
        case downloading
        case paused
        case finished
        case cancelled
        case failed
        case waiting
    }
    
    var id = UUID()
    var name: String = "untitled"
    var source: URL?
    var savedURL: URL?
    @Transient
    var error: (any Error)?
    var resumable: Bool = false
    var allowBackground: Bool = true
    var progress: Double = 0
    var busy: Bool = false
    var state: DownloadState = DownloadState.notStarted
    @Transient
    var buffer: Data = Data()
    @Transient
    var urlResponse: URLResponse? = nil
    @Transient
    var downloadTask: URLSessionDownloadTask? = nil
    @Transient
    var downloadTaskDelegate: DownloadTaskDelegate? = nil
    @Transient
    var urlSession: URLSession? = nil
    
    init(id: UUID = UUID(), name: String = "untitled_download", source: URL? = nil, savedURL: URL? = nil, error: (any Error)? = nil, resumable: Bool = true, buffer: Data = Data(), progress: Double = 0, urlResponse: URLResponse? = nil, busy: Bool = false, state: DownloadState = .notStarted, downloadTask: URLSessionDownloadTask? = nil, downloadTaskDelegate: DownloadTaskDelegate? = nil, urlSession: URLSession? = nil) {
        self.id = id
        self.name = name
        self.source = source
        self.savedURL = savedURL
        self.error = error
        self.resumable = resumable
        self.buffer = buffer
        self.progress = progress
        self.urlResponse = urlResponse
        self.busy = busy
        self.state = state
        self.downloadTask = downloadTask
        self.downloadTaskDelegate = downloadTaskDelegate
        self.urlSession = urlSession
    }
    
    func setError(_ error: (any Error)?) {
        if let error = error {
            print(error)
            self.error = error
        }
        self.state = .failed
    }
    
    func delete() {
        guard let savedURL = self.savedURL else {return}
        do {
            try FileManager.default.removeItem(at: savedURL)
        } catch {
            print(error)
            return
        }
    }
    
    func downloadDidFinish() {
        //send notification
        let content = UNMutableNotificationContent()
        content.title = "Download Complete"
        let name = self.name
        content.body = "The download \"\(name)\" has finished"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
        
    }
    
    /// **HAS BEEN REMOVED**
    func progressDidChangeSignificantly() {
        // update live activity
    }

    
    func cancelDownload() {
        self.busy = false
        self.state = .cancelled
        progress = 0
        buffer.removeAll()
        downloadTask?.cancel()
    }
    
    func pause() {
        if resumable{
            busy = false
            state = .paused
            downloadTask?.cancel(byProducingResumeData: { resumeData in
                if let resumeData = resumeData{
                    self.buffer = resumeData
                }
            })
        } else {
            self.cancelDownload()
            state = .cancelled
        }
    }
    func run() {
        if downloadTaskDelegate == nil {
            downloadTaskDelegate = DownloadTaskDelegate(downloadTask: self)
        }
        if urlSession == nil {
            urlSession = URLSession(configuration: .default, delegate: self.downloadTaskDelegate, delegateQueue: nil)
        }
        guard let source = self.source else { print("nil sourceURL"); return }
        
        guard let urlSession = urlSession else {return}
        
        if resumable && state == .paused  {
            downloadTask = urlSession.downloadTask(withResumeData: buffer)
        } else {
            downloadTask = urlSession.downloadTask(with: source)
            buffer.removeAll()
        }
        
        if let downloadTask = downloadTask {
            self.busy = true
            self.state = .downloading
            downloadTask.resume()
            requestLiveActivity()
        }
//        self.downloadTask = downloadTask
    }
    /// **Live activities removed**
    func requestLiveActivity() {
        // begin live activity
    }
   
}

