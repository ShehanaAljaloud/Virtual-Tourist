//
//  MapViewController.swift
//  VirtualTourist_
//
//  Created by Shehana Aljaloud on 22/06/2019.
//  Copyright © 2019 Shehana Aljaloud. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MapKit



class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var deleteView: UIView!
    
    var editLabelVisible = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        deleteView.isHidden = true
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(addPin(gestureRecognizer:)))
        
        longPress.minimumPressDuration = 0.6
        mapView.addGestureRecognizer(longPress)
        loadAnnotations()
    }
    
    
    @IBAction func editPressed(_ sender: Any) {
        editLabelVisible = !editLabelVisible
        
        if editLabelVisible {
            editButton.title = "Done"
            mapView.frame.origin.y -= 50
            deleteView.isHidden = false
            
        } else {
            editButton.title = "Edit"
            mapView.frame.origin.y = 0
            deleteView.isHidden = true
            
        }
    }
    
    @objc func addPin(gestureRecognizer: UILongPressGestureRecognizer) {

        if gestureRecognizer.state == UIGestureRecognizer.State.began {
            
            let location = gestureRecognizer.location(in: mapView)
            let newCoordinates = mapView.convert(location, toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            
            addedPinSaved(lat: newCoordinates.latitude, lon: newCoordinates.longitude)
            
            executeOnMain {
                self.loadAnnotations()
            }
        }
    }
    
    func addedPinSaved(lat: Double, lon: Double) {
        let context = CoreDataStack.getContext()
        let pin : Pin = NSEntityDescription.insertNewObject(forEntityName: "Pin", into: context) as! Pin
        
        pin.latitude = lat
        pin.longitude = lon
        
        CoreDataStack.saveContext()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToPhotoAlbumVC" {
            let controller = segue.destination as! PhotoCollectionViewController
            let selectedPin = sender as! Pin
            controller.selectedPin = selectedPin
        }
    }
}


extension MapViewController: MKMapViewDelegate {
    
    func loadAnnotations() {
        let fetchRequest : NSFetchRequest<Pin> = Pin.fetchRequest()
        
        do {
            let searchResults = try CoreDataStack.getContext().fetch(fetchRequest)
            print("There are \(searchResults.count) locations")
            var annotations = [MKPointAnnotation]()
            for result in searchResults as [Pin] {
                
                let lat = CLLocationDegrees(result.latitude)
                let long = CLLocationDegrees(result.longitude)
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotations.append(annotation)
                
            }
            executeOnMain {
                self.mapView.addAnnotations(annotations)
                print("Annotations added successfully")
            }
        }
        catch {
            print("Error fetching annotations: \(error)")
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: true)
        let lat = view.annotation?.coordinate.latitude
        let lon = view.annotation?.coordinate.longitude
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        do {
            let searchResults = try CoreDataStack.getContext().fetch(fetchRequest)
            for pin in searchResults as [Pin] {
                if pin.latitude == lat!, pin.longitude == lon! {
                    let selectedPin = pin
                    if editLabelVisible {

                        executeOnMain {
                            
                            CoreDataStack.getContext().delete(selectedPin)
                            CoreDataStack.saveContext()
                            self.mapView.removeAnnotation(view.annotation!)
                            print ("selected pin was deleted")
                        }
                    } else {
                        print("Go to photo Album View Controller")
                        executeOnMain {
                            self.performSegue(withIdentifier: "GoToPhotoAlbumVC", sender: selectedPin)
                        }
                    }
                }
            }
        }catch {
            print("Error: \(error)")
        }
    }
}
