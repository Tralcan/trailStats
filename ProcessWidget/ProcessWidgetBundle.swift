//
//  ProcessWidgetBundle.swift
//  ProcessWidget
//
//  Created by Diego Anguita on 07-10-25.
//

import WidgetKit
import SwiftUI

@main
struct ProcessWidgetBundle: WidgetBundle {
    var body: some Widget {
        ProcessWidget()
        ProcessWidgetControl()
    }
}
