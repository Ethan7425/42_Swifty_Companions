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

    // Current cursus used for the displayed level and skills.
    private var primaryCursus: FortyTwoCursusUser? {
        profile.cursusUsers.first(where: { $0.endAt == nil }) ?? profile.cursusUsers.first
    }

    // Projects grouped by validation result for separate sections.
    private var completedProjects: [FortyTwoProjectUser] {
        profile.projectsUsers.filter { $0.validated == true }
    }

    private var failedProjects: [FortyTwoProjectUser] {
        profile.projectsUsers.filter { $0.validated == false }
    }

    var body: some View {
        ScrollView {
            content
            .padding(28)
            .frame(maxWidth: 820, alignment: .leading)
            .background(
                Color(red: 0.10, green: 0.11, blue: 0.12),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
            .padding(.vertical, 24)
        }
        .scrollIndicators(.hidden)
    }

    // Main profile content shown inside the outer container.
    private var content: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            detailsGrid
            skillsSection
            achievementsSection
            completedProjectsSection
            failedProjectsSection
        }
    }

    // Header with navigation, avatar, display name, and login.
    private var header: some View {
        Group {
            HStack {
                Button(action: onBack) {
                    Label("Back", systemImage: "chevron.left")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.00, green: 0.73, blue: 0.58))
                }
                .buttonStyle(.plain)

                Spacer()
            }

            HStack(alignment: .center, spacing: 18) {
                profileImage

                VStack(alignment: .leading, spacing: 6) {
                    Text(profile.displayName)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("@\(profile.login)")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.62))
                }
            }
        }
    }

    // Summary cards for the main user infos
    private var detailsGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
            DetailCard(title: "Login", value: profile.login)
            DetailCard(title: "Email", value: profile.email ?? "Unavailable")
            DetailCard(title: "Wallet", value: "\(profile.wallet ?? 0)")
            DetailCard(title: "Level", value: formattedLevel(primaryCursus?.level))
        }
    }

    // Skills section
    @ViewBuilder
    private var skillsSection: some View {
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
    }

    // Achievement list
    private var achievementsSection: some View {
        SectionCard(title: "Achievements") {
            if profile.achievements.isEmpty {
                EmptyStateRow(text: "No achievements found.")
            } else {
                VStack(spacing: 12) {
                    ForEach(profile.achievements) { achievement in
                        AchievementRow(achievement: achievement)
                    }
                }
            }
        }
    }

    // Projects
    private var completedProjectsSection: some View {
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
    }

    // Projects Failed
    private var failedProjectsSection: some View {
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
                            .tint(Color(red: 0.00, green: 0.73, blue: 0.58))
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

    // Local placeholder shown when no profile image is available.
    private var fallbackImage: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.00, green: 0.73, blue: 0.58))

            Image(systemName: "person.fill")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(.black.opacity(0.78))
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
                .foregroundStyle(.white.opacity(0.48))

            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
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

private struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.black.opacity(0.18),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }
}

// Skill row
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
                    .foregroundStyle(.white)

                Spacer()

                Text("Lv \(String(format: "%.2f", skill.level))")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.56))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(Color.white.opacity(0.10))

                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(Color(red: 0.00, green: 0.73, blue: 0.58))
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


private struct AchievementRow: View {
    let achievement: FortyTwoAchievement

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(achievement.name)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            if let description = achievement.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.56))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            Color.black.opacity(0.16),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }
}

// Project row
private struct ProjectRow: View {
    let project: FortyTwoProjectUser
    let accent: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(project.project.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

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
                .background(accent.opacity(0.16), in: Capsule())
        }
    }
}

// Placeholder text used when a section has no data.
private struct EmptyStateRow: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.54))
    }
}
