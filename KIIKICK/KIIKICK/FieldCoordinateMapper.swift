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

    init(field: Field) {
        let corners = [field.cornerA, field.cornerB, field.cornerC, field.cornerD]
        let points = corners.map { CGPoint(x: $0.longitude, y: $0.latitude) }

        let centroid = CGPoint(
            x: points.map(\.x).reduce(0, +) / CGFloat(points.count),
            y: points.map(\.y).reduce(0, +) / CGFloat(points.count)
        )
        // centroid 기준 각도로 정렬하면 둘레를 따라가는 순서(p00->p10->p11->p01)가 나온다.
        let ordered = points.sorted { a, b in
            atan2(a.y - centroid.y, a.x - centroid.x) < atan2(b.y - centroid.y, b.x - centroid.x)
        }
        p00 = ordered[0]
        p10 = ordered[1]
        p11 = ordered[2]
        p01 = ordered[3]
    }

    /// 위도/경도 -> 운동장 내 정규화 좌표 (x: 0...1, y: 0...1 근방).
    func normalize(_ coordinate: CLLocationCoordinate2D) -> CGPoint {
        let target = CGPoint(x: coordinate.longitude, y: coordinate.latitude)
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
