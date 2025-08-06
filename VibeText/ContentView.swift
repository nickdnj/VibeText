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
    @State private var showSettings = false
    
    init() {
        let settings = SettingsManager()
        let speech = SpeechManager()
        let formatter = MessageFormatter()
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
                            print("🛑 User tapped stop recording")
                            voiceCaptureViewModel.stopRecording()
                        } else {
                            print("🎤 User tapped start recording")
                            voiceCaptureViewModel.startRecording()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(buttonColor)
                                .frame(width: 120, height: 120)
                                .shadow(radius: 10)
                            
                            Image(systemName: buttonIcon)
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .scaleEffect(speechManager.isRecording ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: speechManager.isRecording)
                    .disabled(voiceCaptureViewModel.isProcessing || speechManager.isTranscribing)
                    
                    // Status Display
                    VStack(spacing: 8) {
                        Text(statusText)
                            .font(.headline)
                            .foregroundColor(statusColor)
                        
                        if speechManager.isRecording {
                            // Animated waveform for visual feedback
                            WaveformView()
                            
                            // Recording duration
                            Text(formatRecordingDuration(speechManager.recordingDuration))
                                .font(.caption)
                                .foregroundColor(speechManager.recordingDuration >= 240 ? .orange : .secondary) // Warning at 4 minutes
                                .fontWeight(speechManager.recordingDuration >= 240 ? .semibold : .regular)
                                
                            // Simple recording indicator text
                            Text("Recording in progress...")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .padding(.top, 8)
                        } else if speechManager.isTranscribing {
                            // Transcription indicator
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Transcribing...")
                                    .font(.subheadline)
                            }
                        } else if voiceCaptureViewModel.isProcessing {
                            // Processing indicator
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Processing...")
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                
                // Error Display
                if let error = voiceCaptureViewModel.currentError {
                    Text(error.localizedDescription)
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
        .errorOverlay(
            error: $voiceCaptureViewModel.currentError,
            onRetry: {
                voiceCaptureViewModel.retry()
            }
        )
    }
    
    // MARK: - Computed Properties
    
    private var buttonColor: Color {
        if speechManager.isRecording {
            return .red
        } else if voiceCaptureViewModel.isProcessing || speechManager.isTranscribing {
            return .gray
        } else {
            return .blue
        }
    }
    
    private var buttonIcon: String {
        if speechManager.isRecording {
            return "stop.fill"
        } else {
            return "mic.fill"
        }
    }
    
    private var statusText: String {
        if speechManager.isRecording {
            return "Recording..."
        } else if speechManager.isTranscribing {
            return "Transcribing..."
        } else if voiceCaptureViewModel.isProcessing {
            return "Processing..."
        } else {
            return "Tap to start recording"
        }
    }
    
    private var statusColor: Color {
        if speechManager.isRecording {
            return .red
        } else if speechManager.isTranscribing {
            return .orange
        } else if voiceCaptureViewModel.isProcessing {
            return .blue
        } else {
            return .secondary
        }
    }
}

// MARK: - Helper Functions

private func formatRecordingDuration(_ duration: TimeInterval) -> String {
    let minutes = Int(duration) / 60
    let seconds = Int(duration) % 60
    return String(format: "%02d:%02d", minutes, seconds)
}

// MARK: - WaveformView

struct WaveformView: View {
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<7, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.red)
                    .frame(width: 3, height: 20)
                    .scaleEffect(y: waveformHeight(for: index), anchor: .bottom)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.1),
                        value: animationPhase
                    )
            }
        }
        .onAppear {
            animationPhase = 1
        }
    }
    
    private func waveformHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 0.3
        let maxHeight: CGFloat = 1.0
        
        // Create a wave pattern
        let wave = sin(Double(index) * 0.8 + animationPhase * 2 * .pi)
        return baseHeight + (maxHeight - baseHeight) * CGFloat(abs(wave))
    }
}

#Preview {
    ContentView()
}
