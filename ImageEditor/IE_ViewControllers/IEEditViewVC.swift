//
//  IEEditViewVC.swift
//  ImageEditor
//
//  Created by Scott Browne on 31/01/2018.
//  Copyright © 2018 Smiles Dev. All rights reserved.
//

import UIKit
import CoreImage

// A simple object to help manage the filter collection view
struct IEFilter {
    
    var name: String
    var filter: CIFilter
    
}

class IEEditViewVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate {
    
//  --- Setting initial variables. ---
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var intensityControl: UISlider!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var shareButton: UIButton!
    
    var currentImage: UIImage!
    var context: CIContext!
    var currentFilter: CIFilter!
    var imageToShare: UIImage?
    var currentColor: UIColor!
    
    var selectedFilter = ""
    var filterArray = [IEFilter]()
    
// --- This is called when the view appears, running any initial code required. ---
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = currentColor
        imageView.layer.cornerRadius = ((imageView.bounds.width-14)/8)
        imageView.clipsToBounds = true
        
        //This code sets up the initil filter when the view is loaded.
        context = CIContext()
        currentFilter = filterArray[0].filter
        let beginImage = CIImage(image: currentImage)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        
        applyProcessing()
    }
    
// --- This function applies the selected filter to the CIContext, as well as enabling/disabling the intensity control bar as required.
    func applyProcessing() {
        
        let inputKeys = currentFilter.inputKeys
        
        if inputKeys.contains(kCIInputIntensityKey){
            intensityControl.isHidden = false
            currentFilter.setValue(intensityControl.value, forKey: kCIInputIntensityKey)
        } else {
            intensityControl.isHidden = true
        }
    
        if inputKeys.contains(kCIInputRadiusKey) {
            currentFilter.setValue((intensityControl.value * 2000), forKey: kCIInputRadiusKey)
            intensityControl.isHidden = false
        }
        
        if let cgimg = context.createCGImage(currentFilter.outputImage!, from: currentFilter.outputImage!.extent) {
            let processedImage = UIImage(cgImage: cgimg)
            self.imageView.image = processedImage
            imageToShare = processedImage
        }
    }
    
    
// --- This sets the number of cells that shold be in the collection view at any time. ---
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filterArray.count
    }
  
    
// --- This populates the collection view with the available filters.
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCell", for: indexPath) as! IEFilterExampleCell
        cell.filterNameLabel.text = filterArray[indexPath.item].name
        cell.filterNameLabel.highlightedTextColor = currentColor
        let imageName = "ex"+filterArray[indexPath.item].name
        cell.imageView.image = UIImage(named: imageName)
        cell.layer.cornerRadius = ((collectionView.bounds.width-30)/16)
        
        return cell
        
    }
    
// --- This controls what happens when the user selects a filter in the collection view. ---
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard currentImage != nil else { return }
        self.selectedFilter = filterArray[indexPath.item].name
        self.currentFilter = filterArray[indexPath.item].filter
        let updatedImage = CIImage(image: currentImage)
        currentFilter.setValue(updatedImage, forKey: kCIInputImageKey)
        
        applyProcessing()
    }
    
// --- This code has the intensity bar apply the varying filter intensity dynamically. ---
    @IBAction func intensityChagned(_ sender: Any) {
        applyProcessing()
    }
    
// --- This functions presents the iOS share sheet, allowing the user to share the image in it's current state. ---
    func displayShareSheet(shareContent:UIImage) {
        let activityViewController = UIActivityViewController(activityItems: [shareContent as UIImage], applicationActivities: nil)
        present(activityViewController, animated: true, completion: {})
    }
    
// --- This calls the share sheet function when the share button is pressed. ---
    @IBAction func shareButton(_ sender: Any) {
        displayShareSheet(shareContent: imageToShare!)
    }
    
// --- This dismisses the Edit View VC when the user swipes right. ---
    @IBAction func backSwipe(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

// --- This function creates the filter array that feeds into the collection view. ---
    func makeFilterList() {
        
        filterArray.append(IEFilter.init(name: "Sepia", filter: CIFilter(name: "CISepiaTone")!))
        filterArray.append(IEFilter.init(name: "Vignette", filter: CIFilter(name: "CIVignette")!))
        filterArray.append(IEFilter.init(name: "Noir", filter: CIFilter(name: "CIPhotoEffectNoir")!))
        filterArray.append(IEFilter.init(name: "Instant", filter: CIFilter(name: "CIPhotoEffectInstant")!))
        filterArray.append(IEFilter.init(name: "Posterize", filter: CIFilter(name: "CIColorPosterize")!))
        filterArray.append(IEFilter.init(name: "Pixellate", filter: CIFilter(name:"CIPixellate")!))
        filterArray.append(IEFilter.init(name: "Comic", filter: CIFilter(name:"CIComicEffect")!))
    }
    
}
