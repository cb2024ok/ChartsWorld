import SwiftUI
import Charts

// 1. 시뮬레이션용 데이터 포인트 구조체 (Rust JointTrajectory 구조체 대응)
struct AppleTrackPoint: Identifiable {
    let id = UUID()
    let time: Double      // 시간 (초)
    let appleX: Double    // 사과 표면 X 좌표
    let appleY: Double    // 사과 표면 Y 좌표
    let shoulderDeg: Double // 어깨 각도 (Theta 1)
    let elbowDeg: Double    // 팔꿈치 각도 (Theta 2)
}

@Observable
class AppleTrajectoryPlanner {
    // 하드웨어 기하학 치수 설정 (Rust source 25 기준)
    let l1: Double = 10.0      // Link 1 길이 (cm)
    let l2: Double = 10.0      // Link 2 길이 (cm)
    let radius: Double = 5.0   // 사과 반지름 (cm)
    let centerX: Double = 10.0 // 사과 중심 X 좌표
    let centerY: Double = 0.0  // 사과 중심 Y 좌표
    
    var totalDuration: Double = 180.0 // 총 가동 시간 (3분)
    var currentTime: Double = 0.0     // 사용자가 조작할 시간 슬라이더 값
    
    // 전체 3분 동안의 궤적 사전 조립 (Rust의 Vec 생성 로직 반영)
    var fullPath: [AppleTrackPoint] {
        let dt = 1.0 // 시각화를 위해 1초 단위 샘플링
        var points: [AppleTrackPoint] = []
        let steps = Int(totalDuration / dt)
        
        for i in 0...steps {
            let t = Double(i) * dt
            let angle = (2.0 * .pi) * (t / totalDuration)
            
            // 1단계: 사과 표면 원형 궤적 (Rust source 25)
            let x = centerX + radius * cos(angle)
            let y = centerY + radius * sin(angle)
            
            // 2단계: 역기하학(IK) 코사인 법칙 연산
            let dSquared = x*x + y*y
            let cosTheta2 = (dSquared - l1*l1 - l2*l2) / (2.0 * l1 * l2)
            
            // 가동 범위 내 안전 체크
            if abs(cosTheta2) <= 1.0 {
                let theta2 = acos(cosTheta2)
                let theta1 = atan2(y, x) - atan2(l2 * sin(theta2), l1 + l2 * cos(theta2))
                
                points.append(AppleTrackPoint(
                    time: t,
                    appleX: x,
                    appleY: y,
                    shoulderDeg: theta1 * (180.0 / .pi),
                    elbowDeg: theta2 * (180.0 / .pi)
                ))
            }
        }
        return points
    }
    
    // 현재 시간(슬라이더 위치)에 매핑되는 관절 데이터 추출
    var currentFrame: AppleTrackPoint? {
        fullPath.min(by: { abs($0.time - currentTime) < abs($1.time - currentTime) })
    }
}

// 2. 물리 궤적 시각화 모니터링 캔버스 뷰
struct ApplePeelerCanvasView: View {
    @State private var planner = AppleTrajectoryPlanner()
    
    var body: some View {
        VStack(spacing: 20) {
            // 정보 리포트 패널 (Rust의 println 출력을 UI로 전환)
            if let frame = planner.currentFrame {
                VStack(alignment: .leading, spacing: 5) {
                    Text("🍎 사과 깎기 관절 계획 시뮬레이터")
                        .font(.headline).bold()
                    HStack {
                        Text("시간: \(String(format: "%.1f", frame.time))초")
                        Spacer()
                        Text("어깨: \(String(format: "%.2f", frame.shoulderDeg))°")
                        Spacer()
                        Text("팔꿈치: \(String(format: "%.2f", frame.elbowDeg))°")
                    }
                    .font(.caption).monospaced()
                    .foregroundColor(.secondary)
                }
                .padding([.horizontal, .top])
            }
            
            // 메인 2D 공간 궤적 차트
            Chart {
                // 1. 전체 사과 모양 원형 궤적선 그리기
                ForEach(planner.fullPath) { pt in
                    LinePlot(x: "X (cm)", y: "Y (cm)") { x in
                        // 원형 상단/하단 보간 매핑
                        if let match = planner.fullPath.first(where: { abs($0.appleX - x) < 0.2 }) {
                            return match.appleY
                        }
                        return 0.0
                    }
                    .foregroundStyle(.red.opacity(0.3))
                }
                
                // 2. 현재 로봇 팔이 물고 있는 타겟 포인트 점 찍기
                if let current = planner.currentFrame {
                    PointMark(
                        x: .value("Target X", current.appleX),
                        y: .value("Target Y", current.appleY)
                    )
                    .foregroundStyle(.green)
                    .symbolSize(100)
                }
            }
            .chartXScale(domain: 0...20)
            .chartYScale(domain: -10...10)
            .frame(height: 240)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // 시간 지연 0ms 제어 슬라이더 (오케스트레이션 타임라인)
            VStack(alignment: .leading) {
                Text("타임라인 제어선 (0 ~ 180초)")
                    .font(.footnote).bold()
                Slider(value: $planner.currentTime, in: 0...180, step: 0.1)
                    .tint(.red)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(14)
            .padding(.horizontal)
        }
    }
}
