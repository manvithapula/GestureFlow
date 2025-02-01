//
//  SpeedMatchView.swift
//  SignLanguage
//
//  Created by admin64 on 29/01/25.
//
import SwiftUI
import ARKit
import RealityKit

struct SpeedMatchView: View {
    @StateObject private var gameManager = GameManager()
    @State private var currentSign = ""
    @State private var choices: [String] = []
    @State private var correctAnswerIndex = 0
    @State private var showFeedback = false
    @State private var isCorrect = false
    
    let signs = ["✌️", "👍", "👋", "✊", "🤚", "👆", "👉", "🤙"]
    let words = ["Peace", "Thumbs Up", "Wave", "Fist", "Stop", "Point Up", "Point", "Call"]
    
    var body: some View {
        ZStack {
            // AR View
            ViewContainer(gameManager: gameManager)
                .edgesIgnoringSafeArea(.all)
            
            // Game UI
            VStack {
                // Top Status Bar
                HStack {
                    ScoreView(score: gameManager.score)
                    Spacer()
                    TimerView(timeRemaining: gameManager.timeRemaining)
                }
                .padding()
                
                Spacer()
                
                // Game Content
                if gameManager.isGameActive {
                    GameContentView(
                        currentSign: currentSign,
                        choices: choices,
                        onChoice: checkAnswer
                    )
                } else {
                    GameStartView(
                        score: gameManager.score,
                        onStart: startNewGame
                    )
                }
            }
            
            // Feedback Overlay
            if showFeedback {
                FeedbackView(isCorrect: isCorrect)
            }
        }
    }
    
    private func startNewGame() {
        gameManager.startGame()
        generateNewQuestion()
    }
    
    private func generateNewQuestion() {
        let randomIndex = Int.random(in: 0..<signs.count)
        currentSign = signs[randomIndex]
        correctAnswerIndex = Int.random(in: 0..<4)
        
        choices = []
        var usedIndices = Set<Int>()
        usedIndices.insert(randomIndex)
        
        for i in 0..<4 {
            if i == correctAnswerIndex {
                choices.append(words[randomIndex])
            } else {
                var newIndex: Int
                repeat {
                    newIndex = Int.random(in: 0..<words.count)
                } while usedIndices.contains(newIndex)
                usedIndices.insert(newIndex)
                choices.append(words[newIndex])
            }
        }
    }
    
    private func checkAnswer(_ index: Int) {
        isCorrect = index == correctAnswerIndex
        gameManager.updateScore(isCorrect: isCorrect)
        
        showFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showFeedback = false
            generateNewQuestion()
        }
    }
}

// MARK: - Supporting Views

struct ViewContainer: UIViewRepresentable {
    let gameManager: GameManager
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Configure AR session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        
        arView.session.run(config)
        
        // Add 3D content
        let anchor = AnchorEntity(plane: .horizontal)
        arView.scene.addAnchor(anchor)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

struct ScoreView: View {
    let score: Int
    
    var body: some View {
        Text("Score: \(score)")
            .font(.title2.bold())
            .padding()
            .background(Color.black.opacity(0.5))
            .foregroundColor(.white)
            .cornerRadius(15)
    }
}

struct TimerView: View {
    let timeRemaining: Int
    
    var body: some View {
        Text("\(timeRemaining)s")
            .font(.title2.bold())
            .padding()
            .background(Color.black.opacity(0.5))
            .foregroundColor(timeRemaining <= 10 ? .red : .white)
            .cornerRadius(15)
    }
}

struct GameContentView: View {
    let currentSign: String
    let choices: [String]
    let onChoice: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Text(currentSign)
                .font(.system(size: 120))
                .padding()
                .background(Color.black.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(20)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                ForEach(0..<4) { index in
                    Button(action: { onChoice(index) }) {
                        Text(choices[index])
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                }
            }
        }
        .padding()
    }
}

struct GameStartView: View {
    let score: Int
    let onStart: () -> Void
    
    var body: some View {
        VStack(spacing: 25) {
            if score > 0 {
                Text("Game Over!")
                    .font(.largeTitle.bold())
                Text("Final Score: \(score)")
                    .font(.title2)
            }
            
            Button(action: onStart) {
                Text(score == 0 ? "Start Game" : "Play Again")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
        }
        .padding()
    }
}

struct FeedbackView: View {
    let isCorrect: Bool
    
    var body: some View {
        Color.black.opacity(0.3)
            .edgesIgnoringSafeArea(.all)
            .overlay(
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(isCorrect ? .green : .red)
            )
    }
}

// MARK: - Game Manager
class GameManager: ObservableObject {
    @Published var score = 0
    @Published var timeRemaining = 60
    @Published var isGameActive = false
    
    private var timer: Timer?
    
    func startGame() {
        isGameActive = true
        score = 0
        timeRemaining = 60
        startTimer()
    }
    
    func updateScore(isCorrect: Bool) {
        score += isCorrect ? 10 : -5
        score = max(0, score)
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.endGame()
            }
        }
    }
    
    private func endGame() {
        isGameActive = false
        timer?.invalidate()
        timer = nil
    }
}
#Preview {
    SpeedMatchView()
}
