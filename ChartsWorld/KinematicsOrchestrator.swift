import SwiftUI
import Charts

// 1. 데이터 모델 정의 (Rust의 Point 및 결과 구조체 매핑)
struct WavePoint: Identifiable {
    let id = UUID()
    let t: Double
    let x: Double
    let y: Double
    let theta1Deg: Double
    let pwm: Int
}

enum ElbowConfig {
    case up, down
}

@Observable
class KinematicsOrchestrator {
    // 로봇 팔 길이 설정 (Rust source 11 기준: L1=150mm, L2=150mm)
    let l1: Double = 150.0
    let l2: Double = 150.0
    
    // 조작 가능한 중간 가속 제어점 (Rust의 handle Point 역할)
    var handleX: Double = 45.0 { didSet { recalculate() } }
    var handleY: Double = 90.0 { didSet { recalculate() } }
    var selectedConfig: ElbowConfig = .up { didSet { recalculate() } }
    
    // Computed가 아닌 저장 프로퍼티로 전환하여 UI 스레드 연산 분리
    private(set) var trajectory: [WavePoint] = []

    init() { recalculate() }
    
    func recalculate() {
            // 무거운 연산은 백그라운드 태스크로 분리
            Task.detached(priority: .userInitiated) {
                let points = await self.computeTrajectory()
                await MainActor.run {
                    self.trajectory = points
                }
            }
        }
    
    // 궤적 생성 (t = 0.0 ... 1.0)
    private func computeTrajectory() -> [WavePoint] {
        let startX: Double = 0.0
        let startY: Double = 0.0
        let endX: Double = 180.0
        let endY: Double = 180.0
        
        return stride(from: 0.0, through: 1.0, by: 0.02).compactMap { t in
            // 1단계: Quadratic Bezier 적용 (Rust lerp 기반 궤적 생성)
            let x1 = (1.0 - t) * startX + t * handleX
            let y1 = (1.0 - t) * startY + t * handleY
            let x2 = (1.0 - t) * handleX + t * endX
            let y2 = (1.0 - t) * handleY + t * endY
            
            let posX = (1.0 - t) * x1 + t * x2
            let posY = (1.0 - t) * y1 + t * y2
            
            // 2단계: 역기구학(IK) 계산
            let distSq = posX * posX + posY * posY
            let dist = sqrt(distSq)
            
            // 도달 범위 가드레일 (Rust의 Out of reach 방어)
            if dist > (l1 + l2) || dist < abs(l1 - l2) { return nil }
            
            let cosTheta2 = (distSq - l1*l1 - l2*l2) / (2.0 * l1 * l2)
            let clampedCos = max(-1.0, min(1.0, cosTheta2))
            let sinTheta2 = sqrt(1.0 - clampedCos * clampedCos)
            
            let theta2: Double
            switch selectedConfig {
            case .up:   theta2 = -atan2(sinTheta2, clampedCos) // Elbow Up
            case .down: theta2 = atan2(sinTheta2, clampedCos)  // Elbow Down
            }
            
            let theta1 = atan2(posY, posX) - atan2(l2 * sin(theta2), l1 + l2 * cos(theta2))
            let theta1Deg = theta1 * (180.0 / .pi)
            
            // 3단계: 안전 가드레일 기반 서보 PWM 매핑 (Rust source 11, 20 로직)
            let degClamped = (theta1Deg).clamped(to: 0.0...180.0)
            let pwm = (degClamped - 0.0) * (2500.0 - 500.0) / (180.0 - 0.0) + 500.0
            
            // 최종 펄스 물리 한계 하드 가드 (Rust source 20의 Safe Clamp)
            let finalPWM = max(500, min(2500, Int(pwm)))
            
            return WavePoint(t: t, x: posX, y: posY, theta1Deg: theta1Deg, pwm: finalPWM)
        }
    }
}

// 2. 미려한 120Hz GPU 직결 UI 뷰 캠퍼스 구성
struct KinematicsCanvasView: View {
    @State private var manager = KinematicsOrchestrator()
    
    var body: some View {
        VStack(spacing: 20) {
            // 상단 모니터링 수식 대용 정보 패널
            VStack(alignment: .leading, spacing: 5) {
                Text("🦾 Physical Robot Canvas")
                    .font(.title3).bold()
                    .foregroundColor(.primary)
                Text("Handle Point: (\(Int(manager.handleX)), \(Int(manager.handleY)))")
                    .font(.caption).monospaced()
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            // 메인 120Hz 렌더링 캔버스 (Swift Charts LinePlot)
            Chart {
                ForEach(manager.trajectory) { point in
                    LineMark(
                            x: .value("X 궤적", point.x),
                            y: .value("Y 궤적", point.y)
                        )
                        .foregroundStyle(.blue)
                }
            }
            .chartXScale(domain: 0...200)
            .chartYScale(domain: 0...200)
            .frame(height: 260)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
            
            // 실시간 물리 조작계 (슬라이더 세트)
            VStack(spacing: 15) {
                Picker("Elbow Config", selection: $manager.selectedConfig) {
                    Text("Elbow UP").tag(ElbowConfig.up)
                    Text("Elbow DOWN").tag(ElbowConfig.down)
                }
                .pickerStyle(.segmented)
                
                VStack(alignment: .leading) {
                    Text("가속 제어점 X: \(Int(manager.handleX))")
                        .font(.footnote).bold()
                    Slider(value: $manager.handleX, in: 10...100)
                }
                
                VStack(alignment: .leading) {
                    Text("가속 제어점 Y: \(Int(manager.handleY))")
                        .font(.footnote).bold()
                    Slider(value: $manager.handleY, in: 30...150)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

// 헬퍼 확장
extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
