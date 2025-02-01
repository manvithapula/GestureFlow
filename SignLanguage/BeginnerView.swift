import SwiftUI

struct AnimatedGradientViewBeginner: View {
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

struct BeginnerView: View {
    var body: some View {
        ZStack{
            AnimatedGradientViewBeginner()
            VStack(alignment: .leading,spacing: 20) {
                Text("Choose a Category")
                    .font(.title2)
                    .bold()
                    .padding(.top)
                
                // Main navigation buttons
                NavigationLink(destination: AlphabetsView()) {
                    CategoryButtonView(
                        title: "Alphabets",
                        icon: "textformat.abc",
                        gradient: Gradient(colors: [Color.cyan, Color.blue])
                    )
                }
                
                NavigationLink(destination: NumbersView()) {
                    CategoryButtonView(
                        title: "Numbers",
                        icon: "number",
                        gradient: Gradient(colors: [Color.cyan, Color.blue])
                    )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Basic")
        }
    }
}

struct CategoryButtonView: View {
    let title: String
    let icon: String
    let gradient: Gradient
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.white)
                .padding(.leading)
            
            Text(title)
                .font(.title2)
                .bold()
                .foregroundColor(.white)
                .padding()
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white)
                .padding()
        }
        .frame(height: 80)
        .background(
            LinearGradient(gradient: gradient, startPoint: .leading, endPoint: .trailing)
        )
        .cornerRadius(12)
        .shadow(radius: 3)
    }
}

struct BeginnerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BeginnerView()
        }
    }
}
