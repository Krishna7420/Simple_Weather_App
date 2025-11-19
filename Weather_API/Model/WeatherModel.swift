//
//  WeatherModel.swift
//  Weather_API
//
//  Created by Shrikrishna Thodsare on 13/11/25.
//

import Foundation

struct WeatherResponse: Decodable {
    let latitude: Double
    let longitude: Double
    let hourly: HourlyData
}

struct HourlyData: Decodable {
    let time: [String]
    let temperature_2m: [Double]
}
