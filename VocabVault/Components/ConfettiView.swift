import SwiftUI

// MARK: - Confetti View (minimal replacement — subtle animated dots)
// In the new design we use a simple emoji burst instead of particle confetti.

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                Text(p.emoji)
                    .font(.system(size: p.size))
                    .position(x: p.x, y: p.y)
                    .opacity(p.opacity)
                    .rotationEffect(.degrees(p.rotation))
            }
        }
        .onAppear { spawnParticles() }
    }

    private func spawnParticles() {
        let emojis = ["✨", "⭐", "🌟", "💫", "✦"]
        let width = UIScreen.main.bounds.width
        particles = (0..<20).map { i in
            ConfettiParticle(
                id: i,
                emoji: emojis[i % emojis.count],
                x: CGFloat.random(in: 0...width),
                y: CGFloat.random(in: -60...200),
                size: CGFloat.random(in: 14...26),
                opacity: Double.random(in: 0.6...1.0),
                rotation: Double.random(in: -45...45)
            )
        }

        withAnimation(.easeOut(duration: 2.4)) {
            for i in particles.indices {
                particles[i].y += CGFloat.random(in: 200...500)
                particles[i].opacity = 0
                particles[i].rotation += Double.random(in: -90...90)
            }
        }
    }
}

private struct ConfettiParticle: Identifiable {
    let id: Int
    let emoji: String
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var rotation: Double
}
