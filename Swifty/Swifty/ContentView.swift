//
//  ContentView.swift
//  Swifty
//
//  Created by Ethan on 20.04.2026.
//

import SwiftUI

struct ContentView: View {
    @State private var login = ""
    @State private var profile: FortyTwoUser?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            backgroundView

            Group {
                if let profile {
                    ProfileView(profile: profile) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.88)) {
                            self.profile = nil
                            errorMessage = nil
                        }
                    }
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )
                } else {
                    loginView
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            )
                        )
                }
            }
            .padding(.horizontal, 24)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.88), value: profile != nil)
    }

    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.12),
                    Color(red: 0.09, green: 0.07, blue: 0.22),
                    Color(red: 0.02, green: 0.06, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 0.52, green: 0.35, blue: 1.00).opacity(0.24))
                .frame(width: 360, height: 360)
                .blur(radius: 60)
                .offset(x: -130, y: -220)

            Circle()
                .fill(Color(red: 0.11, green: 0.62, blue: 1.00).opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(x: 170, y: -120)

            RoundedRectangle(cornerRadius: 44, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                .padding(18)
        }
        .ignoresSafeArea()
    }

    private var loginView: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("42 Swifty Companions")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.96))

                Text("Search a 42 login and surface the profile, level, skills, achievements, and projects in one clean view.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.68))
                    .fixedSize(horizontal: false, vertical: true)
            }

            InputField(
                title: "42 Login",
                text: $login,
                prompt: "for example: jdoe",
                systemImage: "person.text.rectangle",
                enforcesLowercase: true
            )

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 1.00, green: 0.72, blue: 0.84))
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        Color(red: 0.36, green: 0.10, blue: 0.25).opacity(0.36),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color(red: 1.00, green: 0.48, blue: 0.70).opacity(0.18), lineWidth: 1)
                    }
            }

            Button(action: fetchProfile) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Search Login")
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .padding(.horizontal, 20)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.28, green: 0.24, blue: 0.89),
                            Color(red: 0.39, green: 0.18, blue: 0.87),
                            Color(red: 0.18, green: 0.48, blue: 0.98)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                }
                .shadow(color: Color(red: 0.39, green: 0.18, blue: 0.87).opacity(0.38), radius: 18, x: 0, y: 10)
            }
            .buttonStyle(.plain)
            .disabled(isLoading)

            Text("The app reuses the cached OAuth token until it expires, so it does not create a token for each search.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.46))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(28)
        .frame(maxWidth: 440)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.12),
                    Color(red: 0.13, green: 0.11, blue: 0.25).opacity(0.72)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 32, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.34), radius: 30, x: 0, y: 18)
        .shadow(color: Color(red: 0.45, green: 0.32, blue: 1.00).opacity(0.12), radius: 40, x: 0, y: 0)
    }

    private func fetchProfile() {
        let trimmedLogin = login.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedLogin.isEmpty else {
            errorMessage = "Enter a 42 login before searching."
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let fetchedProfile = try await FortyTwoAPIClient.shared.fetchUser(login: trimmedLogin)
                await MainActor.run {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.88)) {
                        profile = fetchedProfile
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = FortyTwoAPIError.from(error).errorDescription
                }
            }

            await MainActor.run {
                isLoading = false
            }
        }
    }
}

private struct InputField: View {
    let title: String
    @Binding var text: String
    let prompt: String
    let systemImage: String
    var enforcesLowercase = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.58))

            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundStyle(Color(red: 0.68, green: 0.75, blue: 1.00).opacity(0.9))
                    .frame(width: 18)

                TextField(
                    "",
                    text: $text,
                    prompt: Text(prompt)
                        .foregroundStyle(.white.opacity(0.35))
                )
                    .autocorrectionDisabled()
                    .onChange(of: text) { _, newValue in
                        guard enforcesLowercase else { return }

                        let normalizedValue = newValue.lowercased()
                        if normalizedValue != newValue {
                            text = normalizedValue
                        }
                    }
                    .foregroundColor(.white.opacity(0.92))
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(
                Color.white.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(red: 0.61, green: 0.53, blue: 1.00).opacity(0.18), lineWidth: 1)
            }
        }
    }
}

#Preview {
    ContentView()
}
