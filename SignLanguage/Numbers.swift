//
//  Numbers.swift
//  newProj
//
//  Created by admin@33 on 29/01/25.
//

import SwiftUI

struct AnimatedGradientViewNumbers: View {
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

struct NumbersView: View {
    let numbers = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack{
            AnimatedGradientViewNumbers()
            ScrollView {
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(numbers, id: \.self) { number in
                        ItemView(
                            text: number,
                            gradient: Gradient(colors: [.cyan, .blue])
                        )
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Numbers")
    }
}

struct NumbersView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NumbersView()
        }
    }
}
