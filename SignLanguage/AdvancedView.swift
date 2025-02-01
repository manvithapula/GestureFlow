//
//  AdvancedView.swift
//  newProj
//
//  Created by admin@33 on 29/01/25.
//

import SwiftUI

struct AnimatedGradientViewAdvanced: View {
    @State private var start = UnitPoint(x: 0, y: -2)
    @State private var end = UnitPoint(x: 4, y: 0)
    
    let timer = Timer.publish(every: 1, on: .main, in: .default).autoconnect()
    let colors = [
        Color.orange.opacity(0.4),
        Color.white.opacity(0.4),
        Color.red.opacity(0.4)
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

struct AdvancedView: View {
    var body: some View {
        ZStack{
            AnimatedGradientViewAdvanced()
            VStack(alignment: .leading,spacing: 20) {
                Text("Choose a Category")
                    .font(.title2)
                    .bold()
                    .padding(.top)
                
                NavigationLink(destination: AlphabetsView()) {
                    CategoryButtonView(
                        title: "Pronouns",
                        icon: "figure.stand.dress.line.vertical.figure",
                        gradient: Gradient(colors: [Color.orange, Color.red])
                    )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Daily Life")
        }
    }
}


struct AdvancedView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedView()
    }
}
