//
//  AnalysisDiagnostics.swift
//  KIIKICK
//
//  이슈 #96: 운동장 변경이 안 되거나 버튼이 안 뜨는 원인을 기기에서 확인하기 위한
//  진단 출력. 어떤 경기가 로컬 기록을 갖고 있는지(= 운동장을 바꿀 수 있는지),
//  서버 제출 상태가 어떤지를 한 번에 찍는다. DEBUG 빌드 전용이며 기능에는 영향이 없다.
//

#if DEBUG
import Foundation

enum AnalysisDiagnostics {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter
    }()

    /// 목록 전체를 찍는다. `source`는 로컬 기록인지 서버 복원인지 구분용.
    static func dump(entries: [AnalysisEntry], source: String) {
        print("[#96] ===== \(source) 경기 \(entries.count)개 =====")
        for entry in entries {
            dump(entry: entry, source: source)
        }
        print("[#96] ===== \(source) 끝 =====")
    }

    static func dump(entry: AnalysisEntry, source: String) {
        let assignment = FieldAssignment(quarters: entry.detail.quarters.map {
            FieldAssignment.QuarterInput(id: $0.id, record: $0.sourceRecord, field: $0.field)
        })
        print("[#96] --- \(formatter.string(from: entry.date)) | \(entry.dateAndQuarter) | 운동장=\(entry.fieldName) | 출처=\(source)")
        print("[#96]     records=\(entry.records.count) quarters=\(entry.detail.quarters.count) " +
              "isEditable=\(assignment.isEditable) hasMissingFields=\(assignment.hasMissingFields) " +
              "commonField=\(assignment.commonField?.name ?? "nil")")
        for (index, quarter) in entry.detail.quarters.enumerated() {
            let record = quarter.sourceRecord
            print("[#96]     쿼터[\(index)] no=\(quarter.quarterNumber) position=\(quarter.position ?? "nil") " +
                  "quarter.field=\(quarter.field?.name ?? "nil") " +
                  "sourceRecord=\(record == nil ? "없음" : "있음") " +
                  "record.field=\(record?.field?.name ?? "nil") " +
                  "record.field.serverID=\(record?.field?.serverID?.uuidString.lowercased() ?? "nil") " +
                  "points=\(quarter.points.count)")
        }
        for (index, record) in entry.records.enumerated() {
            print("[#96]     record[\(index)] matchId=\(record.matchId.uuidString.lowercased()) " +
                  "quarterId=\(record.quarterId.uuidString.lowercased()) " +
                  "hasViewedAnalysis=\(record.hasViewedAnalysis) " +
                  "idempotencyKey=\(record.submissionIdempotencyKey?.uuidString ?? "nil") " +
                  "ifMatch=\(record.submissionIfMatch ?? "nil")")
        }
    }
}
#endif
