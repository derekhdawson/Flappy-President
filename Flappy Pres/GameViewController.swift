

import UIKit
import SpriteKit
import GoogleMobileAds

class GameViewController: UIViewController, GADBannerViewDelegate {
    
    var adBannerView: GADBannerView!
    var interstitial: GADInterstitial!
    static var scenes: [SKScene] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let skView = self.view as! SKView
        
        let menu = MenuScene(size: skView.bounds.size)
        menu.root = self
        
        print(skView.bounds.size)
        
        skView.ignoresSiblingOrder = true
        skView.multipleTouchEnabled = true
        
        
        menu.scaleMode = .AspectFill
        
        skView.presentScene(menu)
        
        
        
        
        adBannerView = GADBannerView(frame: CGRectMake(0, self.view.frame.height - 50, self.view.frame.size.width, 50))
        adBannerView.delegate = self
        adBannerView.rootViewController = self
        adBannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        
        let reqAd = GADRequest()
        adBannerView.loadRequest(reqAd)
        self.view.addSubview(adBannerView)
        
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .All
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func createAndLoadInterstitial() {
        interstitial = GADInterstitial(adUnitID: "ca-app-pub-5214892420848108/8132471670")
        let request = GADRequest()
        request.testDevices = [kGADSimulatorID, "028af437e870b654f8f26c0d88a946ed"]
        interstitial.loadRequest(request)
    }
}
