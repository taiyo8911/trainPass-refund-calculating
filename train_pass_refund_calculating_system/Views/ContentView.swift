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
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        // ヘッダーセクション
                        HeaderSection(calculationState: calculationState)

                        // 入力フォームセクション
                        InputFormSection(calculationState: calculationState)

                        // 計算ボタン
                        CalculateButton(calculationState: calculationState) {
                            // 計算実行後、結果部分にスクロール
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    proxy.scrollTo("result", anchor: .top)
                                }
                            }
                        }

                        // 結果表示セクション
                        if calculationState.showResult {
                            ResultSection(calculationState: calculationState)
                                .id("result")
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        Spacer(minLength: 100) // 下部余白
                    }
                    .padding()
                }
                .navigationTitle("定期券払戻計算")
                .navigationBarTitleDisplayMode(.large)
            }
        }
        .sheet(isPresented: $calculationState.showPDFSheet) {
            PDFPreviewView(calculationState: calculationState)
        }
    }
}

// MARK: - ヘッダーセクション
struct HeaderSection: View {
    @Bindable var calculationState: RefundCalculationState

    var body: some View {
        VStack(spacing: 16) {
            // アプリ説明
            Text("通勤定期券の払戻金額を計算します")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // 計算方式選択
            Picker("計算方式", selection: $calculationState.calculationType) {
                ForEach(RefundCalculationType.allCases, id: \.self) { type in
                    Text(type.description).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: calculationState.calculationType) { _, _ in
                calculationState.resetResult()
            }

            // 計算方式の説明
            Text(calculationTypeDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    private var calculationTypeDescription: String {
        switch calculationState.calculationType {
        case .regular:
            return "定期券の有効期間内での一般的な払戻計算です。残存月数が1ヶ月以上必要です。"
        case .sectionChange:
            return "定期券の区間変更に伴う払戻計算です。旬数（10日単位）での精密計算を行います。"
        }
    }
}

// MARK: - 入力フォームセクション
struct InputFormSection: View {
    @Bindable var calculationState: RefundCalculationState

    var body: some View {
        VStack(spacing: 20) {
            // 基本情報
            BasicInfoSection(calculationState: calculationState)

            // 日付入力
            DateInputSection(calculationState: calculationState)

            // 金額入力
            PriceInputSection(calculationState: calculationState)

            // バリデーションエラー表示
            if !calculationState.validationErrors.isEmpty {
                ErrorSection(errors: calculationState.validationErrors)
            }
        }
    }
}

// MARK: - 基本情報セクション
struct BasicInfoSection: View {
    @Bindable var calculationState: RefundCalculationState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "基本情報", icon: "info.circle")

            // 定期券種別選択
            VStack(alignment: .leading, spacing: 8) {
                Text("定期券種別")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Picker("定期券種別", selection: $calculationState.passType) {
                    ForEach(PassType.allCases, id: \.self) { type in
                        Text(type.description).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: calculationState.passType) { _, _ in
                    calculationState.resetResult()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - 日付入力セクション
struct DateInputSection: View {
    @Bindable var calculationState: RefundCalculationState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "日付", icon: "calendar")

            VStack(spacing: 16) {
                // 開始日
                DatePicker(
                    "開始日",
                    selection: $calculationState.startDate,
                    displayedComponents: .date
                )
                .onChange(of: calculationState.startDate) { _, _ in
                    calculationState.resetResult()
                }

                // 払戻日
                DatePicker(
                    "払戻日",
                    selection: $calculationState.refundDate,
                    displayedComponents: .date
                )
                .onChange(of: calculationState.refundDate) { _, _ in
                    calculationState.resetResult()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - 金額入力セクション
struct PriceInputSection: View {
    @Bindable var calculationState: RefundCalculationState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "金額", icon: "yensign.circle")

            VStack(spacing: 16) {
                // 購入価格（常に表示）
                PriceInputField(
                    title: "購入価格",
                    value: $calculationState.purchasePrice,
                    placeholder: "定期券の購入価格を入力"
                ) {
                    calculationState.resetResult()
                }

                // 片道普通運賃（通常払戻のみ）
                if calculationState.needsOneWayFare {
                    PriceInputField(
                        title: "片道普通運賃",
                        value: $calculationState.oneWayFare,
                        placeholder: "片道の普通運賃を入力"
                    ) {
                        calculationState.resetResult()
                    }
                }

                // 1ヶ月定期運賃（常に表示）
                PriceInputField(
                    title: "1ヶ月定期運賃",
                    value: $calculationState.oneMonthFare,
                    placeholder: "1ヶ月定期の運賃を入力"
                ) {
                    calculationState.resetResult()
                }

                // 3ヶ月定期運賃（6ヶ月定期のみ）
                if calculationState.needsThreeMonthFare {
                    PriceInputField(
                        title: "3ヶ月定期運賃",
                        value: $calculationState.threeMonthFare,
                        placeholder: "3ヶ月定期の運賃を入力"
                    ) {
                        calculationState.resetResult()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - 計算ボタン
struct CalculateButton: View {
    @Bindable var calculationState: RefundCalculationState
    let onCalculate: () -> Void

    var body: some View {
        Button(action: {
            calculationState.performCalculation()
            onCalculate()
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
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(calculationState.canCalculate ? Color.blue : Color.gray)
            )
        }
        .disabled(!calculationState.canCalculate)
        .animation(.easeInOut(duration: 0.2), value: calculationState.canCalculate)
    }
}

// MARK: - 結果表示セクション
struct ResultSection: View {
    @Bindable var calculationState: RefundCalculationState
    @State private var showDetailExpanded = false

    var body: some View {
        VStack(spacing: 20) {
            if let result = calculationState.result {
                // メイン結果表示
                MainResultCard(result: result)

                // 計算詳細
                CalculationDetailCard(
                    result: result,
                    calculationType: calculationState.calculationType,
                    isExpanded: $showDetailExpanded
                )

                // アクションボタン群
                ActionButtonsCard(calculationState: calculationState)
            }
        }
    }
}

// MARK: - メイン結果カード
struct MainResultCard: View {
    let result: RefundResult

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

            // 払戻額表示
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("払戻額")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }

                HStack {
                    Text("¥\(result.refundAmount.formattedWithComma)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(result.refundAmount > 0 ? .primary : .red)
                    Spacer()
                }
            }

            // 基本情報サマリー
            if result.refundAmount > 0 {
                Divider()

                VStack(spacing: 8) {
                    ResultSummaryRow(
                        title: "使用分運賃",
                        value: "¥\(result.usedAmount.formattedWithComma)",
                        icon: "minus.circle"
                    )

                    ResultSummaryRow(
                        title: "手数料",
                        value: "¥\(result.processingFee.formattedWithComma)",
                        icon: "minus.circle"
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - 計算詳細カード
struct CalculationDetailCard: View {
    let result: RefundResult
    let calculationType: RefundCalculationType
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ヘッダー（タップで展開/折りたたみ）
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundColor(.blue)

                    Text("計算詳細")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())

            // 詳細内容（展開時のみ表示）
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // 計算方式の説明
                    Text(calculationType.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)

                    // 計算詳細
                    Text(result.calculationDetails)
                        .font(.body)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )

                    // 注意事項
                    if result.refundAmount == 0 {
                        WarningBox(message: "払戻ができない理由: \(result.calculationDetails)")
                    } else if calculationType == .regular {
                        InfoBox(message: "通常払戻では、残存期間が1ヶ月以上必要です。")
                    } else {
                        InfoBox(message: "区間変更払戻では、旬数（10日単位）で計算されます。")
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - アクションボタンカード
struct ActionButtonsCard: View {
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

            // 新しい計算ボタン
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    calculationState.resetToDefaults()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("新しい計算を開始")
                }
                .font(.headline)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 2)
                        .fill(Color.clear)
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - サポートビュー

struct ResultSummaryRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

struct InfoBox: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
                .font(.caption)

            Text(message)
                .font(.caption)
                .foregroundColor(.blue)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct WarningBox: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.caption)

            Text(message)
                .font(.caption)
                .foregroundColor(.orange)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

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
import PDFKit

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

        // ヘッダー
        yPosition = drawHeader(yPosition: yPosition)
        yPosition += 30

        // 基本情報
        yPosition = drawBasicInfo(inputData: inputData, yPosition: yPosition)
        yPosition += 20

        // 計算結果
        yPosition = drawResult(result: result, yPosition: yPosition)
        yPosition += 20

        // 計算詳細
        yPosition = drawCalculationDetails(result: result, calculationType: calculationType, yPosition: yPosition)

        // フッター
        drawFooter()
    }

    private func drawHeader(yPosition: CGFloat) -> CGFloat {
        let title = "通勤定期券払戻計算書"
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

    private func drawBasicInfo(inputData: PDFInputData, yPosition: CGFloat) -> CGFloat {
        var currentY = yPosition

        // セクションタイトル
        currentY = drawSectionTitle("基本情報", yPosition: currentY)
        currentY += 10

        let font = UIFont.systemFont(ofSize: 12)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"

        // 情報項目
        let basicInfoItems = [
            ("計算方式", inputData.calculationType.description),
            ("定期券種別", inputData.passType.description),
            ("開始日", dateFormatter.string(from: inputData.startDate)),
            ("払戻日", dateFormatter.string(from: inputData.refundDate)),
            ("購入価格", "¥\(inputData.purchasePrice.formattedWithComma)"),
            ("1ヶ月定期運賃", "¥\(inputData.oneMonthFare.formattedWithComma)")
        ]

        var items = basicInfoItems

        if let oneWayFare = inputData.oneWayFare {
            items.append(("片道普通運賃", "¥\(oneWayFare.formattedWithComma)"))
        }

        if let threeMonthFare = inputData.threeMonthFare {
            items.append(("3ヶ月定期運賃", "¥\(threeMonthFare.formattedWithComma)"))
        }

        for (label, value) in items {
            currentY = drawInfoRow(label: label, value: value, yPosition: currentY, font: font)
            currentY += 5
        }

        return currentY
    }

    private func drawResult(result: RefundResult, yPosition: CGFloat) -> CGFloat {
        var currentY = yPosition

        // セクションタイトル
        currentY = drawSectionTitle("計算結果", yPosition: currentY)
        currentY += 10

        // 払戻額（大きく表示）
        let refundAmountText = "¥\(result.refundAmount.formattedWithComma)"
        let refundFont = UIFont.boldSystemFont(ofSize: 28)
        let refundColor = result.refundAmount > 0 ? UIColor.systemGreen : UIColor.systemRed
        let refundAttributes: [NSAttributedString.Key: Any] = [
            .font: refundFont,
            .foregroundColor: refundColor
        ]

        let refundSize = refundAmountText.size(withAttributes: refundAttributes)
        let refundX = (pageWidth - refundSize.width) / 2
        refundAmountText.draw(at: CGPoint(x: refundX, y: currentY), withAttributes: refundAttributes)
        currentY += refundSize.height + 15

        // 結果詳細
        if result.refundAmount > 0 {
            let font = UIFont.systemFont(ofSize: 12)
            let resultItems = [
                ("使用分運賃", "¥\(result.usedAmount.formattedWithComma)"),
                ("手数料", "¥\(result.processingFee.formattedWithComma)")
            ]

            for (label, value) in resultItems {
                currentY = drawInfoRow(label: label, value: value, yPosition: currentY, font: font)
                currentY += 5
            }
        }

        return currentY
    }

    private func drawCalculationDetails(result: RefundResult, calculationType: RefundCalculationType, yPosition: CGFloat) -> CGFloat {
        var currentY = yPosition

        // セクションタイトル
        currentY = drawSectionTitle("計算詳細", yPosition: currentY)
        currentY += 10

        // 詳細内容
        let detailFont = UIFont.systemFont(ofSize: 11)
        let detailAttributes: [NSAttributedString.Key: Any] = [
            .font: detailFont,
            .foregroundColor: UIColor.darkGray
        ]

        let detailText = result.calculationDetails
        let detailRect = CGRect(
            x: margin,
            y: currentY,
            width: pageWidth - 2 * margin,
            height: 200 // 十分な高さを確保
        )

        detailText.draw(in: detailRect, withAttributes: detailAttributes)

        return currentY + 50 // 適当な高さを追加
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

        label.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: attributes)
        value.draw(at: CGPoint(x: margin + 150, y: yPosition), withAttributes: attributes)

        let lineHeight = label.size(withAttributes: attributes).height
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
}

extension DateFormatter {
    static let current: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter
    }()
}

// MARK: - 共通コンポーネント

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
}

struct PriceInputField: View {
    let title: String
    @Binding var value: String
    let placeholder: String
    let onChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)

            TextField(placeholder, text: $value)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: value) { _, _ in
                    onChange()
                }
        }
    }
}

struct ErrorSection: View {
    let errors: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("入力エラー")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
            }

            ForEach(errors, id: \.self) { error in
                Text("• \(error)")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
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
