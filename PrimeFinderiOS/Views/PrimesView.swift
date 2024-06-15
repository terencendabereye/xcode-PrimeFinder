//
//  ParametersFormView.swift
//  PrimeFinder
//
//  Created by Terence  Ndabereye  on 19/05/2024.
//

import SwiftUI
import Foundation

struct PrimesView: View {

    @State var maxPrime: Int = 5000000
    @State var selectedMethod: PrimeFinderMethod = .sieve
    @State var results = PrimeResults(busy: false);
    @State private var cancellableTask: Task<Void, Never>? = nil
    @FocusState var focusField: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Parameters"){
                    TextField("Up to", value: $maxPrime, format: .number)
                        .keyboardType(.numberPad)
                        .focused($focusField)
                        .scrollDismissesKeyboard(.immediately)
                    Picker("Prime finding method", selection: $selectedMethod) {
                        ForEach(PrimeFinderMethod.allCases, id: \.self) { item in
                            Text(String(describing: item))
                        }
                    }
                    .pickerStyle(.automatic)
                    

                    
                    HStack {
                        Button("Run") {
                            cancellableTask = Task {
                                focusField = false
                                results.busy = true
                                results.workingMax = maxPrime
                                
                                switch (selectedMethod) {
                                case .bruteForce:
                                    await results.bruteForceRun()
                                case .sieve:
                                    await results.sieve()
                                default:
                                    break
                                }
                                
                                results.busy = false
                                
                            }
                            
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(results.busy)
                        .keyboardShortcut(.defaultAction)
                        .foregroundStyle((!results.busy) ? .accent : .secondary)
                        
                        Spacer()
                        
                        Button("Cancel") {
                            if let newCancellableTask = cancellableTask {
                                newCancellableTask.cancel()
                                cancellableTask = nil
                            }
                        }
                        .disabled(!results.busy)
                        .buttonStyle(PlainButtonStyle())
                        .foregroundStyle((results.busy) ? .accent : .secondary)
                        
                        Spacer()
                        
                        VStack {
                            if results.alternateStage{
                                Gauge(value: results.progress, label: {
                                    Text(String(format: "%.1f", results.progress*100))
                                })
                                    .tint(.green)
                            } else {
    //                            ProgressView( value: Double(results.progress))
                                Gauge(value: results.progress, label: {
                                    Text(String(format: "%.1f", results.progress*100))
                                })
                                    .tint(.accentColor)
                            }
                        }
                        .sensoryFeedback(.success, trigger: results.busy)
                        .padding(.horizontal)
                        .gaugeStyle(.accessoryCircularCapacity)
                        .animation(.easeInOut(duration: 0.1), value: results.busy)
                        .opacity((results.busy) ? 1 : 0)
                        .scaleEffect(1)
                        
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .keyboard) {
                        Button("dismiss") { focusField = false }
                    }
                }
                

                Section("Results"){
                    LabeledContent("Current max", value: "\(results.workingMax ?? -1)")
                    LabeledContent("Count", value: "\(String(describing: results.count))")
                    LabeledContent("Last", value: "\(results.last)")
                }
            }
            .navigationTitle("Prime Finder")
        }

    }
}

#Preview {
    PrimesView()
}
