//
//  ViewController.swift
//  RDHCollectionViewTableLayoutDemo
//
//  Created by Richard Hodgkins on 06/06/2015.
//  Copyright (c) 2015 Rich H. All rights reserved.
//

import UIKit
import RDHCollectionViewTableLayout

final class ViewController: UIViewController {

    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var layout: CollectionViewTableLayout!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        collectionView.contentInset = UIEdgeInsets(top: 100, left: 80, bottom: 60, right: 70)
        
        layout.firstFrozenTableColumns = 1
//        layout.columnHeaderHeight = 0
        layout.rowHeaderHeight = 20
        layout.rowFooterHeight = 10
        
        collectionView.registerClass(ColumnHeader.self, forSupplementaryViewOfKind: CollectionViewTableLayout.ElementKindColumnHeader, withReuseIdentifier: ColumnHeaderIdentifier)
        collectionView.registerClass(RowHeader.self, forSupplementaryViewOfKind: CollectionViewTableLayout.ElementKindRowHeader, withReuseIdentifier: RowHeaderIdentifier)
        collectionView.registerClass(RowFooter.self, forSupplementaryViewOfKind: CollectionViewTableLayout.ElementKindRowFooter, withReuseIdentifier: RowFooterIdentifier)
    }
}

private let CellIdentifier = "CellIdentifier"
private let ColumnHeaderIdentifier = "ColumnHeaderIdentifier"
private let RowHeaderIdentifier = "RowHeaderIdentifier"
private let RowFooterIdentifier = "RowFooterIdentifier"

// MARK: - Collection view table layout data source

extension ViewController: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Must always be the number of columns
        return 5
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 10
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CellIdentifier, forIndexPath: indexPath) as! Cell
        cell.textLabel.text = "\(indexPath.tableRow),\(indexPath.tableColumn)"
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {

        switch kind {
            case CollectionViewTableLayout.ElementKindColumnHeader:
                let reuse = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: ColumnHeaderIdentifier, forIndexPath: indexPath) as! ColumnHeader
            
                reuse.label.text = "\(indexPath.tableColumn)"
                
                return reuse
            
            case CollectionViewTableLayout.ElementKindRowHeader:
                let reuse = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: RowHeaderIdentifier, forIndexPath: indexPath) as! RowHeader
                
                return reuse
            
            case CollectionViewTableLayout.ElementKindRowFooter:
                let reuse = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: RowFooterIdentifier, forIndexPath: indexPath) as! RowFooter
                
                return reuse

            default:
                fatalError("Unknown kind: \(kind)")
        }
    }
}

// MARK: - Collection view table layout delegate

extension ViewController: CollectionViewTableLayoutDelegate {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, columnWidthForTableColumn: Int) -> CGFloat {
        return 120
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, rowHeightForTableRow: Int) -> CGFloat {
        return 200
    }
    
//    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, rowFooterHeightForTableRow: Int) -> CGFloat {
//        return rowFooterHeightForTableRow % 2 == 0 ? 50 : 0
//    }
//    
//    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, rowHeaderHeightForTableRow: Int) -> CGFloat {
//        return rowHeaderHeightForTableRow % 2 == 0 ? 100 : 0
//    }
}

// MARK: - Cell

class Cell: UICollectionViewCell {
    
    @IBOutlet private weak var textLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.borderWidth = 1
        layer.borderColor = UIColor.greenColor().CGColor
    }
}

// MARK: - Column header

class ColumnHeader: UICollectionReusableView {
    
    private let label = UILabel()
    
    override func willMoveToWindow(newWindow: UIWindow?) {
        super.willMoveToWindow(newWindow)
        
        layer.borderWidth = 1
        layer.borderColor = UIColor.darkGrayColor().CGColor
        backgroundColor = UIColor.redColor()
        
        if label.superview == nil {
            addSubview(label)
            label.textColor = UIColor.whiteColor()
            label.frame = bounds
        }
    }
}

// MARK: - Row header

class RowHeader: UICollectionReusableView {
    
    override func willMoveToWindow(newWindow: UIWindow?) {
        super.willMoveToWindow(newWindow)
        
        layer.borderWidth = 1
        layer.borderColor = UIColor.orangeColor().CGColor
        backgroundColor = UIColor.blueColor()
    }
}

// MARK: - Row footer

class RowFooter: UICollectionReusableView {
    
    override func willMoveToWindow(newWindow: UIWindow?) {
        super.willMoveToWindow(newWindow)
        
        layer.borderWidth = 1
        layer.borderColor = UIColor.purpleColor().CGColor
        backgroundColor = UIColor.yellowColor()
    }
}