//
//  EngineeringWaveCanvas.swift
//  ChartsWorld
//
//  Created by baby Enjhon on 9/15/26.
//

import SwiftUI
import Charts

struct EngineeringWaveCanvas: View {
    // 공학 파라미터 (진폭 A, 주파수 w, 위상 phi)
    @State private var amplitude: Double = 1.0
    @State private var frequency: Double = 2.0
    @State private var phase: Double = 0.0
    
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
            .frame(height: 300)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 4)
            
            // 2. 실시간 파라미터 조절 슬라이더 카드 (Live Parameter Tuning)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("진폭 (A): \(amplitude, specifier: "%.2f")")
                    Slider(value: $amplitude, in: 0.1...3.0)
                }
                HStack {
                    Text("주파수 (w): \(frequency, specifier: "%.2f")")
                    Slider(value: $frequency, in: 0.1...10.0)
                }
                HStack {
                    Text("위상 (phi): \(phase, specifier: "%.2f")")
                    Slider(value: $phase, in: 0.0...Double.pi * 2)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .padding()
    }
}
