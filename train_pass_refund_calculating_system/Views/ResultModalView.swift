//
//  ResultModalView.swift
//  train_pass_refund_calculating_system
//
//  Created by Taiyo KOSHIBA on 2025/06/05.
//

import SwiftUI

struct ResultModalView: View {
    @Bindable var calculationState: RefundCalculationState

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let result = calculationState.result {
                        // メイン結果表示（新しい構成）
                        MainResultCard(
                            result: result,
                            calculationType: calculationState.calculationType,
                            calculationState: calculationState
                        )

                        // アクションボタン群
                        ResultActionButtonsCard(calculationState: calculationState)
                    } else {
                        // エラー表示（通常は発生しないが念のため）
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            Text("計算結果の表示でエラーが発生しました")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    Spacer(minLength: 100) // 下部余白
                }
                .padding()
            }
            .navigationTitle("計算結果")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        calculationState.closeResultModal()
                    }
                }
            }
        }
        .sheet(isPresented: $calculationState.showPDFSheet) {
            PDFPreviewView(calculationState: calculationState)
        }
    }
}

// MARK: - 結果画面専用アクションボタンカード
struct ResultActionButtonsCard: View {
    @Bindable var calculationState: RefundCalculationState

    var body: some View {
        VStack(spacing: 12) {
            // PDF出力ボタン（払戻可能な場合のみ）
            if let result = calculationState.result, result.refundAmount > 0 {
                Button(action: {
                    calculationState.showPDFSheet = true
                }) {
                    HStack {
                        Image(systemName: "doc.richtext")
                        Text("結果をPDFで保存")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green)
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - プレビュー
#Preview {
    let state = RefundCalculationState()
    state.result = RefundResult(
        refundAmount: 15000,
        usedAmount: 5000,
        processingFee: 220,
        calculationDetails: "通常払戻: 使用1ヶ月（経過日数: 30日）、使用分運賃5000円"
    )
    state.calculationType = .regular
    state.passType = .threeMonths

    return ResultModalView(calculationState: state)
}
