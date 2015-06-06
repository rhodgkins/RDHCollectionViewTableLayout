//
//  CollectionViewTableLayout.swift
//  RDHCollectionViewTableLayout
//
//  Created by Richard Hodgkins on 06/06/2015.
//  Copyright (c) 2015 Rich H. All rights reserved.
//

import UIKit

@objc
public protocol CollectionViewTableLayoutDataSource: UICollectionViewDataSource {
    
    func numberOfTableRowsInCollectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout) -> Int
}

@objc
public protocol CollectionViewTableLayoutDelegate: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, columnWidthForTableColumn: Int) -> CGFloat
    
    optional func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, rowHeightForTableRow: Int) -> CGFloat
    
    optional func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, rowHeaderHeightForTableRow: Int) -> CGFloat
    
    optional func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, rowFooterHeightForTableRow: Int) -> CGFloat
}

@objc
public class CollectionViewTableLayout: UICollectionViewLayout {
    
    @objc(elementKindColumnHeader)
    public static let ElementKindColumnHeader = "CollectionViewTableLayout.SupplementaryView.ColumnHeader"
    @objc(elementKindRowHeader)
    public static let ElementKindRowHeader = "CollectionViewTableLayout.SupplementaryView.RowHeader"
    @objc(elementKindRowFooter)
    public static let ElementKindRowFooter = "CollectionViewTableLayout.SupplementaryView.RowFooter"
    
    @IBInspectable var frozenColumnHeaders: Bool = true {
        didSet { invalidateLayoutIfChanged(frozenColumnHeaders, fromOldValue: oldValue) }
    }
    @IBInspectable var columnHeaderHeight: CGFloat = 36 {
        didSet { invalidateLayoutIfChanged(columnHeaderHeight, fromOldValue: oldValue) }
    }
    @IBInspectable var rowHeight: CGFloat = 36 {
        didSet { invalidateLayoutIfChanged(rowHeight, fromOldValue: oldValue) }
    }
    @IBInspectable var rowHeaderHeight: CGFloat = 0 {
        didSet { invalidateLayoutIfChanged(rowHeaderHeight, fromOldValue: oldValue) }
    }
    @IBInspectable var rowFooterHeight: CGFloat = 0 {
        didSet { invalidateLayoutIfChanged(rowFooterHeight, fromOldValue: oldValue) }
    }
    /// Key is the table column
    private var columnHeaderAttributes = [Int : UICollectionViewLayoutAttributes]()
    /// Key is the table row
    private var rowHeaderAttributes = [Int : UICollectionViewLayoutAttributes]()
    /// Key is the table row
    private var rowFooterAttributes = [Int : UICollectionViewLayoutAttributes]()
    /// Key is the cells index path
    private var itemAttributes = [NSIndexPath : UICollectionViewLayoutAttributes]()
    /// Key is the table row, this contains numberOfRows with the value for numberOfRows being maxY of the last item
    private var rowYOffsets = [Int : CGFloat]()
    /// Key is the table row, this contains numberOfRows with the value for numberOfRows being maxY of the last item
    private var rowHeaderYOffsets = [Int : CGFloat]()
    /// Key is the table row, this contains numberOfRows with the value for numberOfRows being maxY of the last item
    private var rowFooterYOffsets = [Int : CGFloat]()
    /// Key is the table column, this contains numberOfColumns with the value for numberOfColumns being maxX of the last item
    private var columnXOffsets = [Int : CGFloat]()
    private var numberOfRows = 0
    private var numberOfColumns = 0
    
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
        
        columnHeaderAttributes.removeAll()
        rowHeaderAttributes.removeAll()
        rowFooterAttributes.removeAll()
        itemAttributes.removeAll()
        rowYOffsets.removeAll()
        rowHeaderYOffsets.removeAll()
        rowFooterYOffsets.removeAll()
        columnXOffsets.removeAll()
    }
    
    public override func prepareLayout() {
        super.prepareLayout()
        
        if let collectionView = collectionView, dataSource = dataSource, delegate = delegate {
            
            /// :returns: the updated attributes if the height is greater than 0, `nil` otherwise
            func updateRowSupplementaryAttributes(attributes: UICollectionViewLayoutAttributes, withYOffset y: CGFloat, #height: CGFloat) -> UICollectionViewLayoutAttributes? {
                if height > 0 {
                    attributes.frame = CGRect(x: 0, y: y, width: collectionView.bounds.width, height: height)
                    return attributes
                } else {
                    return nil
                }
            }
            
            numberOfRows = dataSource.numberOfTableRowsInCollectionView(collectionView, layout:self)
            numberOfColumns = dataSource.collectionView(collectionView, numberOfItemsInSection: 0)
            
            var y: CGFloat = columnHeaderHeight
            for row in 0..<numberOfRows {
                let headerHeight = delegate.collectionView?(collectionView, layout: self, rowHeaderHeightForTableRow: row) ?? rowHeaderHeight
                rowHeaderAttributes[row] = updateRowSupplementaryAttributes(newLayoutAttributesForSupplementaryRowHeaderView(row), withYOffset: y, height: headerHeight)
                rowHeaderYOffsets[row] = y
                y += headerHeight
                // Keep storing the last one
                rowHeaderYOffsets[numberOfRows] = y
                
                rowYOffsets[row] = y
                y += delegate.collectionView?(collectionView, layout: self, rowHeightForTableRow: row) ?? rowHeight
                // Keep storing the last one
                rowYOffsets[numberOfRows] = y
                
                let footerHeight = delegate.collectionView?(collectionView, layout: self, rowFooterHeightForTableRow: row) ?? rowFooterHeight
                rowFooterAttributes[row] = updateRowSupplementaryAttributes(newLayoutAttributesForSupplementaryRowFooterView(row), withYOffset: y, height: footerHeight)
                rowFooterYOffsets[row] = y
                y += footerHeight
                // Keep storing the last one
                rowFooterYOffsets[numberOfRows] = y
            }
            
            var x: CGFloat = 0
            for column in 0..<numberOfColumns {
                let width = delegate.collectionView(collectionView, layout: self, columnWidthForTableColumn: column)
                columnXOffsets[column] = x
                x += width
            }
            columnXOffsets[numberOfColumns] = x
        }
    }
    
    public override func collectionViewContentSize() -> CGSize {
        var size = CGSize.zeroSize
    
        // Look at the footer as thats below the rows
        if let lastXOffset = columnXOffsets[numberOfColumns], lastYOffset = rowFooterYOffsets[numberOfRows] {
            return CGSize(width: lastXOffset, height: lastYOffset)
        } else {
            return CGSize.zeroSize
        }
    }
    
    public override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? {
        var attributes = [UICollectionViewLayoutAttributes]()
        
        func addAttributeIfNeeded(attr: UICollectionViewLayoutAttributes) {
            if rect.intersects(attr.frame) {
                attributes.append(attr)
            }
        }
        
        func visibleColumnRange() -> Range<Int>? {
        
            var lowerColumnBound: Int? = nil
            var upperColumBound: Int? = nil
            for col in 0...numberOfColumns {
                if let x = columnXOffsets[col] {
                    if x > rect.maxX {
                        // Beyond the rect
                        break
                    }
                
                    if x >= rect.minX {
                        if lowerColumnBound == nil {
                            lowerColumnBound = col
                        }
                    }
                
                    if lowerColumnBound != nil {
                        upperColumBound = col
                    }
                }
            }
            
            if let lowerColumnBound = lowerColumnBound, upperColumBound = upperColumBound {
                return lowerColumnBound..<upperColumBound
            } else {
                return nil
            }
        }
        
        func visibleRowRange() -> Range<Int>? {
            
            var lowerRowBound: Int? = nil
            var upperRowBound: Int? = nil
            var y: CGFloat = 0
            for row in 0...numberOfRows {
                if let minY = rowHeaderYOffsets[row], maxY = rowFooterYOffsets[row] {
                    if maxY > rect.maxY {
                        // Beyond the rect
                        break
                    }
                    
                    if minY >= rect.minY {
                        if lowerRowBound == nil {
                            lowerRowBound = row
                        }
                    }
                    
                    if lowerRowBound != nil {
                        upperRowBound = row
                    }
                }
            }
            
            if let lowerRowBound = lowerRowBound, upperRowBound = upperRowBound {
                return lowerRowBound..<upperRowBound
            } else {
                return nil
            }
        }

        if let visibleColumns = visibleColumnRange() {
        
            // Add column headers if the rect maxY is less than the header height or its frozen
            if frozenColumnHeaders || (rect.maxY <= columnHeaderHeight) {
                
                for col in visibleColumns {
                    if let attr = columnHeaderAttributes[col] {
                        addAttributeIfNeeded(attr)
                    }
                }
            }
        
            if let visibleRows = visibleRowRange() {
                for row in visibleRows {
                    
                    for col in visibleColumns {
                        let indexPath = NSIndexPath(forTableColumn: col, inTableRow: row)
                        if let attr = itemAttributes[indexPath] {
                            addAttributeIfNeeded(attr)
                        }
                    }
                }
            }
        }
        
        return attributes
    }
    
    public override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        
        if let attribute = itemAttributes[indexPath] {
            return attribute
        } else {
            let attribute = newLayoutAttributesForItem(indexPath)
            // TODO: Calculate frame
            itemAttributes[indexPath] = attribute
            return attribute
        }
    }
    
    public override func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        
        func resolveInfo() -> (key: Int, lookup: [Int : UICollectionViewLayoutAttributes]) {
            switch elementKind {
                case self.dynamicType.ElementKindColumnHeader:
                    return (indexPath.tableColumn, columnHeaderAttributes)
                 
                case self.dynamicType.ElementKindRowHeader:
                    return (indexPath.tableRow, rowHeaderAttributes)
                
                case self.dynamicType.ElementKindRowFooter:
                    return (indexPath.tableRow, rowFooterAttributes)
                
                default:
                    fatalError("Unknown element kind \"\(elementKind)\" for index path: \(indexPath)")
            }
        }
        
        let info = resolveInfo()
        return info.lookup[info.key]
    }
}

// MARK: - Sizes

private extension CollectionViewTableLayout {
    
    func rangeForColumn(column: Int) -> (min: CGFloat, max: CGFloat)? {
        if let min = columnXOffsets[column], max = columnXOffsets[column + 1] {
            return (min, max)
        } else {
            return nil
        }
    }
    
    func widthForColumn(column: Int) -> CGFloat {
        if let range = rangeForColumn(column) {
            return range.max - range.min
        } else {
            return 0
        }
    }
    
    func rangeForRowHeader(row: Int) -> (min: CGFloat, max: CGFloat)? {
        if let min = rowHeaderYOffsets[row], max = rowHeaderYOffsets[row + 1] {
            return (min, max)
        } else {
            return nil
        }
    }
    
    func heightForRowHeader(row: Int) -> CGFloat {
        if let range = rangeForRowHeader(row) {
            return range.max - range.min
        } else {
            return 0
        }
    }
    
    func rangeForRow(row: Int) -> (min: CGFloat, max: CGFloat)? {
        if let min = rowYOffsets[row], max = rowYOffsets[row + 1] {
            return (min, max)
        } else {
            return nil
        }
    }
    
    func heightForRow(row: Int) -> CGFloat {
        if let range = rangeForRow(row) {
            return range.max - range.min
        } else {
            return 0
        }
    }
    
    func rangeForRowFooter(row: Int) -> (min: CGFloat, max: CGFloat)? {
        if let min = rowFooterYOffsets[row], max = rowFooterYOffsets[row + 1] {
            return (min, max)
        } else {
            return nil
        }
    }
    
    func heightForRowFooter(row: Int) -> CGFloat {
        if let range = rangeForRowFooter(row) {
            return range.max - range.min
        } else {
            return 0
        }
    }
}

// MARK: - Calculations

private enum AttributeZIndex: Int {
    case ScrollBars = 0
    case ColumnHeaders = -1
    case RowHeaders = -2
    case RowFooters = -3
    case Items = -4
}

private struct SupplementaryViewIndexes {
    static let ColumnHeader = -1
    static let RowHeader = 0
    static let RowFooter = 0
}

private extension CollectionViewTableLayout {
    
    /// Sets no position or size information
    func newLayoutAttributesForItem(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes {
        
        let attribute = newLayoutAttributesForItemAtIndexPath(indexPath)
        
        attribute.zIndex = AttributeZIndex.Items.rawValue
        
        return attribute
    }
    
    /// Sets no position or size information
    func newLayoutAttributesForSupplementaryColumnHeaderView(column: Int) -> UICollectionViewLayoutAttributes {
        
        let attribute = newLayoutAttributesForSupplementaryViewOfKind(self.dynamicType.ElementKindColumnHeader, atIndexPath: NSIndexPath(forTableColumn: column, inTableRow: SupplementaryViewIndexes.ColumnHeader))
        
        attribute.zIndex = AttributeZIndex.ColumnHeaders.rawValue
        
        return attribute
    }
    
    /// Sets no position or size information
    func newLayoutAttributesForSupplementaryRowHeaderView(row: Int) -> UICollectionViewLayoutAttributes {
        
        let attribute = newLayoutAttributesForSupplementaryViewOfKind(self.dynamicType.ElementKindRowHeader, atIndexPath: NSIndexPath(forTableColumn: SupplementaryViewIndexes.RowHeader, inTableRow: row))
        
        attribute.zIndex = AttributeZIndex.RowHeaders.rawValue
        
        return attribute
    }
    
    /// Sets no position or size information
    func newLayoutAttributesForSupplementaryRowFooterView(row: Int) -> UICollectionViewLayoutAttributes {
        
        let attribute = newLayoutAttributesForSupplementaryViewOfKind(self.dynamicType.ElementKindRowHeader, atIndexPath: NSIndexPath(forTableColumn: SupplementaryViewIndexes.RowFooter, inTableRow: row))
        
        attribute.zIndex = AttributeZIndex.RowFooters.rawValue
        
        return attribute
    }
}

// MARK: - UICollectionViewLayoutAttributes helper 

private extension CollectionViewTableLayout {
    
    func newLayoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes {
        let cls = self.dynamicType.layoutAttributesClass() as! UICollectionViewLayoutAttributes.Type
        return cls.init(forCellWithIndexPath: indexPath)
    }
    
    func newLayoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes {
        let cls = self.dynamicType.layoutAttributesClass() as! UICollectionViewLayoutAttributes.Type
        return cls.init(forSupplementaryViewOfKind: elementKind, withIndexPath: indexPath)
    }
    
    func newLayoutAttributesForDecorationViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes {
        let cls = self.dynamicType.layoutAttributesClass() as! UICollectionViewLayoutAttributes.Type
        return cls.init(forDecorationViewOfKind: elementKind, withIndexPath: indexPath)
    }
}

// MARK: - Internal helper methods -

private extension CollectionViewTableLayout {
 
    func invalidateLayoutIfChanged<T: Equatable>(newValue: T, fromOldValue oldValue: T) {
        if oldValue != newValue {
            invalidateLayout()
        }
    }
}

// MARK: Layout delegate

private extension CollectionViewTableLayout {
    var dataSource: CollectionViewTableLayoutDataSource? {
        return collectionView?.dataSource as? CollectionViewTableLayoutDataSource
    }
    
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
    
    public convenience init(forTableColumn column: Int, inTableRow row: Int) {
        self.init(forItem: column, inSection: row)
    }
}