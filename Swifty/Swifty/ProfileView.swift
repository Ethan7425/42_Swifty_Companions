//
//  ProfileView.swift
//  Swifty
//
//  Created by Ethan on 20.04.2026.
//

import SwiftUI

struct ProfileView: View {
    let profile: FortyTwoUser
    let onBack: () -> Void

    private var primaryCursus: FortyTwoCursusUser? {
        profile.cursusUsers.first(where: { $0.endAt == nil }) ?? profile.cursusUsers.first
    }

    private var completedProjects: [FortyTwoProjectUser] {
        profile.projectsUsers.filter { $0.validated == true }
    }

    private var failedProjects: [FortyTwoProjectUser] {
        profile.projectsUsers.filter { $0.validated == false }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Button(action: onBack) {
                        Label("Back", systemImage: "chevron.left")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.82))
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }

                HStack(alignment: .center, spacing: 18) {
                    profileImage

                    VStack(alignment: .leading, spacing: 6) {
                        Text(profile.displayName)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.96))

                        Text("@\(profile.login)")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(red: 0.79, green: 0.83, blue: 1.00).opacity(0.68))
                    }
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
                    DetailCard(title: "Login", value: profile.login)
                    DetailCard(title: "Email", value: profile.email ?? "Unavailable")
                    DetailCard(title: "Mobile", value: profile.phone ?? "Unavailable")
                    DetailCard(title: "Location", value: profile.location ?? "Unavailable")
                    DetailCard(title: "Wallet", value: "\(profile.wallet ?? 0)")
                    DetailCard(title: "Level", value: formattedLevel(primaryCursus?.level))
                }

                if let skills = primaryCursus?.skills, !skills.isEmpty {
                    SectionCard(title: "Skills") {
                        VStack(spacing: 12) {
                            ForEach(skills) { skill in
                                SkillRow(skill: skill)
                            }
                        }
                    }
                } else {
                    SectionCard(title: "Skills") {
                        EmptyStateRow(text: "No skills available for this user.")
                    }
                }

                SectionCard(title: "Achievements") {
                    if profile.achievements.isEmpty {
                        EmptyStateRow(text: "No achievements found.")
                    } else {
                        VStack(spacing: 12) {
                            ForEach(profile.achievements) { achievement in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(achievement.name)
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.9))

                                    if let description = achievement.description, !description.isEmpty {
                                        Text(description)
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.56))
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(
                                    Color.white.opacity(0.06),
                                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(Color(red: 0.58, green: 0.52, blue: 1.00).opacity(0.10), lineWidth: 1)
                                }
                            }
                        }
                    }
                }

                SectionCard(title: "Completed Projects") {
                    if completedProjects.isEmpty {
                        EmptyStateRow(text: "No completed projects found.")
                    } else {
                        VStack(spacing: 12) {
                            ForEach(completedProjects) { project in
                                ProjectRow(project: project, accent: Color(red: 0.16, green: 0.48, blue: 0.30))
                            }
                        }
                    }
                }

                SectionCard(title: "Failed Projects") {
                    if failedProjects.isEmpty {
                        EmptyStateRow(text: "No failed projects found.")
                    } else {
                        VStack(spacing: 12) {
                            ForEach(failedProjects) { project in
                                ProjectRow(project: project, accent: Color(red: 0.70, green: 0.24, blue: 0.22))
                            }
                        }
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: 820, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.10),
                        Color(red: 0.09, green: 0.08, blue: 0.22).opacity(0.76)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 32, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.32), radius: 30, x: 0, y: 18)
            .shadow(color: Color(red: 0.42, green: 0.28, blue: 0.98).opacity(0.12), radius: 40, x: 0, y: 0)
            .padding(.vertical, 24)
        }
        .scrollIndicators(.hidden)
    }

    private var profileImage: some View {
        Group {
            if let imageURL = profile.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        fallbackImage
                    case .empty:
                        ProgressView()
                            .tint(.white.opacity(0.8))
                    @unknown default:
                        fallbackImage
                    }
                }
            } else {
                fallbackImage
            }
        }
        .frame(width: 88, height: 88)
        .clipShape(Circle())
    }

    private var fallbackImage: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.23, green: 0.18, blue: 0.52),
                            Color(red: 0.16, green: 0.50, blue: 0.98)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: "person.fill")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(.white.opacity(0.95))
        }
    }

    private func formattedLevel(_ level: Double?) -> String {
        guard let level else { return "Unavailable" }
        return String(format: "%.2f", level)
    }
}

private struct DetailCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 0.78, green: 0.82, blue: 1.00).opacity(0.62))

            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.94))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            Color.white.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))

            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.white.opacity(0.07),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(red: 0.58, green: 0.52, blue: 1.00).opacity(0.10), lineWidth: 1)
        }
    }
}

private struct SkillRow: View {
    let skill: FortyTwoSkill

    private var percentage: Int {
        Int((skill.level.truncatingRemainder(dividingBy: 1)) * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(skill.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))

                Spacer()

                Text("Lv \(String(format: "%.2f", skill.level))")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.76, green: 0.80, blue: 1.00).opacity(0.62))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(Color.white.opacity(0.08))

                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.43, green: 0.30, blue: 0.98),
                                    Color(red: 0.19, green: 0.55, blue: 1.00)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: proxy.size.width * CGFloat(max(skill.level.truncatingRemainder(dividingBy: 1), 0.05)))
                }
            }
            .frame(height: 8)

            Text("\(percentage)% to the next level")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.46))
        }
    }
}




private struct ProjectRow: View {
    let project: FortyTwoProjectUser
    let accent: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(project.project.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))

                Text(project.status ?? "No status")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.48))
            }

            Spacer()

            Text(project.finalMarkText)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(accent.opacity(0.12), in: Capsule())
        }
    }
}

private struct EmptyStateRow: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.54))
    }
}
