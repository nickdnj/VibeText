import SwiftUI

/// A comprehensive error alert view that displays errors with retry options
struct ErrorAlertView: View {
    let error: AppError
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Error Icon
            Image(systemName: error.category.icon)
                .font(.system(size: 48))
                .foregroundColor(Color(error.category.color))
                .padding(.bottom, 8)
            
            // Error Title
            Text(errorTitle)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            // Error Description
            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Recovery Suggestion
            if let recoverySuggestion = error.recoverySuggestion {
                Text(recoverySuggestion)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                // Retry Button (if retryable)
                if error.isRetryable {
                    Button(action: onRetry) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Retry")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                
                // Dismiss Button
                Button(action: onDismiss) {
                    Text(error.isRetryable ? "Cancel" : "OK")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding(.horizontal, 40)
    }
    
    private var errorTitle: String {
        switch error.category {
        case .network:
            return "Connection Error"
        case .permissions:
            return "Permission Required"
        case .audio:
            return "Audio Error"
        case .api:
            return "API Error"
        case .user:
            return "Operation Cancelled"
        case .system:
            return "System Error"
        }
    }
}

/// A modifier that shows an error alert when an error is present
struct ErrorAlertModifier: ViewModifier {
    @Binding var error: AppError?
    let onRetry: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: .constant(error != nil)) {
                if let error = error {
                    if error.isRetryable {
                        Button("Retry") {
                            onRetry()
                        }
                    }
                    Button("OK") {
                        self.error = nil
                    }
                }
            } message: {
                if let error = error {
                    Text(error.localizedDescription)
                }
            }
    }
}

/// A custom error overlay that shows a more detailed error view
struct ErrorOverlayModifier: ViewModifier {
    @Binding var error: AppError?
    let onRetry: () -> Void
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if let error = error {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                ErrorAlertView(
                    error: error,
                    onRetry: {
                        onRetry()
                        self.error = nil
                    },
                    onDismiss: {
                        self.error = nil
                    }
                )
            }
        }
    }
}

extension View {
    /// Shows an error alert when an error is present
    func errorAlert(error: Binding<AppError?>, onRetry: @escaping () -> Void) -> some View {
        modifier(ErrorAlertModifier(error: error, onRetry: onRetry))
    }
    
    /// Shows a custom error overlay when an error is present
    func errorOverlay(error: Binding<AppError?>, onRetry: @escaping () -> Void) -> some View {
        modifier(ErrorOverlayModifier(error: error, onRetry: onRetry))
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Sample Content")
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
    }
    .errorOverlay(
        error: .constant(.networkUnreachable),
        onRetry: { print("Retry tapped") }
    )
} 