//
//  RMSideMenuShadow.swift
//  RetailManagementSwift
//
//  Created by Master on 2017/6/21.
//  Copyright © 2017年 Master. All rights reserved.
//

import UIKit

class RMSideMenuShadow: NSObject {

    var shadowedView : UIView?
    
    var color : UIColor?{
        
        didSet{
            draw()
        }
    }
    
    var opacity : CGFloat?{
        
        didSet{
            draw()
        }
    }

    
    var radius : CGFloat?{
        
        didSet{
            draw()
        }
    }

    
    var enabled : Bool?{
        
        didSet{
            draw()
        }
    }

    
    static func shadowWithView(shadowedView : UIView) -> RMSideMenuShadow {
        
        let shadow = RMSideMenuShadow.shadowWithColor(color: UIColor.black, radius: 10.0, opacity: 0.75)
        shadow.shadowedView = shadowedView
        return shadow
    }
    
    static func shadowWithColor(color : UIColor, radius : CGFloat, opacity : CGFloat) -> RMSideMenuShadow{
        
        let shadow = RMSideMenuShadow()
        shadow.color = color
        shadow.radius = radius
        shadow.opacity = opacity
        return shadow
    }
    
    override init() {
        
        color = UIColor.black
        opacity = 0.75
        radius = 10.0
        enabled = true
        super.init()
        
    }
    
}

// MARK: -
// MARK: -Drawing
extension RMSideMenuShadow{
    
    func draw() {
        if enabled == true {
            
            show()
        }else{
            
            hide()
        }
        
    }
    
    func show() {
        
        var pathRect = shadowedView?.bounds
        pathRect?.size = (shadowedView?.frame.size)!
        shadowedView?.layer.shadowPath = UIBezierPath(rect: pathRect!).cgPath
        shadowedView?.layer.shadowOpacity = Float(opacity!)
        shadowedView?.layer.shadowRadius = radius!
        shadowedView?.layer.shadowColor = color!.cgColor;        shadowedView?.layer.rasterizationScale = UIScreen.main.scale
        
    }
    
    func hide()  {
        
        shadowedView?.layer.shadowOpacity = 0.0
        shadowedView?.layer.shadowRadius = 0.0
    }

}

// MARK: -
// MARK: - ShadowedView Rotation
extension RMSideMenuShadow{
    
    func shadowedViewWillRotate() {
        
        shadowedView?.layer.shadowPath = nil
        shadowedView?.layer.shouldRasterize = true
    }
    
    func shadowedViewDidRotate() {
        
        draw()
        shadowedView?.layer.shouldRasterize = false
    }
}
