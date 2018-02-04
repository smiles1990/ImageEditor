//
//  ViewController.swift
//  ImageEditor
//
//  Created by Scott Browne on 30/01/2018.
//  Copyright © 2018 Smiles Dev. All rights reserved.
//

import UIKit

// This is the structure for parsing the JSON fed back from our API calls.
struct RedditPageJSON: Codable {
    let kind: String
    let data: data
    struct data: Codable {
        let after: String
        let children: Array<data>
        struct data: Codable {
            let data: redditPost
            struct redditPost: Codable {
                let url: String
                let preview: imageData?
                struct imageData: Codable {
                    let images: Array<data>
                    struct data: Codable {
                        let source: data
                        let resolutions: Array<data>
                        struct data: Codable {
                            let url: String
                        }
                    }
                }
            }
        }
    }
}

//This is a simple object for storing a preview image and a high resolution image URL together.
class LoadedImage {
    let lowResImage: UIImage!
    let sourceResImageURL: String!
    
    init(image: UIImage, url: String) {
        lowResImage = image
        sourceResImageURL = url
    }
}

class IEMainVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate {
    
//  --- Setting initial variables. ---
    @IBOutlet weak var collectionView: UICollectionView!
    
    var imageArray = [LoadedImage]()
    var subredditName = "HumanPorn" // The word 'Human' can be changed to any of around 100 different subect matters, and will change the content that appears. (Examples: Motorcycle, Earth, Architecture, Space, Food...)
    var lastImage = ""
    
    let minColorHue: Float = 0.0
    let maxColorHue: Float = 0.18
    
    var bgTotalPercent: Float = 0.0
    var bgCount: Float = 0.0
    var bgColor = UIColor(hue: 0.0, saturation: 0.5, brightness: 0.8, alpha: 1.0)
    
    
// --- This is called when the view appears, running any initial code required. ---
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //This code sets the initial background color for the view and ensures that the collection view fits two equally sized cells side by side symettrically.
        collectionView.backgroundColor = UIColor(hue: 0.0, saturation: 0.5, brightness: 0.7, alpha: 1.0)
        let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let itemWidth = ((collectionView.bounds.width-30)/2)
        let itemHeight = ((collectionView.bounds.width-30)/2)
        layout.itemSize = CGSize(width: itemWidth, height:itemHeight)

        getImages()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    
// --- This sets the number of cells that shold be in the collection view at any time. ---
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }

// --- This function adds new cells to the colelction view whenever new content is available. ---
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! IEImageCell
        cell.layer.cornerRadius = ((collectionView.bounds.width-30)/8)
        cell.cellImage.image = self.imageArray[indexPath.item].lowResImage
        
        return cell
        
    }
    
    
//  --- This function fetches more images to display to the user when the approach the last of the pre loaded content. ---
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item == (imageArray.count-10) {
            getImages()
        }
    }
    
    
    
//  --- This code controls what happens when the user selects a cell. ---
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let secondViewController = storyboard.instantiateViewController(withIdentifier: "EditViewVC") as! IEEditViewVC
        
        //The following block loads the full resolution image, so it can be presented on the following view controller.
        let imgURLString = imageArray[indexPath.item].sourceResImageURL
        let editedString = imgURLString?.replacingOccurrences(of: "amp;", with: "")
        do{
            let imgData = try Data(contentsOf: NSURL(string: editedString!)! as URL)
            let img = UIImage(data: imgData)
            secondViewController.currentImage = img
        
        }catch let imgErr{
            print("Error loading Img:", imgErr)
            secondViewController.currentImage = imageArray[indexPath.item].lowResImage
        }
        
        //This section defines how the Edit View VC looks when it's presented, the background color of the view is the same as the Main VCs current background color.
        secondViewController.currentColor = bgColor
        secondViewController.makeFilterList()
        secondViewController.modalTransitionStyle = UIModalTransitionStyle.flipHorizontal
        self.present(secondViewController, animated: true, completion: nil)
    }
    
    
    
    
    
    
//   --- This code controls the background color as the user scrolls. ---
    
    // When the user scrolls, theis function will call and determine how far the view has been scrolled...
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let maximumVerticalOffset = scrollView.contentSize.height - scrollView.frame.height
        let currentVerticalOffset = scrollView.contentOffset.y
        let percentageVerticalOffset = currentVerticalOffset / maximumVerticalOffset

        didScrollToPercentageOffset(percentOffset: Float(percentageVerticalOffset))
    }
    
    // ...This function is then called, which sets some variables to keep a track of how far has been scrolled in total, then sets the new backgorund color, using...
    func didScrollToPercentageOffset(percentOffset: Float){
        bgTotalPercent = bgTotalPercent + percentOffset
        bgCount = bgTotalPercent - round(Float(bgTotalPercent))
        
        self.collectionView.backgroundColor = colorForOffsetPercentage()
    }
    
    // ...This function to generate the appropriate color, based on the distance scrolled.
    func colorForOffsetPercentage() -> UIColor {
        let percentage = (bgTotalPercent - bgCount) * 0.01
        
        let actualHue = CGFloat.init((maxColorHue - minColorHue) * percentage + minColorHue)
        
        let color = UIColor(hue: actualHue, saturation: 0.5, brightness: 0.7, alpha: 1.0)
        
        bgColor = color
        
        return color
    }
    
    
    
    
    
    
    
//  --- The following function loads the initial images to be displayed when the app is launched, it also sets a variable to use as a pagination reference when making consecutive calls, this allows the function to be called whenever more images are required.
//  --- The images loaded are a much lower resolution than the source, to optimise loading time, but we alo save the URL of the source image, so it can be loaded as necessary. ---
    func getImages(){
        
        var urlString = ""
        
        if lastImage == "" {
            urlString = "https://www.reddit.com/r/"+self.subredditName+"/top.json?limit=20&t=all"
        } else {
            urlString = "https://www.reddit.com/r/"+self.subredditName+"/top.json?limit=20&t=all&after="+lastImage
        }
        
        let jsonURL = NSURL(string: urlString)
        let request = NSMutableURLRequest(url: jsonURL as URL!)
        let session = URLSession.shared
        request.httpMethod = "GET"
        
        session.dataTask(with: request as URLRequest ) { (data, response, error) in
            guard let data = data else { return }
//                let backToString = String(data: data, encoding: String.Encoding.utf8) as String!
//                print(backToString as String!)
            do{
                let info = try JSONDecoder().decode(RedditPageJSON.self, from: data)
                
                self.lastImage = info.data.after
                
                for children in info.data.children {
                    do{
                        if children.data.preview != nil {
                            
                            let apiImgArray = children.data.preview?.images
                            
                            let cellImgURLString = apiImgArray![0].resolutions[2].url
                            let editedString = cellImgURLString.replacingOccurrences(of: "amp;", with: "")
                            let cellImgData = try Data(contentsOf: NSURL(string: editedString)! as URL)
                            let cellImg = UIImage(data: cellImgData)
                            
                            let highResImgURL = apiImgArray![0].source.url
                            
                            let imageObject = LoadedImage.init(image: cellImg!, url: highResImgURL)
                            self.imageArray.append(imageObject)
                            
                        }
                        
                    }catch let imgErr{
                        print(imgErr, "Error: data error fetching image")
                        print(children.data.url)
                    }
                }
                
                
            }catch let jsonErr {
                print ("Error parsing RedditPage JSON", jsonErr)
            }
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
            
        }.resume()
    }
    
}

