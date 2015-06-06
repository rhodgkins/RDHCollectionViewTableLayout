//
//  ViewController.swift
//  RDHCollectionViewTableLayoutDemo
//
//  Created by Richard Hodgkins on 06/06/2015.
//  Copyright (c) 2015 Rich H. All rights reserved.
//

import UIKit

final class ViewController: UIViewController {

    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var layout: CollectionViewTableLayout!
    
    override func viewDidLoad() {
        super.viewDidLoad()
     }
}

private let CellIdentifier = "CellIdentifier"

// MARK: - Collection view table layout data source

extension ViewController: CollectionViewTableLayoutDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Must always be the number of columns
        return 5
    }
    
    func numberOfTableRowsInCollectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout) -> Int {
        return 12
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CellIdentifier, forIndexPath: indexPath) as! Cell
        cell.textLabel.text = "\(indexPath.tableRow),\(indexPath.tableColumn)"
        return cell
    }
}

// MARK: - Collection view table layout delegate

extension ViewController: CollectionViewTableLayoutDelegate {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, columnWidthForTableColumn: Int) -> CGFloat {
        return 90
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, rowHeightForTableRow: Int) -> CGFloat {
        return 44
    }
}

// MARK: - Cell

class Cell: UICollectionViewCell {
    
    @IBOutlet private weak var textLabel: UILabel!
    
}