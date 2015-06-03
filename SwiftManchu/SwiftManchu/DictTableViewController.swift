//
//  DictTableTableViewController.swift
//  SwiftManchu
//
//  Created by Tian Zheng on 2/27/15.
//  Copyright (c) 2015 Tian Zheng. All rights reserved.
//

import UIKit
import SQLite

class DictTableViewController : UITableViewController, UISearchBarDelegate, UISearchDisplayDelegate {
    var words = [Word]()
    var filteredWords = [Word]()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.words = readAllWords()
        
        // Reload the table
        self.tableView.reloadData()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    /*
     // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 0
    }
    */
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.searchDisplayController!.searchResultsTableView {
            return self.filteredWords.count
        } else {
            return self.words.count
        }
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //ask for a reusable cell from the tableview, the tableview will create a new one if it doesn't have any
        let cell = self.tableView.dequeueReusableCellWithIdentifier("Cell") as! UITableViewCell
        
        var word : Word
        
        if tableView == self.searchDisplayController!.searchResultsTableView {
            word = filteredWords[indexPath.row]
        } else {
            word = words[indexPath.row]
        }
        
        // Configure the cell
        cell.textLabel!.text = word.mnc + " " + word.chn
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        
        return cell
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        self.filteredWords = self.words.filter({( word : Word) -> Bool in
            var mncMatch = word.mnc.rangeOfString(searchText)
            // Pay - only content, free for first version
            var chnMatch = word.chn.rangeOfString(searchText)
            var engMatch = word.eng.rangeOfString(searchText)
            return (mncMatch != nil) || (chnMatch != nil) || (engMatch != nil)
        })
    }
    
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchString searchString: String!) -> Bool {
        self.filterContentForSearchText(searchString)
        return true
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("wordDetail", sender: tableView)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "wordDetail" {
            let wordDetailViewController : DetailViewController = segue.destinationViewController as! DetailViewController
            if sender as! UITableView == self.searchDisplayController!.searchResultsTableView {
                let indexPath = self.searchDisplayController!.searchResultsTableView.indexPathForSelectedRow()!
                let wordId = self.filteredWords[indexPath.row].id
                let destinationTitle = self.filteredWords[indexPath.row].mnc
                let wordChn = self.filteredWords[indexPath.row].chn
                let wordEng = self.filteredWords[indexPath.row].eng
                let wordAttr = self.filteredWords[indexPath.row].attr
                wordDetailViewController.title = destinationTitle
                wordDetailViewController.mncText = destinationTitle
                wordDetailViewController.chnText = wordChn
                wordDetailViewController.engText = wordEng
                wordDetailViewController.attrText = wordAttr
                wordDetailViewController.wordid = wordId
            } else {
                let indexPath = self.tableView.indexPathForSelectedRow()!
                let wordId = self.words[indexPath.row].id
                let destinationTitle = self.words[indexPath.row].mnc
                let wordChn = self.words[indexPath.row].chn
                let wordEng = self.words[indexPath.row].eng
                let wordAttr = self.words[indexPath.row].attr
                wordDetailViewController.title = destinationTitle
                wordDetailViewController.mncText = destinationTitle
                wordDetailViewController.chnText = wordChn
                wordDetailViewController.engText = wordEng
                wordDetailViewController.attrText = wordAttr
                wordDetailViewController.wordid = wordId
            }
        }
    }
    
    func readAllWords() -> [Word] {
        var result : [Word]! = []
        
        let path = NSBundle.mainBundle().pathForResource("ManchuDict", ofType: "SQLite")!
        
        let db = Database(path, readonly: true)
        
        let words = db["Word"]
        let id = Expression<Int>("id")
        let mnc = Expression<String>("mnc")
        let chn = Expression<String>("chn")
        let eng = Expression<String>("eng")
        let attr = Expression<String>("attribute")
        
        for word in words {
            //var sents : [Sentence]! = []
            var wid = word[id]
            let tempWord = Word(id:word[id], mnc:word[mnc], chn:word[chn], eng:word[eng], attr:word[attr])
            
//            for sent in sentences.filter(wordid == wid) {
//                let tempSent = Sentence(sentid:sent[sentid], sentmnc:sent[sentmnc], sentchn:sent[sentchn], senteng:sent[senteng], wordid:sent[wordid])
//                sents.append(tempSent)
//            }

            result.append(tempWord)
        }
        
        return result
    }    

}
