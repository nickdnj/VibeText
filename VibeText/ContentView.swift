//
//  ContentView.swift
//  VibeText
//
//  Created by Nick DeMarco on 7/29/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var messageFormatter: MessageFormatter
    @StateObject private var voiceCaptureViewModel: VoiceCaptureViewModel
    
    init() {
        let settings = SettingsManager()
        let speech = SpeechManager()
        let formatter = MessageFormatter(settingsManager: settings)
        let viewModel = VoiceCaptureViewModel(
            speechManager: speech,
            messageFormatter: formatter,
            settingsManager: settings
        )
        
        self._settingsManager = StateObject(wrappedValue: settings)
        self._speechManager = StateObject(wrappedValue: speech)
        self._messageFormatter = StateObject(wrappedValue: formatter)
        self._voiceCaptureViewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("VibeText")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Transform your voice into perfect messages")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Voice Capture Interface
                VStack(spacing: 30) {
                    // Microphone Button
                    Button(action: {
                        if speechManager.isRecording {
                            voiceCaptureViewModel.stopRecording()
                            Task {
                                await voiceCaptureViewModel.processTranscript()
                            }
                        } else {
                            voiceCaptureViewModel.startRecording()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(speechManager.isRecording ? Color.red : Color.blue)
                                .frame(width: 120, height: 120)
                                .shadow(radius: 10)
                            
                            Image(systemName: speechManager.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .scaleEffect(speechManager.isRecording ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: speechManager.isRecording)
                    
                    // Recording Status
                    if speechManager.isRecording {
                        VStack(spacing: 8) {
                            Text("Recording...")
                                .font(.headline)
                                .foregroundColor(.red)
                            
                            // Simple waveform animation
                            HStack(spacing: 4) {
                                ForEach(0..<5, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.red)
                                        .frame(width: 4, height: 20)
                                        .scaleEffect(y: Double.random(in: 0.3...1.0))
                                        .animation(.easeInOut(duration: 0.5).repeatForever(), value: UUID())
                                }
                            }
                        }
                    } else {
                        Text("Tap to start recording")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Transcript Display
                if !speechManager.transcript.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Transcript:")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(speechManager.transcript)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                
                // Error Display
                if let errorMessage = voiceCaptureViewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Settings Button
                NavigationLink(destination: SettingsView(settingsManager: settingsManager)) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $voiceCaptureViewModel.showReview) {
            if let message = voiceCaptureViewModel.currentMessage {
                MessageReviewView(
                    message: message,
                    viewModel: voiceCaptureViewModel
                )
            }
        }
    }
}

#Preview {
    ContentView()
}
