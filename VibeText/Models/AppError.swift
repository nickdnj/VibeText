import Foundation

// MARK: - Core Error Types

/// Represents all possible errors in the VibeText app
enum AppError: LocalizedError, Equatable {
    // Network & API Errors
    case networkUnreachable
    case apiTimeout
    case apiError(statusCode: Int, message: String)
    case invalidAPIResponse
    case noAPIKey
    case apiKeyInvalid
    
    // Audio & Recording Errors
    case microphonePermissionDenied
    case speechRecognitionNotAuthorized
    case audioSessionInterrupted
    case recordingFailed
    case transcriptionFailed
    case audioSessionConfigurationFailed
    
    // User Cancellation
    case userCancelled
    
    // System Errors
    case systemInterruption
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkUnreachable:
            return "No internet connection. Please check your network and try again."
        case .apiTimeout:
            return "Request timed out. Please try again."
        case .apiError(let statusCode, let message):
            return "API Error (\(statusCode)): \(message)"
        case .invalidAPIResponse:
            return "Received an invalid response from the server. Please try again."
        case .noAPIKey:
            return "No API key configured. Please add your OpenAI API key in settings."
        case .apiKeyInvalid:
            return "Invalid API key. Please check your OpenAI API key in settings."
        case .microphonePermissionDenied:
            return "Microphone permission is required for voice recording. Please enable it in Settings."
        case .speechRecognitionNotAuthorized:
            return "Speech recognition permission is required. Please enable it in Settings."
        case .audioSessionInterrupted:
            return "Recording was interrupted. Please try again."
        case .recordingFailed:
            return "Failed to start recording. Please try again."
        case .transcriptionFailed:
            return "Failed to transcribe audio. Please try again."
        case .audioSessionConfigurationFailed:
            return "Failed to configure audio session. Please try again."
        case .userCancelled:
            return "Operation was cancelled."
        case .systemInterruption:
            return "Recording was interrupted by the system. Please try again."
        case .unknownError(let message):
            return "An unexpected error occurred: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkUnreachable:
            return "Check your internet connection and try again."
        case .apiTimeout, .apiError, .invalidAPIResponse:
            return "The server may be busy. Please try again in a moment."
        case .noAPIKey, .apiKeyInvalid:
            return "Go to Settings and add your OpenAI API key."
        case .microphonePermissionDenied, .speechRecognitionNotAuthorized:
            return "Go to Settings > Privacy & Security > Microphone/Speech Recognition and enable VibeText."
        case .audioSessionInterrupted, .recordingFailed, .transcriptionFailed, .audioSessionConfigurationFailed:
            return "Try recording again. If the problem persists, restart the app."
        case .userCancelled:
            return nil
        case .systemInterruption:
            return "Try recording again after the interruption ends."
        case .unknownError:
            return "Please try again. If the problem persists, restart the app."
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .networkUnreachable, .apiTimeout, .apiError, .invalidAPIResponse:
            return true
        case .audioSessionInterrupted, .recordingFailed, .transcriptionFailed, .audioSessionConfigurationFailed, .systemInterruption:
            return true
        case .userCancelled:
            return false
        case .noAPIKey, .apiKeyInvalid, .microphonePermissionDenied, .speechRecognitionNotAuthorized:
            return false
        case .unknownError:
            return true
        }
    }
    
    var shouldShowAlert: Bool {
        switch self {
        case .userCancelled:
            return false
        default:
            return true
        }
    }
}

// MARK: - Error Categories

/// Categorizes errors for UI presentation
enum ErrorCategory {
    case network
    case permissions
    case audio
    case api
    case user
    case system
    
    var icon: String {
        switch self {
        case .network: return "wifi.slash"
        case .permissions: return "lock.shield"
        case .audio: return "mic.slash"
        case .api: return "exclamationmark.triangle"
        case .user: return "xmark.circle"
        case .system: return "exclamationmark.triangle"
        }
    }
    
    var color: String {
        switch self {
        case .network: return "orange"
        case .permissions: return "red"
        case .audio: return "red"
        case .api: return "orange"
        case .user: return "gray"
        case .system: return "orange"
        }
    }
}

extension AppError {
    var category: ErrorCategory {
        switch self {
        case .networkUnreachable, .apiTimeout, .apiError, .invalidAPIResponse:
            return .network
        case .microphonePermissionDenied, .speechRecognitionNotAuthorized:
            return .permissions
        case .audioSessionInterrupted, .recordingFailed, .transcriptionFailed, .audioSessionConfigurationFailed:
            return .audio
        case .noAPIKey, .apiKeyInvalid:
            return .api
        case .userCancelled:
            return .user
        case .systemInterruption, .unknownError:
            return .system
        }
    }
}

// MARK: - Error Handling Utilities

/// Utilities for error handling and user feedback
struct ErrorHandler {
    static func handle(_ error: AppError, in viewModel: any ErrorHandling) {
        DispatchQueue.main.async {
            viewModel.setError(error)
        }
    }
    
    static func clearError(in viewModel: any ErrorHandling) {
        DispatchQueue.main.async {
            viewModel.clearError()
        }
    }
    
    static func isRetryable(_ error: AppError) -> Bool {
        return error.isRetryable
    }
    
    static func shouldShowAlert(_ error: AppError) -> Bool {
        return error.shouldShowAlert
    }
}

// MARK: - Error Handling Protocol

/// Protocol for view models that need error handling
protocol ErrorHandling: AnyObject {
    var currentError: AppError? { get set }
    var isProcessing: Bool { get set }
    
    func setError(_ error: AppError)
    func clearError()
    func retry()
}

extension ErrorHandling {
    func setError(_ error: AppError) {
        currentError = error
        isProcessing = false
    }
    
    func clearError() {
        currentError = nil
    }
} 