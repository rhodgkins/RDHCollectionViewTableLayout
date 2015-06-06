//
//  CollectionViewTableLayout.swift
//  RDHCollectionViewTableLayout
//
//  Created by Richard Hodgkins on 06/06/2015.
//  Copyright (c) 2015 Rich H. All rights reserved.
//

import UIKit

@objc(RDHCollectionViewTableLayoutDelegate)
public protocol CollectionViewTableLayoutDelegate: UICollectionViewDelegate {
    
    func numberOfColumnsInCollectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout) -> Int
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, columnWidthForTableColumn: Int) -> CGFloat
    
    optional func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, rowHeightForTableRow: Int) -> CGFloat
}

@objc(RDHCollectionViewTableLayout)
public class CollectionViewTableLayout: UICollectionViewLayout {
    
    @IBInspectable var frozenColumnHeaders: Bool = true {
        didSet { invalidateLayout() }
    }
    @IBInspectable var frozenRowHeaders: Bool = true {
        didSet { invalidateLayout() }
    }
    @IBInspectable var columnHeaderHeight: CGFloat = 36 {
        didSet { invalidateLayout() }
    }
    @IBInspectable var rowHeaderWidth: CGFloat = 90 {
        didSet { invalidateLayout() }
    }
    @IBInspectable var rowHeight: CGFloat = 36 {
        didSet { invalidateLayout() }
    }
    private var columnHeaderAttributes = [Int : UICollectionViewLayoutAttributes]()
    private var rowHeaderAttributes = [Int : UICollectionViewLayoutAttributes]()
    private var itemAttributes = [Int : UICollectionViewLayoutAttributes]()
    
    public override init() {
        super.init()
        commonInit()
    }
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        
    }
    
    public override func invalidateLayout() {
        super.invalidateLayout()
        
        columnHeaderAttributes.removeAll(keepCapacity: true)
        rowHeaderAttributes.removeAll(keepCapacity: true)
        itemAttributes.removeAll(keepCapacity: true)
    }
    
    public override func prepareLayout() {
        super.prepareLayout()
        
        
    }
}


// MARK: - Internal helper methods -

// MARK: Layout delegate

private extension CollectionViewTableLayout {
    var delegate: CollectionViewTableLayoutDelegate? {
        return collectionView?.delegate as? CollectionViewTableLayoutDelegate
    }
}

// MARK: Extensions

public extension NSIndexPath {
    @objc var tableRow: Int { return section }
    @objc var tableColumn: Int { return item }

    @objc
    public class func indexPathForTableColumn(column: Int, inTableRow row: Int) -> Self {
        return self.init(forTableColumn: column, inTableRow: row)
    }
    
    private convenience init(forTableColumn column: Int, inTableRow row: Int) {
        self.init(forItem: column, inSection: row)
    }
}