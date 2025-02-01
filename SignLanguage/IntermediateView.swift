//
//  IntermediateView.swift
//  newProj
//
//  Created by admin@33 on 29/01/25.
//

import SwiftUI

struct AnimatedGradientViewIntermediate: View {
    @State private var start = UnitPoint(x: 0, y: -2)
    @State private var end = UnitPoint(x: 4, y: 0)
    
    let timer = Timer.publish(every: 1, on: .main, in: .default).autoconnect()
    let colors = [
        Color.purple.opacity(0.4),
        Color.white.opacity(0.4),
        Color.teal.opacity(0.4)
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

struct IntermediateView: View {
    var body: some View {
        ZStack{
            AnimatedGradientViewIntermediate()
            VStack(alignment: .leading,spacing: 20) {
                Text("Choose a Category")
                    .font(.title2)
                    .bold()
                    .padding(.top)
                
                // Main navigation buttons
                NavigationLink(destination: AlphabetsView()) {
                    CategoryButtonView(
                        title: "Greetings",
                        icon: "figure.wave",
                        gradient: Gradient(colors: [Color.purple, Color.teal])
                    )
                }
                
                NavigationLink(destination: NumbersView()) {
                    CategoryButtonView(
                        title: "Colors",
                        icon: "paintpalette.fill",
                        gradient: Gradient(colors: [Color.purple, Color.teal])
                    )
                }
                
                NavigationLink(destination: NumbersView()) {
                    CategoryButtonView(
                        title: "Date and Time",
                        icon: "calendar.badge.clock",
                        gradient: Gradient(colors: [Color.purple, Color.teal])
                    )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Intermediate")
        }
    }
}

struct IntermediateView_Previews: PreviewProvider {
    static var previews: some View {
        IntermediateView()
    }
}
