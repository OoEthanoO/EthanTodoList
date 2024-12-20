////
////  TimerView.swift
////  EthanTodoList
////
////  Created by Ethan Xu on 2024-12-12.
////
//
//import SwiftUI
//
//struct TimerView: View {
//    @State private var timeRemaining = 60
//    @State private var timerRunning = false
//    @State private var timer: Timer?
//    
//    var body: some View {
//        VStack {
//            Text("Time Remaining: \(timeRemaining) seconds")
//                .font(.title)
//                .padding()
//            
//            HStack {
//                Button(action: startTimer) {
//                   Text("Start")
//                }
//                .padding()
//                
//                Button(action: stopTimer) {
//                    Text("Stop")
//                }
//            }
//        }
//    }
//}
