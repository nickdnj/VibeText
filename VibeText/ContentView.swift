//
//  ContentView.swift
//  VibeText
//
//  Created by Nick DeMarco on 7/10/25.
//

import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

#if targetEnvironment(simulator)
let isSimulator = true
#else
let isSimulator = false
#endif

struct Recording: Identifiable {
    let id = UUID()
    let timestamp: Date
    let title: String
    let fileURL: URL? // nil in simulator
    // For now, add a placeholder transcript
    var transcript: String = "Stream of consciousness transcript goes here."
}

struct ContentView: View {
    @State private var isRecording = false
    @State private var audioEngine: AVAudioEngine? = nil
    @State private var audioLevels: [Float] = Array(repeating: 0.0, count: 30)
    @State private var showPermissionAlert = false
    @State private var fakeWaveformTimer: Timer? = nil
    @State private var recordings: [Recording] = []
    @State private var selectedRecording: Recording? = nil
    @State private var showReview = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                // Waveform
                WaveformView(levels: audioLevels, isActive: isRecording)
                    .frame(height: 60)
                    .padding(.bottom, 16)
                // Mic Button
                Button(action: {
                    if isRecording {
                        stopRecording()
                    } else {
                        if isSimulator {
                            startFakeRecording()
                        } else {
                            requestMicPermissionAndStart()
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red : Color.blue)
                            .frame(width: 100, height: 100)
                            .shadow(radius: isRecording ? 16 : 8)
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 40, weight: .bold))
                    }
                }
                .accessibilityLabel(isRecording ? "Stop Recording" : "Start Recording")
                Text(isRecording ? "Recording..." : "Tap to record")
                    .font(.headline)
                // Recent Recordings List
                if !recordings.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Recordings")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 16)
                        ForEach(recordings.sorted(by: { $0.timestamp > $1.timestamp })) { rec in
                            HStack {
                                Image(systemName: "waveform")
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading) {
                                    Text(rec.title)
                                        .font(.body)
                                    Text(Self.fullDateFormatter.string(from: rec.timestamp))
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Button(action: {
                                    selectedRecording = rec
                                    showReview = true
                                }) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.accentColor)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.horizontal)
                }
                Spacer()
            }
            .padding()
            .alert("Microphone access is required to record audio.", isPresented: $showPermissionAlert) {
                Button("OK", role: .cancel) {}
            }
            .background(
                NavigationLink(
                    destination: Group {
                        if let rec = selectedRecording {
                            StudioView(recording: rec)
                        }
                    },
                    isActive: $showReview
                ) { EmptyView() }
                .hidden()
            )
            .navigationTitle("VibeText")
        }
    }
    
    // Simulator: Animate waveform with random data
    func startFakeRecording() {
        isRecording = true
        fakeWaveformTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            let randomLevel = Float.random(in: 0.1...1.0)
            audioLevels.append(randomLevel)
            if audioLevels.count > 30 {
                audioLevels.removeFirst()
            }
        }
    }
    
    func stopFakeRecording() {
        isRecording = false
        fakeWaveformTimer?.invalidate()
        fakeWaveformTimer = nil
        audioLevels = Array(repeating: 0.0, count: 30)
        // Add a placeholder recording
        let rec = Recording(timestamp: Date(), title: "Sim Recording", fileURL: nil)
        recordings.append(rec)
    }
    
    func requestMicPermissionAndStart() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    actuallyStartRecording()
                } else {
                    showPermissionAlert = true
                }
            }
        }
    }
    
    func actuallyStartRecording() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
            return
        }
        isRecording = true
        audioEngine = AVAudioEngine()
        let inputNode = audioEngine!.inputNode
        let bus = 0
        let format = inputNode.inputFormat(forBus: bus)
        inputNode.installTap(onBus: bus, bufferSize: 1024, format: format) { buffer, _ in
            let channelData = buffer.floatChannelData?[0]
            let channelDataValue = stride(from: 0,
                                          to: Int(buffer.frameLength),
                                          by: buffer.stride).map { channelData?[$0] ?? 0 }
            let rms = sqrt(channelDataValue.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
            let level = max(0, min(1, rms * 20))
            DispatchQueue.main.async {
                audioLevels.append(level)
                if audioLevels.count > 30 {
                    audioLevels.removeFirst()
                }
            }
        }
        do {
            try audioEngine?.start()
        } catch {
            print("AudioEngine error: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        if isSimulator {
            stopFakeRecording()
        } else {
            isRecording = false
            audioEngine?.inputNode.removeTap(onBus: 0)
            audioEngine?.stop()
            audioEngine = nil
            audioLevels = Array(repeating: 0.0, count: 30)
            // Add a placeholder for now (later: save file URL)
            let rec = Recording(timestamp: Date(), title: "Recording", fileURL: nil)
            recordings.append(rec)
        }
    }
    
    static let fullDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        return df
    }()
}

struct StudioView: View {
    let recording: Recording
    @State private var transcript: String
    @State private var outputText: String
    @State private var showTranscript = true
    @State private var showTones = true
    @State private var showChat = false
    @State private var chatInput: String = ""
    @State private var chatHistory: [String] = []
    @State private var showShareSheet = false
    
    init(recording: Recording) {
        self.recording = recording
        _transcript = State(initialValue: recording.transcript)
        _outputText = State(initialValue: recording.transcript)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Collapsible Transcript Section
                Section {
                    DisclosureGroup(isExpanded: $showTranscript) {
                        TextEditor(text: $transcript)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(LinearGradient(gradient: Gradient(colors: [Color.mint.opacity(0.15), Color.blue.opacity(0.10)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.mint, lineWidth: 1))
                            .animation(.easeInOut, value: showTranscript)
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundColor(.mint)
                            Text("Transcript")
                                .font(.headline)
                                .foregroundColor(.mint)
                        }
                    }
                }
                // Output/Note Canvas (Always Visible)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("Your Vibe Message")
                            .font(.headline)
                            .foregroundColor(.purple)
                        Spacer()
                        // Copy and Share Buttons
                        HStack(spacing: 12) {
                            Button(action: {
                                UIPasteboard.general.string = outputText
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.purple)
                                    .help("Copy to Clipboard")
                            }
                            Button(action: {
                                showShareSheet = true
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.purple)
                                    .help("Share Message")
                            }
                        }
                    }
                    TextEditor(text: $outputText)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.10), Color.indigo.opacity(0.10)]), startPoint: .top, endPoint: .bottom))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.purple, lineWidth: 1))
                        .font(.body)
                }
                // Collapsible Tone Transformation Buttons (fixed for scroll)
                DisclosureGroup(isExpanded: $showTones) {
                    ScrollView(.horizontal, showsIndicators: true) {
                        HStack(spacing: 12) {
                            ForEach(Self.tonePresets, id: \ .self) { tone in
                                Button(action: {
                                    // Placeholder: transform outputText based on tone
                                    outputText = "[\(tone)] " + transcript
                                }) {
                                    Text(tone)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 10)
                                        .background(LinearGradient(gradient: Gradient(colors: [Color.cyan.opacity(0.25), Color.mint.opacity(0.25)]), startPoint: .top, endPoint: .bottom))
                                        .foregroundColor(.cyan)
                                        .font(.subheadline.bold())
                                        .cornerRadius(18)
                                        .shadow(color: .mint.opacity(0.15), radius: 2, x: 0, y: 2)
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .padding(.horizontal, 4)
                    }
                    .padding(.vertical, 4)
                } label: {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.cyan)
                        Text("Tone Presets")
                            .font(.headline)
                            .foregroundColor(.cyan)
                    }
                }
                // Collapsible Chat Interface (leave as is)
                Section {
                    DisclosureGroup(isExpanded: $showChat) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(chatHistory, id: \ .self) { msg in
                                HStack(alignment: .top) {
                                    Image(systemName: "bubble.left")
                                        .foregroundColor(.orange)
                                    Text(msg)
                                        .padding(6)
                                        .background(Color.orange.opacity(0.10))
                                        .cornerRadius(8)
                                }
                            }
                            HStack {
                                TextField("Type a message or instruction...", text: $chatInput)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Button(action: {
                                    if !chatInput.isEmpty {
                                        chatHistory.append(chatInput)
                                        // Placeholder: simulate AI response
                                        outputText = "[AI] " + chatInput + "\n" + outputText
                                        chatInput = ""
                                    }
                                }) {
                                    Image(systemName: "paperplane.fill")
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    } label: {
                        HStack {
                            Image(systemName: "ellipsis.bubble")
                                .foregroundColor(.orange)
                            Text("AI Chat")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .background(LinearGradient(gradient: Gradient(colors: [Color.white, Color.mint.opacity(0.08), Color.blue.opacity(0.05)]), startPoint: .top, endPoint: .bottom))
        .navigationTitle("Studio")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: [outputText])
        }
    }
    
    static let tonePresets = [
        "Gen Z", "Millennial", "Boomer", "Professional", "Polite", "Friendly"
    ]
}

struct WaveformView: View {
    let levels: [Float]
    let isActive: Bool
    
    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: 2) {
                ForEach(levels.indices, id: \ .self) { i in
                    Capsule()
                        .fill(isActive ? Color.green : Color.gray.opacity(0.4))
                        .frame(width: (geo.size.width / CGFloat(levels.count)) - 2,
                               height: max(8, CGFloat(levels[i]) * geo.size.height))
                        .animation(.linear(duration: 0.1), value: levels[i])
                }
            }
        }
    }
}

// UIKit wrapper for share sheet
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ContentView()
}
