//
//  FieldListView.swift
//  KIIKICK
//

import SwiftUI
import SwiftData

struct FieldListView: View {
    @Query(sort: \Field.name) private var fields: [Field]
    @State private var isPresentingRegistration = false
    
    var body: some View {
        List(fields) { field in
            Text(field.name)
        }
        .overlay {
            if fields.isEmpty {
                Text("등록된 운동장이 없습니다")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("운동장 관리")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("추가") { isPresentingRegistration = true }
            }
        }
        .sheet(isPresented: $isPresentingRegistration) {
            NavigationStack {
                FieldRegistrationView()
            }
        }
    }
}
