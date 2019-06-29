//
//  PhotoCollectionViewController.swift
//  VirtualTourist_
//
//  Created by Shehana Aljaloud on 22/06/2019.
//  Copyright © 2019 Shehana Aljaloud. All rights reserved.
//

import UIKit
import CoreData
import MapKit


private let reuseIdentifier = "PhotoCell"

class PhotoCollectionViewController: UIViewController {
    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var addNewCollection: UIButton!

    
    private let persistanContainter = NSPersistentContainer(name: "Photo")
    var selectedPin : Pin!
    var photos : [Photo] = [Photo]()
    var selectedIndexes = [NSIndexPath]()
    var isPhotosSelected = false
    var currentPage = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationItem.backBarButtonItem?.tintColor = .white
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        addAnnotation()
        print("Selected pin location: \(String(describing: selectedPin))")
        
        fetchPhotos()
        
        let space: CGFloat = 3.0
        let viewWidth = self.view.frame.width
        let dimension: CGFloat = (viewWidth-(2*space))/3.0
        
        collectionViewLayout.minimumInteritemSpacing = space
        collectionViewLayout.minimumLineSpacing = space
        collectionViewLayout.itemSize = CGSize(width: dimension, height: dimension)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.collectionView.reloadData()
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    ////////////////
    func displayAlert(title:String, message:String?) {
        
        if let message = message {
            let alert = UIAlertController(title: title, message: "\(message)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    //////////////////
    
    func getFlickrPhotos(page: Int){
        
        FlickrClient.sharedInstance.getImagesFromFlickr(selectedPin, currentPage) { (results, error) in
            
            guard error == nil else {
                self.displayAlert(title: "Unable to get photos from Flickr", message: error?.localizedDescription)
                return
            }

            executeOnMain {
                if results != nil {
                    self.photos = results!
                    
                    print("\(self.photos.count) photos from Flickr fetched")
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    func removePhotos() {
        
        if selectedIndexes.count > 0 {
            for indexPath in selectedIndexes {
                let photo = photos[indexPath.row]
                CoreDataStack.getContext().delete(photo)
                self.photos.remove(at: indexPath.row)
                self.collectionView.deleteItems(at: [indexPath as IndexPath])
                print("Photo at row \(indexPath.row) was deleted")
            }
            CoreDataStack.saveContext()
        }
        selectedIndexes = [NSIndexPath]()
    }
    
    @IBAction func newCollectionTapped(_ sender: UIButton) {
        if isPhotosSelected {
            removePhotos()
            self.collectionView.reloadData()
            isPhotosSelected = false
            addNewCollection.setTitle("New Collection", for: .normal)
        } else {
            for photo in photos {
                CoreDataStack.getContext().delete(photo)
            }
            CoreDataStack.saveContext()
            currentPage += 1
            getFlickrPhotos(page: currentPage)
            
        }
    }
    
}

extension PhotoCollectionViewController: MKMapViewDelegate {
    
    func addAnnotation() {
        let annotation = MKPointAnnotation()
        let lat = CLLocationDegrees(selectedPin.latitude)
        let lon = CLLocationDegrees(selectedPin.longitude)
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        annotation.coordinate = coordinate
        let span = MKCoordinateSpan.init(latitudeDelta: 0.25, longitudeDelta: 0.25)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        
        executeOnMain {
            self.mapView.addAnnotation(annotation)
            self.mapView.setRegion(region, animated: true)
        }
    }
}

extension PhotoCollectionViewController: NSFetchedResultsControllerDelegate {
    
    func fetchPhotos(){
        
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin = %@", selectedPin!)
        let context = CoreDataStack.getContext()
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedResultsController.performFetch()
            
        } catch {
            let fetchError = error as NSError
            print("Unable to Perform Fetch Request")
            print("\(fetchError), \(fetchError.localizedDescription)")
        }
        
        if let data = fetchedResultsController.fetchedObjects, data.count > 0 {
            print("\(data.count) photos from core data fetched.")
            photos = data
            self.collectionView.reloadData()
        } else {
            getFlickrPhotos(page: currentPage)
        }
    }
}

extension PhotoCollectionViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let flickrCell = collectionView.dequeueReusableCell(withReuseIdentifier: "flickrPhotoCell", for: indexPath) as! PhotoCollectionViewCell
        
        let photo = photos[indexPath.row]
        
        flickrCell.imageView.image = UIImage(named: "placeholder")
        flickrCell.spinner.startAnimating()
        
        if photo.imageData != nil {
            executeOnMain {
                flickrCell.spinner.stopAnimating()
            }
            flickrCell.imageView.image = UIImage(data: photo.imageData! as Data)
        } else {
            
            FlickrClient.sharedInstance.getDataFromUrl(photo.urlString!) { (results, error) in
                guard let imageData = results else {
                    self.displayAlert(title: "Image data error", message: error)
                    return
                }
                
                executeOnMain {
                    photo.imageData = imageData as NSData?
                    flickrCell.spinner.stopAnimating()
                    flickrCell.imageView.image = UIImage(data: photo.imageData! as Data)
                }
            }
        }
        
        if selectedIndexes.index(of: indexPath as NSIndexPath) != nil {
            flickrCell.imageView.alpha = 0.25
        } else {
            flickrCell.imageView.alpha = 1.0
        }
        
        return flickrCell
    }
}


extension PhotoCollectionViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCollectionViewCell
        
        let index = selectedIndexes.index(of: indexPath as NSIndexPath)
        
        if let index = index {
            selectedIndexes.remove(at: index)
            cell.imageView.alpha = 1.0
        } else {
            selectedIndexes.append(indexPath as NSIndexPath)
            print(selectedIndexes)
            selectedIndexes.sort{$1.row < $0.row}
            cell.imageView.alpha = 0.25
        }
        
        if selectedIndexes.count > 0 {
            addNewCollection.setTitle("Delete", for: .normal)
            isPhotosSelected = true
            
        } else {
            addNewCollection.setTitle("New Collection", for: .normal)
            isPhotosSelected = false
            
        }
    }
}



