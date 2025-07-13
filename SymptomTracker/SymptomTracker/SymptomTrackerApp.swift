//
//  SymptomTrackerApp.swift
//  SymptomTracker
//
//  Created by singingstranger on 08.07.25.
//

import SwiftUI

func Testing(){
    let label = "The width is "
    let quotation = """
    This is the same line
    even though there's a line break
        This should be a new line.
        This, too should be a new line.
    This should be back
    to being one line.
    """
    
    print(label)
    print(quotation)
}


@main
struct SymptomTrackerApp: App {
    
    init(){
        Testing()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
