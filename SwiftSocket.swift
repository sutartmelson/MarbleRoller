//
//  swiftSocket.swift
//  SocketConnection
//
//  Created by Stuart Nelson on 4/9/15.
//  Copyright (c) 2015 Stuart Nelson. All rights reserved.
//

import Foundation


class SwiftSocket
{
    var address = "lab1-8.eng.utah.edu"
    var host = 2115
    var client : TCPClient
    var readMore : Bool = true
    init()
    {
        client = TCPClient(addr: address, port : host)
        client.connect(timeout: 10)
    }
    func Read(Callback : (Success : Bool, Message : String?) -> Void)
    {
        let priority = DISPATCH_QUEUE_PRIORITY_HIGH
        dispatch_async(dispatch_get_global_queue(priority, 0))
        {
            var receivingString : String = ""
            // do some task
            while self.readMore
            {
                var b = self.client.read(32)
                if b != nil
                {
            
                    var s = NSString(bytes: b!, length: b!.count, encoding: NSASCIIStringEncoding)
                    if s == nil
                    {
                        dispatch_async(dispatch_get_main_queue())
                        {
                            Callback(Success: false, Message: nil)
                        }
                        return
                    }
            
                    var str : String = String(s!)
//            println(str)
                    for char in str
                    {
                        if char == "\n"
                        {
                            Callback(Success: true, Message: receivingString)
                            receivingString = ""
                        }
                        else
                        {
                            if char != " "
                            {
                                receivingString.append(char)
                            }
                        }
                    }
                }
            }
        }
        
    }
    func Send(Message : String)
    {
        var b = client.send(str: Message)
        if !b.0
        {
            //error
        }
    }
    
}