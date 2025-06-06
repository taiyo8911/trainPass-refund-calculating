//
//  ContentView.swift
//  train_pass_refund_calculating_system
//
//  Created by Taiyo KOSHIBA on 2025/06/03.
//

import SwiftUI

struct ContentView: View {
    @State private var calculationState = RefundCalculationState()

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // 入力フォームセクション
                CompactInputFormSection(calculationState: calculationState)

                // 計算ボタン
                CalculateButton(calculationState: calculationState)

                Spacer() // 残りスペースを埋める
            }
            .padding()
            .navigationTitle("定期券払戻計算")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $calculationState.showResultModal) {
            ResultModalView(calculationState: calculationState)
        }
    }
}

// MARK: - 計算ボタン
struct CalculateButton: View {
    @Bindable var calculationState: RefundCalculationState

    var body: some View {
        Button(action: {
            calculationState.performCalculation()
        }) {
            HStack {
                if calculationState.isCalculating {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "calculator")
                }
                Text(calculationState.isCalculating ? "計算中..." : "払戻額を計算")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(calculationState.canCalculate ? Color.blue : Color.gray)
            )
        }
        .disabled(!calculationState.canCalculate)
        .animation(.easeInOut(duration: 0.2), value: calculationState.canCalculate)
    }
}

#Preview {
    ContentView()
}
