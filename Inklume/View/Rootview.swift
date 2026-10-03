//
//  RootView.swift
//  Inklume
//
//  Created by Tufan Cakir on 03.10.26.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        StartView()
    }
}

#Preview {
    RootView()
        .environment(AppModel())
}
