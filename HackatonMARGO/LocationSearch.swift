//
//  LocationSearch.swift
//  HackatonMARGO
//
//  Created by Mathis Sedkaoui on 14/03/2025.
//

import SwiftUI
import MapKit

class LocationSearch: ObservableObject {
    @Published var landmarks: [MKMapItem] = []
    @Published var results: [Itinerary?] = Array(repeating: nil, count: 4);
    @Published var hasResults: Bool = false;
    public var locationManager = LocationManager();
    
    
    func resetSearch() {
        hasResults = false;
        self.results = [nil, nil, nil, nil];
    }
    
    func search(for query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 45.193548, longitude: 5.768362),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else {
                print("Erreur de recherche: \(error?.localizedDescription ?? "Inconnue")")
                return
            }
            
//            DispatchQueue.main.async {
//
//                
//            }
            self.landmarks = response.mapItems
            self.locationManager.startLocationServices()
            // On lance le calcul d'itinéraire
            if let dest = response.mapItems.first {
                let src = self.locationManager.userLocation!.coordinate
                
                Task { @MainActor in
                    // Utilise await pour créer des itinéraires de manière asynchrone
                    let walk = await Itinerary(from: src, to: dest.placemark.coordinate, transportMode: "WALK")
                    let tram = await Itinerary(from: src, to: dest.placemark.coordinate, transportMode: "TRAM")
                    let bus = await Itinerary(from: src, to: dest.placemark.coordinate, transportMode: "BUS")
                    let car = await Itinerary(from: src, to: dest.placemark.coordinate, transportMode: "CAR")
                    
                    // Mets à jour les résultats sur le thread principal
                    DispatchQueue.main.async { [self] in
                        hasResults = true
                        results = [walk, tram, bus, car]
                        //print(self.results[1].subItineraries.count)
                    }
                    
                }
                
                
                

            }
        }
    }
}
