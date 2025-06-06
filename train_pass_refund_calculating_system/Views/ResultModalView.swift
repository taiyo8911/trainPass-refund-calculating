//
//  ResultModalView.swift
//  train_pass_refund_calculating_system
//
//  Created by Taiyo KOSHIBA on 2025/06/06.
//

import SwiftUI

// MARK: - 結果モーダルビュー
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

// MARK: - メイン結果カード
struct MainResultCard: View {
    let result: RefundResult
    let calculationType: RefundCalculationType
    let calculationState: RefundCalculationState

    var body: some View {
        VStack(spacing: 16) {
            // 結果ステータス
            HStack {
                Image(systemName: result.refundAmount > 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(result.refundAmount > 0 ? .green : .red)

                Text(result.refundAmount > 0 ? "払戻可能" : "払戻不可")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(result.refundAmount > 0 ? .green : .red)

                Spacer()
            }

            Divider()

            // 詳細情報
            VStack(spacing: 12) {
                ResultDetailRow(title: "計算方式", value: calculationType.description)

                ResultDetailRow(title: "定期購入金額", value: "¥\(Int(calculationState.purchasePrice) ?? 0)")

                ResultDetailRow(title: "経過日数", value: "\(calculateElapsedDays(from: calculationState.startDate, to: calculationState.refundDate))日")

                ResultDetailRow(title: "使用分運賃", value: "¥\(result.usedAmount.formattedWithComma)")

                ResultDetailRow(title: "手数料", value: "¥\(result.processingFee.formattedWithComma)")
            }

            Divider()

            // 払戻額（大きく表示）
            VStack(spacing: 8) {
                Text("払戻額")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("¥\(result.refundAmount.formattedWithComma)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(result.refundAmount > 0 ? .primary : .red)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }

    // 経過日数計算のヘルパー関数
    private func calculateElapsedDays(from startDate: Date, to endDate: Date) -> Int {
        let calendar = Calendar.current
        let normalizedStartDate = calendar.startOfDay(for: startDate)
        let normalizedEndDate = calendar.startOfDay(for: endDate)

        let components = calendar.dateComponents([.day], from: normalizedStartDate, to: normalizedEndDate)
        return (components.day ?? 0) + 1 // 開始日を含むため+1
    }
}

// MARK: - 結果詳細行
struct ResultDetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
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

// MARK: - 拡張メソッド
extension Int {
    var formattedWithComma: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? String(self)
    }
}

// MARK: - プレビュー
#Preview("払戻可能ケース") {
    let state = RefundCalculationState()
    state.result = RefundResult(
        refundAmount: 15000,
        usedAmount: 5000,
        processingFee: 220,
        calculationDetails: "通常払戻: 使用1ヶ月（経過日数: 30日）、使用分運賃5000円"
    )
    state.calculationType = .regular
    state.passType = .threeMonths
    state.purchasePrice = "20000"

    return ResultModalView(calculationState: state)
}

#Preview("払戻不可ケース") {
    let state = RefundCalculationState()
    state.result = RefundResult(
        refundAmount: 0,
        usedAmount: 18000,
        processingFee: 220,
        calculationDetails: "1ヶ月定期は使用開始から8日以降は払戻不可（経過日数: 15日）"
    )
    state.calculationType = .regular
    state.passType = .oneMonth
    state.purchasePrice = "16000"

    return ResultModalView(calculationState: state)
}
