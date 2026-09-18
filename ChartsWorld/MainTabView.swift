import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .waveCanvas
    
    enum Tab {
        case waveCanvas
        case kinematics
        case hardware
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // 1. 실시간 신호 분석 & AI/DSP 하이브리드 진단
            NavigationStack {
                AIAnomalDetectorCanvas()
                    .navigationTitle("Wave Lab")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("파형 분석", systemImage: "waveform.path.ecg")
            }
            .tag(Tab.waveCanvas)

            // 2. 궤적 계획 & 역운동학(Kinematics) 모듈
            NavigationStack {
                //TrajectoryKinematicsView()
                ApplePeelerCanvasView()
                    .navigationTitle("Trajectory Engine")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("궤적 계산", systemImage: "gearshape.2")
            }
            .tag(Tab.kinematics)

            // 3. ESP32 / MCU 하드웨어 직접 통신 모듈
            NavigationStack {
                //HardwareBridgeView()
                KinematicsCanvasView()
                    .navigationTitle("MCU Bridge")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("하드웨어 제어", systemImage: "cpu")
            }
            .tag(Tab.hardware)
        }
        .tint(.blue) // 엔지니어링 툴 특유의 차분한 액센트 컬러
    }
}

// 궤적 계산 탭 임시 플레이스홀더
struct TrajectoryKinematicsView: View {
    var body: some View {
        VStack {
            Text("⚙️ Trajectory & Kinematics Engine")
                .font(.headline)
            Text("AppleTrajectoryPlanner & KinematicsOrchestrator")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// 하드웨어 제어 탭 임시 플레이스홀더
struct HardwareBridgeView: View {
    var body: some View {
        VStack {
            Text("🔌 ESP32 Hardware Bridge")
                .font(.headline)
            Text("Direct UART / BLE Low-Latency Pipeline")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
