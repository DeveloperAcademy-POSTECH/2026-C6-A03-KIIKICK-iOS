//
//  FieldCoordinateMapper.swift
//  KIIKICK
//
//  GPS 좌표 <-> 운동장 내 정규화 좌표(0...1, 0...1) 변환.
//  4개 꼭짓점이 완벽한 직사각형이 아니어도(GPS 핀 오차) 동작하도록
//  bilinear 사각형 보간의 역변환을 Newton-Raphson으로 근사한다.
//

import CoreLocation
import CoreGraphics

struct FieldCoordinateMapper {
    private let p00: CGPoint
    private let p10: CGPoint
    private let p11: CGPoint
    private let p01: CGPoint
    
    private let referenceLatitude: Double
    private let referenceLongitude: Double
    private let metersPerLongitudeDegree: Double
    private static let metersPerLatitudeDegree = 111_320.0

    init(field: Field) {
        self.init(corners: [field.cornerA, field.cornerB, field.cornerC, field.cornerD].map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        })
    }

    init(corners: [CLLocationCoordinate2D]) {
        precondition(corners.count == 4)
        let latitude = corners.map(\.latitude).reduce(0, +) / 4
        let longitude = corners.map(\.longitude).reduce(0, +) / 4
        let longitudeScale = Self.metersPerLatitudeDegree * cos(latitude * .pi / 180)
        referenceLatitude = latitude
        referenceLongitude = longitude
        metersPerLongitudeDegree = longitudeScale
        let points = corners.map {
            CGPoint(x: ($0.longitude - longitude) * longitudeScale,
                    y: ($0.latitude - latitude) * Self.metersPerLatitudeDegree)
        }
        let centroid = CGPoint(x: points.map(\.x).reduce(0, +) / 4,
                               y: points.map(\.y).reduce(0, +) / 4)
        var ordered = points.sorted {
            atan2($0.y - centroid.y, $0.x - centroid.x) < atan2($1.y - centroid.y, $1.x - centroid.x)
        }
        func length(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(b.x - a.x, b.y - a.y) }
        let firstPair = length(ordered[0], ordered[1]) + length(ordered[2], ordered[3])
        let secondPair = length(ordered[1], ordered[2]) + length(ordered[3], ordered[0])
        // 긴 변은 위·경도의 도수가 아닌 미터 단위로 비교하고 대변 쌍의 평균으로 정한다.
        if secondPair > firstPair {
            ordered = Array(ordered[1...]) + [ordered[0]]
        }
        // 로컬 평면은 동쪽→오른쪽, 북쪽→위쪽이지만 화면 세로축은 아래로 증가한다.
        // CCW 둘레를 그대로 화면에 대응시키면 긴 축을 기준으로 거울상이 된다.
        // 긴 변의 진행 방향은 유지하고 위/아래 꼭짓점 쌍을 바꿔 회전만 일어나도록 한다.
        p00 = ordered[3]
        p10 = ordered[2]
        p11 = ordered[1]
        p01 = ordered[0]
    }

    /// 정규화 좌표 (0,0) → (1,0) → (1,1) → (0,1)에 대응하는 실제 꼭짓점.
    var orderedCorners: [CLLocationCoordinate2D] {
        [p00, p10, p11, p01].map {
            CLLocationCoordinate2D(latitude: referenceLatitude + $0.y / Self.metersPerLatitudeDegree,
                                   longitude: referenceLongitude + $0.x / metersPerLongitudeDegree)
        }
    }

    var horizontalLengthMeters: Double { hypot(p10.x - p00.x, p10.y - p00.y) }
    var verticalLengthMeters: Double { hypot(p01.x - p00.x, p01.y - p00.y) }

    /// 위도/경도 -> 운동장 내 정규화 좌표 (x: 0...1, y: 0...1 근방).
    func normalize(_ coordinate: CLLocationCoordinate2D) -> CGPoint {
        let target = CGPoint(x: (coordinate.longitude - referenceLongitude) * metersPerLongitudeDegree,
                             y: (coordinate.latitude - referenceLatitude) * Self.metersPerLatitudeDegree)
        var u: CGFloat = 0.5
        var v: CGFloat = 0.5
        
        for _ in 0..<12 {
            let f = bilinear(u: u, v: v)
            let rx = f.x - target.x
            let ry = f.y - target.y
            
            let fxu = (1 - v) * (p10.x - p00.x) + v * (p11.x - p01.x)
            let fxv = (1 - u) * (p01.x - p00.x) + u * (p11.x - p10.x)
            let fyu = (1 - v) * (p10.y - p00.y) + v * (p11.y - p01.y)
            let fyv = (1 - u) * (p01.y - p00.y) + u * (p11.y - p10.y)
            
            let det = fxu * fyv - fxv * fyu
            guard abs(det) > 1e-12 else { break }
            
            let du = (rx * fyv - ry * fxv) / det
            let dv = (fxu * ry - fyu * rx) / det
            
            u -= du
            v -= dv
            
            if abs(du) < 1e-9 && abs(dv) < 1e-9 { break }
        }
        
        return CGPoint(x: u, y: v)
    }
    
    private func bilinear(u: CGFloat, v: CGFloat) -> CGPoint {
        let x = (1 - u) * (1 - v) * p00.x + u * (1 - v) * p10.x + (1 - u) * v * p01.x + u * v * p11.x
        let y = (1 - u) * (1 - v) * p00.y + u * (1 - v) * p10.y + (1 - u) * v * p01.y + u * v * p11.y
        return CGPoint(x: x, y: y)
    }
}
