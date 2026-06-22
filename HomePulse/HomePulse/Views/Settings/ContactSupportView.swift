import SwiftUI

struct ContactSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSubject: SupportSubject = .general
    @State private var customSubject: String = ""
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var message: String = ""
    @State private var isSubmitting = false
    @State private var submitResult: FeedbackResult?

    private let contactService = ContactSupportService.shared

    private var effectiveSubject: String {
        if selectedSubject == .other {
            return customSubject.isEmpty ? "Other" : customSubject
        }
        return selectedSubject.displayName
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    subjectSection
                    nameSection
                    emailSection
                    messageSection
                    submitButton
                }
                .padding()
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Contact Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var subjectSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Subject")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(SupportSubject.allCases, id: \.self) { subject in
                    Button(action: { selectedSubject = subject }) {
                        Text(subject.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedSubject == subject ? Color.accentColor : Color(.secondarySystemBackground))
                            .foregroundStyle(selectedSubject == subject ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }

            if selectedSubject == .other {
                TextField("Specify subject", text: $customSubject)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Name")
                .font(.headline)
            TextField("Your name", text: $name)
                .textFieldStyle(.roundedBorder)
                .textContentType(.name)
        }
    }

    private var emailSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email")
                .font(.headline)
            TextField("you@example.com", text: $email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled()
        }
    }

    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Message")
                .font(.headline)
            TextEditor(text: $message)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var submitButton: some View {
        VStack(spacing: 12) {
            Button(action: submitFeedback) {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isSubmitting ? "Sending..." : "Submit Feedback")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canSubmit ? Color.accentColor : Color.secondary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canSubmit || isSubmitting)

            if let result = submitResult {
                if result.success {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.green)
                        Text("Feedback submitted. Thank you!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Done") { dismiss() }
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding()
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title)
                            .foregroundStyle(.orange)
                        Text(result.errorMessage ?? "Unknown error")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
        }
    }

    private var canSubmit: Bool {
        !name.isEmpty && !email.isEmpty && !message.isEmpty && email.contains("@")
    }

    private func submitFeedback() {
        isSubmitting = true
        submitResult = nil

        Task {
            let result = await contactService.submitFeedback(
                name: name,
                email: email,
                subject: effectiveSubject,
                message: message
            )
            isSubmitting = false
            submitResult = result
        }
    }
}

enum SupportSubject: CaseIterable {
    case general
    case featureSuggestion
    case bugReport
    case usageQuestion
    case performanceIssue
    case uiImprovement
    case other

    var displayName: String {
        switch self {
        case .general: return "General"
        case .featureSuggestion: return "Feature"
        case .bugReport: return "Bug Report"
        case .usageQuestion: return "Question"
        case .performanceIssue: return "Performance"
        case .uiImprovement: return "UI"
        case .other: return "Other"
        }
    }
}
