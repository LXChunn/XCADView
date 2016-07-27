//
//  XCADView.swift
//  ADView-swift
//
//  The MIT License (MIT)
//
//  Copyright (c) 2014 - 2016 Fabrizio Brancati. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import UIKit

@objc public protocol XCAdViewDelegate: class {
    
    /**
     *  慢加载网络图片
     *
     *  @param adView    广告控件
     *  @param index     索引
     *  @param imageView 控件
     *  @param imageURL  图片URL
     */
    optional func adView(adView:XCADView, lazyLoadAtIndex index:Int, loadImageView imageView:UIImageView, loadImageURL imageURL:String)
    
    /**
     *  选择到某个广告
     *
     *  @param adView    广告控件
     *  @param index     索引
     *  @param imageView 视图
     *  @param imagePath 图片路径（可能是本地；可能是网络）
     */
    func adView(adView:XCADView, didSelectedAtIndex index:Int, selectedImageView imageView:UIImageView, selectedImagePath imagePath:String)
}

public class XCADView: UIView {
    public typealias XCADSelectedBlock = (UIImageView,String,Int) ->()
    
    /**
     *  选中block（与前面delegate效果一样）
     */
    public var selectedBlock: XCADSelectedBlock!
    
    /**
     *  委托
     */
    public weak var delegate: XCAdViewDelegate!
    
    /**
     *  正在加载广告的过渡图像
     */
    public var defaultADImage: UIImage?
    
    /**
     *  广告数据（本地：图片名称；网络：图片路径）
     */
    var datas:NSArray?
    public var dataArray:NSArray!{
        set {
            guard let newDataArray = newValue else {
                self.scrollView?.hidden = true
                return
            }
            self.datas = newDataArray
            self.scrollView?.hidden = false
            
            self.unusedImageViewArray.addObjectsFromArray(self.usedImageViewArray as [AnyObject])
            self.usedImageViewArray.removeAllObjects()
            
            var count:Int = (newDataArray.count)
            self.pageControl?.numberOfPages = count
            if self.isCircle == true {
                count += 2
            }
            
            for i in 0 ..< count {
                var imageView:UIImageView! = self.unusedImageViewArray?.ad_SafeObjectAtIndex(i) as! UIImageView
                if imageView.isEqual(nil) {
                    imageView = UIImageView()
                }
                let screenWidth:CGFloat = self.frame.size.width
                
                imageView.frame = CGRect(x: CGFloat(i) * screenWidth, y: 0, width: self.frame.size.width, height: self.frame.size.height)
                self.scrollView?.contentSize = CGSize(width: CGFloat(i + 1) * screenWidth, height: self.frame.size.height)
                self.scrollView?.addSubview(imageView)
                self.usedImageViewArray?.addObject(imageView)
                
                var imagePath = newDataArray.ad_SafeObjectAtIndex(i)
                if self.isCircle == true {
                    if 0 == i {
                        imagePath = newDataArray.lastObject!
                    }else if(i == count - 1){
                        imagePath = newDataArray.firstObject!
                    }else{
                        imagePath = newDataArray.ad_SafeObjectAtIndex(i - 1)
                    }
                }
                
                if self.isWebImage == true {
                    imageView.image = self.defaultADImage
                    if let adView = self.delegate?.adView {
                        if 0 == i {
                            imagePath = newDataArray.firstObject!
                        }
                        adView(self, lazyLoadAtIndex: i, loadImageView: imageView, loadImageURL: imagePath as! String)
                    }else{
                        imageView.image = UIImage(data: NSData(contentsOfURL: NSURL(string: imagePath as! String)!)!)
                    }
                }else{
                    imageView.image = UIImage(named: imagePath as! String)
                }
            }
            self.unusedImageViewArray.removeObjectsInArray(self.usedImageViewArray as [AnyObject])
        }
        
        get {
            return self.datas
        }
    }
    
    /**
     *  page控件
     */
    public var pageControl: UIPageControl?
    
    /**
     *  page控件frame是否自定义,默认false
     */
    public var isCustomPageControl: Bool = false
    
    /**
     *  滚动间隔时间，默认是2秒
     */
    public var displayTime: Int = 2
    
    /**
     *  设置是否为网络图片，默认是true
     */
    public var isWebImage: Bool = true
    
    var isCircle:Bool = true
    var scrollView:UIScrollView?
    var timeInterval:NSTimeInterval!{
        set (newTimeInterval){
            if self.timer != nil {
                dispatch_source_cancel(self.timer!)
            }
            
            let timeout = newTimeInterval
            let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
            self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue)
            dispatch_source_set_timer(self.timer!, dispatch_walltime(nil, 0), UInt64(timeout) * NSEC_PER_SEC, 0)
            dispatch_source_set_event_handler(self.timer!) { 
                if timeout <= 0 {
                    dispatch_source_cancel(self.timer!)
                }else{
                    if self.scrollView?.tracking == true{
                        return
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), { 
                        if self.scrollView?.contentOffset.x >= self.scrollView?.contentSize.width {
                            self.scrollView?.contentOffset = CGPointZero
                        }else{
                            let width:CGFloat = (self.scrollView?.frame.size.width)!
                            if self.scrollView?.contentOffset.x >= width && self.scrollView?.contentOffset.x <= width * CGFloat(self.dataArray.count - 1){
                                UIView.animateWithDuration(0.5, animations: {
                                    self.scrollView?.contentOffset = CGPointMake((self.scrollView?.contentOffset.x)! + (self.scrollView?.frame.size.width)!, 0)
                                })
                            }else{
                                self.scrollView?.contentOffset = CGPointMake((self.scrollView?.contentOffset.x)! + (self.scrollView?.frame.size.width)!, 0)
                            }
                        }
                    })
                }
            }
            dispatch_resume(self.timer!)
        }
        
        get {
            return self.timeInterval
        }
        
    }
    
    var unusedImageViewArray:NSMutableArray! = nil
    var usedImageViewArray:NSMutableArray! = nil
    #if OS_OBJECT_USE_OBJC
    var timer: dispatch_source_t?
    #else
    var timer: dispatch_source_t?
    #endif
    var tapGestureRecognizer:UITapGestureRecognizer?
    //MARK:public
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        self.unusedImageViewArray = NSMutableArray()
        self.usedImageViewArray = NSMutableArray()
        
        self.scrollView = UIScrollView(frame:CGRectZero)
        self.pageControl = UIPageControl(frame:CGRectZero)
        
        self.addSubview(self.scrollView!)
        self.addSubview(self.pageControl!)
        
        self.scrollView?.delegate = self
        self.scrollView?.scrollsToTop = false
        self.scrollView?.pagingEnabled = true
        self.scrollView?.showsVerticalScrollIndicator = false
        self.scrollView?.showsHorizontalScrollIndicator = false
        
        self.tapGestureRecognizer = UITapGestureRecognizer(target: self,action: #selector(self.didTapGesture(_:)))
        self.scrollView?.addGestureRecognizer(self.tapGestureRecognizer!)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.scrollView?.frame = CGRect(x: 0,y: 0,width: self.frame.size.width,height: self.frame.size.height)
        if self.isCustomPageControl == false{
            self.pageControl?.frame = CGRect(x: 0,y: self.frame.size.height - 30, width: self.frame.size.width, height: 30)
        }
        
        let count = self.usedImageViewArray.count
        self.scrollView?.contentSize = CGSize(width: CGFloat(count)*self.frame.size.width,height: self.frame.size.height)
        for i in 0 ..< count {
            let imageView = self.usedImageViewArray.ad_SafeObjectAtIndex(i) as! UIImageView
            if !imageView.isEqual(nil) {
                imageView.frame = CGRect(x: CGFloat(i)*self.frame.size.width,y:0,width: self.frame.size.width,height: self.frame.size.height)
            }
        }
    }
    
    public func perform(){
        self.timeInterval = NSTimeInterval(self.displayTime)
    }
    
    //MARK:private
    func didTapGesture(sender: UITapGestureRecognizer) {
        if self.dataArray?.count > 0 {
            var index:Int = (Int)((self.scrollView?.contentOffset.x)!/(self.scrollView?.frame.size.width)!)
            if self.isCircle == true{
                if 0 == index {
                    index = 1
                }
                index -= 1
            }
            let imagePath:String = (self.dataArray?.ad_SafeObjectAtIndex(index))! as! String
            let imageView:UIImageView = (self.usedImageViewArray?.ad_SafeObjectAtIndex(index + 1))! as! UIImageView
            if (self.selectedBlock != nil) {
                self.selectedBlock!(imageView,imagePath,index)
            }
            delegate.adView(self, didSelectedAtIndex: index, selectedImageView: imageView, selectedImagePath: imagePath)
        }
    }
}

extension NSArray {
    func ad_SafeObjectAtIndex(index: Int) -> AnyObject {
        if self.count > 0 && self.count > index {
            return self.objectAtIndex(index)
        }else{
            return UIImageView()
        }
    }
}

extension XCADView:UIScrollViewDelegate{
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        if self.isCircle == true {
            var page = scrollView.contentOffset.x/scrollView.frame.size.width
            if Int(page) == dataArray.count + 1 {
                page = 0
            }else{
                page -= 1
            }
            self.pageControl?.currentPage = Int(page)
            if 0 == scrollView.contentOffset.x {
                scrollView.contentOffset = CGPoint(x: scrollView.frame.size.width * CGFloat(dataArray.count),y:0)
            }else if(scrollView.contentOffset.x == scrollView.frame.size.width * CGFloat(dataArray.count + 1)){
                scrollView.contentOffset = CGPoint(x: scrollView.frame.size.width,y: 0)
            }
        }else{
            let page = scrollView.contentOffset.x/scrollView.frame.size.width
            self.pageControl?.currentPage = Int(page)
        }
    }
}

