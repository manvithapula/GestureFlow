//
//  Alphabets.swift
//  newProj
//
//  Created by admin@33 on 29/01/25.
//

import SwiftUI

struct AnimatedGradientViewAlphabets: View {
    @State private var start = UnitPoint(x: 0, y: -2)
    @State private var end = UnitPoint(x: 4, y: 0)
    
    let timer = Timer.publish(every: 1, on: .main, in: .default).autoconnect()
    let colors = [
        Color.cyan.opacity(0.4),
        Color.white.opacity(0.4),
        Color.blue.opacity(0.4)
    ]
    
    var body: some View {
        LinearGradient(colors: colors, startPoint: start, endPoint: end)
            .ignoresSafeArea()
            .onReceive(timer) { _ in
                withAnimation(.easeInOut(duration: 3).repeatForever()) {
                    self.start = UnitPoint(x: 4, y: 0)
                    self.end = UnitPoint(x: 0, y: 2)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.easeInOut(duration: 3).repeatForever()) {
                        self.start = UnitPoint(x: 0, y: -2)
                        self.end = UnitPoint(x: 4, y: 0)
                    }
                }
            }
    }
}

struct AlphabetsView: View {
    let alphabets = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
                     "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack{
            AnimatedGradientViewAlphabets()
            ScrollView {
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(alphabets, id: \.self) { letter in
                        ItemView(
                            text: letter,
                            gradient: Gradient(colors: [.cyan, .blue])
                        )
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Alphabets")
    }
}

//// MARK: - Updated ItemView
struct ItemView: View {
    let text: String
    let gradient: Gradient
    
    var body: some View {
        NavigationLink(destination: AlphabetDetailView(letter: text)) {
            Text(text)
                .font(.title)
                .bold()
                .foregroundColor(.white)
                .frame(height: 80)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
                .shadow(radius: 3)
        }
    }
}

struct AlphabetsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AlphabetsView()
        }
    }
}
