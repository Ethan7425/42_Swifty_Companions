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
        Color(red: 0.06, green: 0.07, blue: 0.08)
        .ignoresSafeArea()
    }

    private var loginView: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 10) {
                Text("42 Project")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.00, green: 0.73, blue: 0.58))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.00, green: 0.73, blue: 0.58).opacity(0.14), in: Capsule())

                Text("42 Swifty Companions")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Search a 42 login to display the profile, skills, achievements, project grades and various other infos.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
                    .fixedSize(horizontal: false, vertical: true)
            }

            InputField(
                title: "42 Login",
                text: $login,
                prompt: "for example: etbernar",
                systemImage: "person.text.rectangle",
                enforcesLowercase: true
            )

            if let errorMessage {
                Text(errorMessage)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 1.00, green: 0.77, blue: 0.77))
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        Color.white.opacity(0.04),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.red.opacity(0.18), lineWidth: 1)
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
                .foregroundStyle(Color.black.opacity(0.82))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .padding(.horizontal, 20)
                .background(
                    Color(red: 0.00, green: 0.73, blue: 0.58),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        }
        .padding(32)
        .frame(maxWidth: 460)
        .background(
            Color(red: 0.10, green: 0.11, blue: 0.12),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
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
                .foregroundStyle(.white.opacity(0.56))

            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundStyle(Color(red: 0.00, green: 0.73, blue: 0.58))
                    .frame(width: 18)

                TextField(
                    "",
                    text: $text,
                    prompt: Text(prompt)
                        .foregroundStyle(.white.opacity(0.34))
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
                Color.black.opacity(0.18),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            }
        }
    }
}

#Preview {
    ContentView()
}
