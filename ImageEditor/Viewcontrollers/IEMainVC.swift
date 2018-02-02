//
//  ViewController.swift
//  ImageEditor
//
//  Created by Scott Browne on 30/01/2018.
//  Copyright © 2018 Smiles Dev. All rights reserved.
//

import UIKit

struct RedditPageJSON: Codable {
    
    let data: data
    let kind: String
    
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

class LoadedImage {
    let lowResImage: UIImage!
    let sourceResImageURL: String!
    
    init(image: UIImage, url: String) {
        lowResImage = image
        sourceResImageURL = url
    }
}

class IEMainVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var imageArray = [LoadedImage]()
    var subredditName = "HumanPorn"
    var lastImage = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let itemWidth = ((collectionView.bounds.width-30)/2)
        let itemHeight = ((collectionView.bounds.width-30)/2)
        layout.itemSize = CGSize(width: itemWidth, height:itemHeight)
        
        getImages()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getImages(){
        
        var urlString = ""
        
        if lastImage == "" {
            urlString = "https://www.reddit.com/r/"+self.subredditName+"/top.json?limit=20&t=all"
        } else {
            urlString = "https://www.reddit.com/r/"+self.subredditName+"/top.json?limit=20&t=all&after="+lastImage
            print(urlString)
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
                
                print("Last Image:"+self.lastImage)
                
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
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! IEImageCell

        cell.layer.cornerRadius = ((collectionView.bounds.width-30)/8)
        
        cell.cellImage.image = self.imageArray[indexPath.item].lowResImage
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if indexPath.item == (imageArray.count-10) {
            getImages()
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let secondViewController = storyboard.instantiateViewController(withIdentifier: "EditViewVC") as! IEEditViewVC
        
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
        
        secondViewController.makeFilterList()
        
        self.present(secondViewController, animated: true, completion: nil)

    }
    
}

