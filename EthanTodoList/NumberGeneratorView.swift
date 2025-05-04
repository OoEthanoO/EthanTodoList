import SwiftUI

struct NumberGeneratorView: View {
    @AppStorage("numbers28String") private var numbers28String: String = ""
    @AppStorage("numbers24String") private var numbers24String: String = ""
    @AppStorage("numbers90String") private var numbers90String: String = ""
    @AppStorage("numbersGenerationDate") private var numbersGenerationDate: Date = Date()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title and generate button
                HStack {
                    Text("Random Number Generator")
                        .font(.title)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            generateRandomNumbers()
                        }
                    }) {
                        Label("Generate", systemImage: "dice")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("g", modifiers: [.command])
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Generated numbers display
                VStack(alignment: .leading, spacing: 20) {
                    if !numbers28String.isEmpty {
                        Text("Last generated: \(timeFormatter.string(from: numbersGenerationDate))")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            numberSection(title: "Numbers (1-28):", numbers: numbers28String)
                            
                            Divider()
                            
                            numberSection(title: "Numbers (1-24):", numbers: numbers24String)
                            
                            Divider()
                            
                            numberSection(title: "Numbers (1-90):", numbers: numbers90String)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    } else {
                        Text("No numbers generated yet. Press 'Generate' to create random numbers.")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 60)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                .padding([.horizontal, .bottom])
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Properties & Methods
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    private func numberSection(title: String, numbers: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            
            Text(numbers)
                .font(.system(.title3, design: .monospaced))
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
        }
    }
    
    private func generateRandomNumbers() {
        // Generate 10 random numbers from 1 to 28
        let randomNumbers28 = (0..<10).map { _ in
            Int.random(in: 1...28)
        }
        numbers28String = randomNumbers28.map { "\($0)" }.joined(separator: ", ")
        
        // Generate 10 random numbers from 1 to 24
        let randomNumbers24 = (0..<10).map { _ in
            Int.random(in: 1...24)
        }
        numbers24String = randomNumbers24.map { "\($0)" }.joined(separator: ", ")
        
        // Generate 10 random numbers from 1 to 90
        let randomNumbers90 = (0..<10).map { _ in
            Int.random(in: 1...90)
        }
        numbers90String = randomNumbers90.map { "\($0)" }.joined(separator: ", ")
        
        // Update timestamp
        numbersGenerationDate = Date()
    }
}
