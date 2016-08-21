
import SpriteKit
import GoogleMobileAds

class MenuScene: SKScene {
    
    var trump: SKSpriteNode!
    var hillary: SKSpriteNode!
    var hillaryLabel: SKLabelNode!
    var donaldLabel: SKLabelNode!
    var redRect: SKSpriteNode!
    var blueRect: SKSpriteNode!
    var activityIndicator: UIActivityIndicatorView!
    var timer: NSTimer!
    
    var root: UIViewController!
        
    override func didMoveToView(view: SKView) {
        
        let background = SKSpriteNode(imageNamed: "background")
        background.size = frame.size
        background.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
        background.zPosition = 0
        addChild(background)
        
        trump = SKSpriteNode(imageNamed: "big_donald")
        hillary = SKSpriteNode(imageNamed: "big_hillary")
        
        trump.position = CGPoint(x: frame.width / 4, y: frame.height * 0.51)
        hillary.position = CGPoint(x: frame.width / 4 * 3, y: frame.height * 0.51)
        
        addChild(trump)
        addChild(hillary)
        
        trump.zPosition = 1
        hillary.zPosition = 1
        
        let globalLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        globalLabel.text = "Global Scores"
        globalLabel.fontColor = SKColor.whiteColor()
        globalLabel.fontSize = 21
        globalLabel.position = CGPoint(x: frame.width / 2, y: frame.height * 0.50 + 155)
        globalLabel.zPosition = 2
        addChild(globalLabel)
        
        let selectLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        selectLabel.text = "Select Presidential Nominee"
        selectLabel.fontColor = SKColor.blackColor()
        selectLabel.fontSize = 20
        selectLabel.position = CGPoint(x: frame.width / 2, y: frame.height * 0.36)
        selectLabel.zPosition = 2
        //        addChild(selectLabel)
        
        drawScores(redraw: false)
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        activityIndicator.center = CGPoint(x: frame.width / 2, y: frame.height * 0.5 - 115)
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        
        let wait = SKAction.waitForDuration(5.0)
        let run = SKAction.runBlock {
            print("redraw score")
            self.drawScores(redraw: true)
        }
    
        globalLabel.runAction(SKAction.repeatActionForever(SKAction.sequence([wait, run])))
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let skView = view!
        let menu = GameScene(size: skView.bounds.size)
        skView.ignoresSiblingOrder = true
        skView.multipleTouchEnabled = true
        menu.scaleMode = .AspectFill
        
        for touch in touches {
            if trump.containsPoint(touch.locationInNode(self)) {
                menu.nominee = "donald"
                menu.root = self.root
                activityIndicator.stopAnimating()
                skView.presentScene(menu)
            } else if hillary.containsPoint(touch.locationInNode(self)) {
                menu.nominee = "hillary"
                menu.root = self.root
                activityIndicator.stopAnimating()
                skView.presentScene(menu)
            }
        }
    }
    
    func drawScores(dScore: Double, hScore: Double, redraw: Bool) {
        
        if (view == nil) {
            return
        }
        
        let totalScore = dScore + hScore
        let dScorePercent = dScore / totalScore
        let hScorePercent = hScore / totalScore
        
        if !redraw {
            redRect = SKSpriteNode(color: SKColor.redColor(), size: CGSize(width: view!.frame.width * 0.8 * CGFloat(dScorePercent), height: 24))
            blueRect = SKSpriteNode(color: SKColor.blueColor(), size: CGSize(width: view!.frame.width * 0.8 * CGFloat(hScorePercent), height: 24))
            donaldLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            hillaryLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            
            blueRect.zPosition = 3
            redRect.zPosition = 3
            donaldLabel.zPosition = 3
            hillaryLabel.zPosition = 3
            donaldLabel.fontSize = 20
            donaldLabel.fontColor = SKColor.redColor()
            hillaryLabel.fontSize = 20
            hillaryLabel.fontColor = SKColor.blueColor()
            addChild(donaldLabel)
            addChild(hillaryLabel)
            addChild(blueRect)
            addChild(redRect)
        }
        if redRect == nil {
            return
        }
        
        redRect.size = CGSize(width: view!.frame.width * 0.8 * CGFloat(dScorePercent), height: 24)
        blueRect.size = CGSize(width: view!.frame.width * 0.8 * CGFloat(hScorePercent), height: 24)
        redRect.position = CGPoint(x: frame.width / 2 - (frame.width - redRect.frame.width) / 2 + 10, y: frame.height * 0.49 + 100 + 30)
        blueRect.position = CGPoint(x: frame.width / 2 - (frame.width - blueRect.frame.width) / 2 + 10, y: frame.height * 0.49 + 100)
        
        let donaldIcon = SKLabelNode(fontNamed: "AvenirNext-Bold")
        donaldIcon.text = "D"
        donaldIcon.zPosition = 3
        donaldIcon.verticalAlignmentMode = .Center
        donaldIcon.fontSize = 16
        redRect.addChild(donaldIcon)
        
        let hillaryIcon = SKLabelNode(fontNamed: "AvenirNext-Bold")
        hillaryIcon.text = "H"
        hillaryIcon.zPosition = 3
        hillaryIcon.verticalAlignmentMode = .Center
        hillaryIcon.fontSize = 16
        blueRect.addChild(hillaryIcon)
        
        donaldLabel.text = "\(Int(dScore))"
        donaldLabel.position = CGPoint(x: redRect.frame.width + 40, y: frame.height * 0.49 + 100 + 30 - (donaldLabel.frame.height / 2))
        
        hillaryLabel.text = "\(Int(hScore))"
        hillaryLabel.position = CGPoint(x: blueRect.frame.width + 40, y: frame.height * 0.49 + 100 - (donaldLabel.frame.height / 2))
        
        activityIndicator.stopAnimating()
    }
    
    func drawScores(redraw redraw: Bool) {
        var scoreObjects: [PFObject] = []
        let query = PFQuery(className: "Score")
        query.addAscendingOrder("nominee")
        query.findObjectsInBackgroundWithBlock { (objects, error) in
            if error == nil {
                scoreObjects = objects!
                let dScore = scoreObjects[0]["score"] as! Double
                let hScore = scoreObjects[1]["score"] as! Double
                self.drawScores(dScore, hScore: hScore, redraw: redraw)
            } else {
                print(error)
            }
        }
    }
}
