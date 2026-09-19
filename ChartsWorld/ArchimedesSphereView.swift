//
//  ArchimedesSphereView.swift
//  ChartsWorld
//
//  Created by baby Enjhon on 9/19/26.
//


import SwiftUI
import SceneKit
import WebKit

struct ArchimedesSphereView: View {
    @Binding var radius: Float
    @Binding var sliceX: Float

    var body: some View {
        SceneView(
            scene: makeScene(),
            options: [.autoenablesDefaultLighting, .allowsCameraControl]
        )
    }

    // Helper to create a SceneKit scene visualizing the sphere and a slice
    private func makeScene() -> SCNScene {
        let scene = SCNScene()

        // Sphere node
        let sphere = SCNSphere(radius: CGFloat(radius))
        sphere.firstMaterial?.diffuse.contents = UIColor.systemGreen.withAlphaComponent(0.7)
        sphere.firstMaterial?.isDoubleSided = true
        let sphereNode = SCNNode(geometry: sphere)
        scene.rootNode.addChildNode(sphereNode)

        // Plane node to show the slice
        let plane = SCNPlane(width: CGFloat(radius*2), height: CGFloat(radius*2))
        plane.firstMaterial?.diffuse.contents = UIColor.systemOrange.withAlphaComponent(0.5)
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3(0, CGFloat(sliceX), 0)
        planeNode.eulerAngles = SCNVector3(-Float.pi/2, 0, 0)
        scene.rootNode.addChildNode(planeNode)

        // Camera setup
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, Float(radius * 3))
        scene.rootNode.addChildNode(cameraNode)

        return scene
    }
}

// MARK: - LaTeX 수식 렌더러 (반응형 모바일 맞춤 CSS)
struct MathView: UIViewRepresentable {
    let latex: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
            <script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
            <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
            <style>
                body {
                    background-color: transparent;
                    color: #2C3E50;
                    font-size: 14px;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    margin: 0;
                    padding: 8px;
                }
                .mjx-chtml {
                    font-size: 100% !important;
                }
            </style>
        </head>
        <body>
            $$\(latex)$$
        </body>
        </html>
        """
        uiView.loadHTMLString(htmlString, baseURL: nil)
    }
}

// MARK: - SwiftUI 메인 콘솔 (ScrollView 적용 및 SafeArea 처리)
struct GeometricEngineView: View {
    @State private var radius: Float = 5.0
    @State private var sliceX: Float = -3.0
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 16) {
                Text("Archimedes' Volume Proof")
                    .font(.title2.bold())
                    .padding(.top, 8)
                
                // 3D SceneKit View
                ArchimedesSphereView(radius: $radius, sliceX: $sliceX)
                    .frame(height: 280)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)
                
                // 수식 컨트롤 패널
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Radius (r): \(radius, specifier: "%.1f")")
                        Spacer()
                        Text("Slice Height (x): \(sliceX, specifier: "%.1f")")
                    }
                    .font(.headline)
                    
                    Slider(value: $sliceX, in: -radius...radius) {
                        Text("Slice Position")
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        let sphereArea = Double.pi * Double(radius*radius - sliceX*sliceX)
                        let coneArea = Double.pi * Double(sliceX * sliceX)
                        let cylinderArea = Double.pi * Double(radius*radius)
                        
                        HStack {
                            Circle().fill(Color.green).frame(width: 8, height: 8)
                            Text("Sphere Slice Area: \(sphereArea, specifier: "%.2f")")
                        }
                        
                        HStack {
                            Circle().fill(Color.orange).frame(width: 8, height: 8)
                            Text("Cone Slice Area: \(coneArea, specifier: "%.2f")")
                        }
                        
                        Divider().frame(width: 200)
                        
                        HStack {
                            Circle().fill(Color.blue).frame(width: 8, height: 8)
                            Text("Sphere + Cone: \(sphereArea + coneArea, specifier: "%.2f")")
                                .bold()
                        }
                        
                        HStack {
                            Circle().fill(Color.blue).frame(width: 8, height: 8)
                            Text("Cylinder Slice Area: \(cylinderArea, specifier: "%.2f")")
                                .foregroundColor(.blue)
                                .bold()
                        }
                    }
                    .font(.system(.subheadline, design: .monospaced))
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // 수식 패널 (LaTeX 가로 분할 렌더링)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Mathematical Proof")
                        .font(.headline)
                    
                    Divider()
                    
                    // 1. 단면적 정의
                    MathView(latex: """
                    \\begin{aligned}
                    \\text{Sphere} &= \\pi(r^2 - x^2) \\\\[2pt]
                    \\text{Cone} &= \\pi x^2 \\\\[2pt]
                    \\text{Cylinder} &= \\pi r^2
                    \\end{aligned}
                    """)
                    .frame(height: 100)
                    
                    Divider()
                    
                    // 2. 부피 증명
                    MathView(latex: """
                    \\begin{aligned}
                    V_{\\text{Sphere}} + V_{\\text{Cone}} &= V_{\\text{Cylinder}} \\\\[4pt]
                    V_{\\text{Sphere}} &= 2\\pi r^3 - \\frac{2}{3}\\pi r^3 = \\frac{4}{3}\\pi r^3
                    \\end{aligned}
                    """)
                    .frame(height: 90)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }
}

#Preview {
    GeometricEngineView()
}

