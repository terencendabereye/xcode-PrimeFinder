//
//  Model.swift
//  PrimeFinder
//
//  Created by Terence  Ndabereye  on 19/05/2024.
//

import Foundation
import SwiftUI
import SwiftData


@Observable
//@Model
class PrimeResults {
    var count: Int
    var last: [Int]
    var busy: Bool
    var workingMax: Int?
    var current: Int = 0
    var progress: Double = 0.0
    var alternateStage: Bool = false
    
    
    init(count: Int? = nil, last: [Int]? = nil, busy: Bool) {
        self.count = 0
        self.busy = busy
        self.last = []
    }
    
    func sieve() async {
        guard let max = workingMax else {return}
        guard max >= 2 else {
            return
        }
        var primes = [Bool](repeating: true, count: max+1)
        primes[0] = false
        primes[1] = false
        
        self.alternateStage = false
        
        for number in 2...Int(sqrt(Double(max))) {
            if primes[number] {
                do{
                    for multiple in stride(from: number*number, through: max, by: number) {
                        try Task.checkCancellation()
                        primes[multiple] = false
                    }
                    
                } catch {
                    return
                }
            }
            
            self.current = number
            self.progress = Double(self.current) / sqrt(Double(max))
            
        }
        
        self.current = 0
        self.progress = 0
        
        var localCurrent = self.current
        var primesFiltered: [Int] = []
//        var primesFiltered = [Int](repeating: 0, count: max)
        
        self.alternateStage = true
        
        for (i,v) in primes.enumerated() {
            do{
                try Task.checkCancellation()
                await Task.yield()
//                
                if Double(i-localCurrent)/Double(max) > 1.0/100.0{
                    localCurrent = i
                    self.current = i
                    self.progress = Double(self.current)/Double(max)
                }
                
                if v { primesFiltered.append(i) }
            } catch {
                return
            }
        }
        
        self.last = primesFiltered.suffix(5)
        self.count = primesFiltered.count
        self.busy = false
    }
    
    func bruteForceRun() async {
        
        guard let max = self.workingMax else {return}
        
        var primes: [Int] = []
        primes.reserveCapacity(Int(sqrt(Double(max))))
        self.progress = 0;
        
        for i in 2...max {
            if self.isPrime(i){
                do {
                    try Task.checkCancellation()
                    primes.append(i)
                    self.progress = Double(i)/Double(max)
                } catch {
                    break
                }
            }
        }
                
        self.last = primes.suffix(5)
        self.count = primes.count
        
        finishedPrimes(found: self.count)
        
    }
    
    func isPrime(_ n: Int) -> Bool {
        if n<2 {
            return false
        } else {
            for i in 2..<n {
                guard let _ = try? Task.checkCancellation() else {return false}
                if n%i==0 {
                    return false
                }
            }
            return true
        }
    }
    enum PrimeResultError: Error {
        case missingValues
    }
}

enum PrimeFinderMethod: String, CaseIterable {
    case bruteForce
    case sieve
    case random
}


import UserNotifications
func finishedPrimes(found primes: Int) {
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .badge], completionHandler: {granted, error in
        if error != nil {
            print(error as Any)
        } else if granted {
            let content = UNMutableNotificationContent()
            content.title = "Primefinder done!"
            content.body = "I have found \(primes) primes"
            content.sound = .default
            //    content.badge = .init(integerLiteral: primes)
            content.badge = .init(integerLiteral: 1)
            
            let request = UNNotificationRequest.init(identifier: UUID().uuidString, content: content, trigger: nil)
            center.add(request)
        }
    })
}
