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

// MARK: - 入力フォームセクション
struct CompactInputFormSection: View {
    @Bindable var calculationState: RefundCalculationState

    var body: some View {
        VStack(spacing: 12) {
            // 計算方式選択
            VStack(alignment: .leading, spacing: 4) {
                Text("計算方式")
                    .font(.caption)
                    .fontWeight(.medium)

                Picker("計算方式", selection: $calculationState.calculationType) {
                    ForEach(RefundCalculationType.allCases, id: \.self) { type in
                        Text(type.description).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: calculationState.calculationType) { _, _ in
                    calculationState.resetResult()
                }
            }

            // 定期券種別選択
            VStack(alignment: .leading, spacing: 4) {
                Text("定期券種別")
                    .font(.caption)
                    .fontWeight(.medium)

                Picker("種別", selection: $calculationState.passType) {
                    ForEach(PassType.allCases, id: \.self) { type in
                        Text(type.rawValue == 1 ? "1ヶ月" : type.rawValue == 3 ? "3ヶ月" : "6ヶ月").tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: calculationState.passType) { _, _ in
                    calculationState.resetResult()
                }
            }

            // 日付入力（縦並び）
            VStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("開始日")
                        .font(.caption)
                        .fontWeight(.medium)
                    HStack {
                        DatePicker("", selection: $calculationState.startDate, displayedComponents: .date)
                            .labelsHidden()
                            .environment(\.locale, Locale(identifier: "ja_JP"))
                            .onChange(of: calculationState.startDate) { _, _ in
                                calculationState.resetResult()
                            }
                        Spacer()
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("払戻日")
                        .font(.caption)
                        .fontWeight(.medium)
                    HStack {
                        DatePicker("", selection: $calculationState.refundDate, displayedComponents: .date)
                            .labelsHidden()
                            .environment(\.locale, Locale(identifier: "ja_JP"))
                            .onChange(of: calculationState.refundDate) { _, _ in
                                calculationState.resetResult()
                            }
                        Spacer()
                    }
                }
            }

            // 金額入力
            CompactPriceInputSection(calculationState: calculationState)

            // バリデーションエラー表示
            if !calculationState.validationErrors.isEmpty {
                CompactErrorSection(errors: calculationState.validationErrors)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.1), radius: 1, x: 0, y: 1)
        )
    }
}

// MARK: - 金額入力セクション
struct CompactPriceInputSection: View {
    @Bindable var calculationState: RefundCalculationState

    var body: some View {
        VStack(spacing: 8) {
            // 定期券購入価格（常に表示）
            CompactPriceField(
                title: "定期券購入価格",
                value: $calculationState.purchasePrice,
                placeholder: "定期券購入価格"
            ) {
                calculationState.resetResult()
            }

            // 1ヶ月定期運賃（常に表示）
            CompactPriceField(
                title: "1ヶ月定期運賃",
                value: $calculationState.oneMonthFare,
                placeholder: "1ヶ月運賃"
            ) {
                calculationState.resetResult()
            }

            // 片道普通運賃（通常払戻のみ）
            if calculationState.needsOneWayFare {
                CompactPriceField(
                    title: "片道普通運賃",
                    value: $calculationState.oneWayFare,
                    placeholder: "片道運賃"
                ) {
                    calculationState.resetResult()
                }
            }

            // 3ヶ月定期運賃（6ヶ月定期のみ）
            if calculationState.needsThreeMonthFare {
                CompactPriceField(
                    title: "3ヶ月定期運賃",
                    value: $calculationState.threeMonthFare,
                    placeholder: "3ヶ月運賃"
                ) {
                    calculationState.resetResult()
                }
            }
        }
    }
}

// MARK: - 金額入力フィールド
struct CompactPriceField: View {
    let title: String
    @Binding var value: String
    let placeholder: String
    let onChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            TextField(placeholder, text: $value)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.subheadline)
                .onChange(of: value) { _, _ in
                    onChange()
                }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - エラーセクション
struct CompactErrorSection: View {
    let errors: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
                Text("入力エラー")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
            }

            ForEach(errors, id: \.self) { error in
                Text("• \(error)")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
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

// MARK: - 拡張
extension Int {
    var formattedWithComma: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? String(self)
    }
}

#Preview {
    ContentView()
}
