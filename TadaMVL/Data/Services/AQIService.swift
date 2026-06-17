//
//  AQIService.swift
//  TadaMVL
//
//  Created by Subhash Arya on 10/05/26.
//

import Foundation

protocol AQIServiceProtocol {
    func fetchAQI(latitude: Double, longitude: Double) async throws -> Int
}
