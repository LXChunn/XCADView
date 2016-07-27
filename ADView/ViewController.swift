//
//  ViewController.swift
//  ADView
//
//  Created by 刘小椿 on 16/6/23.
//  Copyright © 2016年 刘小椿. All rights reserved.
//

import UIKit
import XCADView
import WebImage

class ViewController: UIViewController, XCAdViewDelegate{

    @IBOutlet weak var adCoverView: UIView!
    @IBOutlet weak var adDefaultImaeView: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    
    var adView:XCADView!
    var imageUrls:NSArray?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.adView = XCADView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.adCoverView.bounds.height))
        self.adView.delegate = self
        self.adView.displayTime = 3
        self.adView.defaultADImage = UIImage(named: "common_ad_default")
        self.adView.perform()
        self.adView.isCustomPageControl = true
        self.adView.pageControl?.frame = CGRect(x: self.view.bounds.size.width - 100,y:self.adCoverView.frame.size.height - 30,width: 100,height:30)
        
        self.adCoverView.addSubview(self.adView)
    }
    @IBAction func action(sender: AnyObject) {
        self.imageUrls = ["http://img1.3lian.com/2015/w7/98/d/22.jpg",
                          "http://pic9.nipic.com/20100904/4845745_195609329636_2.jpg",
                          "http://pic10.nipic.com/20101103/5063545_000227976000_2.jpg",
                          "http://pic15.nipic.com/20110731/8022110_162804602317_2.jpg",
                          "http://img1b.xgo-img.com.cn/pics/1538/1537502.jpg",
                          "http://img.xgo-img.com.cn/pics/1577/a1576165.jpg"]
        
        if self.imageUrls?.count > 0 {
            if 1 == self.imageUrls?.count {
                self.adView.pageControl?.hidden = true
            }
            self.adDefaultImaeView.hidden = true
            self.adView.dataArray = self.imageUrls
        }else{
            self.adDefaultImaeView.hidden = false
        }
    }
    
    //MARK:delegate
    func adView(adView:XCADView, lazyLoadAtIndexOrDidselectIndex index:Int, loadImageView imageView:UIImageView, loadImageURL imageURL:String)
    {
        imageView.sd_setImageWithURL(NSURL(string: imageURL as String), placeholderImage: UIImage(named: "common_ad_default"))
    }
    
    func adView(adView:XCADView, didSelectedAtIndex index:Int, selectedImageView imageView:UIImageView, selectedImagePath imagePath:String)
    {
        print("\(index) == \(imagePath)")
        self.imageView.image = imageView.image
    }
}

