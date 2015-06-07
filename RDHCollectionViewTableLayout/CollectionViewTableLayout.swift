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
    
//    /// Should examine the `tableColumn` property of the index path when dequeuing.
//    @objc(elementKindColumnHeader)
//    public static let ElementKindColumnHeader = "CollectionViewTableLayout.SupplementaryView.ColumnHeader"
//    /// Should examine the `tableRow` property of the index path when dequeuing.
//    @objc(elementKindRowHeader)
//    public static let ElementKindRowHeader = "CollectionViewTableLayout.SupplementaryView.RowHeader"
//    /// Should examine the `tableRow` property of the index path when dequeuing.
//    @objc(elementKindRowFooter)
//    public static let ElementKindRowFooter = "CollectionViewTableLayout.SupplementaryView.RowFooter"
    
    /// Should examine the `tableColumn` property of the index path when dequeuing.
    @objc(elementKindColumnHeader)
    public static let ElementKindColumnHeader = "ColumnHeader"
    /// Should examine the `tableRow` property of the index path when dequeuing.
    @objc(elementKindRowHeader)
    public static let ElementKindRowHeader = "   RowHeader"
    /// Should examine the `tableRow` property of the index path when dequeuing.
    @objc(elementKindRowFooter)
    public static let ElementKindRowFooter = "   RowFooter"
    
    @IBInspectable public var frozenColumnHeaders: Bool = true {
        didSet {
            invalidateLayoutIfChanged(frozenColumnHeaders, fromOldValue: oldValue) {
                let context = TableLayoutInvaldationContext()
                context.invalidColumnHeaderFreezeState = true
                return context
            }
        }
    }
    @IBInspectable public var columnHeaderHeight: CGFloat = 36 {
        didSet { invalidateLayoutIfChanged(columnHeaderHeight, fromOldValue: oldValue) }
    }
    @IBInspectable public var rowHeight: CGFloat = 36 {
        didSet { invalidateLayoutIfChanged(rowHeight, fromOldValue: oldValue) }
    }
    @IBInspectable public var rowHeaderHeight: CGFloat = 0 {
        didSet { invalidateLayoutIfChanged(rowHeaderHeight, fromOldValue: oldValue) }
    }
    @IBInspectable public var rowFooterHeight: CGFloat = 0 {
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
    /// Cached
    private var numberOfRows = 0
    /// Cached
    private var numberOfColumns = 0
    
    // Invalidation
    private var everythingNeedsUpdate = true
    private var columnHeaderYNeedsUpdate = true
    private var rowSupplementaryViewXNeedsUpdate = true
    
    public override class func invalidationContextClass() -> AnyClass {
        return TableLayoutInvaldationContext.self
    }
    
    public override func invalidateLayout() {
        super.invalidateLayout()
        
        if everythingNeedsUpdate {
            columnHeaderAttributes.removeAll()
            rowHeaderAttributes.removeAll()
            rowFooterAttributes.removeAll()
            itemAttributes.removeAll()
            rowYOffsets.removeAll()
            rowHeaderYOffsets.removeAll()
            rowFooterYOffsets.removeAll()
            columnXOffsets.removeAll()
        }
    }
    
    public override func invalidateLayoutWithContext(context: UICollectionViewLayoutInvalidationContext) {
        super.invalidateLayoutWithContext(context)
        
        if everythingNeedsUpdate {
            // Nothing to do
            return
        }
        
        let context = context as! TableLayoutInvaldationContext
        
        columnHeaderYNeedsUpdate = context.invalidColumnHeaderFreezeState
        rowSupplementaryViewXNeedsUpdate = context.invalidateRowSupplementaryViews
        
        if context.invalidateEverything || context.invalidateDataSourceCounts {
            everythingNeedsUpdate = true
        } else {
            everythingNeedsUpdate = false
            
            if let invalidatedItemIndexPaths = context.invalidatedItemIndexPaths as? [NSIndexPath] {
                // Remove all index paths of items that need invalidating, these can be generated on the fly
                for indexPath in invalidatedItemIndexPaths {
                    itemAttributes.removeValueForKey(indexPath)
                }
            }
        }
        
        println("Everything: \(context.invalidateEverything)")
        println("Row header/footer: \(context.invalidateRowSupplementaryViews)")
        println("Colunn freezing: \(context.invalidColumnHeaderFreezeState)")
    }
    
    public override func invalidationContextForBoundsChange(newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        
        let context = super.invalidationContextForBoundsChange(newBounds) as! TableLayoutInvaldationContext

        if newBounds.origin.x != collectionView?.bounds.origin.x {
            // Need to update any headers and footers as these are full width
            context.invalidateRowSupplementaryViews = true
        }
        
        if frozenColumnHeaders {
            if newBounds.origin.y != collectionView?.bounds.origin.y {
                // Need to move the column headers if we're frozen
                context.invalidColumnHeaderFreezeState = true
            }
        }
        
//        println(newBounds)
//        println(UIEdgeInsetsInsetRect(newBounds, collectionView!.contentInset))
        if let collectionView = collectionView {
            
            let newInsetBounds = UIEdgeInsetsInsetRect(newBounds, collectionView.contentInset)
            
            // Check if we need to update the Y position of the column headers to keep them pinned to the top when scroll view is pull down too far
            if newInsetBounds.minY < 0 {
                context.invalidColumnHeaderFreezeState = true
            }

            // Check if we need to update the X position of the row headers to keep them pinned to the left or right when scrolling too far
            if newInsetBounds.minX < 0 {
                context.invalidateRowSupplementaryViews = true
            }
            if newInsetBounds.maxX > collectionView.contentSize.width {
                context.invalidateRowSupplementaryViews = true
            }
        }
        
        return context
    }
    
    public override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        // Only invalidate if the bounds change
        return collectionView?.bounds != newBounds
    }
    
    public override func prepareLayout() {
        super.prepareLayout()
        
        println("Everything updates: \(everythingNeedsUpdate)")
        println("Row header/footer updates: \(rowSupplementaryViewXNeedsUpdate)")
        println("Colunn updates: \(columnHeaderYNeedsUpdate)")

        if self.collectionView == nil {
            // Nothing to do
            return
        }
        
        let collectionView = self.collectionView!
            
        let bounds = UIEdgeInsetsInsetRect(collectionView.bounds, collectionView.contentInset)
        
        func calculateColumnHeaderY() -> CGFloat {
            var y: CGFloat = 0
            if frozenColumnHeaders {
                y += bounds.minY
            }
            if bounds.minY < 0 {
                y = bounds.minY
            }
            return y
        }
        
        let rowSupplementaryViewX = bounds.minX
        
        let columnHeaderX = collectionView.contentInset.left
        let columnHeaderY = calculateColumnHeaderY()
        
        println("Y:                     \(bounds.minY)")
        println("columnHeaderY:         \(columnHeaderY)")
        println("minX:                  \(bounds.minX)")
        println("maxX:                  \(bounds.maxX)")
        println("rowSupplementaryViewX: \(rowSupplementaryViewX)")
        println("columnHeaderX:         \(columnHeaderX)")
        if everythingNeedsUpdate {
            
            /// Only adds attributes if `columnHeaderHeight` is greater than 0.
            func addColumnHeader(column: Int, x: CGFloat, width: CGFloat) {
                if columnHeaderHeight > 0 {
                    let attrs = newLayoutAttributesForSupplementaryColumnHeaderView(column)
                    attrs.frame = CGRect(x: x, y: columnHeaderY, width: width, height: columnHeaderHeight)
                    columnHeaderAttributes[column] = attrs
                }
            }

            /// :returns: the updated attributes if the height is greater than 0, `nil` otherwise
            func updateRowSupplementaryAttributes(attributes: UICollectionViewLayoutAttributes, withYOffset y: CGFloat, #height: CGFloat) -> UICollectionViewLayoutAttributes? {
                if height > 0 {
                    attributes.frame = CGRect(x: rowSupplementaryViewX, y: y, width: bounds.width, height: height)
                    return attributes
                } else {
                    return nil
                }
            }
            
            if let dataSource = dataSource, delegate = delegate {
                
                numberOfRows = dataSource.numberOfSectionsInCollectionView?(collectionView) ?? 0
                numberOfColumns = dataSource.collectionView(collectionView, numberOfItemsInSection: 0)
                
                // Visible collection view
                var visibleRect = collectionView.bounds
                visibleRect.origin = collectionView.contentOffset
                
                // Get current row range
                var visibleRowLowerBounds: Int?
                var visibleRowUpperBounds: Int?
                
                var y = columnHeaderHeight
                
                // Set initial values in case there are no rows
                rowHeaderYOffsets[numberOfRows] = y
                rowYOffsets[numberOfRows] = y
                rowFooterYOffsets[numberOfRows] = y
                
                for row in 0..<numberOfRows {
                    let headerHeight = delegate.collectionView?(collectionView, layout: self, rowHeaderHeightForTableRow: row) ?? rowHeaderHeight
                    rowHeaderAttributes[row] = updateRowSupplementaryAttributes(newLayoutAttributesForSupplementaryRowHeaderView(row), withYOffset: y, height: headerHeight)
                    rowHeaderYOffsets[row] = y
                    y += headerHeight
                    // Keep storing the last one
                    rowHeaderYOffsets[numberOfRows] = y
                    
                    let height = delegate.collectionView?(collectionView, layout: self, rowHeightForTableRow: row) ?? rowHeight
                    let intersects = visibleRect.intersects(CGRect(x: 0, y: y, width: 0, height: height))
                    if intersects {
                        if visibleRowLowerBounds == nil {
                            visibleRowLowerBounds = row
                            visibleRowUpperBounds = row + 1
                        }
                        
                        if intersects {
                            visibleRowUpperBounds = row
                        }
                    }
                    
                    rowYOffsets[row] = y
                    y += height
                    // Keep storing the last one
                    rowYOffsets[numberOfRows] = y
                    
                    let footerHeight = delegate.collectionView?(collectionView, layout: self, rowFooterHeightForTableRow: row) ?? rowFooterHeight
                    rowFooterAttributes[row] = updateRowSupplementaryAttributes(newLayoutAttributesForSupplementaryRowFooterView(row), withYOffset: y, height: footerHeight)
                    rowFooterYOffsets[row] = y
                    y += footerHeight
                    // Keep storing the last one
                    rowFooterYOffsets[numberOfRows] = y
                }
                
                /// :returns: `true` if x is in the visible range of the collection view
                func isXInCollectionViewBounds(x: CGFloat) -> Bool {
                    return visibleRect.contains(CGPoint(x: x, y: visibleRect.midY))
                }
                
                let rowRange: Range<Int>?
                if let lower = visibleRowLowerBounds, upper = visibleRowUpperBounds {
                    rowRange = lower..<upper
                } else {
                    rowRange = nil
                }
                
                var x: CGFloat = columnHeaderX
                for column in 0..<numberOfColumns {
                    let width = delegate.collectionView(collectionView, layout: self, columnWidthForTableColumn: column)
                    
                    // Add column header attribute
                    addColumnHeader(column, x, width)
                    
                    if let rowRange = rowRange where isXInCollectionViewBounds(x) {
                        // Pre calculate these items
                        for row in rowRange {
                            if let minY = rowYOffsets[row], maxY = rowFooterYOffsets[row] {
                                let indexPath = NSIndexPath(forTableColumn: column, inTableRow: row)
                                let attrs = newLayoutAttributesForItem(indexPath)
                                attrs.frame = CGRect(x: x, y: minY, width: width, height: maxY - minY)
                                itemAttributes[indexPath] = attrs
                            }
                        }
                    }
                    
                    // Store and update
                    columnXOffsets[column] = x
                    x += width
                }
                columnXOffsets[numberOfColumns] = x
            }
            
            // These have already been calculated
            rowSupplementaryViewXNeedsUpdate = false
            columnHeaderYNeedsUpdate = false
        }
        
        if rowSupplementaryViewXNeedsUpdate {
            
            func updateRowSupplementaryViewSize(attributes: UICollectionViewLayoutAttributes?) {
                attributes?.frame.origin.x = rowSupplementaryViewX
                attributes?.size.width = bounds.width
            }
            
            for row in 0..<numberOfRows {
                updateRowSupplementaryViewSize(rowHeaderAttributes[row])
                updateRowSupplementaryViewSize(rowFooterAttributes[row])
            }
        }
        
        if columnHeaderYNeedsUpdate {
            for column in 0..<numberOfColumns {
                let attr = columnHeaderAttributes[column]
                if let x = columnXOffsets[column] {
                    attr?.frame.origin.x = columnHeaderX + x
                }
                attr?.frame.origin.y = columnHeaderY
            }
        }
        
        // Reset invalidation state
        everythingNeedsUpdate = false
        rowSupplementaryViewXNeedsUpdate = false
        columnHeaderYNeedsUpdate = false
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
        
        if numberOfColumns == 0 {
            // Break early as we'll have nothing to show
            return attributes
        }
        
        func addAttributeIfNeeded(attr: UICollectionViewLayoutAttributes) {
            if rect.intersects(attr.frame) {
                attributes.append(attr)
            }
        }
        
        func visibleRange(min: CGFloat, max: CGFloat, offsetCount: Int, @noescape offsetsCalculator: (item: Int) -> (min: CGFloat?, max: CGFloat?)) -> Range<Int>? {
       
            var lowerBound: Int? = nil
            var upperBound: Int? = nil
            
            let rect = CGRect(x: min, y: 0, width: max - min, height: 0)
            
            for idx in 0...offsetCount {
                let itemRange = offsetsCalculator(item: idx)
                let itemMax = itemRange.max ?? itemRange.min
                if let itemMin = itemRange.min, itemMax = itemMax {
                    let itemRect = CGRect(x: itemMin, y: 0, width: itemMax - itemMin, height: 0)
                    
                    let intersects = rect.intersects(itemRect)
                    
                    if intersects {
                        if lowerBound == nil {
                            lowerBound = idx
                        }
                    }
                    
                    if lowerBound != nil {
                        upperBound = idx
                        
                        if !intersects {
                            // We're done intersecting
                            break
                        }
                    }
                }
            }
            
            if let lowerBound = lowerBound, upperBound = upperBound {
                return lowerBound..<upperBound
            } else {
                return nil
            }
        }
        
        let visibleRows = visibleRange(rect.minY, rect.maxY, numberOfRows) { (item) in// -> (CGFloat?, CGFloat?) in
            return (rowHeaderYOffsets[item], rowFooterYOffsets[item])
        }
        let visibleColumns = visibleRange(rect.minX, rect.maxX, numberOfColumns) { (item) -> (CGFloat?, CGFloat?) in
            return (columnXOffsets[item], columnXOffsets[item + 1])
        }
        
        // Add items for all visible rows
        if let collectionView = collectionView, visibleRows = visibleRows, visibleColumns = visibleColumns {
            
            println("Currently visible rows: \(visibleRows)")
            println("Currently visible columns: \(visibleColumns)")
            
            // Add column headers if the rect maxY is less than the header height or its frozen
            let columnsHeadersNeedAdding = frozenColumnHeaders || (rect.maxY <= columnHeaderHeight)
            
            for col in visibleColumns {
                if let attr = columnHeaderAttributes[col] {
                    addAttributeIfNeeded(attr)
                }
            }
            
            for row in visibleRows {
                
                // Headers
                if let attr = rowHeaderAttributes[row] {
                    addAttributeIfNeeded(attr)
                }
                
                // Add column items
                for col in visibleColumns {
                    // Cells
                    let indexPath = NSIndexPath(forTableColumn: col, inTableRow: row)
                    addAttributeIfNeeded(loadLayoutAttributesForItem(indexPath))
                }
                
                // Footers
                if let attr = rowFooterAttributes[row] {
                    addAttributeIfNeeded(attr)
                }
            }
        }
        
//        println("Rect: \(rect)")
//        println("Items: {\n" + join("", map(attributes) { "\t[(\($0.indexPath.tableRow),\($0.indexPath.tableColumn)) - \($0.representedElementKind) : \($0.frame)]\n" }) + "}")
        
        return attributes
    }
    
    public override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        
        return loadLayoutAttributesForItem(indexPath)
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
        let attrs = info.lookup[info.key]
        return attrs
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
    
    func loadLayoutAttributesForItem(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes {
       
        if let attribute = itemAttributes[indexPath] {
            return attribute
        } else {
            let attribute = newLayoutAttributesForItem(indexPath)
            
            let column = indexPath.tableColumn
            let row = indexPath.tableRow
            // Bottom of cell is top of its footer
            if let minX = columnXOffsets[column], maxX = columnXOffsets[column + 1], minY = rowYOffsets[row], maxY = rowFooterYOffsets[row] {
                attribute.frame = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
            }
            
            itemAttributes[indexPath] = attribute
            return attribute
        }
    }
    
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
        
        let attribute = newLayoutAttributesForSupplementaryViewOfKind(self.dynamicType.ElementKindRowFooter, atIndexPath: NSIndexPath(forTableColumn: SupplementaryViewIndexes.RowFooter, inTableRow: row))
        
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

// MARK: - Custom invalidation context

private class TableLayoutInvaldationContext: UICollectionViewLayoutInvalidationContext {
    
    var invalidColumnHeaderFreezeState = false
    var invalidateRowSupplementaryViews = false
}

// MARK: - Internal helper methods -

private extension CollectionViewTableLayout {
 
    func invalidateLayoutIfChanged<T: Equatable>(newValue: T, fromOldValue oldValue: T, contextCreator: (() -> TableLayoutInvaldationContext)? = nil) {
        if oldValue != newValue {
            if let context = contextCreator?() {
                invalidateLayoutWithContext(context)
            } else {
                invalidateLayout()
            }
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