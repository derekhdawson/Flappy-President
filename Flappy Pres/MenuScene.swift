

import SpriteKit

class MenuScene: SKScene {
    
    var trump: SKSpriteNode!
    var hillary: SKSpriteNode!
    var hillaryLabel: SKLabelNode!
    var donaldLabel: SKLabelNode!
    var redRect: SKSpriteNode!
    var blueRect: SKSpriteNode!
    var timer = NSTimer()
    
    override func didMoveToView(view: SKView) {
        
        let background = SKSpriteNode(imageNamed: "background")
        background.size = frame.size
        background.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
        background.zPosition = 0
        addChild(background)
        
        trump = SKSpriteNode(imageNamed: "donald")
        hillary = SKSpriteNode(imageNamed: "hillary")
        
        trump.setScale(0.15)
        trump.position = CGPoint(x: frame.width / 4, y: frame.height * 0.5)
        hillary.setScale(0.15)
        hillary.position = CGPoint(x: frame.width / 4 * 3, y: frame.height * 0.5)
        
        addChild(trump)
        addChild(hillary)
        
        trump.zPosition = 1
        hillary.zPosition = 1
        
        let globalLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        globalLabel.text = "Global Scores"
        globalLabel.fontColor = SKColor.blackColor()
        globalLabel.fontSize = 20
        globalLabel.position = CGPoint(x: frame.width / 2, y: frame.height * 0.5 + 170)
        globalLabel.zPosition = 2
        addChild(globalLabel)
        
        let selectLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        selectLabel.text = "Select Presidential Nominee"
        selectLabel.fontColor = SKColor.blackColor()
        selectLabel.fontSize = 20
        selectLabel.position = CGPoint(x: frame.width / 2, y: frame.height * 0.36)
        selectLabel.zPosition = 2
        //        addChild(selectLabel)
        
        
        
        var scoreObjects: [PFObject] = []
        let query = PFQuery(className: "Score")
        query.addAscendingOrder("nominee")
        query.findObjectsInBackgroundWithBlock { (objects, error) in
            if error == nil {
                scoreObjects = objects!
                let dScore = scoreObjects[0]["score"] as! Double
                let hScore = scoreObjects[1]["score"] as! Double
                self.drawScores(dScore, hScore: hScore)
                //                self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(MenuScene.updateScores), userInfo: nil, repeats: true)
                
            } else {
                print(error)
            }
        }
        
        
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
                skView.presentScene(menu)
            } else if hillary.containsPoint(touch.locationInNode(self)) {
                menu.nominee = "hillary"
                skView.presentScene(menu)
            }
        }
    }
    
    func drawScores(dScore: Double, hScore: Double) {
        
        if (view == nil) {
            return
        }
        
        let totalScore = dScore + hScore
        let dScorePercent = dScore / totalScore
        let hScorePercent = hScore / totalScore
        
        redRect = SKSpriteNode(color: SKColor.redColor(), size: CGSize(width: view!.frame.width * 0.8 * CGFloat(dScorePercent), height: 30))
        redRect.position = CGPoint(x: frame.width / 2 - (frame.width - redRect.frame.width) / 2 + 10, y: frame.height * 0.5 + 100 + 30 + 10)
        redRect.zPosition = 3
        
        blueRect = SKSpriteNode(color: SKColor.blueColor(), size: CGSize(width: view!.frame.width * 0.8 * CGFloat(hScorePercent), height: 30))
        blueRect.position = CGPoint(x: frame.width / 2 - (frame.width - blueRect.frame.width) / 2 + 10, y: frame.height * 0.5 + 100)
        blueRect.zPosition = 3
        
        donaldLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        donaldLabel.fontSize = 20
        donaldLabel.fontColor = SKColor.blackColor()
        donaldLabel.text = "\(Int(hScore))"
        donaldLabel.position = CGPoint(x: blueRect.frame.width + 30, y: frame.height * 0.5 + 100 - (donaldLabel.frame.height / 2))
        donaldLabel.zPosition = 3
        addChild(donaldLabel)
        
        hillaryLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        hillaryLabel.text = "\(Int(dScore))"
        hillaryLabel.fontSize = 20
        hillaryLabel.fontColor = SKColor.blackColor()
        hillaryLabel.position = CGPoint(x: redRect.frame.width + 30, y: frame.height * 0.5 + 100 + 30 + 10 - (donaldLabel.frame.height / 2))
        hillaryLabel.zPosition = 3
        addChild(hillaryLabel)
        
        addChild(blueRect)
        addChild(redRect)
    }
    
    func getScores() {
        var scoreObjects: [PFObject] = []
        let query = PFQuery(className: "Score")
        query.addAscendingOrder("nominee")
        query.findObjectsInBackgroundWithBlock { (objects, error) in
            if error == nil {
                scoreObjects = objects!
                let dScore = scoreObjects[0]["score"] as! Double
                let hScore = scoreObjects[1]["score"] as! Double
                self.updateScores(hScore, dScore: dScore)
            } else {
                print(error)
            }
        }
    }
    
    func updateScores(hScore: Double, dScore: Double) {
        let totalScore = dScore + hScore
        let dScorePercent = dScore / totalScore
        let hScorePercent = hScore / totalScore
        redRect.size = CGSize(width: view!.frame.width * 0.8 * CGFloat(dScorePercent), height: 30)
        redRect.position = CGPoint(x: frame.width / 2 - (frame.width - redRect.frame.width) / 2 + 10, y: frame.height * 0.5 + 100 + 30 + 10)
        blueRect.size = CGSize(width: view!.frame.width * 0.8 * CGFloat(hScorePercent), height: 30)
        blueRect.position = CGPoint(x: frame.width / 2 - (frame.width - blueRect.frame.width) / 2 + 10, y: frame.height * 0.5 + 100)
        donaldLabel.text = "\(Int(hScore))"
        hillaryLabel.text = "\(Int(dScore))"
    }
    
}
