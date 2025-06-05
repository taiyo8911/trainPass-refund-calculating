//
//  ContentView.swift
//  train_pass_refund_calculating_system
//
//  Created by Taiyo KOSHIBA on 2025/06/03.
//


import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tram.fill")
                .imageScale(.large)
                .foregroundStyle(.blue)
                .font(.system(size: 50))

            Text("JR定期券払い戻し計算")
                .font(.title)
                .fontWeight(.bold)

            Text("テストを実行してコンソールで結果を確認")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button(action: {
                print("🚀 テスト開始...")
                runRefundCalculatorTests()
                print("✅ テスト完了。コンソールを確認してください。")
            }) {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("テストを実行")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }

            Text("⚠️ 実行後はXcodeのデバッグコンソール（⌘+Shift+Y）で結果を確認してください")
                .font(.caption)
                .foregroundColor(.orange)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
