# trainPass-refund-calculating

# 通勤定期券払戻計算システム仕様書

## 1. システム概要
通勤定期券の払戻金額を自動計算するiOSアプリケーションシステム。通常払戻と区間変更払戻の2つの計算方式に対応し、定期券の種類（1ヶ月、3ヶ月、6ヶ月）に応じた正確な計算を実行する。

## 2. 機能仕様

### 2.1 対応する定期券種別
- **1ヶ月定期券**: 使用開始から7日以内の特別ルール適用
- **3ヶ月定期券**: 使用開始から7日以内の特別ルール適用、月単位での使用分運賃計算
- **6ヶ月定期券**: 使用開始から7日以内の特別ルール適用、月単位での使用分運賃計算、3ヶ月以上使用している場合は3ヶ月定期運賃を基準とした計算

### 2.2 払戻計算方式
1. **通常払戻** (`RegularRefundCalculator`)
   - 定期券の有効期間内での一般的な払戻
   - 残存月数が1ヶ月以上必要（1ヶ月定期除く）
   
2. **区間変更払戻** (`SectionChangeRefundCalculator`)
   - 定期券の区間変更に伴う払戻
   - 旬数（10日単位）での計算
   - 日割運賃による精密計算

## 3. データ構造

### 3.1 共通データ型（`CommonTypes.swift`）

#### PassType (定期券種別)
```swift
enum PassType: Int, CaseIterable {
    case oneMonth = 1      // 1ヶ月定期
    case threeMonths = 3   // 3ヶ月定期  
    case sixMonths = 6     // 6ヶ月定期
}
```

#### RefundResult (払戻結果)
```swift
struct RefundResult {
    let refundAmount: Int        // 最終払戻額
    let usedAmount: Int          // 使用分運賃
    let processingFee: Int       // 手数料（固定220円）
    let calculationDetails: String // 計算詳細説明
}
```

#### RefundCalculationType (払戻計算方式)
```swift
enum RefundCalculationType: String, CaseIterable {
    case regular = "regular"           // 通常払戻
    case sectionChange = "sectionChange" // 区間変更払戻
}
```

### 3.2 通常払戻用データ構造（`RegularRefundCalculator.swift`）

#### RefundData
- **基本入力項目**
  - `startDate`: 開始日
  - `passType`: 定期券種別
  - `purchasePrice`: 発売額
  - `refundDate`: 払戻日
  - `oneWayFare`: 片道普通運賃
  - `oneMonthFare`: 1ヶ月定期運賃
  - `threeMonthFare`: 3ヶ月定期運賃（6ヶ月定期の3ヶ月以上使用時の計算に必要）

- **自動計算項目**
  - `endDate`: 終了日（定期券有効期限）
  - `elapsedDays`: 使用日数（開始日含む）
  - `remainingDays`: 残存日数
  - `remainingMonths`: 残存月数
  - `usedMonths`: 使用月数
  - `roundTripFare`: 往復普通運賃（片道運賃×2）
  - `processingFee`: 払戻手数料（固定220円）

### 3.3 区間変更払戻用データ構造（`SectionChangeRefundCalculator.swift`）

#### SectionChangeRefundData
- **基本入力項目**
  - `startDate`: 開始日
  - `passType`: 定期券種別
  - `purchasePrice`: 発売額
  - `refundDate`: 払戻日
  - `oneMonthFare`: 1ヶ月定期運賃
  - `threeMonthFare`: 3ヶ月定期運賃（6ヶ月定期の3ヶ月以上使用時に必要）

- **自動計算項目**
  - `elapsedDays`: 経過日数（開始日含む）
  - `usedJun`: 使用旬数（10日単位、端数は1旬扱い）
  - `dailyFare`: 日割運賃（1円未満切り上げ）
  - `processingFee`: 払戻手数料（固定220円）

## 4. 計算ロジック仕様

### 4.1 通常払戻計算 (`RegularRefundCalculator`)

#### 4.1.1 1ヶ月定期の払戻計算
- **使用開始から7日以内の場合**
  ```
  払戻額 = max(0, 購入価格 - (往復運賃 × 使用日数) - 手数料)
  ```
- **使用開始から7日を超えた場合**
  ```
  払戻額 = 0円（払戻不可）
  ```

#### 4.1.2 3ヶ月定期の払戻計算
- **使用開始から7日以内の場合**
  ```
  払戻額 = max(0, 購入価格 - (往復運賃 × 使用日数) - 手数料)
  ```
- **使用開始から7日を超えた場合**
  - 残存期間が1ヶ月以上必要
- **計算方式**
  - **1-2ヶ月使用**: `使用分運賃 = 1ヶ月定期運賃 × 使用月数`
  ```
  払戻額 = 購入価格 - 使用分運賃 - 手数料
  ```

#### 4.1.3 6ヶ月定期の払戻計算
- **使用開始から7日以内の場合**
  ```
  払戻額 = max(0, 購入価格 - (往復運賃 × 使用日数) - 手数料)
  ```
- **使用開始から7日を超えた場合**
  - 残存期間が1ヶ月以上必要
  - **3ヶ月定期運賃の入力が必須**
- **計算方式**
  - **1-2ヶ月使用**: `使用分運賃 = 1ヶ月定期運賃 × 使用月数`
  - **3ヶ月以上使用**: `使用分運賃 = 3ヶ月定期運賃 + (1ヶ月定期運賃 × 追加月数)`
  ```
  払戻額 = 購入価格 - 使用分運賃 - 手数料
  ```

### 4.2 区間変更払戻計算 (`SectionChangeRefundCalculator`)

#### 4.2.1 旬数計算ロジック
```swift
使用旬数 = (経過日数 ÷ 10) + (端数 > 0 ? 1 : 0)
```

#### 4.2.2 日割運賃計算
- **1ヶ月定期**: `日割運賃 = ceil(1ヶ月定期運賃 ÷ 30)`
- **3ヶ月定期**: `日割運賃 = ceil(3ヶ月定期運賃 ÷ 90)`
- **6ヶ月定期**: `日割運賃 = ceil(購入価格 ÷ 180)`

※1円未満切り上げ

#### 4.2.3 最終計算
```swift
使用分運賃 = 使用旬数 × 日割運賃 × 10
払戻額 = max(0, 購入価格 - 使用分運賃 - 手数料)
```

## 5. 入力検証仕様

### 5.1 共通検証項目
- `払戻日 ≥ 開始日`
- 6ヶ月定期の場合、3ヶ月定期運賃の入力必須

### 5.2 通常払戻固有の検証
- `払戻日 ≤ 終了日`（定期券有効期限内）

### 5.3 区間変更払戻固有の検証
- `払戻日 ≤ 開始日 + 6ヶ月`（現実的な範囲内）

## 6. 出力仕様

### 6.1 計算結果出力（RefundResult）
- **refundAmount**: 最終払戻額
- **usedAmount**: 使用分運賃
- **processingFee**: 払戻手数料（220円固定）
- **calculationDetails**: 計算詳細説明文

### 6.2 詳細ログ出力
- コンソールに詳細な計算過程を出力
- エラー時は具体的なエラー理由を表示
- 7日以内の場合は特別な注意喚起を表示

## 7. プロジェクト構造

### 7.1 Models
- `CommonTypes.swift`: 共通データ型定義
- `RegularRefundCalculator.swift`: 通常払戻計算ロジック
- `SectionChangeRefundCalculator.swift`: 区間変更払戻計算ロジック

### 7.2 Views
- `ContentView.swift`: メイン画面
- `MainSelectionView.swift`: 計算方式選択画面（未実装）
- `InputView.swift`: データ入力画面（未実装）
- `ResultView.swift`: 計算結果表示画面（未実装）

### 7.3 Test Files
- `RefundCalculatorTest.swift`: テストケース実装

### 7.4 App Configuration
- `train_pass_refund_calculating_systemApp.swift`: アプリエントリーポイント
- `Assets.xcassets/`: アプリアイコンとカラーリソース

## 8. テスト仕様

### 8.1 実装済みテストケース（`RefundCalculatorTest.swift`）
1. 1ヶ月定期（5日使用、7日以内）
2. 1ヶ月定期（15日使用、7日超）
3. 3ヶ月定期（1ヶ月使用）
4. 3ヶ月定期（2ヶ月使用）
5. 6ヶ月定期（2ヶ月使用）
6. 6ヶ月定期（4ヶ月使用）
7. 6ヶ月定期（5ヶ月使用）
8. 6ヶ月定期（5日使用）

### 8.2 区間変更払戻デモ（`SectionChangeRefundDemo`）
- 正常ケース、境界値ケース、エラーケースを網羅
- 旬数計算の検証ケースを含む

## 9. 技術仕様

- **開発言語**: Swift
- **フレームワーク**: SwiftUI
- **対象プラットフォーム**: iOS
- **アーキテクチャ**: MVVM（予定）
- **日付処理**: Foundation.Calendar使用

## 10. 制約事項・特記事項

### 10.1 固定値
- 払戻手数料: 220円（固定）
- 日割計算基準日数: 1ヶ月=30日、3ヶ月=90日、6ヶ月=180日

### 10.2 計算精度
- 日割運賃は1円未満切り上げ
- 最終払戻額は0円未満にならない（max(0, 計算結果)）

## 11. 今後の実装予定

### 11.1 UI実装
- 計算方式選択画面
- データ入力画面（日付ピッカー、数値入力）
- 結果表示画面（計算詳細表示）

### 11.2 機能拡張
- 計算履歴保存
- PDFレポート出力
