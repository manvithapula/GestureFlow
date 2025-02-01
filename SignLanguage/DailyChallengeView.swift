//
//  DailyChallengeView.swift
//  SignLanguage
//
//  Created by admin64 on 29/01/25.
//

import SwiftUI
import RealityKit

// MARK: - Models
struct DailyChallengeData: Identifiable {
    let id = UUID()
    let day: Int
    let date: Date
    let signWord: String
    let isUnlocked: Bool
    let isCompleted: Bool
}

struct LessonProgress {
    var currentStep: Int = 0
    var isCompleted: Bool = false
    var attempts: Int = 0
    var startTime: Date = Date()
    
    mutating func nextStep() {
        currentStep += 1
        if currentStep >= 3 {
            isCompleted = true
        }
    }
}

// MARK: - Views
struct DailyChallengeView: View {
    @State private var selectedDay: DailyChallengeData?
    
    @State private var challenges: [DailyChallengeData] = {
        let calendar = Calendar.current
        let today = Date()
        
        return (0..<30).map { day in
            let date = calendar.date(byAdding: .day, value: -day, to: today)!
            return DailyChallengeData(
                day: day + 1,
                date: date,
                signWord: ["Hello", "Thank You", "Please", "Good Morning", "Friend"].randomElement()!,
                isUnlocked: day <= 0,
                isCompleted: day > 0
            )
        }
    }()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack(spacing: 20) {
                    ChallengeStatCard(title: "Current Streak", value: "7", symbol: "flame.fill", color: .orange)
                    ChallengeStatCard(title: "Signs Learned", value: "24", symbol: "hand.raised.fill", color: .purple)
                }
                .padding(.horizontal)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                    ForEach(challenges) { challenge in
                        ChallengeDayCard(challenge: challenge) {
                            if challenge.isUnlocked && !challenge.isCompleted {
                                selectedDay = challenge
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Daily Challenge")
        .sheet(item: $selectedDay) { challenge in
            ChallengeLessonView(challenge: challenge)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct ChallengeStatCard: View {
    let title: String
    let value: String
    let symbol: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: symbol)
                    .foregroundColor(color)
                Text(title)
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct ChallengeDayCard: View {
    let challenge: DailyChallengeData
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text("Day \(challenge.day)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 60, height: 60)
                    
                    Group {
                        if challenge.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        } else if challenge.isUnlocked {
                            Image(systemName: "hand.raised.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "lock.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                }
                
                Text(challenge.date.formatted(.dateTime.day().month()))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundColor: Color {
        if challenge.isCompleted {
            return .green
        } else if challenge.isUnlocked {
            return .blue
        } else {
            return .gray.opacity(0.5)
        }
    }
}

struct ChallengeLessonView: View {
    let challenge: DailyChallengeData
    @Environment(\.dismiss) private var dismiss
    @State private var progress = LessonProgress()
    @State private var showCongratulations = false
    @State private var isARViewActive = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Word Card
                    VStack(spacing: 12) {
                        Text("Today's Sign")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(challenge.signWord)
                            .font(.system(size: 42, weight: .bold))
                        
                        ProgressBar(value: Float(progress.currentStep) / 3.0)
                            .frame(height: 8)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    
                    // AR View
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Interactive Experience")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        ZStack {
                            if isARViewActive {
                                ARViewContainer(signWord: challenge.signWord)
                                    .frame(height: 300)
                                    .cornerRadius(16)
                            } else {
                                Button(action: { isARViewActive = true }) {
                                    VStack(spacing: 12) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 30))
                                        Text("Start AR Experience")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.blue)
                                    .frame(height: 300)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(16)
                                }
                            }
                        }
                    }
                    
                    // Practice Steps
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Practice Steps")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        ForEach(0..<3) { step in
                            StepCard(
                                step: step + 1,
                                title: ["Watch Demo", "Practice Motion", "Test Yourself"][step],
                                isCompleted: progress.currentStep > step,
                                isActive: progress.currentStep == step
                            )
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    
                    Button(action: {
                        if progress.currentStep < 3 {
                            withAnimation {
                                progress.nextStep()
                            }
                        } else {
                            showCongratulations = true
                        }
                    }) {
                        Text(progress.currentStep < 3 ? "Continue" : "Complete Lesson")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(16)
                    }
                }
                .padding()
            }
            .navigationTitle("Day \(challenge.day)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showCongratulations) {
                CongratulationsView(signWord: challenge.signWord) {
                    dismiss()
                }
            }
        }
    }
}

struct ProgressBar: View {
    let value: Float
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color(.systemGray5))
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: CGFloat(value) * geometry.size.width)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct StepCard: View {
    let step: Int
    let title: String
    let isCompleted: Bool
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 40, height: 40)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                } else {
                    Text("\(step)")
                        .foregroundColor(isActive ? .white : .secondary)
                        .fontWeight(.semibold)
                }
            }
            
            Text(title)
                .font(.headline)
            
            Spacer()
            
            if isActive {
                Text("In Progress")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(isActive ? Color.blue.opacity(0.05) : Color.clear)
        .cornerRadius(12)
    }
    
    private var backgroundColor: Color {
        if isCompleted {
            return .green
        } else if isActive {
            return .blue
        } else {
            return Color(.systemGray5)
        }
    }
}

struct CongratulationsView: View {
    let signWord: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("Congratulations!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("You've mastered the sign for")
                .foregroundColor(.secondary)
            
            Text(signWord)
                .font(.title2)
                .fontWeight(.bold)
            
            Button(action: onDismiss) {
                Text("Continue Learning")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(16)
            }
            .padding(.top)
        }
        .padding()
        .presentationDetents([.height(400)])
    }
}

// MARK: - AR View Container
struct ARViewContainer: UIViewRepresentable {
    let signWord: String
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        // Configure AR experience here
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Update AR view if needed
    }
}

#Preview {
    NavigationStack {
        DailyChallengeView()
    }
}
