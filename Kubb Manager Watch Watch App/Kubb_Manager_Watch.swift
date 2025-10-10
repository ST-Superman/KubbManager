//
//  Kubb_Manager_Watch.swift
//  Kubb Manager Watch
//
//  Created by Scott Thompson on 10/8/25.
//

import AppIntents

struct Kubb_Manager_Watch: AppIntent {
    static var title: LocalizedStringResource { "Kubb Manager Watch" }
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
