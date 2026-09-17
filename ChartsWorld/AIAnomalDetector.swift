//
//  EngineeringWaveCanvas.swift
//  ChartsWorld
//
//  Created by baby Enjhon on 9/15/26.
//  Enhanced with Local AI Orchestration
//

import SwiftUI
import Charts
// ⚠️ 애플 순정 온디바이스 생성형 AI 프레임워크 탑재
import FoundationModels 

@Observable
class AIAnomalDetector {
    private var session: LanguageModelSession?
    var aiGuidance: String = "신호를 분석 대기 중..."
    var isAnalyzing: Bool = false
    
    init() {
        // 100% 오프라인으로 작동할 로컬 LLM의 페르소나 설정
        let systemInstructions = """
        당신은 로봇 및 제어공학 신호 분석 전문가입니다. 
        입력되는 진폭(A), 주파수(w), 위상(phi) 수치를 보고 시스템의 안정성 상태를 엔지니어 관점에서 한 줄로 날카롭게 요약하세요.
        """
        self.session = LanguageModelSession(instructions: systemInstructions)
    }
    
    /// 슬라이더를 멈추거나 신호가 바뀔 때 백그라운드 NPU에서 비동기로 분석을 처리하는 함수
    func analyzeSignal(amplitude: Double, frequency: Double, phase: Double) async {
        guard let session = session else { return }
        
        await MainActor.run { self.isAnalyzing = true }
        
        // 로컬 LLM에게 전달할 순수 하드웨어 물리 데이터 컨텍스트 구성
        let prompt = """
        현재 관측 파형 데이터 리포트:
        - 진폭(Amplitude): \(amplitude)
        - 주파수(Frequency): \(frequency) rad/s
        - 위상(Phase): \(phase) rad
        현재 주파수가 너무 높거나 진폭이 과도하여 모터 발열 및 탈조 위험이 있는지 진단 가이드를 간결하게 한 문장으로 제공하세요.
        """
        
        do {
            // 외부 서버 통신 없이 100% 내 맥북/아이폰 내부에서만 추론 실행
            let response = try await session.respond(to: prompt)
            await MainActor.run {
                self.aiGuidance = response.content
                self.isAnalyzing = false
            }
        } catch {
            /*await MainActor.run {
                self.aiGuidance = "로컬 AI 연산 에러: \(error.localizedDescription)"
                self.isAnalyzing = false
            }*/
            await runRuleBasedDiagnostic(
                amplitude: amplitude,
                frequency: frequency
            )
        }
    }
    
    /// NPU/Apple Intelligence 미지원 기기를 위한 로컬 수학/공학 알고리즘 진단 모드
    private func runRuleBasedDiagnostic(amplitude: Double, frequency: Double) async {
            await MainActor.run {
                self.isAnalyzing = false
                if frequency > 8.0 {
                    self.aiGuidance = "⚠️ [Rule Engine] 고주파 영역 진입: 모터 탈조 및 과열 위험이 높습니다."
                } else if amplitude > 2.5 {
                    self.aiGuidance = "⚠️ [Rule Engine] 과도 진폭: 기계적 진동으로 인한 스텝 손실에 주의하세요."
                } else {
                    self.aiGuidance = "✅ [Rule Engine] 시스템 응답이 안정적인 제어 범위 내에 있습니다."
                }
            }
    }
}

struct AIAnomalDetectorCanvas: View {
    // 공학 파라미터 (진폭 A, 주파수 w, 위상 phi)
    @State private var amplitude: Double = 1.0
    @State private var frequency: Double = 2.0
    @State private var phase: Double = 0.0
    
    // 🤖 온디바이스 AI 매니저 주입
    @State private var aiDetector = AIAnomalDetector()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("y = \(amplitude, specifier: "%.1f") • sin(\(frequency, specifier: "%.1f")x + \(phase, specifier: "%.1f"))")
                .font(.system(.title3, design: .monospaced))
                .fontWeight(.bold)
            
            let currentAmplitude = amplitude
            let currentFrequency = frequency
            let currentPhase = phase
            
            // 1. 고성능 수식 렌더링 캔버스 (Swift Charts LinePlot)
            Chart {
                LinePlot(x: "x", y: "y", domain: -5.0...5.0) { x in
                    // 유저 파라미터가 적용된 정밀 수식 연산
                    currentAmplitude * sin(currentFrequency * x + currentPhase)
                }
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
            }
            .chartXScale(domain: -5...5)
            .chartYScale(domain: -3...3)
            .chartXAxisLabel("Time / Position (x)")
            .chartYAxisLabel("Amplitude / Velocity (y)")
            .frame(height: 260)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 4)
            
            // 🤖 2. 온디바이스 AI 실시간 진단 모니터링 레이어 (소름 돋는 핵심 본질)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("🤖 On-Device AI Diagnostic")
                        .font(.caption).bold()
                        .foregroundColor(.blue)
                    if aiDetector.isAnalyzing {
                        ProgressView().scaleEffect(0.7)
                    }
                }
                Text(aiDetector.aiGuidance)
                    .font(.footnote)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .cornerRadius(10)
            
            // 3. 실시간 파라미터 조절 슬라이더 카드 (Live Parameter Tuning)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("진폭 (A): \(amplitude, specifier: "%.2f")")
                        .frame(width: 110, alignment: .leading)
                    Slider(value: $amplitude, in: 0.1...3.0)
                }
                HStack {
                    Text("주파수 (w): \(frequency, specifier: "%.2f")")
                        .frame(width: 110, alignment: .leading)
                    Slider(value: $frequency, in: 0.1...10.0)
                }
                HStack {
                    Text("위상 (phi): \(phase, specifier: "%.2f")")
                        .frame(width: 110, alignment: .leading)
                    Slider(value: $phase, in: 0.0...Double.pi * 2)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            // 슬라이더 조작이 멈추거나 값이 바뀔 때 로컬 NPU에게 연산 요청 바인딩
            .onChange(of: amplitude) { triggerAI() }
            .onChange(of: frequency) { triggerAI() }
            .onChange(of: phase)     { triggerAI() }
        }
        .padding()
    }
    
    // 디바운스나 가벼운 태스크를 통해 슬라이더 이동 시 NPU 부하 최적화 트리거
    private func triggerAI() {
        Task {
            await aiDetector.analyzeSignal(amplitude: amplitude, frequency: frequency, phase: phase)
        }
    }
}
