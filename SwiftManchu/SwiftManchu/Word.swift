//
//  Entry.swift
//  SwiftManchu
//
//  Created by Tian Zheng on 2/27/15.
//  Copyright (c) 2015 Tian Zheng. All rights reserved.
//

import Foundation

struct Word {
    let id : Int
    let mnc : String
    let chn : String
    let eng : String
    let attr : String
    //let sentences : [Sentence]
}

struct Sentence {
    let sentid : Int
    let sentmnc : String
    let sentchn : String
    let senteng : String
    let wordid : Int
}