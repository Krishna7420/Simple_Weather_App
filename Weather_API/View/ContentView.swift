//
//  ContentView.swift
//  Weather_API
//
//  Created by Shrikrishna Thodsare on 13/11/25.
//


import SwiftUI

struct ContentView: View {
    @StateObject var vm = WeatherViewModel()
    @State private var animateGradient = false
    @State private var pulse = false
    @State private var drawChart: CGFloat = 0
    @State private var selectedIndex: Int? = nil
    
    var body: some View {
        ZStack {
            // 1) Solid dark base (prevents white showing through)
            Color(red: 0.01, green: 0.03, blue: 0.08)
                .ignoresSafeArea()
            
            // 2) Animated background layers
            ParticleBackgroundView()
                .ignoresSafeArea()
            AnimatedGradientView(animate: $animateGradient)
                .ignoresSafeArea()
                .blendMode(.overlay)
                .opacity(0.95)
            
            // 3) Main content
            VStack(spacing: 18) {
                TopHeaderView(vm: vm, pulse: pulse)
                    .padding(.top, 28)
                
                TemperatureCard(vm: vm, pulse: pulse)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                
                // Chart + details
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Hourly Trend")
                            .font(.headline)
                        Spacer()
                        if vm.timeList.isEmpty {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Button {
                                withAnimation(.easeOut(duration: 1.2)) {
                                    drawChart = 0
                                    selectedIndex = nil
                                }
                                withAnimation(.easeOut(duration: 1.2).delay(0.05)) {
                                    drawChart = 1
                                }
                            } label: {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    ChartView(timeList: vm.timeList, tempList: vm.tempList, progress: drawChart, selectedIndex: $selectedIndex)
                        .frame(height: 220)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 6)
                    
                    if let i = selectedIndex, vm.timeList.indices.contains(i) {
                        HStack {
                            Text("Time: \(shortTime(vm.timeList[i]))")
                            Spacer()
                            Text(String(format: "%.1f°C", vm.tempList[i]))
                                .fontWeight(.semibold)
                        }
                        .font(.footnote)
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else {
                        Text("Tap a dot for details")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }
                }
                .background(Color.black.opacity(0.14))   // dark translucent card
                .cornerRadius(14)
                .padding(.horizontal)
                
                // Horizontal compact hourly list
                HourlyListView(timeList: vm.timeList, tempList: vm.tempList)
                    .padding(.horizontal)
                    .padding(.top, 6)
                
                Spacer()
                
                HStack {
                    Spacer()
                    Button {
                        Task { await vm.fetchWeather() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.12))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            } // VStack
            .foregroundColor(.white)
            .onAppear {
                Task {
                    await vm.fetchWeather()
                    withAnimation(.easeOut(duration: 1.2)) { drawChart = 1 }
                }
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    pulse.toggle()
                }
            }
            .padding(.bottom, 6)
            .padding(.top, 6)
        } // ZStack
    }
    
    func shortTime(_ iso: String) -> String {
        iso.split(separator: "T").last.map(String.init) ?? iso
    }
}

// MARK: - Top Header
struct TopHeaderView: View {
    @ObservedObject var vm: WeatherViewModel
    var pulse: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Weather Now")
                    .font(.largeTitle.weight(.bold))
                    .shadow(radius: 6)
                Text(vm.cityName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(AngularGradient(colors: [.yellow, .orange, .pink], center: .center))
                    .frame(width: 44, height: 44)
                    .blur(radius: pulse ? 8 : 3)
                    .opacity(0.95)
                Image(systemName: "location.fill")
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Temperature Card
struct TemperatureCard: View {
    @ObservedObject var vm: WeatherViewModel
    var pulse: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.black.opacity(0.20))
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.04), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 12)
            
            HStack {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 92, height: 92)
                        .scaleEffect(pulse ? 1.02 : 0.98)
                        .rotationEffect(.degrees(pulse ? 8 : -8))
                        .shadow(radius: 12)
                    
                    Image(systemName: "sun.max.fill")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(vm.currentTemp.isEmpty ? "—°C" : vm.currentTemp)
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                    Text("Feels like now")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(18)
        }
        .frame(height: 140)
    }
}

// MARK: - Hourly List View (compact)
struct HourlyListView: View {
    var timeList: [String]
    var tempList: [Double]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Hourly")
                .font(.headline)
                .padding(.leading, 6)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(timeList.enumerated()), id: \.offset) { idx, t in
                        VStack(spacing: 6) {
                            Text(shortH(t))
                                .font(.caption)
                            Text(String(format: "%.0f°", tempList.indices.contains(idx) ? tempList[idx] : 0))
                                .font(.subheadline.weight(.bold))
                            Capsule()
                                .fill(colorForTemp(tempList.indices.contains(idx) ? tempList[idx] : 0))
                                .frame(width: 24, height: 36)
                                .opacity(0.9)
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.06)))
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 110)
        }
    }
    
    func shortH(_ iso: String) -> String {
        iso.split(separator: "T").last.map(String.init) ?? iso
    }
}

// MARK: - ChartView + supporting shapes
struct ChartView: View {
    var timeList: [String]
    var tempList: [Double]
    var progress: CGFloat // 0..1 drives trim
    @Binding var selectedIndex: Int?
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                GridLines()
                    .stroke(Color.white.opacity(0.04), lineWidth: 1)
                
                if !tempList.isEmpty {
                    let pts = normalizedPoints(size: geo.size, temps: tempList)
                    
                    ChartShape(points: pts)
                        .trim(from: 0, to: progress)
                        .stroke(LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .leading, endPoint: .trailing), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .shadow(color: Color.orange.opacity(0.25), radius: 12, x: 0, y: 8)
                        .animation(.easeOut(duration: 1.2), value: progress)
                    
                    ChartShape(points: pts)
                        .trim(from: 0, to: progress)
                        .fill(LinearGradient(colors: [Color.orange.opacity(0.12), Color.clear], startPoint: .top, endPoint: .bottom))
                        .animation(.easeOut(duration: 1.2), value: progress)
                    
                    ForEach(Array(pts.enumerated()), id: \.offset) { idx, p in
                        Circle()
                            .fill(Color.white)
                            .frame(width: selectedIndex == idx ? 12 : 8, height: selectedIndex == idx ? 12 : 8)
                            .position(x: p.x, y: p.y)
                            .shadow(radius: selectedIndex == idx ? 6 : 2)
                            .onTapGesture {
                                withAnimation(.easeInOut) {
                                    selectedIndex = (selectedIndex == idx) ? nil : idx
                                }
                            }
                    }
                } else {
                    Text("No data")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    func normalizedPoints(size: CGSize, temps: [Double]) -> [CGPoint] {
        guard !temps.isEmpty else { return [] }
        let minT = temps.min() ?? 0
        let maxT = temps.max() ?? 1
        let count = temps.count
        let step = size.width / CGFloat(max(count - 1, 1))
        return temps.enumerated().map { i, t in
            let x = step * CGFloat(i)
            let yRange = maxT - minT == 0 ? 1 : maxT - minT
            let yRatio = (t - minT) / yRange
            let y = size.height - CGFloat(yRatio) * size.height
            return CGPoint(x: x, y: y)
        }
    }
}

struct ChartShape: Shape {
    var points: [CGPoint]
    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard points.count > 0 else { return p }
        p.move(to: CGPoint(x: points[0].x, y: points[0].y))
        for i in 1..<points.count {
            p.addLine(to: CGPoint(x: points[i].x, y: points[i].y))
        }
        return p
    }
}

struct GridLines: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let rows = 4
        for i in 0...rows {
            let y = rect.height * CGFloat(i) / CGFloat(rows)
            p.move(to: CGPoint(x: 0, y: y))
            p.addLine(to: CGPoint(x: rect.width, y: y))
        }
        return p
    }
}

// MARK: - Particle & Floating blobs (dark blue animated)
struct Particle {
    var x: Double
    var y: Double
    var size: Double
    var alpha: Double
    var blur: Double
    var color: Color
    var delay: Double = 0
    var duration: Double = 12
    var scale: Double = 1.0
    
    static func randomBlue() -> Particle {
        let palettes: [Color] = [
            Color(red: 0.06, green: 0.18, blue: 0.36),
            Color(red: 0.10, green: 0.24, blue: 0.48),
            Color(red: 0.07, green: 0.14, blue: 0.32),
            Color(red: 0.12, green: 0.20, blue: 0.42).opacity(0.95)
        ]
        return Particle(
            x: Double.random(in: -0.12...1.12),
            y: Double.random(in: -0.12...1.12),
            size: Double.random(in: 0.03...0.16),
            alpha: Double.random(in: 0.02...0.14),
            blur: Double.random(in: 6...34),
            color: palettes.randomElement() ?? Color.blue.opacity(0.06),
            delay: 0,
            duration: Double.random(in: 12...30),
            scale: Double.random(in: 0.9...1.2)
        )
    }
}

struct ParticleBackgroundView: View {
    @State private var particles: [Particle] = []
    let particleCount = 20
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(particles.enumerated()), id: \.offset) { idx, p in
                    Circle()
                        .fill(p.color)
                        .frame(width: geo.size.width * CGFloat(p.size), height: geo.size.width * CGFloat(p.size))
                        .position(x: geo.size.width * CGFloat(p.x), y: geo.size.height * CGFloat(p.y))
                        .opacity(p.alpha)
                        .blur(radius: p.blur)
                        .scaleEffect(p.scale)
                        .animation(.easeInOut(duration: p.duration).repeatForever(autoreverses: true).delay(p.delay), value: p.x)
                }
                
                FloatingBlobsView()
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            .onAppear {
                if particles.isEmpty {
                    particles = (0..<particleCount).map { i in
                        var p = Particle.randomBlue()
                        p.delay = Double(i) * 0.15
                        p.duration = Double.random(in: 10...26)
                        p.scale = Double.random(in: 0.9...1.15)
                        return p
                    }
                    
                    for i in particles.indices {
                        let variationX = Double.random(in: -0.18...0.18)
                        let variationY = Double.random(in: -0.12...0.12)
                        withAnimation(.easeInOut(duration: particles[i].duration).repeatForever(autoreverses: true).delay(particles[i].delay)) {
                            particles[i].x = min(max(particles[i].x + variationX, -0.15), 1.15)
                            particles[i].y = min(max(particles[i].y + variationY, -0.15), 1.15)
                        }
                    }
                }
            }
        }
    }
}

struct FloatingBlobsView: View {
    @State private var offset1: CGSize = .zero
    @State private var offset2: CGSize = .zero
    @State private var offset3: CGSize = .zero
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color(red:0.06, green:0.12, blue:0.28).opacity(0.95), Color(red:0.03, green:0.14, blue:0.36).opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: geo.size.width * 0.9, height: geo.size.width * 0.9)
                    .offset(x: offset1.width - geo.size.width * 0.35, y: offset1.height - geo.size.height * 0.25)
                    .blur(radius: 40)
                    .opacity(0.22)
                
                Circle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color(red:0.14, green:0.06, blue:0.36).opacity(0.9), Color(red:0.06, green:0.16, blue:0.46).opacity(0.8)]), startPoint: .top, endPoint: .bottom))
                    .frame(width: geo.size.width * 0.55, height: geo.size.width * 0.55)
                    .offset(x: offset2.width + geo.size.width * 0.25, y: offset2.height - geo.size.height * 0.3)
                    .blur(radius: 30)
                    .opacity(0.18)
                
                Circle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color(red:0.18, green:0.54, blue:0.84).opacity(0.9), Color(red:0.10, green:0.34, blue:0.62).opacity(0.9)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: geo.size.width * 0.28, height: geo.size.width * 0.28)
                    .offset(x: offset3.width + geo.size.width * 0.12, y: offset3.height + geo.size.height * 0.2)
                    .blur(radius: 18)
                    .opacity(0.16)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                    offset1 = CGSize(width: 30, height: 16)
                }
                withAnimation(.easeInOut(duration: 14).repeatForever(autoreverses: true)) {
                    offset2 = CGSize(width: -22, height: 22)
                }
                withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                    offset3 = CGSize(width: -10, height: -16)
                }
            }
        }
    }
}

// MARK: - Animated Gradient (dark blue / energetic)
struct AnimatedGradientView: View {
    @Binding var animate: Bool
    @State private var angle: Double = 0
    @State private var shift: CGFloat = 0
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color(red: 0.02, green: 0.06, blue: 0.18), location: 0),
                .init(color: Color(red: 0.03, green: 0.12, blue: 0.30), location: 0.25),
                .init(color: Color(red: 0.10, green: 0.14, blue: 0.40), location: 0.5),
                .init(color: Color(red: 0.10, green: 0.18, blue: 0.50), location: 0.75),
                .init(color: Color(red: 0.05, green: 0.10, blue: 0.32), location: 1)
            ]),
            startPoint: UnitPoint(x: cos(angle + Double(shift)), y: sin(angle + Double(shift))),
            endPoint: UnitPoint(x: cos(angle + 3 + Double(shift)), y: sin(angle + 3 + Double(shift)))
        )
        .blendMode(.screen)
        .onAppear {
            withAnimation(.linear(duration: 18).repeatForever(autoreverses: true)) {
                angle = 6.0
            }
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                shift = 0.9
            }
        }
    }
}

// MARK: - Helpers
func colorForTemp(_ t: Double) -> Color {
    switch t {
        case ..<0: return Color.blue.opacity(0.9)
        case 0..<6: return Color.cyan
        case 6..<12: return Color.green
        case 12..<18: return Color.yellow
        case 18..<26: return Color.orange
        default: return Color.red
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
