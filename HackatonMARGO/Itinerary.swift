//
//  Itinerary.swift
//  HackatonMARGO
//
//  Created by Mathis Sedkaoui on 14/03/2025.
//

import Polyline
import Foundation
import MapKit
import SwiftUI

class Itinerary: ObservableObject {
    public var src: CLLocationCoordinate2D = CLLocationCoordinate2D();
    public var dest: CLLocationCoordinate2D = CLLocationCoordinate2D();
    public var transportMode: String = "TRAM";  // Dans TRAM, WALK ou BUS
    public var duration: Int = -1;
    public var distance: Int = -1;
    
    @Published public var polylines: MKPolyline = MKPolyline();
    @Published public var subItineraries: [Itinerary] = [];
    
    public var lineColor: Color = .blue;
    public var strokeStyle: StrokeStyle = StrokeStyle(lineWidth: 3.0);
    
    init(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, transportMode: String) async {
        self.transportMode = transportMode;
        self.src = from;
        self.dest = to;
        print("before \(transportMode): \(self.polylines)")
        if transportMode != "CAR" {
            await self.callAPI(from: from, to: to, mode: transportMode);
        } else {
            await self.setCarItinerary(from: from, to: to);
        }
        
        print("\(transportMode) \(self.polylines)");
        
    }
    
    
    init(leg: [String: Any]) {
        self.transportMode = leg["mode"] as! String;
        let startTime = leg["startTime"] as! Int;
        let endTime = leg["endTime"] as! Int;
        self.duration = (endTime - startTime) / 1000;   // Divisé par 1000 car en ms
        
        let geom = leg["legGeometry"] as! [String: Any];
        
        // Si jamais il n'y a que la marche
//        var isWalk = true;
//        let steps = leg["steps"] as! [String: Any];
//        for step in steps {
//            let 
//        }
        
        self.polylines = Polyline(encodedPolyline: geom["points"] as! String).mkPolyline!
        print("    Création d'un sous-itinéraire \(self.transportMode) de durée \(duration / 60)min");
    }
    
    public func getCO2() -> Float {
        /* En grammes par km */
        let transportToCO2: [String: Float] = [
            "WALK": 0,
            "TRAM": 4.28,
            "BUS": 113,
            "CAR": 220
        ]
         
        return transportToCO2[self.transportMode]! * Float(self.distance) / 1000;
    }
    
    
    private func setCarItinerary(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async {
        let sourcePlacemark = MKPlacemark(coordinate: from)
        let destinationPlacemark = MKPlacemark(coordinate: to)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = MKMapItem(placemark: destinationPlacemark)
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Erreur lors du calcul de l'itinéraire : \(error.localizedDescription)")
                    return
                }
                
                guard let route = response?.routes.first else {
                    print("Aucun itinéraire trouvé")
                    return
                }

                self.polylines = route.polyline;
                self.subItineraries.append(self);
                self.distance = Int(route.distance);
                self.duration = Int(route.expectedTravelTime);
                print(self.distance)
            }
        }
    }
    
    public func getDurationString() -> String {
        return "\(self.duration / 60)min \(self.duration % 60)s";
    }
    
    
    private func createSubItinerary(leg: [String: Any]) -> Itinerary {
        let mode = leg["mode"] as! String;
        switch mode {
        case "TRAM":
            return TramItinerary(leg: leg);
        case "WALK":
            return WalkItinerary(leg: leg);
        case "BUS":
            return BusItinerary(leg: leg);
        default:
            print("Erreur")
            exit(1);
        }
    }

    
    
    private func loadFromJson(json: [String: Any]) async {
        DispatchQueue.main.async {
            if let plan = json["plan"] as? [String: Any], let itineraries = plan["itineraries"] as? [[String: Any]] {
                let itinerary = self.transportMode == "WALK" ? itineraries[0] : itineraries[itineraries.count > 1 ? 1 : 0];
                
                self.duration = itinerary["duration"] as! Int;
                self.distance = Int(itinerary["walkDistance"] as! Double);
                
                if let legs = itinerary["legs"] as? [[String: Any]] {
                    for leg in legs {
                        self.subItineraries.append(self.createSubItinerary(leg: leg));
                    }
                }
            } else {
                print("Format JSON invalide")
            }

        }
    }
    
    public func getSub(idx: Int) -> Itinerary {
        return subItineraries[idx];
    }
    
    
    
    private func callAPI(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, mode: String) async {
        var components = URLComponents(string: "https://data.mobilites-m.fr/api/routers/default/plan");
        components?.queryItems = [
            URLQueryItem(name: "fromPlace", value: "\(from.latitude),\(from.longitude)"),
            URLQueryItem(name: "toPlace", value: "\(to.latitude),\(to.longitude)"),
            URLQueryItem(name: "mode", value: mode),
            URLQueryItem(name: "numItineraries", value: String(mode == "WALK" ? 1 : 2))
        ]
        
        guard let url = components?.url else {
            print("URL invalide")
            return
        }
        print("\(self.transportMode) -> \(url)");
        
        // Création de la requête
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Utilise `await` pour effectuer l'appel asynchrone
        let (data, _) = try! await URLSession.shared.data(for: request)
        
        // Processus des données reçues
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            await self.loadFromJson(json: json)
        }
    }
}



// Pour une future extension si on veut changer l'affichage de chaque type de trajet
class TramItinerary: Itinerary {
    override init(leg: [String : Any]) {
        super.init(leg: leg);
        
//        self.strokeStyle = StrokeStyle(dash: [3.0, 3.0]);
    }
}

class WalkItinerary: Itinerary {
    override init(leg: [String : Any]) {
        super.init(leg: leg);
        
        // 1 seul sous-itinéraire si on marche
//        self.polylines = self.subItineraries[0].polylines;
        self.lineColor = .blue;
//        self.strokeStyle = StrokeStyle(lineWidth: 3.0, lineCap: .round, dash: [6.0, 8.0]);
    }
}


class BusItinerary: Itinerary {
    override init(leg: [String : Any]) {
        super.init(leg: leg);
        
        self.lineColor = .blue;
    }
}

class CarItinerary: Itinerary {
    override init(leg: [String : Any]) {
        super.init(leg: leg);
        
        self.lineColor = .blue;
    }
}

