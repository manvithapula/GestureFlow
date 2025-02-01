//
//  QuizView.swift
//  SignLanguage
//
//  Created by admin64 on 29/01/25.


import SwiftUI
import RealityKit

struct QuizView: View {
    @State private var currentWord: String = "Hello"
    @State private var score: Int = 0
    @State private var isARViewActive: Bool = true // Start with AR view active
    @State private var showCorrectAnimation: Bool = false
    
    let words = ["Hello", "Thank You", "Please", "Good Morning", "Friend"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Sign This Word")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(.top)

                Text(currentWord)
                    .font(.system(size: 48, weight: .bold))
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .shadow(radius: 5)

                if isARViewActive {
                    ARViewContainer(signWord: currentWord)
                        .frame(height: 400)
                        .cornerRadius(16)
                        .shadow(radius: 10)
                        .padding(.bottom)

                    if showCorrectAnimation {
                        Text("✅ Correct!")
                            .font(.largeTitle)
                            .foregroundColor(.green)
                            .transition(.scale)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .animation(.easeInOut, value: showCorrectAnimation)
                    }
                }
                
                HStack {
                    Text("Score: \(score)")
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer()

                    Button(action: {
                        // Reset to a new word without leaving the AR view
                        currentWord = words.randomElement()!
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)

            }
            .padding()
            .navigationTitle("Sign Language Quiz")
            // Removed Close button to keep focus on AR experience
        }
        .onAppear {
            // Initialize with a random word when the view appears
            currentWord = words.randomElement()!
        }
    }
    
    private func handleCorrectSign() {
        withAnimation {
            score += 10
            showCorrectAnimation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            showCorrectAnimation = false
            currentWord = words.randomElement()!
        }
    }
}

struct ARViewContainerQuiz: UIViewRepresentable {
    let signWord: String
    let onCorrectSign: () -> Void
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        // AR sign detection setup here
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Process sign verification and call onCorrectSign when correct
    }
}

#Preview {
    NavigationStack {
        QuizView()
    }
}
