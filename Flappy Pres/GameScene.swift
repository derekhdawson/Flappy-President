
import SpriteKit
import AVFoundation
import GoogleMobileAds
import Social



class GameScene: SKScene, SKPhysicsContactDelegate, GADInterstitialDelegate {
    
    var jumpAmount:CGFloat!
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
    var numNomineeSounds = 0
    var numNomineeDeathSounds = 0
    
    var scoreObject: PFObject!
    var playIndex = 0
    
    var nomineeSounds: [AVAudioPlayer] = []
    var nomineeDeathSound: [AVAudioPlayer] = []
    var flappySounds: [AVAudioPlayer] = []
    
    var interstitial: GADInterstitial!
    
    var root: UIViewController!
    
    var facebook: SKSpriteNode!
    var twitter: SKSpriteNode!

    
    override func didMoveToView(view: SKView) {
        
        jumpAmount = 225
        interstitial = createAndLoadInterstitial()
        
        physicsWorld.contactDelegate = self
//        view.showsPhysics = true
        
        
        createScene()
        jumpImpulse = jumpAmount
        
        
        if Reachability.isConnectedToNetwork() {
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
        }
        
        if nominee == "donald" {
            numNomineeSounds = 8
            numNomineeDeathSounds = 4
        } else {
            numNomineeSounds = 6
            numNomineeDeathSounds = 4
        }
        
        for i in 1...numNomineeSounds {
            let soundFile = "\(nominee)_sound\(i)"
            let sound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("\(soundFile)", ofType: "mp3")!)
            let audioPlayer = try! AVAudioPlayer(contentsOfURL: sound)
            audioPlayer.prepareToPlay()
            nomineeSounds.append(audioPlayer)
        }
        
        
        if numNomineeDeathSounds > 0 {
            for i in 1...numNomineeDeathSounds {
                let soundFile = "\(nominee)_sound_death\(i)"
                let sound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("\(soundFile)", ofType: "mp3")!)
                let audioPlayer = try! AVAudioPlayer(contentsOfURL: sound)
                audioPlayer.prepareToPlay()
                nomineeDeathSound.append(audioPlayer)
            }
        }
        
        
        
        playIndex = Int(CGFloat.random(min: 4, max: 10))
        
        flappySounds.append(createAudioPlayer("coin"))
        flappySounds.append(createAudioPlayer("hit"))
        flappySounds.append(createAudioPlayer("sfx_wing"))
        
        
    }
    
    func createScene() {
        
        pause = SKSpriteNode(imageNamed: "pause")
        pause.size = CGSize(width: 32, height: 32)
        pause.position = CGPoint(x: 22, y: frame.height - 22)
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
        
        let texture = SKTexture(imageNamed: "small_\(nominee)")
        texture.filteringMode = .Nearest
        bird = SKSpriteNode(texture: texture)
        
        bird.position = CGPoint(x: frame.width / 2 - bird.frame.width, y: frame.height / 2)
        bird.physicsBody = SKPhysicsBody(rectangleOfSize: bird.size)
        bird.size = CGSize(width: frame.width * 0.1203125, height: (frame.width * 0.1203125) * 1.2987012987)
        bird.physicsBody?.affectedByGravity = true
        bird.physicsBody?.dynamic = false
        bird.physicsBody?.categoryBitMask = PhysicsCategory.Bird
        bird.physicsBody?.collisionBitMask = PhysicsCategory.Ground | PhysicsCategory.Wall
        bird.physicsBody?.contactTestBitMask = PhysicsCategory.Ground | PhysicsCategory.Wall
        bird.physicsBody?.mass = 0.5
        bird.zPosition = 4
        bird.name = "bird"
        self.addChild(bird)

        ground = SKSpriteNode()
        ground.size = CGSize(width: frame.width, height: bird.frame.height)
        ground.position = CGPoint(x: frame.width / 2, y: ground.frame.height - ground.frame.height / 2)
        ground.physicsBody = SKPhysicsBody(rectangleOfSize: ground.size)
        ground.physicsBody?.affectedByGravity = false
        ground.physicsBody?.dynamic = false

        ground.zPosition = 3
        self.addChild(ground)
        
        background = SKSpriteNode(imageNamed: "\(nominee)_background")
        background.size = frame.size
        background.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
        background.zPosition = 1
        self.addChild(background)
        
        scoreLabel = SKLabelNode()
        scoreLabel.text = "0"
        scoreLabel.fontSize = 40
        scoreLabel.fontName = "AvenirNext-Bold";
        scoreLabel.position = CGPoint(x: frame.width / 2, y: frame.height - bird.frame.height - 5)
        scoreLabel.zPosition = 6
        self.addChild(scoreLabel)
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if !gameOver {
            if !gameStarted {
                GameViewController.rounds += 1
                gameStarted = true
                bird.physicsBody?.dynamic = true
                let spawn = SKAction.runBlock {
                    self.createWalls()
                }
                
                let delay = SKAction.waitForDuration(1.4)
                let spawnDelay = SKAction.sequence([spawn, delay])
                let spawnDelayForever = SKAction.repeatActionForever(spawnDelay)
                self.runAction(spawnDelayForever)
                
                let distance = CGFloat(self.frame.width + bird.frame.width * 2)
                let movePipes = SKAction.moveByX(-distance, y: 0, duration: NSTimeInterval(2.5))
                let removePipes = SKAction.removeFromParent()
                moveAndRemove = SKAction.sequence([movePipes, removePipes])
                playFlappyJumpSound()
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
                        playFlappyJumpSound()
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
        let wallWidth = bird.frame.width * 1.5
        let topWall = SKSpriteNode()
        topWall.size = CGSize(width: wallWidth, height: topWallHeight)
        topWall.position = CGPoint(x: frame.width + topWall.frame.width / 2, y: frame.height - topWallHeight / 2)
        
        topWall.texture = SKTexture(rect: CGRect(x: 0, y: 0, width: 1, height: topWall.size.height / frame.size.height), inTexture: SKTexture(imageNamed: "\(nominee)_pipe"))
        
        
        let bottomWall = SKSpriteNode()
        bottomWall.size = CGSize(width: wallWidth, height: frame.height - ground.frame.height - topWallHeight - (bird.frame.height * 1.85))
        bottomWall.position = CGPoint(x: frame.width + bottomWall.frame.width / 2, y: bottomWall.frame.height / 2)
        
        bottomWall.texture = SKTexture(rect: CGRect(x: 0, y: 0, width: 1, height: bottomWall.size.height / frame.size.height), inTexture: SKTexture(imageNamed: "\(nominee)_pipe"))
        
        
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
        
        
        if firstBody.categoryBitMask == PhysicsCategory.Bird && secondBody.categoryBitMask == PhysicsCategory.Score || firstBody.categoryBitMask == PhysicsCategory.Score && secondBody.categoryBitMask == PhysicsCategory.Bird {
            if firstBody.categoryBitMask == PhysicsCategory.Score {
                firstBody.node?.removeFromParent()
            } else {
                secondBody.node?.removeFromParent()
            }
            score += 1
            scoreLabel.text = "\(score)"
            playFlappyCoinSound()
            if score > 0 &&  score % playIndex == 0 {
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), {
                    for sound in self.nomineeSounds {
                        if sound.playing {
                            sound.stop()
                            sound.currentTime = 0
                        }
                    }
                    let clipIndex = Int(CGFloat.random(min: 0, max: CGFloat(self.numNomineeSounds)))
                    self.nomineeSounds[clipIndex].play()
                })
            }
        }
        
        // GAME OVER
        if firstBody.categoryBitMask == PhysicsCategory.Bird && secondBody.categoryBitMask == PhysicsCategory.Wall || firstBody.categoryBitMask == PhysicsCategory.Wall && secondBody.categoryBitMask == PhysicsCategory.Bird {
            
            
            if gameOver == false {
                createSocialButtons()
                bird.physicsBody?.friction = 0.5
                bird.physicsBody?.restitution = 0.2
//                bird.physicsBody?.applyImpulse(CGVector(dx: CGFloat.random(min: 2, max: 6), dy: CGFloat.random(min: 0.2, max: 3)))
                playFlappyDiedSound()
                let dieSoundIndex = Int(CGFloat.random(min: 0, max: CGFloat(numNomineeDeathSounds)))
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), {
                    if self.numNomineeDeathSounds > 0 {
                        self.nomineeDeathSound[dieSoundIndex].play()
                    }
                })
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
                
                
                
                if Reachability.isConnectedToNetwork() {
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
                    let user = PFUser.currentUser()
                    if user != nil {
                        let userScore = PFObject(className: "UserScores")
                        userScore["score"] = self.score
                        userScore["nominee"] = self.nominee
                        userScore.saveInBackgroundWithBlock({ (success, error) in
                            if error == nil {
                                let userScores = user!.relationForKey("userScores")
                                userScores.addObject(userScore)
                                user!.saveInBackground()
                                print("saved user score")
                            } else {
                                print(error)
                            }
                        })
                        
                    }
                    
                }
                
                let userDefaults = NSUserDefaults.standardUserDefaults()
                let num = userDefaults.integerForKey("highscore")
                if score > num {
                    userDefaults.setInteger(score, forKey: "highscore")
                    createHighScoreLabel(score, newScore: true)
                } else {
                    createHighScoreLabel(num, newScore: false)
                }
                jumpImpulse = 0
                for sound in nomineeSounds {
                    if sound.playing {
                        sound.stop()
                    }
                }
                if GameViewController.rounds % 10 == 0 {
                    if interstitial.isReady {
                        interstitial.presentFromRootViewController(self.root)
                    }
                }
            }
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
        highScoreLabel.fontSize = 29
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
    
    func createAudioPlayer(file: String) -> AVAudioPlayer {
        let sound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource(file, ofType: "mp3")!)
        let audioPlayer = try! AVAudioPlayer(contentsOfURL: sound)
        audioPlayer.prepareToPlay()
        audioPlayer.volume = 0.5
        return audioPlayer
    }
    
    func createAndLoadInterstitial() -> GADInterstitial {
        let interstitial = GADInterstitial(adUnitID: "ca-app-pub-5214892420848108/8132471670")
        interstitial.delegate = self
        let request = GADRequest()
        interstitial.loadRequest(request)
        return interstitial
    }
    
    func createSocialButtons() {
        
        let socialSize: CGFloat = 40
        facebook = SKSpriteNode(imageNamed: "facebook")
        facebook.size = CGSize(width: socialSize, height: socialSize)
        facebook.position = CGPoint(x: frame.width / 2 - socialSize, y: ground.frame.height + 25)
        facebook.zPosition = 5
        addChild(facebook)
        
        twitter = SKSpriteNode(imageNamed: "twitter")
        twitter.size = CGSize(width: socialSize, height: socialSize)
        twitter.position = CGPoint(x: frame.width / 2 + socialSize, y: ground.frame.height + 25)
        twitter.zPosition = 5
        addChild(twitter)
    }
    
    func interstitialDidDismissScreen(ad: GADInterstitial!) {
        interstitial = createAndLoadInterstitial()
    }
    
    func postToFacebook() { //                https://itunes.apple.com/us/app/flappy-pres/id1139952569?ls=1&mt=8
        let shareToFacebook = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
        shareToFacebook.addURL(NSURL(string: "https://itunes.apple.com/us/app/flappy-pres/id1139952569?ls=1&mt=8"))
        root.presentViewController(shareToFacebook, animated: false, completion: nil)
    }
    
    func postToTwitter() {
        let shareToTwitter = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
        shareToTwitter.addURL(NSURL(string: "https://itunes.apple.com/us/app/flappy-pres/id1139952569?ls=1&mt=8"))
        root.presentViewController(shareToTwitter, animated: false, completion: nil)
    }
    
    func playFlappyCoinSound() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), {
            self.flappySounds[0].play()
        })
    }
    
    func playFlappyDiedSound() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), {
            self.flappySounds[1].play()
        })
    }
    
    func playFlappyJumpSound() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), {
            self.flappySounds[2].play()
        })
    }
    
    
    func cropToBounds(image: UIImage, width: Double, height: Double) -> UIImage {
        
        let contextImage: UIImage = UIImage(CGImage: image.CGImage!)
        
        let contextSize: CGSize = contextImage.size
        
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgwidth: CGFloat = CGFloat(width)
        var cgheight: CGFloat = CGFloat(height)
        
        // See what size is longer and create the center off of that
        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            cgwidth = contextSize.height
            cgheight = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            cgwidth = contextSize.width
            cgheight = contextSize.width
        }
        
        let rect: CGRect = CGRectMake(posX, posY, cgwidth, cgheight)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImageRef = CGImageCreateWithImageInRect(contextImage.CGImage, rect)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let image: UIImage = UIImage(CGImage: imageRef, scale: image.scale, orientation: image.imageOrientation)
        
        return image
    }
    
    
}
