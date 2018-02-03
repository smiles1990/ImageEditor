//
//  IEEditViewVC.swift
//  ImageEditor
//
//  Created by Scott Browne on 31/01/2018.
//  Copyright © 2018 Smiles Dev. All rights reserved.
//

import UIKit
import CoreImage

struct IEFilter {
    
    var name: String
    var filter: CIFilter
    
}

class IEEditViewVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var intensityControl: UISlider!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    var currentImage: UIImage!
    var context: CIContext!
    var currentFilter: CIFilter!
    var imageToShare: UIImage?
    var currentColor: UIColor!
    
    var selectedFilter = ""
    
    var filterArray = [IEFilter]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = currentColor
//        intensityControl.tintColor = currentColor
//        collectionView.backgroundColor = currentColor
//        backButton.setTitleColor(currentColor, for: .normal)
//        shareButton.setTitleColor(currentColor, for: .normal)
        
        imageView.layer.cornerRadius = ((imageView.bounds.width-14)/8)
        imageView.clipsToBounds = true
        //imageView.image = currentImage
        
        context = CIContext()
        currentFilter = filterArray[0].filter
        let beginImage = CIImage(image: currentImage)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        
        applyProcessing()
  
    }
    
    func applyProcessing() {
        
        let inputKeys = currentFilter.inputKeys
        
        if inputKeys.contains(kCIInputIntensityKey){
            intensityControl.isEnabled = true
            intensityControl.alpha = 1.0
            currentFilter.setValue(intensityControl.value, forKey: kCIInputIntensityKey)
        } else {
            intensityControl.isEnabled = false
            intensityControl.alpha = 0.2
        }
    
        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(intensityControl.value * 200, forKey: kCIInputRadiusKey)
        }
        
        if let cgimg = context.createCGImage(currentFilter.outputImage!, from: currentFilter.outputImage!.extent) {
            let processedImage = UIImage(cgImage: cgimg)
            self.imageView.image = processedImage
            imageToShare = processedImage
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filterArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCell", for: indexPath) as! IEFilterExampleCell
        cell.filterNameLabel.text = filterArray[indexPath.item].name
        cell.filterNameLabel.highlightedTextColor = currentColor
        let imageName = "ex"+filterArray[indexPath.item].name
        cell.imageView.image = UIImage(named: imageName)
        cell.layer.cornerRadius = ((collectionView.bounds.width-30)/16)
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard currentImage != nil else { return }
        
        self.selectedFilter = filterArray[indexPath.item].name
        
        self.currentFilter = filterArray[indexPath.item].filter
        
        let updatedImage = CIImage(image: currentImage)
        currentFilter.setValue(updatedImage, forKey: kCIInputImageKey)
        
        applyProcessing()
    }
    
    @IBAction func intensityChagned(_ sender: Any) {
        applyProcessing()
    }
    
    func displayShareSheet(shareContent:UIImage) {
        let activityViewController = UIActivityViewController(activityItems: [shareContent as UIImage], applicationActivities: nil)
        present(activityViewController, animated: true, completion: {})
    }
    
    @IBAction func shareButton(_ sender: Any) {
        
        displayShareSheet(shareContent: imageToShare!)
        
    }
    
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func makeFilterList() {
        
        filterArray.append(IEFilter.init(name: "Sepia", filter: CIFilter(name: "CISepiaTone")!))
        filterArray.append(IEFilter.init(name: "Vignette", filter: CIFilter(name: "CIVignette")!))
        filterArray.append(IEFilter.init(name: "Noir", filter: CIFilter(name: "CIPhotoEffectNoir")!))
        filterArray.append(IEFilter.init(name: "Instant", filter: CIFilter(name: "CIPhotoEffectInstant")!))
        filterArray.append(IEFilter.init(name: "Posterize", filter: CIFilter(name: "CIColorPosterize")!))
        
    }
    
}
