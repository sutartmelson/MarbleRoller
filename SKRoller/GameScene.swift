//
//  GameScene.swift
//  SKRoller
//
//  Created by Stuart Nelson on 4/11/15.
//  Copyright (c) 2015 Stuart Nelson. All rights reserved.
//

import SpriteKit
import CoreMotion
import MultipeerConnectivity

enum CollisionTypes : UInt32
{
    case Ball = 1
    case Wall = 2
    case Star = 4
    case BlackHole = 8
}

class GameScene: SKScene, SKPhysicsContactDelegate
{
    var ball          : SKSpriteNode = SKSpriteNode()
    var motionManager : CMMotionManager = CMMotionManager()
    
    var otherCurrentForce : CGVector?
    var currentPoint    : CGPoint   = CGPointMake(0.0, 0.0)
    var listening       : Bool      = true
    var lock            : NSLock    = NSLock()
    var dt              : Double    = 0.04
    var currectXV       : Double    = 0
    var currentYV       : Double    = 0
    var con             : SwiftSocket = SwiftSocket()
    var k1              : Double    = 1000
    var k2              : Double    = 0.0001
    var otherBall       : SKShapeNode?
    var wallMask        : UInt32    = 1
    var ballMask        : UInt32    = 2
    var setupOtherFlag  : Bool      = false
    //var score           : Int
    private var sent    : Bool      = false
    private var heightDiff      : CGFloat?
    private var widthDiff       : CGFloat?
    private var blockH  : CGFloat   = 32
    private var blockW  : CGFloat   = 18
    
    
//    func Callback(Success: Bool, Message : String?)
//    {
//        lock.lock()
//        
//        if Success
//        {
//            if !setupOtherFlag
//            {
////                println("CALLBACK")
//                otherBall = createBall()
//                otherBall?.fillColor = SKColor.redColor()
//                setupOtherFlag = true
//                addChild(otherBall!)
//            }
//            var sArray = Message!.componentsSeparatedByString(",")
//            if sArray.count == 2
//            {
//                var x = (sArray[0] as NSString).floatValue
//                var y = (sArray[1] as NSString).floatValue
//                otherBall?.position.x = CGFloat(x)
//                otherBall?.position.y = CGFloat(y)
//                
////                otherBall?.physicsBody?.applyForce(CGVector(dx: CGFloat(x), dy: CGFloat(y)))
//                //                otherPoints.append(CGPointMake(CGFloat(x), CGFloat(y)))
//                dispatch_async(dispatch_get_main_queue(),
//                    {
//                        //self.setNeedsDisplay()
//                    }
//                )
//            }
//        }
//        lock.unlock()
//    }
    
//    func onVelocityReceived(peerID: MCPeerID, object: AnyObject?)
//    {
//        if object != nil
//        {
//            var s : String = object as! String
//            lock.lock()
//            
//            if !setupOtherFlag
//            {
//                println("onVelocityReceived")
//                otherBall = createBall()
//                otherBall?.fillColor = SKColor.redColor()
//                setupOtherFlag = true
//                addChild(otherBall!)
//            }
//            var sArray = s.componentsSeparatedByString(",")
//            if sArray.count == 2
//            {
//                var x = CGFloat((sArray[0] as NSString).floatValue)
//                var y = CGFloat((sArray[1] as NSString).floatValue)
//                var point : CGPoint = CGPointMake(x * frame.width, y * frame.height)
//                
//
//                var action : SKAction = SKAction.moveTo(point, duration: dt*2)
//                otherBall?.runAction(action)
////                otherBall?.position.x = CGFloat(x)
////                otherBall?.position.y = CGFloat(y)
//                
//                //otherBall?.physicsBody?.applyForce(CGVector(dx: CGFloat(x), dy: CGFloat(y)))
//                dispatch_async(dispatch_get_main_queue(),
//                    {
//                        //self.setNeedsDisplay()
//                    })
//            }
//            lock.unlock()
//        }
//    }
    
    func onStartGame(myPeerID: MCPeerID, peerID: MCPeerID)
    {
        println("GAMESTARTED")
    }
    
    func onDisconnect(myPeerID: MCPeerID, peerID: MCPeerID)
    {
        PeerConnectionManager.start()
        otherBall?.removeFromParent()
        setupOtherFlag = false
    }
    
    override init(size: CGSize)
    {
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func didMoveToView(view: SKView)
    {
        /* Setup your scene here */
        UIApplication.sharedApplication().idleTimerDisabled = true
        backgroundColor = UIColor.whiteColor()
        heightDiff  = frame.height/blockH
        widthDiff   = frame.width/blockW
        setupPeerConnection()
        setupMotion()
        currentPoint    = CGPointMake(self.frame.width/2, self.frame.height/2)
        physicsBody     = SKPhysicsBody(edgeLoopFromRect: self.frame)
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        physicsBody?.dynamic = false
        physicsBody?.categoryBitMask  = CollisionTypes.Wall.rawValue
        physicsBody?.collisionBitMask = CollisionTypes.Ball.rawValue
        physicsBody?.restitution = 0.5
        loadLevel(0)
        ball = createBall()
        addChild(ball)
    }
    
    private func setupMotion()
    {
        motionManager.accelerometerUpdateInterval   = dt
        motionManager.gyroUpdateInterval            = dt
        motionManager.deviceMotionUpdateInterval    = dt
        if motionManager.deviceMotionAvailable
        {
            motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.mainQueue(), withHandler : motionHandler)
        }
    }
    
    private func setupPeerConnection()
    {
        
        PeerConnectionManager.OnConnect(onStartGame)
        PeerConnectionManager.OnDisconnect(onDisconnect)
//        PeerConnectionManager.onEvent(Event.Velocity, run: onVelocityReceived)
        PeerConnectionManager.start()
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent)
    {
        
    }
   
    override func update(currentTime: CFTimeInterval)
    {
        /* Called before each frame is rendered */
    }
    
    func createBall() -> SKSpriteNode
    {
        var b = SKSpriteNode(imageNamed: "player")
        b.name         = "player"
        b.anchorPoint  = CGPointMake(0.5, 0.5)
        b.position     = currentPoint
        b.physicsBody  = SKPhysicsBody(circleOfRadius: b.size.width/2)
        b.physicsBody?.allowsRotation   = false
        b.physicsBody?.dynamic          = true
        b.physicsBody?.restitution      = 0.4
        b.physicsBody?.linearDamping    = 0.5
        b.physicsBody?.categoryBitMask  = CollisionTypes.Ball.rawValue
        b.physicsBody?.collisionBitMask = CollisionTypes.Wall.rawValue
        b.physicsBody?.contactTestBitMask = CollisionTypes.Ball.rawValue | CollisionTypes.Wall.rawValue | CollisionTypes.Star.rawValue | CollisionTypes.BlackHole.rawValue
        
        return b
        
    }
    
    private func loadLevel(level : Int)
    {
        var curHeight   = CGFloat(heightDiff!/2)
        var curWidth    = CGFloat(widthDiff!/2)
        if let levelPath = NSBundle.mainBundle().pathForResource("level\(level)", ofType: "txt")
        {
            if let levelString = NSString(contentsOfFile: levelPath, usedEncoding: nil, error: nil)
            {
                let lines = levelString.componentsSeparatedByString("\n") as! [String]
                
                for (row, line) in enumerate(reverse(lines))
                {
                    for (colomn, letter) in enumerate(line)
                    {
                        var curPoint : CGPoint = CGPointMake(curWidth, curHeight)
                        
                        if letter == "x"
                        {
                            //wall
                            makeWallAt(curPoint)
                        }
                        else if letter == "s"
                        {
                            //start ball here
                            currentPoint = CGPointMake(curWidth, curHeight)
                        }
                        else if letter == "t"
                        {
                            //star
                            makeStarAt(curPoint)
                        }
                        else if letter == "b"
                        {
                            //black hole
                            makeBlackHoleAt(curPoint)
                        }
                        else if letter == "f"
                        {
                            //finish
                            
                        }
                        //other possible conditions
                        curWidth += widthDiff!
                    }
                    curWidth = CGFloat(widthDiff!/2)
                    curHeight += heightDiff!
                }
            }
        }
    }
    
    private func makeWallAt(position : CGPoint)
    {
        var wall : SKSpriteNode = SKSpriteNode(color: UIColor.grayColor(), size: CGSize(width: widthDiff!, height: heightDiff!))
//        wall.anchorPoint = CGPointMake(0, 0)
        wall.name        = "wall"
        wall.position    = position
        wall.physicsBody = SKPhysicsBody(rectangleOfSize: wall.size)
        wall.physicsBody!.categoryBitMask = CollisionTypes.Wall.rawValue
        wall.physicsBody!.dynamic = false
        wall.physicsBody?.restitution = 0.5
        addChild(wall)
    }
    
    private func makeStarAt(position : CGPoint)
    {
        var star : SKSpriteNode = SKSpriteNode(imageNamed: "star")
        star.name        = "star"
        star.position    = position
        star.physicsBody = SKPhysicsBody(circleOfRadius: star.size.width/2)
        star.physicsBody!.categoryBitMask = CollisionTypes.Star.rawValue
        star.physicsBody!.collisionBitMask = CollisionTypes.Ball.rawValue
        star.physicsBody!.dynamic = false
        addChild(star)
        
    }
    
    private func makeBlackHoleAt(position : CGPoint)
    {
        var blackHole : SKSpriteNode = SKSpriteNode(imageNamed: "black hole")
        blackHole.name      = "blackHole"
        blackHole.position  = position
        blackHole.physicsBody = SKPhysicsBody(circleOfRadius: blackHole.size.width/2)
        blackHole.physicsBody!.categoryBitMask = CollisionTypes.BlackHole.rawValue
        blackHole.physicsBody!.collisionBitMask = CollisionTypes.Ball.rawValue
        blackHole.physicsBody!.dynamic = false
        addChild(blackHole)
    }
    
    private func makeFinishAt(position : CGPoint)
    {
        
    }
    
    func didBeginContact(contact: SKPhysicsContact)
    {
        if contact.bodyA.node == ball
        {
            PlayerCollisionWith(contact.bodyB.node!)
        }
        else if contact.bodyB.node == ball
        {
            PlayerCollisionWith(contact.bodyA.node!)
        }
    }
    
    func PlayerCollisionWith(node : SKNode)
    {
        if node.name == "star"
        {
            let scaleUp = SKAction.scaleBy(1.5, duration: 0.25)
            let scaleDown = SKAction.scaleBy(0.0001, duration: 0.25)
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([scaleUp, scaleDown, remove])
            
            node.runAction(sequence)
            //handle star collision
        }
        else if node.name == "blackHole"
        {
            ball.physicsBody!.dynamic = false
            let move = SKAction.moveTo(node.position, duration: 0.25)
            let scale = SKAction.scaleBy(0.0001, duration: 0.25)
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([move, scale, remove])
            
            ball.runAction(sequence, completion:
                {
                () -> Void in
                    self.ball = self.createBall()
                    self.ball.position = self.currentPoint
                    self.addChild(self.ball)
                }
            )

        }
        else if node.name == "finish"
        {
            //handle finish
        }
        
    }
    
    func motionHandler(motion : CMDeviceMotion!, error : NSError!)
    {
        
        var data = motion.attitude
        
        var ax = (k1 * sin(data.roll)) - (k2 * cos(data.roll))
        var ay = (k1 * sin(data.pitch)) - (k2 * cos(data.pitch))
        
        var vy = -(ay * dt)
        var vx = (ax * dt)
        
        currentYV += vy
        currectXV += vx
        
//        ball.physicsBody?.applyImpulse(CGVector(dx: CGFloat(vx), dy: CGFloat(vy)))
        
        ball.physicsBody?.applyForce(CGVector(dx: CGFloat(vx), dy: CGFloat(vy)))
        
//        // if x point is outside of bounds, bounce.
//        currentPoint.x += CGFloat(currectXV * dt)
//        if currentPoint.x > self.frame.width - ball.frame.width/2
//        {
//            currentPoint.x = self.frame.width - ball.frame.width/2
//            currectXV *= -0.75
//            currentPoint.x += CGFloat(currectXV * dt)
//        }
//        
//        if currentPoint.x < 0 + ball.frame.width/2
//        {
//            currentPoint.x = ball.frame.width/2
//            currectXV *= -0.75
//            currentPoint.x += CGFloat(currectXV * dt)
//        }
//        
//        
//        // if y point is outside of bounds, bounce.
//        currentPoint.y += CGFloat(currentYV * dt)
//        if currentPoint.y > self.frame.height - ball.frame.width/2
//        {
//            currentPoint.y = self.frame.height - ball.frame.width/2
//            currentYV *= -0.75
//            currentPoint.y += CGFloat(currentYV * dt)
//        }
//        
//        if currentPoint.y < 0 + ball.frame.width/2
//        {
//            currentPoint.y = ball.frame.width/2
//            currentYV *= -0.75
//            currentPoint.y += CGFloat(currentYV * dt)
//        }
//        
//        currentPoint.x = round(currentPoint.x * 100) / 100
//        currentPoint.y = round(currentPoint.y * 100) / 100
        if(!sent)
        {
        PeerConnectionManager.SendEvent(Event.Velocity, object: "\(((ball.position.x)/frame.width).description), \(((ball.position.y)/frame.height).description)")
//            PeerConnectionManager.SendEvent(Event.Velocity, object: "\(vx.description), \(vy.description)")
            //con.Send("\(ball.position.x.description), \(ball.position.y.description)\n")
        }
        sent = !sent
    }

    
}
