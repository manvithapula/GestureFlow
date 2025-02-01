//
//  HomeView.swift
//  SignLanguage
//
//  Created by admin64 on 30/01/25.
//
import SwiftUI

import SwiftUI

// MARK: - User Data Model
class UserData: ObservableObject {
    @Published var currentStreak: Int = 0
    @Published var lastCompletionDate: Date?
    @Published var dailyProgress: Int = 0
    @Published var totalDailyGoal: Int = 20
    
    init() {
        loadStreak()
    }
    
    private func loadStreak() {
        currentStreak = UserDefaults.standard.integer(forKey: "currentStreak")
        if let savedDate = UserDefaults.standard.object(forKey: "lastCompletionDate") as? Date {
            lastCompletionDate = savedDate
        }
        checkAndUpdateStreak()
    }
    
    func checkAndUpdateStreak() {
        guard let lastCompletion = lastCompletionDate else { return }
        
        let calendar = Calendar.current
        let today = Date()
        
        if !calendar.isDateInToday(lastCompletion) {
            if !calendar.isDateInYesterday(lastCompletion) {
                currentStreak = 0
            }
        }
        
        saveStreak()
    }
    
    func completeActivity() {
        let today = Date()
        
        if let lastCompletion = lastCompletionDate {
            if !Calendar.current.isDateInToday(lastCompletion) {
                currentStreak += 1
            }
        } else {
            currentStreak = 1
        }
        
        lastCompletionDate = today
        dailyProgress += 1
        
        saveStreak()
    }
    
    private func saveStreak() {
        UserDefaults.standard.set(currentStreak, forKey: "currentStreak")
        UserDefaults.standard.set(lastCompletionDate, forKey: "lastCompletionDate")
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @StateObject private var userData = UserData()
    @State private var selectedTab = 0
    @State private var showProfile = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeTabView(showProfile: $showProfile, userData: userData)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            LearnTabView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Learn")
                }
                .tag(1)
            
            GamesTabView()
                .tabItem {
                    Image(systemName: "gamecontroller.fill")
                    Text("Games")
                }
                .tag(2)
        }
        .sheet(isPresented: $showProfile) {
            ProfileView(isPresented: $showProfile, userData: userData)
        }
    }
}

// MARK: - Home Tab View
struct HomeTabView: View {
    @Binding var showProfile: Bool
    @ObservedObject var userData: UserData
    @State private var isAnimating = false
    private let particleSystem = ParticleSystem()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header section with streak
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome Back!")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Animated Streak Card
                    streakCard
                        .modifier(CardAnimationModifier(isAnimating: isAnimating, delay: 0.2))
                        .padding(.horizontal)
                    
                    // Daily Progress
                    HomeCard(
                        title: "Today's Progress",
                        symbol: "chart.bar.fill",
                        description: "\(userData.dailyProgress)/\(userData.totalDailyGoal) signs completed",
                        gradient: [Color.blue, Color.blue.opacity(0.7)]
                    ) {
                        CircularProgressView(progress: Double(userData.dailyProgress) / Double(userData.totalDailyGoal))
                            .frame(width: 60, height: 60)
                    }
                    
                    // Quick Actions
                    Text("Quick Actions")
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    LazyVStack(spacing: 16) {
                        NavigationLink(destination: Text("AR Practice")) {
                            ActionCard(
                                title: "Practice AR",
                                symbol: "camera.fill",
                                description: "Practice signs in AR",
                                gradient: [Color.purple, Color.purple.opacity(0.7)]
                            )
                        }
                        .onTapGesture {
                            userData.completeActivity()
                        }
                        
                        NavigationLink(destination: Text("Daily Lesson")) {
                            ActionCard(
                                title: "Daily Lesson",
                                symbol: "book.fill",
                                description: "Complete today's lesson",
                                gradient: [Color.green, Color.green.opacity(0.7)]
                            )
                        }
                        .onTapGesture {
                            userData.completeActivity()
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showProfile.toggle() }) {
                        Image(systemName: "person.crop.circle")
                            .font(.title2)
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isAnimating = true
                }
                particleSystem.createParticles(count: 15)
            }
        }
    }
    
    // MARK: - Streak Card Component
    private var streakCard: some View {
        ZStack {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily Streak")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(userData.currentStreak) days")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("🔥 Current streak")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Image(systemName: "flame.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .foregroundColor(.orange)
                    .scaleEffect(isAnimating ? 1.2 : 1)
                    .animation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#FF6D00"), Color(hex: "#FF3D00")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .shadow(color: Color.orange.opacity(0.3), radius: 20, x: 0, y: 10)
            
            ParticleView(system: particleSystem)
        }
    }
}

// MARK: - Particle System
class ParticleSystem {
    var particles = [Particle]()
    
    func createParticles(count: Int) {
        for _ in 0..<count {
            particles.append(Particle())
        }
    }
    
    func update(date: TimeInterval) {
        particles = particles.compactMap { particle in
            var particle = particle
            let age = date - particle.creationDate
            
            guard age <= 3 else { return nil }
            
            particle.position.x += cos(particle.direction) * particle.speed
            particle.position.y += sin(particle.direction) * particle.speed
            particle.speed *= 0.95
            particle.scale = max(0, 1 - age/3)
            particle.rotation += particle.rotationSpeed
            
            return particle
        }
    }
}

// MARK: - Particle View
struct ParticleView: View {
    let system: ParticleSystem
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                system.update(date: timeline.date.timeIntervalSinceReferenceDate)
                
                for particle in system.particles {
                    let particleShape = Path { path in
                        path.addArc(center: .zero, radius: 5, startAngle: .zero, endAngle: .degrees(360), clockwise: true)
                    }
                    
                    context.translateBy(x: particle.position.x, y: particle.position.y)
                    context.rotate(by: .radians(particle.rotation))
                    context.scaleBy(x: particle.scale, y: particle.scale)
                    
                    context.stroke(particleShape, with: .color(.orange), lineWidth: 2)
                    
                    context.transform = .identity
                }
            }
        }
    }
}

// MARK: - Particle Model
struct Particle {
    let id = UUID()
    var position: CGPoint = CGPoint(x: 180, y: 50)
    var direction: Double = .random(in: 0..<(.pi * 2))
    var speed: Double = .random(in: 1...5)
    var scale: Double = 1
    var rotation: Double = .random(in: 0...(.pi * 2))
    var rotationSpeed: Double = .random(in: -0.5...0.5)
    var creationDate = Date().timeIntervalSinceReferenceDate
}

// MARK: - Card Animation Modifier
struct CardAnimationModifier: ViewModifier {
    let isAnimating: Bool
    let delay: Double
    
    init(isAnimating: Bool, delay: Double = 0) {
        self.isAnimating = isAnimating
        self.delay = delay
    }
    
    func body(content: Content) -> some View {
        content
            .offset(y: isAnimating ? 0 : 30)
            .opacity(isAnimating ? 1 : 0)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.8).delay(delay),
                value: isAnimating
            )
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct LearnTabView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Start Learning")
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    LazyVStack(spacing: 16) {
                        NavigationLink(destination: Text("Basics")) {
                            LessonCard(
                                title: "Basics",
                                symbol: "hand.wave.fill",
                                description: "Learn fundamental signs",
                                gradient: [Color.blue, Color.blue.opacity(0.7)],
                                progress: "10 lessons"
                            )
                        }
                        
                        NavigationLink(destination: Text("Greetings")) {
                            LessonCard(
                                title: "Greetings",
                                symbol: "person.2.fill",
                                description: "Common greeting signs",
                                gradient: [Color.purple, Color.purple.opacity(0.7)],
                                progress: "8 lessons"
                            )
                        }
                        
                        NavigationLink(destination: Text("Daily Life")) {
                            LessonCard(
                                title: "Daily Life",
                                symbol: "sun.max.fill",
                                description: "Everyday communication",
                                gradient: [Color.orange, Color.orange.opacity(0.7)],
                                progress: "12 lessons"
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Learn")
        }
    }
}

// MARK: - Home Card
struct HomeCard<Content: View>: View {
    let title: String
    let symbol: String
    let description: String
    let gradient: [Color]
    let content: Content
    
    init(
        title: String,
        symbol: String,
        description: String,
        gradient: [Color],
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.symbol = symbol
        self.description = description
        self.gradient = gradient
        self.content = content()
    }
    
    var body: some View {
        VStack {
            HStack(spacing: 20) {
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
                
                content
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal)
    }
}

// MARK: - Action Card
struct ActionCard: View {
    let title: String
    let symbol: String
    let description: String
    let gradient: [Color]
    
    @State private var isPressed = false
    
    var body: some View {
        VStack {
            HStack(spacing: 20) {
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
    }
}

// MARK: - Lesson Card
struct LessonCard: View {
    let title: String
    let symbol: String
    let description: String
    let gradient: [Color]
    let progress: String
    
    @State private var isPressed = false
    
    var body: some View {
        VStack {
            HStack(spacing: 20) {
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
                    
                    Text(progress)
                        .font(.caption)
                        .foregroundColor(.blue)
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
    }
}

// MARK: - Circular Progress View
struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .bold()
        }
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @Binding var isPresented: Bool
    @ObservedObject var userData: UserData
    
    let currentXP: Int = 1250
    let xpRequiredForNextLevel: Int = 1500
    let level: Int = 5
    
    var xpProgress: CGFloat {
        return CGFloat(currentXP) / CGFloat(xpRequiredForNextLevel)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .foregroundColor(.gray)
                
                Text("John Doe")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Aspiring Sign Language Learner! 🌟")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("📧 Email: johndoe@example.com")
                    Text("📍 Location: India")
                    Text("🔗 Linked Social: @john_doe")
                }
                .font(.body)
                .padding(.horizontal)
                
                Divider()
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(userData.currentStreak) Day Streak!")
                            .font(.title2)
                            .fontWeight(.bold)  // Fixed by adding .bold
                    }
                    .padding(.horizontal)
                    if let lastCompletion = userData.lastCompletionDate {
                        Text("Last activity: \(lastCompletion.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Daily Progress
                    VStack(spacing: 5) {
                        Text("Today's Progress")
                            .font(.headline)
                        ProgressView(value: Double(userData.dailyProgress), total: Double(userData.totalDailyGoal))
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        Text("\(userData.dailyProgress)/\(userData.totalDailyGoal) signs completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // XP Progress Bar
                    HStack {
                        Text("Lv \(level)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                        ProgressView(value: xpProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .black))
                            .frame(width: 150, height: 30)
                        Spacer()
                        Text("\(currentXP) / \(xpRequiredForNextLevel)")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                }
                
                Divider()
                
                // Achievements & Badges
                VStack(alignment: .leading, spacing: 10) {
                    Text("🏆 Achievements")
                        .font(.headline)
                    HStack {
                        Image(systemName: "star.fill").foregroundColor(.yellow)
                        Text("1st Week Streak!")
                    }
                    HStack {
                        Image(systemName: "trophy.fill").foregroundColor(.orange)
                        Text("Learned 50 Signs!")
                    }
                    HStack {
                        Image(systemName: "rosette").foregroundColor(.blue)
                        Text("Daily Learner")
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Dismiss") {
                        isPresented = false
                    }
                }
            }
            .padding()
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }
}
#Preview{
    MainTabView()
}
