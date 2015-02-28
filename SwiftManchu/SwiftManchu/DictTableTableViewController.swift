//
//  DictTableTableViewController.swift
//  SwiftManchu
//
//  Created by Tian Zheng on 2/27/15.
//  Copyright (c) 2015 Tian Zheng. All rights reserved.
//

import UIKit
import SQLite

class DictTableTableViewController : UITableViewController, UISearchBarDelegate, UISearchDisplayDelegate {
    var candies = [Word]()
    var filteredCandies = [Word]()

    override func viewDidLoad() {
        super.viewDidLoad()

        //self.candies = [Word(mnc:"manchu", chn:"满洲")]
        self.candies = readAllWords()
        
        // Reload the table
        self.tableView.reloadData()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    /*
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
     // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 0
    }
    */
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.searchDisplayController!.searchResultsTableView {
            return self.filteredCandies.count
        } else {
            return self.candies.count
        }
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //ask for a reusable cell from the tableview, the tableview will create a new one if it doesn't have any
        let cell = self.tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell
        
        var word : Word
        // Check to see whether the normal table or search results table is being displayed and set the Candy object from the appropriate array
        if tableView == self.searchDisplayController!.searchResultsTableView {
            word = filteredCandies[indexPath.row]
        } else {
            word = candies[indexPath.row]
        }
        
        // Configure the cell
        cell.textLabel!.text = word.mnc + " " + word.chn
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        
        return cell
    }
    func filterContentForSearchText(searchText: String) {
        // Filter the array using the filter method
        self.filteredCandies = self.candies.filter({( word: Word) -> Bool in
            let stringMatch = word.mnc.rangeOfString(searchText)
            return (stringMatch != nil)
        })
    }
    
    func searchDisplayController(controller: UISearchDisplayController!, shouldReloadTableForSearchString searchString: String!) -> Bool {
        self.filterContentForSearchText(searchString)
        return true
    }
    
    func searchDisplayController(controller: UISearchDisplayController!, shouldReloadTableForSearchScope searchOption: Int) -> Bool {
        self.filterContentForSearchText(self.searchDisplayController!.searchBar.text)
        return true
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("wordDetail", sender: tableView)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "wordDetail" {
            let wordDetailViewController = segue.destinationViewController as UIViewController
            if sender as UITableView == self.searchDisplayController!.searchResultsTableView {
                let indexPath = self.searchDisplayController!.searchResultsTableView.indexPathForSelectedRow()!
                let destinationTitle = self.filteredCandies[indexPath.row].mnc
                wordDetailViewController.title = destinationTitle
            } else {
                let indexPath = self.tableView.indexPathForSelectedRow()!
                let destinationTitle = self.candies[indexPath.row].mnc
                wordDetailViewController.title = destinationTitle
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
            let tempWord = Word(id:word[id], mnc:word[mnc], chn:word[chn], eng:word[eng], attr:word[attr])
            result.append(tempWord)
        }
        
        return result
    }
    
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

}
