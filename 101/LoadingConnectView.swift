//
//  LoadingConnectView.swift
//  101
//
//  Created by 刘明 on 05/03/2026.
//

import SwiftUI

struct LoadingConnectView: View {
    
    @EnvironmentObject var journeyRecorder: JourneyRecorder
    @EnvironmentObject var appState: AppState
    
    @State private var goSummary = false
    
    @EnvironmentObject var summaryLoader: SummaryLoader
    
    var body: some View {
        NavigationStack{
            
            ZStack {
                
                LoadingView(loader: summaryLoader)
            }
            .navigationDestination(isPresented: $goSummary){
                SummaryView()
                    .navigationBarHidden(true)

            }
            .onAppear {
                
                Task {
                    
                    await summaryLoader.load(journeyRecorder: journeyRecorder)
                    
                    //summaryLoader.processStoryIntoParagraphs()
                    
                    goSummary = true
                }
            }
        }
    }
}
