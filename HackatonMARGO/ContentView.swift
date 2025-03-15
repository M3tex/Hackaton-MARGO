//
//  ContentView.swift
//  HackatonMARGO
//
//  Created by Mathis Sedkaoui on 13/03/2025.
//

import SwiftUI
import SwiftData
import MapKit
import Polyline
import CoreLocation

struct ContentView: View {
    @State private var selectedLandmark: MKMapItem? = nil
    @State private var sheetHeight: CGFloat = 0
    @State public var selectedItinerary: Itinerary? = nil
    
    @StateObject private var locationManager = LocationManager();
    @StateObject private var locationSearch = LocationSearch();
    
    private var lineA = TransitLine(fromFile: "tram_a")
    private var lineB = TransitLine(fromFile: "tram_b")
    private var lineC = TransitLine(fromFile: "tram_c")
    private var lineD = TransitLine(fromFile: "tram_d")
    private var lineE = TransitLine(fromFile: "tram_e")
    
    
    var safeAreaBottomInset: CGFloat {
            let keyWindow = UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                .first
            return keyWindow?.safeAreaInsets.bottom ?? 0
        }
    
    
    func resetIt() {
        self.selectedItinerary = nil;
    }
    
    
    var body: some View {
        // Position de départ de la map (Ensimag)
        let initialPosition = MapCameraPosition.region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 45.19354810029131 , longitude: 5.768362456660572),
            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        ))
        
        ZStack {
            Map(initialPosition: initialPosition) {
                UserAnnotation()
                MapPolyline(coordinates: lineA.lineCoordinates).stroke(!locationSearch.hasResults ? .blue : .gray, lineWidth: 3.0)
                MapPolyline(coordinates: lineB.lineCoordinates).stroke(!locationSearch.hasResults ? .green : .gray, lineWidth: 3.0)
                MapPolyline(coordinates: lineC.lineCoordinates).stroke(!locationSearch.hasResults ? .red : .gray, lineWidth: 3.0)
                MapPolyline(coordinates: lineD.lineCoordinates).stroke(!locationSearch.hasResults ? .orange : .gray, lineWidth: 3.0)
                MapPolyline(coordinates: lineE.lineCoordinates).stroke(!locationSearch.hasResults ? .purple : .gray, lineWidth: 3.0)

//                
//                ForEach(locationSearch.results.indices) {i in
//                    if let itinerary = locationSearch.results[i] {
//                        ForEach(itinerary.subItineraries.indices) { j in
//                            let it = itinerary.subItineraries[j];
//                            MapPolyline(it.polylines).strokeStyle(style: it.strokeStyle).stroke(it.lineColor)
//                        }
//                    }
//                }
                
                if (self.selectedItinerary != nil) {
                    ForEach(self.selectedItinerary!.subItineraries.indices) {idx in
                        if let it = self.selectedItinerary?.subItineraries[idx] {
                            MapPolyline(it.polylines).strokeStyle(style: it.strokeStyle).stroke(it.lineColor)
                        }
                    }
                } else if locationSearch.results[1] != nil {
                    ForEach(locationSearch.results[1]!.subItineraries.indices) {idx in
                        if let it = locationSearch.results[1]?.subItineraries[idx] {
                            MapPolyline(it.polylines).strokeStyle(style: it.strokeStyle).stroke(it.lineColor)
                        }
                    }
                } else if locationSearch.results[0] != nil {
                    ForEach(locationSearch.results[0]!.subItineraries.indices) {idx in
                        if let it = locationSearch.results[0]?.subItineraries[idx] {
                            MapPolyline(it.polylines).strokeStyle(style: it.strokeStyle).stroke(it.lineColor)
                        }
                    }
                }
                
                // Affichage des résultats de la recherche
//                ForEach(locationSearch.landmarks, id: \.self) { item in
//                    Marker(item.name ?? "Lieu inconnu", coordinate: item.placemark.coordinate)
//                }
//                ForEach(locationSearch.landmarks, id: \.self) { item in
//                    Annotation(item.placemark.name ?? "", coordinate: item.placemark.coordinate) {
//                        Image(systemName: getSymbol(for: item)) // Icône de la marque
//                            .resizable()
//                            .frame(width: 30, height: 30)
//                            .foregroundColor(.red)
//                            .onTapGesture {
//                                selectedLandmark = item // Enregistre l'élément sélectionné
//                            }
//                    }
//
//                }
                if (!locationSearch.landmarks.isEmpty) {
                    let item = locationSearch.landmarks[0];
                    Annotation(item.placemark.name ?? "", coordinate: item.placemark.coordinate) {
                        Image(systemName: getSymbol(for: item)) // Icône de la marque
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.orange)
                            .onTapGesture {
                                selectedLandmark = item // Enregistre l'élément sélectionné
                            }
                    }
                }
                
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
                MapPitchToggle()
            }

            .onAppear {
                locationManager.startLocationServices()
            }
            
            
            VStack {
                if let selected = self.selectedItinerary {
                    HStack(spacing: 0) {

                        switch selected.transportMode {
                        case "TRAM":
                            Image(systemName: "tram.fill")
                                .font(.title)
                                .foregroundStyle(.foreground)
                                .padding()
                        case "BUS":
                            Image(systemName: "bus.fill")
                                .font(.title)
                                .foregroundStyle(.foreground)
                                .padding()
                        case "CAR":
                            Image(systemName: "car.fill")
                                .font(.title)
                                .foregroundStyle(.foreground)
                                .padding()
                        default:
                            Image(systemName: "figure.walk")
                                .font(.title)
                                .foregroundStyle(.foreground)
                                .padding()
                        }
                        
                        VStack(alignment: .leading) {
                            Text("\(selected.getDurationString())")
                                
                                .font(.caption)
                            HStack {
                                Image(systemName: "leaf")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                                
                                let co2 = String(format: "%.1f", selected.getCO2())
                                Text("\(co2)g de CO2")
                                    .font(.caption)
                            }
                            
                        }
                        .padding(.vertical)
                        .padding(.trailing)
                        
                    }
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding(.horizontal, 5)
                }
                Spacer()
                HStack(alignment: .bottom) {
                    ZStack {
                        // Partie pour sélectionner les différents mode de transports
                        if (locationSearch.hasResults) {
                            HStack(alignment: .bottom, spacing: 0) {
                                let selected = selectedItinerary?.transportMode;
                                Button {
                                    if let tmp = locationSearch.results[0] {
                                        self.selectedItinerary = tmp;
                                    }
                                } label: {
                                    Image(systemName: "figure.walk")
                                        .foregroundStyle(.foreground)
                                        .padding()
                                }
                                .background(selected == "WALK" ? .ultraThickMaterial : .thinMaterial)
                                
                                Button {
                                    if let tmp = locationSearch.results[1] {
                                        self.selectedItinerary = tmp;
                                    }
                                } label: {
                                    Image(systemName: "tram.fill")
                                        .foregroundStyle(.foreground)
                                        .padding()
                                }
                                .background(selectedItinerary?.transportMode == "TRAM" ? .ultraThickMaterial : .thinMaterial)
                                
                                Button {
                                    if let tmp = locationSearch.results[2] {
                                        self.selectedItinerary = tmp;
                                    }
                                } label: {
                                    Image(systemName: "bus.fill")
                                        .foregroundStyle(.foreground)
                                        .padding()
                                }
                                .background(selected == "BUS" ? .ultraThickMaterial : .thinMaterial)
                                
                                Button {
                                    if let tmp = locationSearch.results[3] {
                                        self.selectedItinerary = tmp;
                                    }
                                } label: {
                                    Image(systemName: "car.fill")
                                        .foregroundStyle(.foreground)
                                        .padding()
                                }
                                .background(selected == "CAR" ? .ultraThickMaterial : .thinMaterial)
                                
                            }
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .padding(.horizontal, 5)
                        }
                        
                        // Pur UI, prévision pour le futur -> le "score" vert/orange/rouge
                        HStack {
                            VStack (alignment: .leading, spacing: 0) {
                                HStack(spacing: 0) {
                                    Image(systemName: "leaf.fill")
                                        //.resizable()
                                        .foregroundStyle(.green)
                                        //.frame(width: 30, height: 30)
                                        .padding()
                                    
                                }
                                
                                if (locationSearch.hasResults) {
                                    Button {
                                        locationSearch.resetSearch()
                                        selectedItinerary = nil;
                                        locationSearch.landmarks.removeAll();
                                    } label: {
                                        Image(systemName: "mappin.slash.circle.fill")
                                            .foregroundStyle(.red)
                                            .padding()
                                            
                                    }
                                    //.background(.ultraThickMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .padding(.horizontal, 5)
                                }
                            }
                            .background(.ultraThickMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .padding(.horizontal, 5)
                            
                            Spacer()
                        }
                        
                        
//                        Spacer()
                    }
                }
                Spacer()
                    .frame(height: sheetHeight + 15)
            }
        }
            .sheet(isPresented: .constant(true)) {
                GeometryReader { geometry in
                    BottomSheetView(parentView: self)
                        .environmentObject(locationSearch)
                    .presentationDetents([.fraction(0.1)])
                        .presentationDragIndicator(.visible)
                        .interactiveDismissDisabled(true)
                        .presentationBackground(.ultraThickMaterial)
                        .presentationBackgroundInteraction(.enabled)
                        .onAppear {
                            sheetHeight = geometry.size.height
                        }
                        .onChange(of: geometry.size.height) { newHeight in
                            sheetHeight = newHeight
                        }
                }
                
            }

    }
    
    func getSymbol(for item: MKMapItem) -> String {
        guard let category = item.pointOfInterestCategory else {
            return "mappin.circle.fill"
        }

        switch category {
        case .restaurant: return "fork.knife.circle.fill"
        case .cafe: return "cup.and.saucer.fill"
        case .bank: return "banknote.circle.fill"
        case .hospital: return "cross.circle.fill"
        case .pharmacy: return "pills.circle.fill"
        case .airport: return "airplane.circle.fill"
        case .park: return "leaf.circle.fill"
        case .store: return "bag.circle.fill"
        case .hotel: return "bed.double.fill"
        case .gasStation: return "fuelpump.circle.fill"
        default: return "mappin.circle.fill"
        }
    }

    struct BottomSheetView: View {
        @State private var searchValue: String = ""
        @EnvironmentObject var locationSearch: LocationSearch;
        var parentView: ContentView;
        @FocusState private var isTextFieldFocused: Bool;
        
        var body: some View {
            HStack {
                TextField (
                    "Rechercher une destination",
                    text: $searchValue
                )
                .onSubmit {
                    sendMessage();
                }
                .focused($isTextFieldFocused)
                //.padding(10)
                .textFieldStyle(.roundedBorder)
                Button() {
                    isTextFieldFocused = false;
                    sendMessage();
                } label: {
                    HStack {
                        Image(systemName: "tram")
                        Text("Go")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
            }
            .padding()
        }
        
        private func sendMessage() {
            print("Message envoyé: \(searchValue)");
            locationSearch.resetSearch();
            parentView.resetIt();
            locationSearch.search(for: searchValue);
            searchValue = ""
        }
    }
}



extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
