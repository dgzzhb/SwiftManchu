//
//  DetailViewController.swift
//  SwiftManchu
//
//  Created by Tian Zheng on 2/27/15.
//  Copyright (c) 2015 Tian Zheng. All rights reserved.
//

import UIKit
import SQLite

class DetailViewController: UIViewController {

    @IBOutlet weak var mncLabel: UILabel!
    @IBOutlet weak var chnLabel: UILabel!
    @IBOutlet weak var engLabel: UILabel!
    @IBOutlet weak var attrLabel: UILabel!
    @IBOutlet weak var sentences: UITextView!
    
    var wordid = Int();
    var mncText = String();
    var chnText = String();
    var engText = String();
    var attrText = String();
    var sentText = String();
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        var sents : [Sentence]! = [] // Max 7 Sentence per Word
        sents = readSentences(wordid)
        for sent in sents {
            sentText += sent.sentmnc;
            sentText += "\n";
            sentText += sent.sentchn;
            sentText += "\n";
            sentText += sent.senteng;
            sentText += "\n";
            
        }
        
        mncLabel.text = mncText
        chnLabel.text = chnText
        engLabel.text = engText
        attrLabel.text = attrText
        sentences.text = sentText
        
    }

    func readSentences(wid : Int) -> [Sentence] {
        var result : [Sentence]! = []
        
        let path = NSBundle.mainBundle().pathForResource("ManchuDict", ofType: "SQLite")!
        
        let db = Database(path, readonly: true)
        
        let sentences = db["Sentence"]
        let sentid = Expression<Int>("sentid")
        let sentmnc = Expression<String>("sentmnc")
        let sentchn = Expression<String>("sentchn")
        let senteng = Expression<String>("senteng")
        let wordid = Expression<Int>("wordid")
        
        for sent in sentences.filter(wordid == wid) {
            let tempSent = Sentence(sentid:sent[sentid], sentmnc:sent[sentmnc], sentchn:sent[sentchn], senteng:sent[senteng], wordid:sent[wordid])
            result.append(tempSent)
        }
        return result
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
