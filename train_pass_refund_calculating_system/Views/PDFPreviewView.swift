//
//  PDFPreviewView.swift
//  train_pass_refund_calculating_system
//
//  Created by Taiyo KOSHIBA on 2025/06/06.
//


import SwiftUI
import PDFKit

// MARK: - PDFプレビュー
struct PDFPreviewView: View {
    @Bindable var calculationState: RefundCalculationState
    @State private var pdfData: Data?
    @State private var isGeneratingPDF = false
    @State private var showShareSheet = false

    var body: some View {
        NavigationView {
            VStack {
                if isGeneratingPDF {
                    // PDF生成中
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("PDFを生成中...")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let pdfData = pdfData {
                    // PDFプレビュー
                    PDFPreview(data: pdfData)
                } else {
                    // エラー表示
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("PDFの生成に失敗しました")
                            .font(.headline)
                        Button("再試行") {
                            generatePDF()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("計算結果PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        calculationState.showPDFSheet = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(pdfData == nil)
                }
            }
            .onAppear {
                generatePDF()
            }
            .sheet(isPresented: $showShareSheet) {
                if let pdfData = pdfData {
                    ShareSheet(items: [pdfData])
                }
            }
        }
    }

    private func generatePDF() {
        isGeneratingPDF = true

        DispatchQueue.global(qos: .userInitiated).async {
            let generator = PDFGenerator()
            let data = generator.generatePDF(
                result: calculationState.result,
                calculationType: calculationState.calculationType,
                inputData: createInputDataForPDF()
            )

            DispatchQueue.main.async {
                self.pdfData = data
                self.isGeneratingPDF = false
            }
        }
    }

    private func createInputDataForPDF() -> PDFInputData {
        return PDFInputData(
            calculationType: calculationState.calculationType,
            passType: calculationState.passType,
            startDate: calculationState.startDate,
            refundDate: calculationState.refundDate,
            purchasePrice: Int(calculationState.purchasePrice) ?? 0,
            oneWayFare: Int(calculationState.oneWayFare),
            oneMonthFare: Int(calculationState.oneMonthFare) ?? 0,
            threeMonthFare: Int(calculationState.threeMonthFare)
        )
    }
}

// MARK: - PDFプレビューコンポーネント
struct PDFPreview: View {
    let data: Data

    var body: some View {
        if let url = saveToTemporaryFile(data: data) {
            PDFKitView(url: url)
        } else {
            Text("PDFの表示に失敗しました")
                .foregroundColor(.red)
        }
    }

    private func saveToTemporaryFile(data: Data) -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFile = tempDirectory.appendingPathComponent("refund_calculation.pdf")

        do {
            try data.write(to: tempFile)
            return tempFile
        } catch {
            print("Failed to save PDF to temporary file: \(error)")
            return nil
        }
    }
}

// MARK: - PDFKitView (UIViewRepresentable)
struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        // No updates needed
    }
}

// MARK: - 共有シート
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiView: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - PDF生成データ構造
struct PDFInputData {
    let calculationType: RefundCalculationType
    let passType: PassType
    let startDate: Date
    let refundDate: Date
    let purchasePrice: Int
    let oneWayFare: Int?
    let oneMonthFare: Int
    let threeMonthFare: Int?
}

// MARK: - PDF生成クラス
class PDFGenerator {
    private let pageWidth: CGFloat = 595.2  // A4 width in points
    private let pageHeight: CGFloat = 841.8 // A4 height in points
    private let margin: CGFloat = 50

    func generatePDF(result: RefundResult?, calculationType: RefundCalculationType, inputData: PDFInputData) -> Data? {
        guard let result = result else { return nil }

        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight),
            format: format
        )

        return renderer.pdfData { context in
            context.beginPage()
            drawPDFContent(result: result, calculationType: calculationType, inputData: inputData)
        }
    }

    private func drawPDFContent(result: RefundResult, calculationType: RefundCalculationType, inputData: PDFInputData) {
        var yPosition: CGFloat = margin

        // 1. ヘッダー
        yPosition = drawHeader(yPosition: yPosition)
        yPosition += 30

        // 2. 定期券詳細セクション
        yPosition = drawPassDetailSection(inputData: inputData, yPosition: yPosition)
        yPosition += 20

        // 3. 使用状況セクション
        yPosition = drawUsageStatusSection(result: result, inputData: inputData, yPosition: yPosition)
        yPosition += 20

        // 4. 払戻金額セクション
        yPosition = drawRefundCalculationSection(result: result, inputData: inputData, yPosition: yPosition)

        // 5. フッター
        drawFooter()
    }

    private func drawHeader(yPosition: CGFloat) -> CGFloat {
        let title = "定期券払戻計算書"
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]

        let titleSize = title.size(withAttributes: titleAttributes)
        let titleX = (pageWidth - titleSize.width) / 2

        title.draw(at: CGPoint(x: titleX, y: yPosition), withAttributes: titleAttributes)

        return yPosition + titleSize.height
    }

    private func drawPassDetailSection(inputData: PDFInputData, yPosition: CGFloat) -> CGFloat {
        var currentY = yPosition

        // セクションタイトル
        currentY = drawSectionTitle("▼ 定期券詳細", yPosition: currentY)
        currentY += 10

        let font = UIFont.systemFont(ofSize: 12)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"

        // 終了日を計算
        let endDate = calculateEndDate(startDate: inputData.startDate, passType: inputData.passType)

        // 情報項目
        let passDetailItems = [
            ("種別", inputData.passType.description),
            ("期間", "\(dateFormatter.string(from: inputData.startDate)) ～ \(dateFormatter.string(from: endDate))"),
            ("購入価格", "¥\(inputData.purchasePrice.formattedWithComma)")
        ]

        for (label, value) in passDetailItems {
            currentY = drawInfoRow(label: "\(label):", value: value, yPosition: currentY, font: font)
            currentY += 18
        }

        return currentY
    }

    private func drawUsageStatusSection(result: RefundResult, inputData: PDFInputData, yPosition: CGFloat) -> CGFloat {
        var currentY = yPosition

        // セクションタイトル
        currentY = drawSectionTitle("▼ 使用状況", yPosition: currentY)
        currentY += 10

        let font = UIFont.systemFont(ofSize: 12)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"

        // 払戻申請日
        currentY = drawInfoRow(
            label: "払戻申請日:",
            value: dateFormatter.string(from: inputData.refundDate),
            yPosition: currentY,
            font: font
        )
        currentY += 18

        // 実際使用期間
        let usagePeriodInfo = createUsagePeriodInfo(inputData: inputData)
        currentY = drawInfoRow(
            label: "実際使用期間:",
            value: usagePeriodInfo,
            yPosition: currentY,
            font: font
        )
        currentY += 18

        // 使用分運賃
        currentY = drawInfoRow(
            label: "使用分運賃:",
            value: "¥\(result.usedAmount.formattedWithComma)",
            yPosition: currentY,
            font: font
        )
        currentY += 18

        // 計算根拠（インデント付き）
        let calculationBasis = createCalculationBasis(result: result, inputData: inputData)
        currentY = drawInfoRow(
            label: "　└ 計算根拠:",
            value: calculationBasis,
            yPosition: currentY,
            font: font
        )
        currentY += 18

        return currentY
    }

    private func drawRefundCalculationSection(result: RefundResult, inputData: PDFInputData, yPosition: CGFloat) -> CGFloat {
        var currentY = yPosition

        // セクションタイトル
        let sectionTitle = "▼ 払戻金額（\(inputData.calculationType.description)）"
        currentY = drawSectionTitle(sectionTitle, yPosition: currentY)
        currentY += 15

        let font = UIFont.systemFont(ofSize: 12)
        let boldFont = UIFont.boldSystemFont(ofSize: 12)

        // 計算詳細
        currentY = drawCalculationRow(
            label: "購入価格",
            value: "¥\(inputData.purchasePrice.formattedWithComma)",
            yPosition: currentY,
            font: font
        )
        currentY += 18

        currentY = drawCalculationRow(
            label: "使用分運賃",
            value: "-¥\(result.usedAmount.formattedWithComma)",
            yPosition: currentY,
            font: font
        )
        currentY += 18

        currentY = drawCalculationRow(
            label: "手数料",
            value: "-¥\(result.processingFee.formattedWithComma)",
            yPosition: currentY,
            font: font
        )
        currentY += 18

        // 罫線
        currentY = drawSeparatorLine(yPosition: currentY)
        currentY += 10

        // 払戻金額
        if result.refundAmount > 0 {
            currentY = drawCalculationRow(
                label: "払戻金額",
                value: "¥\(result.refundAmount.formattedWithComma)",
                yPosition: currentY,
                font: boldFont
            )
        } else {
            currentY = drawCalculationRow(
                label: "払戻金額",
                value: "払戻不可",
                yPosition: currentY,
                font: boldFont,
                isError: true
            )
        }

        return currentY + 30
    }

    private func drawSectionTitle(_ title: String, yPosition: CGFloat) -> CGFloat {
        let titleFont = UIFont.boldSystemFont(ofSize: 16)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]

        title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)

        let titleSize = title.size(withAttributes: titleAttributes)
        return yPosition + titleSize.height
    }

    private func drawInfoRow(label: String, value: String, yPosition: CGFloat, font: UIFont) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black
        ]

        if !label.isEmpty {
            label.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: attributes)
            value.draw(at: CGPoint(x: margin + 150, y: yPosition), withAttributes: attributes)
        } else {
            value.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: attributes)
        }

        let lineHeight = value.size(withAttributes: attributes).height
        return yPosition + lineHeight
    }

    private func drawFooter() {
        let footerText = "作成日時: \(DateFormatter.current.string(from: Date()))"
        let footerFont = UIFont.systemFont(ofSize: 10)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]

        let footerSize = footerText.size(withAttributes: footerAttributes)
        let footerY = pageHeight - margin - footerSize.height
        let footerX = (pageWidth - footerSize.width) / 2

        footerText.draw(at: CGPoint(x: footerX, y: footerY), withAttributes: footerAttributes)
    }

    // MARK: - ヘルパーメソッド

    private func calculateEndDate(startDate: Date, passType: PassType) -> Date {
        let calendar = Calendar.current
        let tempEndDate: Date
        switch passType {
        case .oneMonth:
            tempEndDate = calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        case .threeMonths:
            tempEndDate = calendar.date(byAdding: .month, value: 3, to: startDate) ?? startDate
        case .sixMonths:
            tempEndDate = calendar.date(byAdding: .month, value: 6, to: startDate) ?? startDate
        }
        return calendar.date(byAdding: .day, value: -1, to: tempEndDate) ?? tempEndDate
    }

    private func createUsagePeriodInfo(inputData: PDFInputData) -> String {
        let calendar = Calendar.current
        let normalizedStartDate = calendar.startOfDay(for: inputData.startDate)
        let normalizedRefundDate = calendar.startOfDay(for: inputData.refundDate)

        let elapsedComponents = calendar.dateComponents([.day], from: normalizedStartDate, to: normalizedRefundDate)
        let elapsedDays = (elapsedComponents.day ?? 0) + 1

        if inputData.calculationType == .sectionChange {
            // 区間変更払戻の場合：旬数表示
            let totalDays = elapsedDays
            let fullJun = totalDays / 10
            let remainder = totalDays % 10
            let usedJun = fullJun + (remainder > 0 ? 1 : 0)
            return "\(elapsedDays)日間（\(usedJun)旬）"
        } else {
            // 通常払戻の場合：月数表示
            if elapsedDays <= 7 {
                return "\(elapsedDays)日間（7日以内）"
            } else {
                let monthComponents = calendar.dateComponents([.month], from: inputData.startDate, to: inputData.refundDate)
                let usedMonths = (monthComponents.month ?? 0) + 1
                return "\(elapsedDays)日間（約\(usedMonths)ヶ月）"
            }
        }
    }

    private func createCalculationBasis(result: RefundResult, inputData: PDFInputData) -> String {
        if inputData.calculationType == .sectionChange {
            // 区間変更払戻の場合
            switch inputData.passType {
            case .oneMonth:
                return "1ヶ月定期運賃 ¥\(inputData.oneMonthFare.formattedWithComma)"
            case .threeMonths:
                let fare = inputData.threeMonthFare ?? inputData.oneMonthFare
                return "3ヶ月定期運賃 ¥\(fare.formattedWithComma)"
            case .sixMonths:
                return "6ヶ月定期運賃 ¥\(inputData.purchasePrice.formattedWithComma)"
            }
        } else {
            // 通常払戻の場合
            let calendar = Calendar.current
            let normalizedStartDate = calendar.startOfDay(for: inputData.startDate)
            let normalizedRefundDate = calendar.startOfDay(for: inputData.refundDate)
            let elapsedComponents = calendar.dateComponents([.day], from: normalizedStartDate, to: normalizedRefundDate)
            let elapsedDays = (elapsedComponents.day ?? 0) + 1

            if elapsedDays <= 7 {
                // 7日以内の場合
                if let oneWayFare = inputData.oneWayFare {
                    return "往復運賃 ¥\(oneWayFare * 2) × \(elapsedDays)日"
                }
            } else {
                // 月単位計算の場合
                let monthComponents = calendar.dateComponents([.month], from: inputData.startDate, to: inputData.refundDate)
                let usedMonths = (monthComponents.month ?? 0) + 1

                if inputData.passType == .sixMonths && usedMonths >= 3 {
                    if let threeMonthFare = inputData.threeMonthFare {
                        let additionalMonths = usedMonths - 3
                        if additionalMonths > 0 {
                            return "3ヶ月定期運賃 ¥\(threeMonthFare.formattedWithComma) + 1ヶ月定期運賃 ¥\(inputData.oneMonthFare.formattedWithComma) × \(additionalMonths)ヶ月"
                        } else {
                            return "3ヶ月定期運賃 ¥\(threeMonthFare.formattedWithComma)"
                        }
                    }
                } else {
                    return "1ヶ月定期運賃 ¥\(inputData.oneMonthFare.formattedWithComma) × \(usedMonths)ヶ月"
                }
            }
        }
        return "1ヶ月定期運賃 ¥\(inputData.oneMonthFare.formattedWithComma)"
    }

    private func drawCalculationRow(label: String, value: String, yPosition: CGFloat, font: UIFont, isError: Bool = false) -> CGFloat {
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black
        ]

        let valueColor = isError ? UIColor.systemRed : UIColor.black
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: valueColor
        ]

        // ラベルを左揃えで表示（適切な幅で調整）
        label.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: labelAttributes)

        // 値を右揃えで表示
        let valueSize = value.size(withAttributes: valueAttributes)
        let valueX = pageWidth - margin - valueSize.width
        value.draw(at: CGPoint(x: valueX, y: yPosition), withAttributes: valueAttributes)

        return yPosition + valueSize.height
    }

    private func drawSeparatorLine(yPosition: CGFloat) -> CGFloat {
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(UIColor.black.cgColor)
        context?.setLineWidth(1.0)
        context?.move(to: CGPoint(x: margin, y: yPosition))
        context?.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
        context?.strokePath()

        return yPosition + 5
    }
}

extension DateFormatter {
    static let current: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter
    }()
}
