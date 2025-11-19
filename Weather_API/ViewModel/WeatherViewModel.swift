//
//  WeatherViewModel.swift
//  Weather_API
//
//  Created by Shrikrishna Thodsare on 13/11/25.
//



import Foundation
import Combine

@MainActor
class WeatherViewModel: ObservableObject {
    
    @Published var cityName: String = "Pune, IN"
    @Published var currentTemp: String = ""
    @Published var timeList: [String] = []
    @Published var tempList: [Double] = []
    
    func fetchWeather() async {
        // Pune coordinates (Open-Meteo)
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=18.52&longitude=73.85&hourly=temperature_2m"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(WeatherResponse.self, from: data)
            
            // Update properties on main actor (we are inside @MainActor already)
            self.timeList = decoded.hourly.time
            self.tempList = decoded.hourly.temperature_2m
            
            if let first = tempList.first {
                self.currentTemp = String(format: "%.1f°C", first)
            } else {
                self.currentTemp = "--°C"
            }
        } catch {
            print("Error fetching/decoding:", error)
        }
    }
}
