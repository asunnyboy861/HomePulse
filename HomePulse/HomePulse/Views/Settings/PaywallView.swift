import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var isPurchasing = false
    @State private var purchaseError: String?

    private let githubUser = "asunnyboy861"
    private let appName = "HomePulse"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    featuresSection
                    pricingSection
                    legalSection
                }
                .padding()
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("HomePulse Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(Color.accentColor)

            Text("Unlock All Features")
                .font(.title2)
                .fontWeight(.bold)

            Text("Get the most out of HomePulse with historical charts, anomaly alerts, Live Activity, iCloud sync, and more.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            featureRow(icon: "chart.line.uptrend.xyaxis", title: "Historical Charts", description: "7-day and 30-day trends with min/max/avg stats")
            featureRow(icon: "bell.badge", title: "Anomaly Alerts", description: "Get notified when sensors cross your thresholds")
            featureRow(icon: "square.and.arrow.up", title: "CSV Export", description: "Export sensor history for analysis")
            featureRow(icon: "house.lodge", title: "Multi-Home Support", description: "Manage multiple homes or HA instances")
            featureRow(icon: "icloud", title: "iCloud Sync", description: "Sync settings across your devices")
            featureRow(icon: "iphone", title: "Lock Screen Widget", description: "Compact sensor display on lock screen")
            featureRow(icon: "waveform", title: "Live Activity", description: "Dynamic Island alerts for sensor anomalies")
            featureRow(icon: "thermostat", title: "Thermostat Control", description: "Adjust target temperature from the app")
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
        }
    }

    private var pricingSection: some View {
        VStack(spacing: 12) {
            if purchaseManager.isLoading {
                ProgressView("Loading options...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let error = purchaseManager.loadError {
                VStack(spacing: 8) {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                    Button("Retry") {
                        Task { await purchaseManager.loadProducts() }
                    }
                }
            } else {
                if let lifetime = purchaseManager.lifetimeProduct {
                    pricingCard(
                        product: lifetime,
                        title: "Lifetime",
                        subtitle: "One-time purchase. No recurring fees.",
                        isRecommended: true
                    )
                }

                if let yearly = purchaseManager.yearlyProduct {
                    pricingCard(
                        product: yearly,
                        title: "Yearly",
                        subtitle: "Renews annually. Cancel anytime.",
                        isRecommended: false
                    )
                }

                if let monthly = purchaseManager.monthlyProduct {
                    pricingCard(
                        product: monthly,
                        title: "Monthly",
                        subtitle: "Renews monthly. Cancel anytime.",
                        isRecommended: false
                    )
                }
            }

            Button(action: {
                Task { await purchaseManager.restorePurchases() }
            }) {
                Text("Restore Purchases")
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.top, 8)

            if let error = purchaseError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func pricingCard(product: Product, title: String, subtitle: String, isRecommended: Bool) -> some View {
        Button(action: {
            Task {
                isPurchasing = true
                purchaseError = nil
                let success = await purchaseManager.purchase(product)
                isPurchasing = false
                if success {
                    dismiss()
                } else if let error = purchaseManager.loadError {
                    purchaseError = error
                }
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                        if isRecommended {
                            Text("Recommended")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)
                    if isPurchasing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isRecommended ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing)
    }

    private var legalSection: some View {
        VStack(spacing: 8) {
            Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless canceled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscriptions in your App Store account settings after purchase.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Link("Privacy Policy", destination: URL(string: "https://\(githubUser).github.io/\(appName)/privacy.html")!)
                    .font(.caption2)
                    .foregroundStyle(Color.accentColor)
                Link("Terms of Use", destination: URL(string: "https://\(githubUser).github.io/\(appName)/terms.html")!)
                    .font(.caption2)
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.top, 4)

            Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                Text("Manage Subscriptions")
                    .font(.caption2)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.horizontal)
    }
}
