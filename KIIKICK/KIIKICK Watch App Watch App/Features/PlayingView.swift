//
//  PlayingView.swift
//  KIIKICK Watch App Watch App
//
//  Created by Seungjun Lee on 11/1/26.
//

import SwiftUI

struct PlayingView: View {
    
    enum ScoreType: String {
        case goal, assist
        
        var icon: Image {
            switch self {
            case .goal:
                Image(systemName: "soccerball.inverse")
            case .assist:
                Image(systemName: "shoe.running.and.shadow.fill")
            }
        }
    }
    

    var action: () -> Void

    var body: some View {
        TabView {
            RecordEditView(type: .goal)
            RecordEditView(type: .assist)
            QuarterSetView(action: action)
        }.tabViewStyle(.verticalPage)
    }
    
    
    struct RecordEditView: View {
        
        @State var type: ScoreType
        
        var body: some View {
            GeometryReader { geo in
                VStack(spacing: 4) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Match Time")
                            .font(.caption1M)
                        HStack(alignment: .center) {
                            Text("12:34")
                                .font(.title4SB)
                            Spacer()
                            HStack(spacing: 4) {
                                type.icon
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24, height: 24)
                                Text("\(type.rawValue.uppercased())")
                                    .font(.body4R)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    Spacer()
                    StepperViewWatch()
                        .frame(width: geo.size.width - 32)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            }
        }
    }
    
    struct QuarterSetView: View {
        var action: () -> Void

        var body: some View {
            VStack(spacing: 8) {
                ProgressWatchButton()
                CtaWatchView(text: "쿼터 종료", type: .destructive, action: { action() })
            }
        }
    }
}
