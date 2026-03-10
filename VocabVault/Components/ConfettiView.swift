import SwiftUI

// MARK: - Confetti Particle

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGPoint
    var rotation: Double
    var rotationVelocity: Double
    var color: Color
    var size: CGFloat
    var shape: ConfettiShape
    var opacity: Double = 1.0
}

private enum ConfettiShape: CaseIterable {
    case circle, rectangle, triangle
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var timer: Timer?
    var onComplete: (() -> Void)?

    private let colors: [Color] = [
        .gradPurple1, .gradTeal1, .gradCoral1,
        .gradAmber1, .gradMint1, .gradRose1, .gradLav1,
        .white
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    ParticleView(particle: particle)
                }
            }
            .onAppear {
                spawnParticles(in: geo.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func spawnParticles(in size: CGSize) {
        particles = (0..<120).map { i in
            let delay = Double(i) * 0.012
            let startX = Double.random(in: size.width * 0.2 ... size.width * 0.8)
            let startY = size.height * 0.4

            return ConfettiParticle(
                position: CGPoint(x: startX, y: startY),
                velocity: CGPoint(
                    x: Double.random(in: -180 ... 180),
                    y: Double.random(in: -450 ... -150)
                ),
                rotation: Double.random(in: 0 ..< 360),
                rotationVelocity: Double.random(in: -720 ... 720),
                color: colors.randomElement() ?? .white,
                size: CGFloat.random(in: 6 ... 14),
                shape: ConfettiShape.allCases.randomElement() ?? .circle
            )
        }

        // Animate all particles
        withAnimation(.linear(duration: 0.016).repeatCount(120, autoreverses: false)) {
            // physics handled via individual particle animations
        }

        // Drive physics with a display-link style timer
        var tick = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { t in
            tick += 1
            let dt = 1.0 / 60.0
            let gravity = 280.0

            for i in particles.indices {
                particles[i].position.x += particles[i].velocity.x * dt
                particles[i].position.y += particles[i].velocity.y * dt
                particles[i].velocity.y += gravity * dt
                particles[i].rotation  += particles[i].rotationVelocity * dt

                if tick > 90 {
                    particles[i].opacity = max(0, particles[i].opacity - 0.025)
                }
            }

            if tick > 150 {
                t.invalidate()
                particles = []
                onComplete?()
            }
        }
    }
}

// MARK: - Individual Particle View

private struct ParticleView: View {
    let particle: ConfettiParticle

    var body: some View {
        Group {
            switch particle.shape {
            case .circle:
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
            case .rectangle:
                Rectangle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size * 0.5)
            case .triangle:
                Triangle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
            }
        }
        .rotationEffect(.degrees(particle.rotation))
        .opacity(particle.opacity)
        .position(particle.position)
    }
}

// MARK: - Triangle Shape

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

// MARK: - Burst Effect (mastery level up)

struct BurstEffect: View {
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 1
    let color: Color

    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                let angle = Double(i) * 45.0
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                    .offset(
                        x: cos(angle * .pi / 180) * 50 * scale,
                        y: sin(angle * .pi / 180) * 50 * scale
                    )
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                scale = 1.0
                opacity = 0
            }
        }
    }
}
