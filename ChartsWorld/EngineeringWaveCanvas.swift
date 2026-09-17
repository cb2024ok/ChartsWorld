import SwiftUI
import Charts
import FoundationModels

struct EngineeringWaveCanvas: View {
    @State private var amplitude: Double = 1.0
    @State private var frequency: Double = 2.0
    @State private var phase: Double = 0.0
    @State private var aiDetector = AIAnomalDetector()

    var body: some View {
        VStack(spacing: 20) {
            Text("y = \(amplitude, specifier: "%.1f") • sin(\(frequency, specifier: "%.1f")x + \(phase, specifier: "%.1f"))")
                .font(.system(.title3, design: .monospaced))
                .fontWeight(.bold)
            let currentAmplitude = amplitude
            let currentFrequency = frequency
            let currentPhase = phase
            Chart {
                LinePlot(x: "x", y: "y", domain: -5.0...5.0) { x in
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
            .onChange(of: amplitude) { triggerAI() }
            .onChange(of: frequency) { triggerAI() }
            .onChange(of: phase)     { triggerAI() }
        }
        .padding()
    }

    private func triggerAI() {
        Task {
            await aiDetector.analyzeSignal(amplitude: amplitude, frequency: frequency, phase: phase)
        }
    }
}

