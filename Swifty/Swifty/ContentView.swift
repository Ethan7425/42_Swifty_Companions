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
        LinearGradient(
            colors: [
                Color(red: 0.97, green: 0.96, blue: 0.94),
                Color(red: 0.91, green: 0.93, blue: 0.96)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color.white.opacity(0.6))
                .frame(width: 320, height: 320)
                .blur(radius: 12)
                .offset(x: 140, y: -180)
        }
        .ignoresSafeArea()
    }

    private var loginView: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text("42 Swifty Companions")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.9))

                Text("Enter a 42 login to fetch the profile, level, skills, and projects.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(.black.opacity(0.55))
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
                    .foregroundStyle(Color(red: 0.68, green: 0.15, blue: 0.15))
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        Color.white.opacity(0.76),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
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
                    Color.black.opacity(0.92),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
            }
            .buttonStyle(.plain)
            .disabled(isLoading)

            Text("The app reuses the cached OAuth token until it expires, so it does not create a token for each search.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.black.opacity(0.5))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(28)
        .frame(maxWidth: 440)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(.white.opacity(0.8), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 30, x: 0, y: 18)
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
                .foregroundStyle(.black.opacity(0.55))

            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundStyle(.black.opacity(0.45))
                    .frame(width: 18)

                TextField(prompt, text: $text)
                    .autocorrectionDisabled()
                    .onChange(of: text) { _, newValue in
                        guard enforcesLowercase else { return }

                        let normalizedValue = newValue.lowercased()
                        if normalizedValue != newValue {
                            text = normalizedValue
                        }
                    }
                    .foregroundColor(.black.opacity(0.9))
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

#Preview {
    ContentView()
}
