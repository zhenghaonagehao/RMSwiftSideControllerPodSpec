//
//  RMSideController.swift
//  RetailManagementSwift
//
//  Created by Master on 2017/6/21.
//  Copyright © 2017年 Master. All rights reserved.
//

import UIKit

struct RMSideMenuPanMode : OptionSet {
    
    var rawValue = 0
    static var None = RMSideMenuPanMode(rawValue : 1)
    static var CenterViewController = RMSideMenuPanMode(rawValue : 2)
    static var SideMenu = RMSideMenuPanMode(rawValue : 4)
    static var Default = [RMSideMenuPanMode.SideMenu, RMSideMenuPanMode.CenterViewController]

}

enum RMSideMenuStateEvent {
    case WillOpen //将要打开
    case DidOpen
    case WillClose
    case DidClose
}

struct RMSideMenuState : OptionSet {
    
    var rawValue = 0
    static var Closed = RMSideMenuState(rawValue : 1 )
    static var LeftMenuOpen = RMSideMenuState(rawValue : 2)
    static var RightMenuOpen = RMSideMenuState(rawValue : 4)
    
}

fileprivate enum RMSideMenuPanDirection {
    case None
    case Left
    case Right
}
let RMSideMenuStateNotificationEvent = "RMSideMenuStateNotificationEvent"

class RMSideController: UIViewController {
    
    fileprivate var menuContainerView : UIView?
    
    //手势速率
    
    fileprivate var panGestureVelocity : CGFloat?
    
    fileprivate var panGestureOrigin : CGPoint?
    
    fileprivate var panDirection : RMSideMenuPanDirection?
    
    fileprivate var viewHasAppeared : Bool?
    
    var centerViewController : AnyObject?{
        
        willSet{
            
            removeCenterGestureRecognizers()
            removeChildViewControllerFromContainer(childViewController: centerViewController as! UIViewController?)
        }
        
        didSet{
            
            let origin = (self.centerViewController as? UIViewController)?.view.frame.origin
            
            if self.centerViewController == nil {
                return
            }
            addChildViewController(self.centerViewController as! UIViewController)
            view.addSubview((self.centerViewController?.view)!)
            (self.centerViewController as? UIViewController)?.view.frame = CGRect(origin: origin!, size: (centerViewController?.view.frame.size)!)
            
            self.centerViewController?.didMove(toParentViewController: self)
            
            if shadow != nil {
                
                shadow?.shadowedView = centerViewController?.view
            }else{
                
                shadow = RMSideMenuShadow.shadowWithView(shadowedView: (self.centerViewController?.view)!)
            }
            shadow?.draw()
            addCenterGestureRecognizers()
            
        }
    }
    
    var leftMenuViewController : AnyObject?{
        
        willSet{
            
            removeChildViewControllerFromContainer(childViewController: self.leftMenuViewController as! UIViewController?)
            

        }
        
        didSet{
            
            if self.leftMenuViewController == nil {
                return
            }
            addChildViewController(self.leftMenuViewController! as! UIViewController)
            if menuContainerView?.superview != nil {
                menuContainerView?.insertSubview((leftMenuViewController?.view)!, at: 0)
            }
            leftMenuViewController?.didMove(toParentViewController: self)
            
            if viewHasAppeared == true {
                
                setLeftSideMenuFrameToClosePosition()
            }

        }
    }

    
    var rightMenuViewController : AnyObject?{
        
        willSet{
            
            removeChildViewControllerFromContainer(childViewController: self.rightMenuViewController as! UIViewController?)
        }
        
        didSet{
            
            if rightMenuViewController == nil {
                
                return
            }
            
            addChildViewController(rightMenuViewController! as! UIViewController)
            if menuContainerView?.superview != nil {
                
                menuContainerView?.insertSubview((rightMenuViewController?.view)!, at: 0)
            }
            rightMenuViewController?.didMove(toParentViewController: self)
            if viewHasAppeared == true {
                setRightSideMenuFrameToClosePosition()
            }

        }
    }

    
    var menuState : RMSideMenuState?
    
    var panMode : [RMSideMenuPanMode]?
    
    //动画时长 可限制最长
    
    var menuAnimationDefaultDuration : CGFloat?
    
    var menuAnimationMaxDuration : CGFloat?
    
    // 侧边栏的宽
    
    var menuWidth : CGFloat?{
        
        didSet{
            setMenuWidth(menuWidth:menuWidth!, animated: true)
        }
    }
    
    var leftMenuWidth : CGFloat?
    
    var rightMenuWidth : CGFloat?

    //阴影
    
    var shadow : RMSideMenuShadow?
    
    // 滑动动画
    
    var menuSlideAnimationEnabled : Bool?
    
    //值越大 菜单动画距离越小
    
    var menuSlideAnimationFactor : CGFloat?
    
    fileprivate var disablePan : Bool?
    
    static func containerWithCenterViewController(centerViewController : AnyObject? ,leftMenuViewController : AnyObject? , rightMenuViewController : AnyObject?) -> RMSideController {
        
        let controller = RMSideController.init()
        
        controller.centerViewController = centerViewController
        controller.leftMenuViewController = leftMenuViewController
        controller.rightMenuViewController = rightMenuViewController
        
        return controller
    }
    
    //重写init方法
    init() {
        
        super.init(nibName: nil, bundle: nil)
        self.setDefaultSettings()
    
    }
    
    required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)
        self.setDefaultSettings()
        
    }
    
    func setDefaultSettings()  {
        
        guard self.menuContainerView == nil else {
            
            return
        }
        
        menuContainerView = UIView()
        menuState = .Closed
        menuWidth = 270.0
        menuSlideAnimationFactor = 3.0
        menuAnimationMaxDuration = 0.4
        menuAnimationDefaultDuration = 0.2
        panMode = RMSideMenuPanMode.Default
        menuSlideAnimationEnabled = false
        disablePan = false
        viewHasAppeared = false
        
    }
        
    func setupMenuContainerView()  {
        
        guard self.menuContainerView!.superview == nil else {
            return
        }
        
        menuContainerView?.frame = self.view.bounds
        menuContainerView?.autoresizingMask = [UIViewAutoresizing.flexibleHeight,.flexibleWidth]
        view.insertSubview(menuContainerView!, at: 0)
        
        if (self.leftMenuViewController != nil) && (self.leftMenuViewController?.view.superview == nil) {
            menuContainerView?.addSubview((leftMenuViewController?.view)!)
        }
        
        if self.rightMenuViewController != nil && (self.rightMenuViewController?.view.superview == nil) {
            menuContainerView?.addSubview((rightMenuViewController?.view)!)
        }
        
    }
    
}
    // MARK: -
    // MARK: - view lifecycle
extension RMSideController {
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        if self.viewHasAppeared  == false {
            
            setupMenuContainerView()
            setLeftSideMenuFrameToClosePosition()
            setRightSideMenuFrameToClosePosition()
            
            
            
        }
        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if self.responds(to: #selector(getter: topLayoutGuide)) {
            
            let insets = UIEdgeInsetsMake(topLayoutGuide.length, 0, 0, 0)
        
            if (leftMenuViewController != nil) && (leftMenuViewController?.automaticallyAdjustsScrollViewInsets)! && ((leftMenuViewController?.view)?.isKind(of: UIScrollView.classForCoder()))!{
                // TODO: 判断==或！=nil
                (leftMenuViewController?.view as? UIScrollView)?.contentInset = insets
            }
            
            if rightMenuViewController != nil && (rightMenuViewController?.automaticallyAdjustsScrollViewInsets)! && ((rightMenuViewController?.view) as?UIScrollView)?.contentInset != nil {
                
                ((rightMenuViewController?.view) as?UIScrollView)?.contentInset = insets
            }
            
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        if centerViewController != nil {
            
            if centerViewController is UINavigationController {
            
                return ((centerViewController as! UINavigationController).topViewController?.preferredStatusBarStyle)!
            }
            return (centerViewController?.preferredStatusBarStyle)!
        }
        return UIStatusBarStyle.default
    }
    
}

// MARK: -
// MARK: - UIViewController Roatation
extension RMSideController {
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask{
        
        get{
            if centerViewController != nil {
            
                if centerViewController is UINavigationController {
                    
                    return ((centerViewController as! UINavigationController).topViewController?.supportedInterfaceOrientations)!
                }
            }
            return super.supportedInterfaceOrientations
        }
    
    }
    
    override var shouldAutorotate: Bool{
        
        get{
            
            if centerViewController != nil {
                
                if centerViewController is UINavigationController {
                    
                    return ((centerViewController as! UINavigationController).topViewController?.shouldAutorotate)!
                }
                return (centerViewController?.shouldAutorotate)!
            }
            return true
        }
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation{
        
        get{
            
            if centerViewController != nil {
                
                if centerViewController is UINavigationController {
                    
                    return ((centerViewController as! UINavigationController).topViewController?.preferredInterfaceOrientationForPresentation)!
                }
                return (centerViewController?.preferredInterfaceOrientationForPresentation)!
            }
            return UIInterfaceOrientation.portrait
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        shadow?.shadowedViewWillRotate()
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        shadow?.shadowedViewDidRotate()
    }
}

// MARK: -
// MARK: - UIViewController Containment
extension RMSideController {
    
    func removeChildViewControllerFromContainer(childViewController : UIViewController?)  {
        
        if childViewController == nil   {
            return
        }
        childViewController?.willMove(toParentViewController: nil)
        childViewController?.removeFromParentViewController()
        childViewController?.view.removeFromSuperview()
    }
    
}

// MARK: -
// MARK: - UIGestureRecognizer Helpers
extension RMSideController {
    
    func removeCenterGestureRecognizers() {
        
        if centerViewController != nil {
            
            (centerViewController! as? UIViewController)?.view.removeGestureRecognizer((centerTapGestureRecognizer()))
            
        }
    }
    func addGestureRecognizers() {
        
        addCenterGestureRecognizers()
        menuContainerView?.addGestureRecognizer(panGestureRecognizer())
    }
    
    func addCenterGestureRecognizers() {
        
        if centerViewController != nil {
            
            (centerViewController as? UIViewController)?.view.addGestureRecognizer(centerTapGestureRecognizer())
            (centerViewController as? UIViewController)?.view.addGestureRecognizer(panGestureRecognizer())
        }
    }
    
 
    func centerTapGestureRecognizer() -> UITapGestureRecognizer {
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(centerViewControllerTapped(sender:)))
        tapRecognizer.delegate = self
        return tapRecognizer
        
    }
    
    func panGestureRecognizer() -> UIPanGestureRecognizer {
        
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(recognizer:)))
        recognizer.maximumNumberOfTouches = 1
        recognizer.delegate = self
        return recognizer
    }
}
// MARK: -
// MARK: - Menu State
extension RMSideController {
    
    func toggleLeftSideMenuCompletion(completion : Optional<()->()> )  {
        
        if menuState == RMSideMenuState.LeftMenuOpen {
            setMenuState(menuState: RMSideMenuState.Closed, completion: completion)
            
        }else{
            
            setMenuState(menuState: RMSideMenuState.LeftMenuOpen, completion: completion)
        }
        
    }
    
    func openLeftSideMenuCompletion(completion : Optional<()->()>) {
        
        guard leftMenuViewController != nil else {
            return
        }
        
        menuContainerView?.bringSubview(toFront:(leftMenuViewController?.view)!)
        setCenterViewControllerOffset(offset: (leftMenuWidth)!, animated: true, completion: completion)
        
    }
    
    func openRightSideMenuCompletion(completion : @escaping ()->()) {
        
        guard rightMenuViewController != nil else {
            return
        }
        
        menuContainerView?.bringSubview(toFront:(rightMenuViewController?.view)!)
        setCenterViewControllerOffset(offset: -1 * (rightMenuWidth)!, animated: true, completion: completion)
        
    }
    
    func closeSideMenuCompletion(completion : @escaping ()->() ) {
        
        setCenterViewControllerOffset(offset: 0, animated: true, completion: completion)
        
    }
    
    func setMenuState(menuState : RMSideMenuState) {
        
        setMenuState(menuState: menuState, completion: nil)
    }
    
    func setMenuState(menuState : RMSideMenuState , completion : Optional<()->()> ) {
        
        
        let inneerCompletion = {
            
            self.menuState = menuState
            
            self.setUserInteractionStateForCenterViewController()
            let eventType = self.menuState == RMSideMenuState.Closed ? RMSideMenuStateEvent.DidClose : RMSideMenuStateEvent.DidOpen
            self.sendStateEventNotification(event: eventType)
            
            completion?()
        }
        
        switch menuState {
        case RMSideMenuState.Closed:
            
            sendStateEventNotification(event: RMSideMenuStateEvent.WillClose)
            closeSideMenuCompletion {
                self.leftMenuViewController?.view.isHidden = true
                self.rightMenuViewController?.view.isHidden = true
                inneerCompletion()
            }
            
            break
        case RMSideMenuState.LeftMenuOpen:
            
            guard self.leftMenuViewController != nil else {
                return
            }
            sendStateEventNotification(event: RMSideMenuStateEvent.WillOpen)
            leftMenuWillShow()
            openLeftSideMenuCompletion(completion: inneerCompletion)
            
            break
            
        case RMSideMenuState.RightMenuOpen:
            
            guard rightMenuViewController != nil else {
                return
            }
            sendStateEventNotification(event: RMSideMenuStateEvent.WillOpen)
            rightMenuWillShow()
            openRightSideMenuCompletion(completion: inneerCompletion)
            break
            
        default:
            break
        }
        
        
    }
    
    func leftMenuWillShow()  {
        
        leftMenuViewController?.view.isHidden = false
        menuContainerView?.bringSubview(toFront: (leftMenuViewController?.view)!)
        
    }
    
    func rightMenuWillShow()  {
        
        rightMenuViewController?.view.isHidden = false
        menuContainerView?.bringSubview(toFront: (rightMenuViewController?.view)!)
        
    }
    
}
// MARK: -
// MARK: - State Event Notification
extension RMSideController {
    
    func sendStateEventNotification(event : RMSideMenuStateEvent) {
        
        let userInfo = NSDictionary(dictionary: ["eventTupe":NSNumber.init(value: event.hashValue)])
        NotificationCenter.default.post(name:NSNotification.Name(rawValue: RMSideMenuStateNotificationEvent), object: self, userInfo: userInfo as? [AnyHashable : Any])
        
    }
    
}
    // MARK: -
    // MARK: - side menu prositoning
extension RMSideController {
    
    func setLeftSideMenuFrameToClosePosition() {
        
        guard leftMenuViewController != nil else {
            return
        }
        
        var leftFrame = self.leftMenuViewController?.view.frame
        leftFrame?.size.width = leftMenuWidth!
        leftFrame?.origin.x = menuSlideAnimationEnabled! ? (-1 * (leftFrame?.size.width)! / menuSlideAnimationFactor!) : 0
        leftFrame?.origin.y = 0
        leftMenuViewController?.view.frame = leftFrame!
        leftMenuViewController?.view.autoresizingMask = [.flexibleRightMargin,.flexibleHeight]
        
    }
    
    func setRightSideMenuFrameToClosePosition() {
        
        guard rightMenuViewController != nil else {
            return
        }
        
        var rightFrame = self.rightMenuViewController?.view.frame
        rightFrame?.size.width = rightMenuWidth!
        rightFrame?.origin.x = (menuContainerView?.frame.size.width)! - rightMenuWidth!
        rightFrame?.origin.y = 0
        if menuSlideAnimationEnabled == true {
            rightFrame?.origin.x += rightMenuWidth! / menuSlideAnimationFactor!
        }
        leftMenuViewController?.view.frame = rightFrame!
        leftMenuViewController?.view.autoresizingMask = [.flexibleLeftMargin,.flexibleHeight]
        
    }
    
    
    func alignLeftMenuControllerWithCenterViewController() {
    
        let xOffset = centerViewController?.view.frame.origin.x
        let xPositionDivider = menuSlideAnimationEnabled! ? menuSlideAnimationFactor : 1.0
        
        leftMenuViewController?.view.frame.origin.x = (xOffset! / xPositionDivider!) - (leftMenuWidth! / xPositionDivider!)
        leftMenuViewController?.view.frame.size.width = leftMenuWidth!
    }
    
    func alignRightMenuControllerWithCenterViewController() {
        
        rightMenuViewController?.view.frame.size.width = rightMenuWidth!
        
        let xOffset = centerViewController?.view.frame.origin.x
        let xPositionDivider = menuSlideAnimationEnabled! ? self.menuSlideAnimationFactor : 1.0
        
        rightMenuViewController?.view.frame.origin.x = (menuContainerView?.frame.size.width)! - rightMenuWidth! + xOffset! / xPositionDivider! + rightMenuWidth! / xPositionDivider!
        
    }
}
    // MARK: -
    // MARK: - side Menu width
extension RMSideController {
    
      func setMenuWidth(menuWidth : CGFloat , animated : Bool) {
        
        setLeftMenuWideth(leftMenuWidth: menuWidth, animated: animated)
        setRightMenuWidth(rightMenuwidth: menuWidth, animated: animated)
    }
    
    func setLeftMenuWideth(leftMenuWidth : CGFloat , animated : Bool) {
        
        self.leftMenuWidth = leftMenuWidth
        
        guard menuState == RMSideMenuState.LeftMenuOpen else {
            setLeftSideMenuFrameToClosePosition()
            return
        }
        
        let offset = leftMenuWidth
        let effects = {
            
            self.alignLeftMenuControllerWithCenterViewController()
        }
        
        setCenterViewControllerOffset(offset: offset, additionalAnimations: effects, animated: animated, completion: nil)
        
    }
    
    func setRightMenuWidth(rightMenuwidth : CGFloat, animated : Bool) {
        
        self.rightMenuWidth = rightMenuwidth
        
        if menuState != RMSideMenuState.RightMenuOpen {
            
            setRightSideMenuFrameToClosePosition()
            return
        }
        
        let offset = -1 * rightMenuwidth
        let effects = {
            
            self.alignRightMenuControllerWithCenterViewController()
        }
        setCenterViewControllerOffset(offset: offset, additionalAnimations: effects, animated: animated, completion: nil)
        
        
    }
    
}

// MARK: -
// MARK: - MFSideMenuPanMode
extension RMSideController {
    
    func centerViewControllerPanEnabled() ->Bool {
        
        return panMode!.contains(RMSideMenuPanMode.CenterViewController)
    }
    
    func sideMenuPanEnabled() -> Bool {
        
        return panMode!.contains(RMSideMenuPanMode.SideMenu)
    }
    
}
// MARK: -
// MARK: - UIGestureRecognizerDelegate
extension RMSideController : UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        if gestureRecognizer is UITapGestureRecognizer && menuState != RMSideMenuState.Closed {
            
            return true
        }
        
        if gestureRecognizer is UIPanGestureRecognizer  {
            
            if (gestureRecognizer.view?.isEqual((self.centerViewController?.view)!))!{
                
                return centerViewControllerPanEnabled()
            }
            if (gestureRecognizer.view?.isEqual(self.menuContainerView))! {
             
                return sideMenuPanEnabled()
            }
            
            return true
        }
        
        return false
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if gestureRecognizer is UIPanGestureRecognizer {
            
            let velocity = (gestureRecognizer as! UIPanGestureRecognizer).velocity(in: gestureRecognizer.view)
            let isHorizontalPanning = fabsf(Float(velocity.x)) > fabsf(Float(velocity.y))
            return isHorizontalPanning
  
        }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return false
    }
    
}
// MARK: -
// MARK: - UIGestureRecognizer Callbacks
extension RMSideController {
    
    func handlePan(recognizer : UIPanGestureRecognizer) -> Void {
        
        guard disablePan == false else {
            return
        }
        
        let view = centerViewController?.view
        
        if recognizer.state == UIGestureRecognizerState.began {
            
            panGestureOrigin = view?.frame.origin
            panDirection = RMSideMenuPanDirection.None
            
        }
        
        if panDirection == RMSideMenuPanDirection.None {
            
            let translatePoint = recognizer.translation(in: view)
            
            if translatePoint.x > 0  {
                
                panDirection = RMSideMenuPanDirection.Right
                if leftMenuViewController != nil && menuState == RMSideMenuState.Closed {
                    
                    leftMenuWillShow()
                }
            }else if translatePoint.x < 0 {
                
                panDirection = RMSideMenuPanDirection.Left
                if rightMenuViewController != nil && menuState == RMSideMenuState.Closed {
                    rightMenuWillShow()
                }
            }
        }
        
        if (menuState == [RMSideMenuState.LeftMenuOpen , RMSideMenuState.RightMenuOpen] && panDirection == RMSideMenuPanDirection.Left)||(menuState == RMSideMenuState.LeftMenuOpen && panDirection == RMSideMenuPanDirection.Right) {
            
            panDirection = RMSideMenuPanDirection.None
            return
        }
        
        if panDirection == RMSideMenuPanDirection.Left {
            
            handleLeftPan(recognizer: recognizer)
        }else if panDirection == RMSideMenuPanDirection.Right{
            
            handleRightPan(recognizer: recognizer)
        }
    }
    
    func handleLeftPan(recognizer : UIPanGestureRecognizer) {
        
        if rightMenuViewController == nil && menuState == RMSideMenuState.Closed {
            return
        }
        
        let view = centerViewController?.view
        
        var translatedPoint = recognizer.translation(in: view)
        let adjustedOrigin = panGestureOrigin
        translatedPoint = CGPoint(x: (adjustedOrigin?.x)! + translatedPoint.x, y: (adjustedOrigin?.y)! + translatedPoint.y)
        translatedPoint.x = max(translatedPoint.x, -1 * rightMenuWidth!)
        translatedPoint.x = min(translatedPoint.x, leftMenuWidth!)
        if menuState == RMSideMenuState.LeftMenuOpen {
            
            translatedPoint.x = max(translatedPoint.x, 0)
        }else{
            
            translatedPoint.x = min(translatedPoint.x, 0)
        }
        
        setCenterViewControllerOffset(xOffset: translatedPoint.x)
        
        if recognizer.state == UIGestureRecognizerState.ended {
            
            let velocity = recognizer.velocity(in: view)
            let finalX = translatedPoint.x + (0.35 * velocity.x)
            let viewWidth = view?.frame.size.width
            
            if menuState == RMSideMenuState.Closed {
                
                let showMenu = (finalX < ( ( -1 * viewWidth! ) / 2 )) || (  finalX < (-1 * rightMenuWidth! ) / 2 )
                if showMenu == true {
                    
                    panGestureVelocity = velocity.x
                    setMenuState(menuState: RMSideMenuState.RightMenuOpen)
                }else{
                    
                    panGestureVelocity = 0
                    setCenterViewControllerOffset(offset: 0, animated: true, completion: nil)
                }
            }else{
                
                let hideMenu = finalX < (adjustedOrigin?.x)!
                if hideMenu == true{
                    
                    panGestureVelocity = velocity.x
                    setMenuState(menuState: RMSideMenuState.Closed)
                }
            }
        }
    }
    
    func handleRightPan(recognizer : UIPanGestureRecognizer) {
        
        let view = centerViewController?.view
        
        var translatedPoint = recognizer.translation(in: view)
        let adjustedOrigin = panGestureOrigin
        translatedPoint = CGPoint(x: (adjustedOrigin?.x)! + translatedPoint.x, y: (adjustedOrigin?.y)! + translatedPoint.y)
        translatedPoint.x = max(translatedPoint.x,  -1 * rightMenuWidth!)
        translatedPoint.x = min(translatedPoint.x,  leftMenuWidth!)

        if menuState == RMSideMenuState.RightMenuOpen {
            
            translatedPoint.x = min(translatedPoint.x, 0)
        }else {
            
            translatedPoint.x = max(translatedPoint.x, 0)
        }
        
        if recognizer.state == UIGestureRecognizerState.ended {
            
            let velocity = recognizer.velocity(in: view)
            let finalX  = translatedPoint.x + (0.35 * velocity.x)
            let viewWideth = view?.frame.size.width
            
            if menuState == RMSideMenuState.Closed {
                
                let showMenu = (finalX > viewWideth! / 2) || (finalX > leftMenuWidth! / 2)
                
                if showMenu == true {
                    
                    panGestureVelocity = velocity.x
                    setMenuState(menuState: RMSideMenuState.LeftMenuOpen)
                }else{
                    
                    panGestureVelocity = 0
                    setCenterViewControllerOffset(offset: 0, animated: true, completion: nil)
                }
                
            }else {
                
                let hideMenu = finalX > (adjustedOrigin?.x)!
                if hideMenu == true {
                    
                    panGestureVelocity = velocity.x
                    setMenuState(menuState: RMSideMenuState.Closed)
                }else{
                
                    panGestureVelocity = 0
                    setCenterViewControllerOffset(offset: (adjustedOrigin?.x)!, animated: true, completion: nil)
                }
            }
            
            panDirection = RMSideMenuPanDirection.None
        }else{
            
            setCenterViewControllerOffset(xOffset: translatedPoint.x)
        }
    }
    
    func centerViewControllerTapped(sender : UIPanGestureRecognizer? ) {
        
        if menuState != RMSideMenuState.Closed {
            
            setMenuState(menuState: RMSideMenuState.Closed)
        }
    }
    func setUserInteractionStateForCenterViewController() {
        
        if self.centerViewController?.viewControllers != nil{
            
            let viewControllers = centerViewController?.viewControllers
            for viewController in viewControllers! {
                
                viewController.view.isUserInteractionEnabled = menuState == RMSideMenuState.Closed
            }
            
        }
        
    }
    
}

// MARK: -
// MARK: - Center View Controller Movement
extension RMSideController {
    
    func setCenterViewControllerOffset(offset : CGFloat , animated : Bool , completion : Optional< ()->() > ) {
        
        setCenterViewControllerOffset(offset: offset ,additionalAnimations : nil , animated: animated, completion: completion)
        
    }
    
    func setCenterViewControllerOffset(offset : CGFloat , additionalAnimations : Optional< ()->() >, animated : Bool , completion :  Optional< ()->() > ) {
        
        let innerCompletion = {
            self.panGestureVelocity = 0.0
            completion?()
        }
        
        if animated == true {
            
            let centerViewControllerXPosition = CGFloat(fabsf(Float((centerViewController?.view.frame.origin.x)!)))
            let duration = animationDurationFromStartPosition(startPosition: centerViewControllerXPosition, endPosition: offset)
            
            UIView.animate(withDuration: TimeInterval(duration), animations: {
                self.setCenterViewControllerOffset(xOffset: offset)
            },completion: { (finished : Bool) in
                innerCompletion()
            })

        }
        
    }
    
    func setCenterViewControllerOffset(xOffset : CGFloat) {
        
        var frame = centerViewController?.view.frame
        frame?.origin.x = xOffset
        centerViewController?.view.frame = frame!
        
        guard menuSlideAnimationEnabled == true else {
            
            return
            
        }
        
        if xOffset > 0 {
            
            alignLeftMenuControllerWithCenterViewController()
            setRightSideMenuFrameToClosePosition()
            
        }else if xOffset < 0 {
            
            alignRightMenuControllerWithCenterViewController()
            setLeftSideMenuFrameToClosePosition()
            
        }else{
            
            setLeftSideMenuFrameToClosePosition()
            setRightSideMenuFrameToClosePosition()
        }
        
        
    }
    
    func animationDurationFromStartPosition(startPosition : CGFloat , endPosition : CGFloat) -> CGFloat {
        
        let animationPositionDelta = abs(endPosition - startPosition)
        
        
        var duration : CGFloat
        if fabsf(Float(panGestureVelocity!)) > 1.0 {
            
            duration = animationPositionDelta / CGFloat(fabsf(Float(panGestureVelocity!)))
            
        }else {
            
            let menuWidth = max(leftMenuWidth!, rightMenuWidth!)
            let animationPerecent = animationPositionDelta == 0 ? 0 : menuWidth / animationPositionDelta
            duration = menuAnimationDefaultDuration! * animationPerecent
            
        }
        
        return min(duration, menuAnimationMaxDuration!)
    }
    
}

