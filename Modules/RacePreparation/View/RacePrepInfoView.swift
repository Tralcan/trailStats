
//
//  RacePrepInfoView.swift
//  trailStats
//
//  Created by Daniel on 9/7/25.
//

import SwiftUI

struct RacePrepInfoView: View {
    let response: RaceGeminiCoachResponse
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Razón Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text("Razón de la Estimación")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        Text(response.razon)
                            .font(.body)
                            .italic()
                    }
                    
                    Divider()

                    // Importante Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Puntos Importantes")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        ForEach(response.importante, id: \.self) { point in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.headline)
                                Text(point)
                                    .font(.body)
                                Spacer()
                            }
                        }
                    }
                    
                    Divider()

                    // Nutrición Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "leaf.arrow.triangle.circlepath")
                                .foregroundColor(.blue)
                            Text("Nutrición")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        ForEach(response.nutricion, id: \.self) { point in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "drop.fill")
                                    .foregroundColor(.cyan)
                                    .font(.headline)
                                Text(point)
                                    .font(.body)
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Recomendaciones IA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

