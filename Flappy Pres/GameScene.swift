
import SpriteKit
import AVFoundation
import GoogleMobileAds
import Social



class GameScene: SKScene, SKPhysicsContactDelegate, GADInterstitialDelegate {
    
    var jumpAmount:CGFloat = 38
    var jumpImpulse:CGFloat!
    
    var bird: SKSpriteNode!
    var ground: SKSpriteNode!
    var background: SKSpriteNode!
    var wallPair: SKNode = SKNode()
    var gameStarted = false
    var gameOver = false
    var moveAndRemove = SKAction()
    var timeOfDeath: NSDate! = nil
    var scoreLabel: SKLabelNode!
    var score = 0
    var nominee: String!
    var pause: SKSpriteNode!
    var play: SKLabelNode!
    var back: SKLabelNode!
    var numSounds = 1
    
    var scoreObject: PFObject!
    var playIndex = 0
    
    var nomineeSounds: [AVAudioPlayer] = []
    var flappySounds: [AVAudioPlayer] = []
    var diedSound: AVAudioPlayer!
    
    var interstitial: GADInterstitial!
    
    var root: UIViewController!
    var rounds = 0
    
    var facebook: SKSpriteNode!
    var twitter: SKSpriteNode!

    
    override func didMoveToView(view: SKView) {
        
        interstitial = createAndLoadInterstitial()
        
        physicsWorld.contactDelegate = self
//        view.showsPhysics = true
        
        
        createScene()
        jumpImpulse = jumpAmount
        
        let query = PFQuery(className: "Score")
        query.whereKey("nominee", equalTo: nominee)
        query.limit = 1
        query.findObjectsInBackgroundWithBlock { (objects, error) in
            if error == nil {
                self.scoreObject = objects![0]
            } else {
                print(error)
            }
        }
        
        if nominee == "donald" {
            numSounds = 7
        }
        
        for i in 1...numSounds {
            let soundFile = "\(nominee)_sound\(i)"
            let sound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("\(soundFile)", ofType: "mp3")!)
            let audioPlayer = try! AVAudioPlayer(contentsOfURL: sound)
            audioPlayer.prepareToPlay()
            nomineeSounds.append(audioPlayer)
        }
        playIndex = Int(CGFloat.random(min: 4, max: 10))
        
        
        flappySounds.append(createAudioPlayer("coin"))
        flappySounds.append(createAudioPlayer("hit"))
        flappySounds.append(createAudioPlayer("sfx_wing"))
        diedSound = createAudioPlayer("unbelievable")
        
    }
    
    func createScene() {
        
        pause = SKSpriteNode(imageNamed: "pause")
        pause.size = CGSize(width: 30, height: 30)
        pause.position = CGPoint(x: 20, y: frame.height - 20)
        pause.zPosition = 3
        addChild(pause)
        
        play = SKLabelNode()
        play.text = "Play"
        play.fontName = "AvenirNext-Bold";
        play.fontColor = SKColor.greenColor()
        play.fontSize = 35
        play.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
        play.zPosition = 5
        play.hidden = true
        addChild(play)
        
        back = SKLabelNode()
        back.text = "Back"
        back.fontName = "AvenirNext-Bold";
        back.fontColor = SKColor.blueColor()
        back.fontSize = 35
        back.position = CGPoint(x: frame.width / 2, y: frame.height / 2 - play.frame.height - 25)
        back.zPosition = 5
        back.hidden = true
        addChild(back)
        
        bird = SKSpriteNode(imageNamed: nominee)
        bird.setScale(0.08)
        bird.position = CGPoint(x: frame.width / 2 - bird.frame.width, y: frame.height / 2)
        bird.physicsBody = SKPhysicsBody(rectangleOfSize: bird.size)
        bird.physicsBody?.affectedByGravity = true
        bird.physicsBody?.dynamic = false
        bird.physicsBody?.categoryBitMask = PhysicsCategory.Bird
        bird.physicsBody?.collisionBitMask = PhysicsCategory.Ground | PhysicsCategory.Wall
        bird.physicsBody?.contactTestBitMask = PhysicsCategory.Ground | PhysicsCategory.Wall
        bird.zPosition = 4
        bird.name = "bird"
        self.addChild(bird)
        
        ground = SKSpriteNode(color: SKColor.greenColor(), size: CGSize(width: frame.width, height: bird.frame.height))
        ground.position = CGPoint(x: frame.width / 2, y: ground.frame.height - ground.frame.height / 2)
        ground.texture = SKTexture(imageNamed: "ground")
        ground.physicsBody = SKPhysicsBody(rectangleOfSize: ground.size)
        ground.physicsBody?.affectedByGravity = false
        ground.physicsBody?.dynamic = false

        ground.zPosition = 3
        self.addChild(ground)
        
        var backgroundName = "background"
        if nominee == "hillary" {
            backgroundName = "hillary_background"
        }
        
        background = SKSpriteNode(imageNamed: backgroundName)
        background.size = frame.size
        background.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
        background.zPosition = 1
        self.addChild(background)
        
        scoreLabel = SKLabelNode()
        scoreLabel.text = "0"
        scoreLabel.fontSize = 40
        scoreLabel.fontName = "AvenirNext-Bold";
        scoreLabel.position = CGPoint(x: frame.width / 2, y: frame.height - bird.frame.height)
        scoreLabel.zPosition = 6
        self.addChild(scoreLabel)
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if !gameOver {
            if !gameStarted {
                rounds += 1
                gameStarted = true
                bird.physicsBody?.dynamic = true
                let spawn = SKAction.runBlock {
                    self.createWalls()
                }
                
                let delay = SKAction.waitForDuration(1.5)
                let spawnDelay = SKAction.sequence([spawn, delay])
                let spawnDelayForever = SKAction.repeatActionForever(spawnDelay)
                self.runAction(spawnDelayForever)
                
                let distance = CGFloat(self.frame.width + bird.frame.width * 2)
                let movePipes = SKAction.moveByX(-distance, y: 0, duration: NSTimeInterval(2.5))
                let removePipes = SKAction.removeFromParent()
                moveAndRemove = SKAction.sequence([movePipes, removePipes])
                flappySounds[2].play()
                bird.physicsBody?.velocity = CGVectorMake(0, 0)
                bird.physicsBody?.applyImpulse(CGVectorMake(0, jumpImpulse))
            } else {
                if play.hidden {
                    var pauseTouched = false
                    for touch in touches {
                        if pause.containsPoint(touch.locationInNode(self)) {
                            pauseTouched = true
                        }
                    }
                    if pauseTouched {
                        play.hidden = false
                        back.hidden = false
                        pause.hidden = true
                        scene?.paused = true
                        
                    } else {
                        flappySounds[2].play()
                        bird.physicsBody?.velocity = CGVectorMake(0, 0)
                        bird.physicsBody?.applyImpulse(CGVectorMake(0, jumpImpulse))
                    }
                } else if pause.hidden {
                    var playTouched = false
                    var backTouched = false
                    for touch in touches {
                        if play.containsPoint(touch.locationInNode(self)) {
                            playTouched = true
                        } else if back.containsPoint(touch.locationInNode(self)) {
                            backTouched = true
                        }
                    }
                    if playTouched {
                        scene?.paused = false
                        play.hidden = true
                        back.hidden = true
                        pause.hidden = false
                    } else if backTouched {
                        goToMainMenu()
                    }
                }
            }
        } else {
            var backTouched = false
            var fbTouched = false
            var twitterTouched = false
            for touch in touches {
                if back.containsPoint(touch.locationInNode(self)) {
                    backTouched = true
                }
                if facebook.containsPoint(touch.locationInNode(self)) {
                    fbTouched = true
                }
                if twitter.containsPoint(touch.locationInNode(self)) {
                    twitterTouched = true
                }
            }
            
            if fbTouched {
                postToFacebook()
            } else if twitterTouched {
                postToTwitter()
            } else if backTouched {
                goToMainMenu()
            } else {
                let timeNow = NSDate()
                if (timeNow.timeIntervalSinceDate(timeOfDeath) > 0.2) {
                    gameOver = false
                    gameStarted = false
                    self.removeAllChildren()
                    createScene()
                    jumpImpulse = jumpAmount
                    score = 0
                }
            }
        }
    }
    
    func createWalls() {
        wallPair = SKNode()
        wallPair.zPosition = 2
        
        let topWallHeight = CGFloat.random(min: bird.frame.height, max: frame.height - (bird.frame.height * 3) - ground.frame.height)
        var name = "pipe"
        if nominee == "hillary" {
            name = "pipe2"
        }
        let wallWidth = bird.frame.width * 1.5
        let topWall = SKSpriteNode(imageNamed: name)
        topWall.size = CGSize(width: wallWidth, height: topWallHeight)
        topWall.position = CGPoint(x: frame.width + topWall.frame.width / 2, y: frame.height - topWallHeight / 2)
        let bottomWall = SKSpriteNode(imageNamed: name)
        bottomWall.size = CGSize(width: wallWidth, height: frame.height - ground.frame.height - topWallHeight - (bird.frame.height * 1.85))
        bottomWall.position = CGPoint(x: frame.width + bottomWall.frame.width / 2, y: bottomWall.frame.height / 2)
        let walls = [bottomWall, topWall]
        for wall in walls {
            wall.physicsBody = SKPhysicsBody(rectangleOfSize: wall.size)
            wall.physicsBody?.categoryBitMask = PhysicsCategory.Wall
            wall.physicsBody?.collisionBitMask = PhysicsCategory.Bird
            wall.physicsBody?.contactTestBitMask = PhysicsCategory.Bird
            wall.physicsBody?.dynamic = false
            wall.physicsBody?.affectedByGravity = false
            wallPair.addChild(wall)
        }
        
        var iconname = "rep_icon"
        if nominee == "hillary" {
            iconname = "dem_icon"
        }
        let scoreNode = SKSpriteNode(imageNamed: iconname)
        scoreNode.setScale(0.15)
        scoreNode.position = CGPoint(x: self.frame.width + topWall.frame.width / 2, y: frame.height - topWallHeight - bird.frame.height * 1.5)
        scoreNode.physicsBody = SKPhysicsBody(rectangleOfSize: scoreNode.size)
        scoreNode.physicsBody?.affectedByGravity = false
        scoreNode.physicsBody?.dynamic = false
        scoreNode.physicsBody?.categoryBitMask = PhysicsCategory.Score
        scoreNode.physicsBody?.collisionBitMask = 0
        scoreNode.physicsBody?.contactTestBitMask = PhysicsCategory.Bird
        wallPair.addChild(scoreNode)
        wallPair.name = "wallPair"
        wallPair.runAction(moveAndRemove)
        addChild(wallPair)
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB
        
        // GAME OVER
        if firstBody.categoryBitMask == PhysicsCategory.Bird && secondBody.categoryBitMask == PhysicsCategory.Wall || firstBody.categoryBitMask == PhysicsCategory.Wall && secondBody.categoryBitMask == PhysicsCategory.Bird {

            
            if gameOver == false {
                bird.physicsBody?.friction = 0.5
                bird.physicsBody?.restitution = 0.2
                bird.physicsBody?.applyImpulse(CGVector(dx: CGFloat.random(min: 2, max: 6), dy: CGFloat.random(min: 0.2, max: 3)))
                flappySounds[1].play()
                gameOver = true
                for child in children {
                    if child.name == "wallPair" {
                        child.removeAllActions()
                    }
                }
                self.removeAllActions()
                createGameOverLabel()
                back.hidden = false
                timeOfDeath = NSDate()
                
                if nominee == "donald" {
                    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), {
                        self.diedSound.play()
                    })
                }
                
                if scoreObject != nil {
                    let totalScore = scoreObject["score"] as! Int
                    scoreObject["score"] = totalScore + self.score
                    scoreObject.saveInBackgroundWithBlock({ (success, error) in
                        if error == nil {
                            print("score saved")
                        } else {
                            print(error)
                        }
                    })
                }
                
                let userDefaults = NSUserDefaults.standardUserDefaults()
                let num = userDefaults.integerForKey("highscore")
                if score > num {
                    print("a - \(score) \(num)")
                    userDefaults.setInteger(score, forKey: "highscore")
                    createHighScoreLabel(score, newScore: true)
                } else {
                    print("b - \(score) \(num)")
                    createHighScoreLabel(num, newScore: false)
                }
                jumpImpulse = 0
                for sound in nomineeSounds {
                    if sound.playing {
                        sound.stop()
                    }
                }
                if rounds % 5 == 0 {
                    if interstitial.isReady {
                        interstitial.presentFromRootViewController(self.root)
                    }
                }
            }
            
            createSocialButtons()
        
        }
        
        if firstBody.categoryBitMask == PhysicsCategory.Bird && secondBody.categoryBitMask == PhysicsCategory.Score || firstBody.categoryBitMask == PhysicsCategory.Score && secondBody.categoryBitMask == PhysicsCategory.Bird {
            if firstBody.categoryBitMask == PhysicsCategory.Score {
                firstBody.node?.removeFromParent()
            } else {
                secondBody.node?.removeFromParent()
            }
            score += 1
            scoreLabel.text = "\(score)"
            if score > 0 &&  score % playIndex == 0 {
                playSound()
                playIndex = Int(CGFloat.random(min: 4, max: 10))
            }
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), {
                for sound in self.nomineeSounds {
                    if sound.playing {
                        sound.stop()
                    }
                }
                self.flappySounds[0].play()
            })
        }
    }
    
    func createGameOverLabel() {
        let gameOverLabel = SKLabelNode()
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.fontSize = 50
        gameOverLabel.fontColor = SKColor.redColor()
        gameOverLabel.position = CGPoint(x: frame.width / 2, y: frame.height / 2 + 25)
        gameOverLabel.zPosition = 5
        gameOverLabel.fontName = "AvenirNext-Bold";
        addChild(gameOverLabel)
    }
    
    func createHighScoreLabel(highscore: Int, newScore: Bool) {
        let highScoreLabel = SKLabelNode()
        highScoreLabel.text = "Highscore: \(highscore)"
        highScoreLabel.fontSize = 28
        highScoreLabel.fontColor = SKColor.whiteColor()
        highScoreLabel.position = CGPoint(x: frame.width / 2, y: frame.height / 2 - 15)
        highScoreLabel.zPosition = 5
        highScoreLabel.fontName = "AvenirNext-Bold";
        if newScore {
            let wait = SKAction.waitForDuration(0.5)
            let on = SKAction.runBlock {
                highScoreLabel.hidden = false
            }
            let off = SKAction.runBlock {
                highScoreLabel.hidden = true
            }
            highScoreLabel.runAction(SKAction.repeatActionForever(SKAction.sequence([on, wait, off, wait])))
        }
        addChild(highScoreLabel)
    }
    
    func goToMainMenu() {
        let skView = view!
        let menu = MenuScene(size: skView.bounds.size)
        skView.ignoresSiblingOrder = true
        skView.multipleTouchEnabled = true
        menu.scaleMode = .AspectFill
        menu.root = self.root
        skView.presentScene(menu)
    }
    
    func playSound() {
        let clipIndex = Int(CGFloat.random(min: 0, max: CGFloat(numSounds)))
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            self.nomineeSounds[clipIndex].play()
        })
    }
    
    func createAudioPlayer(file: String) -> AVAudioPlayer {
        let sound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource(file, ofType: "mp3")!)
        let audioPlayer = try! AVAudioPlayer(contentsOfURL: sound)
        audioPlayer.prepareToPlay()
        audioPlayer.volume = 0.5
        return audioPlayer
    }
    
    func createAndLoadInterstitial() -> GADInterstitial {
        let interstitial = GADInterstitial(adUnitID: "ca-app-pub-3940256099942544/4411468910")
        interstitial.delegate = self
        let request = GADRequest()
//        request.testDevices = [kGADSimulatorID, "028af437e870b654f8f26c0d88a946ed"]
        interstitial.loadRequest(request)
        return interstitial
    }
    
    func createSocialButtons() {
        facebook = SKSpriteNode(imageNamed: "facebook")
        facebook.size = CGSize(width: 35, height: 35)
        facebook.position = CGPoint(x: frame.width / 2 - 35, y: ground.frame.height + 22)
        facebook.zPosition = 5
        addChild(facebook)
        
        twitter = SKSpriteNode(imageNamed: "twitter")
        twitter.size = CGSize(width: 35, height: 35)
        twitter.position = CGPoint(x: frame.width / 2 + 35, y: ground.frame.height + 22)
        twitter.zPosition = 5
        addChild(twitter)
    }
    
    func interstitialDidDismissScreen(ad: GADInterstitial!) {
        interstitial = createAndLoadInterstitial()
    }
    
    func postToFacebook() {
        let shareToFacebook = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
//        let image = UIImage(named: "donald")
//        shareToFacebook.addImage(image)
        shareToFacebook.setInitialText("I just got \(score) with Donald Trump on Flappy President!")
//        let url = NSURL(fileURLWithPath: "http://nba.com")
//        shareToFacebook.addURL(url)
        root.presentViewController(shareToFacebook, animated: false, completion: nil)
    }
    
    func postToTwitter() {
        let shareToTwitter = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
        root.presentViewController(shareToTwitter, animated: false, completion: nil)
    }
    
    
}
