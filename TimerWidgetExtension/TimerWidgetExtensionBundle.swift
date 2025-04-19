//
//  TimerWidgetExtensionBundle.swift
//  TimerWidgetExtension
//
//  Created by Ethan Xu on 2025-04-13.
//

import WidgetKit
import SwiftUI

@main
struct TimerWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        TimerWidgetExtension()
        TimerWidgetExtensionControl()
        TimerWidgetExtensionLiveActivity()
    }
}
