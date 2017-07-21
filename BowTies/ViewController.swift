//
//  ViewController.swift
//  BowTies
//
//  Created by AlexS on 28/07/2016.
//  Copyright © 2016 AStevensProductions. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var timesWornLabel: UILabel!
    @IBOutlet weak var lastWornLabel: UILabel!
    @IBOutlet weak var favoriteLabel: UILabel!

    var managedContext: NSManagedObjectContext!
    var currentBowtie : Bowtie!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //check for data
        insertSampleData()
        
        let request = NSFetchRequest(entityName: "Bowtie")
        let firstTitle = segmentedControl.titleForSegmentAtIndex(0)
        
        request.predicate = NSPredicate(format: "searchKey == %@", firstTitle!)
        
        do {
            let results =
            try managedContext.executeFetchRequest(request) as! [Bowtie]
            currentBowtie = results.first
            populate(results.first!)
        } catch let error as NSError {
            print("Could not fetch , \(error), \(error.userInfo)")
        }
    }
   
    @IBAction func segmentedControl(sender: UISegmentedControl) {
        // Gets the searchKey from the segment and displays new bowtie
        let selectedValue = sender.titleForSegmentAtIndex(sender.selectedSegmentIndex)!
        let request = NSFetchRequest(entityName: "Bowtie")
        
        request.predicate = NSPredicate(format:"searchKey == %@",selectedValue)
        
        do {
            let results = try managedContext.executeFetchRequest(request) as! [Bowtie]
            currentBowtie = results.first
            populate(currentBowtie)
            
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    @IBAction func wear(sender: AnyObject) {
        // Increments and updates the display for timesWorn and lastWorn tie properties
        let times = currentBowtie.timesWorn!.integerValue
        currentBowtie.timesWorn = NSNumber(integer: (times + 1))
        
        currentBowtie.lastWorn = NSDate()
        do{
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save \(error), \(error.userInfo)")
        }
      populate(currentBowtie)
        
    }
    
    @IBAction func rate(sender: AnyObject) {
        // creates and shows prompt alert for value of rating
        let alert = UIAlertController(title: "Rate Tie", message: "Give this tie a rating", preferredStyle: .Alert)
        let  cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: {(action:UIAlertAction!) in })
        let saveAction = UIAlertAction(title: "Save", style: .Default, handler: {(action:UIAlertAction!) in
            let textField = alert.textFields![0] as UITextField
            self.updateRating(textField.text!)
        })
        
        alert.addTextFieldWithConfigurationHandler{(textfield : UITextField!) in textfield.keyboardType = .DecimalPad}
        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        alert.view.setNeedsLayout()
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func updateRating(rating:String) {
        //Updates the value of rating
        currentBowtie.rating = (rating as NSString).doubleValue
        
        do {
            try managedContext.save()
            populate(currentBowtie)
        } catch let error as NSError {
            print("Could not save to context \(error), \(error.userInfo)")
            if error.domain == NSCocoaErrorDomain &&
            (error.code == NSValidationNumberTooLargeError ||
                error.code == NSValidationNumberTooSmallError) {
                rate(currentBowtie)
            }
        }
    }
    
    func insertSampleData() {
        // create fetch to check for data
        let fetchRequest = NSFetchRequest(entityName: "Bowtie")
        fetchRequest.predicate = NSPredicate(format:  "searchKey != nil")
        let count = managedContext.countForFetchRequest(fetchRequest, error: nil)
        
        if count > 0 {return}
        // If no  data is in the data base then insert data  from plist so that there is results for the fetch request in ViewDidLoad else  return
        let path = NSBundle.mainBundle().pathForResource("SampleData", ofType: "plist")
        let dataArray = NSArray(contentsOfFile: path!)!
        
        for dict: AnyObject in dataArray {
            // create new bowtie object in managed content
            let entity = NSEntityDescription.entityForName("Bowtie", inManagedObjectContext: managedContext)
            let bowtie = Bowtie(entity: entity!, insertIntoManagedObjectContext: managedContext)
            let btDict = dict as! NSDictionary
            
            // read from dictionary to set up bowtie object
            bowtie.name = btDict["name"] as? String
            print(bowtie.name!)
            bowtie.searchKey = btDict["searchKey"] as? String
            bowtie.rating = btDict["rating"] as? NSNumber
            let tintColourDict = btDict["tintColour"] as! NSDictionary
            bowtie.tintColour = colourFromDict(tintColourDict)
            
            let imageName = btDict["imageName"] as? String
            print(imageName)
            if let image = UIImage(named: imageName!) {
             let photoData = UIImagePNGRepresentation(image)
                bowtie.photoData = photoData
            }
            
            bowtie.lastWorn = btDict["lastWorn"] as? NSDate
            bowtie.timesWorn = btDict["timesWorn"] as? NSNumber
            bowtie.isFavorite = btDict["isFavorite"] as? NSNumber
            
        }
    }
    
    func colourFromDict(dict:NSDictionary)-> UIColor {
        // create colour from rgb values in dictionary
        print(dict.count)
        let red = dict["red"] as! NSNumber
        let green = dict["green"] as! NSNumber
        let blue = dict["blue"] as! NSNumber
        
        let colour = UIColor(red: CGFloat(red)/255.0,
                             green: CGFloat(green)/255.0,
                             blue:  CGFloat(blue)/255.0,
                             alpha: 1)
        return colour
    }
    
    func populate(bowtie: Bowtie) {
        
        // Populate the UI elements with the new data
        if (bowtie.photoData != nil) {
       
            imageView.image = UIImage(data: bowtie.photoData!)
        }
        else {
            imageView.image = nil
        }
    
        nameLabel.text = bowtie.name
        ratingLabel.text = "Rating: \(bowtie.rating!.doubleValue)/5"
        
        
        timesWornLabel.text = "# times worn: \(bowtie.timesWorn!.integerValue)"
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .NoStyle
        
        lastWornLabel.text = "Last worn: " + dateFormatter.stringFromDate(bowtie.lastWorn!)
        favoriteLabel.hidden = !bowtie.isFavorite!.boolValue
        
        view.tintColor = bowtie.tintColour as! UIColor
    }
}

