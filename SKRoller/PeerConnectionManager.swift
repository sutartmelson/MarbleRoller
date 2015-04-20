//
//  PeerConnectionManager.swift
//  SKRoller
//
//  Created by Stuart Nelson on 4/14/15.
//  Copyright (c) 2015 Stuart Nelson. All rights reserved.
//

import Foundation
import MultipeerConnectivity

enum Event : String
{
    case StartGame  = "StartGame"
    case Velocity   = "Velocity"
    case EndGame    = "EndGame"
}

struct PeerConnectionManager
{
    private static var peers : [MCPeerID]
        {
        return session?.connectedPeers as! [MCPeerID]? ?? []
    }
    
    static func start()
    {
        transceive("SKRoller")
    }
    
    static func OnConnect(run : PeerBlock?)
    {
        onConnect = run
    }
    
    static func OnDisconnect(run : PeerBlock?)
    {
        onDisconnect = run
    }
    
    static func SendEvent(event : Event, object : AnyObject?)
    {
        sendEvent(event.rawValue, object: object, toPeers: peers)
    }
    
    static func onEvent(event: Event, run: ObjectBlock?) {
        if let run = run {
            eventBlocks[event.rawValue] = run
        } else {
            eventBlocks.removeValueForKey(event.rawValue)
        }
    }
}