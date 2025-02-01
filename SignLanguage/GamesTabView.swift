//
// GamesTabView.swift
// SignLanguage
//
// Created by admin64 on 29/01/25.
//

import SwiftUI
struct GamesTabView: View {
    @State private var selectedGame: GameType?
    enum GameType: String, Identifiable {
        case quiz = "Quiz"
        case dailyChallenge = "Daily Challenge"
        case speedMatch = "Speed Match"
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header section
                    Text("Choose Your Challenge")
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // Game cards
                    LazyVStack(spacing: 16) {
                        NavigationLink(destination: DailyChallengeView()) {
                            GameCard(
                                title: "Daily Challenge",
                                symbol: "calendar.badge.clock",
                                description: "Master one new sign every day",
                                gradient: [Color.blue, Color.blue.opacity(0.7)]
                            )
                        }
                        
                        NavigationLink(destination: QuizView()) {
                            GameCard(
                                title: "Sign Quiz",
                                symbol: "hand.raised.fill",
                                description: "Test your signing knowledge",
                                gradient: [Color.purple, Color.purple.opacity(0.7)]
                            )
                        }
                        
                        NavigationLink(destination: SpeedMatchView()) {
                            GameCard(
                                title: "Speed Match",
                                symbol: "bolt.fill",
                                description: "Race against time to match signs",
                                gradient: [Color.orange, Color.orange.opacity(0.7)]
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Games")
        }
    }
}

struct GameCard: View {
    let title: String
    let symbol: String
    let description: String
    let gradient: [Color]
    
    @State private var isPressed = false
    
    var body: some View {
        VStack {
            HStack(spacing: 20) {
                // Icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: symbol)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .scaleEffect(isPressed ? 0.98 : 1)
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    GamesTabView()
}
