//
//  GeoJsonParser.swift
//  HackatonMARGO
//
//  Created by Mathis Sedkaoui on 13/03/2025.
//

import Foundation
import MapKit
import SwiftUI



class TransitLine {
    let lineName: String = ""
    
    // Les points formant le tracé de la ligne
    var lineCoordinates: [CLLocationCoordinate2D] = []
    
    init(fromFile file: String) {
        loadGeoJSON(from: file)
    }
    
    
    private func loadGeoJSON(from fileName: String) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "geojson") else {
            print("Fichier non trouvé")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let features = json["features"] as? [[String: Any]] {
                
                for feature in features {
                    if let geometry = feature["geometry"] as? [String: Any],
                       let type = geometry["type"] as? String,
                       type == "MultiLineString",
                       let tmp = geometry["coordinates"] as? [[[Double]]] {
                        let coords = tmp[0]
                        
                        for line in coords {
                            lineCoordinates.append(CLLocationCoordinate2D(
                                latitude: line.last!, longitude: line.first!
                            ))
                        }
                    }
                }
            }
        } catch {
            print("Erreur lors du chargement: \(error)")
        }
    }
}
