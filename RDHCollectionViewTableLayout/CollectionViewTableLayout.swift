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
    
    /// If implemented a greater than 0 return value will take precidece over the layouts `rowHeight` property.
    optional func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, rowHeightForTableRow: Int) -> CGFloat
    
    /// If implemented the return value will take precidece over the layouts `rowHeaderHeight` property. Return a greater than 0 value to include a header for this table row.
    optional func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, rowHeaderHeightForTableRow: Int) -> CGFloat
    
    /// If implemented the return value will take precidece over the layouts `rowFooterHeight` property. Return a greater than 0 value to include a footer for this table row.
    optional func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, rowFooterHeightForTableRow: Int) -> CGFloat
}

@objc
public class CollectionViewTableLayout: UICollectionViewLayout {
    
    /// Should examine the `tableColumn` property of the index path when dequeuing.
    @objc(elementKindColumnHeader)
    public static let ElementKindColumnHeader = "CollectionViewTableLayout.SupplementaryView.ColumnHeader"
    /// Should examine the `tableRow` property of the index path when dequeuing.
    @objc(elementKindRowHeader)
    public static let ElementKindRowHeader = "CollectionViewTableLayout.SupplementaryView.RowHeader"
    /// Should examine the `tableRow` property of the index path when dequeuing.
    @objc(elementKindRowFooter)
    public static let ElementKindRowFooter = "CollectionViewTableLayout.SupplementaryView.RowFooter"
    
    /// Set to `true` to always show the column headers above the rows.
    @IBInspectable public var frozenColumnHeaders: Bool = true {
        didSet {
            invalidateLayoutIfChanged(frozenColumnHeaders, fromOldValue: oldValue) {
                let context = TableLayoutInvaldationContext()
                context.invalidateColumnHeaderFreezeState = true
                return context
            }
        }
    }
    /// Setting too many columns here will eventaully cause only these columns to show when scrolling!
    @IBInspectable public var firstFrozenTableColumns = 0 {
        didSet {
            invalidateLayoutIfChanged(firstFrozenTableColumns, fromOldValue: oldValue) {
                let context = TableLayoutInvaldationContext()
                context.frozenColumnsAdjustment = oldValue - self.firstFrozenTableColumns
                return context
            }
        }
    }
    /// Column header height, dequeue views with `ElementKindColumnHeader`
    @IBInspectable public var columnHeaderHeight: CGFloat = 36 {
        didSet { invalidateLayoutIfChanged(columnHeaderHeight, fromOldValue: oldValue) }
    }
    /// Constant row height. This can be set per row using `collectionView:layout:rowHeightForTableRow:` in `CollectionViewTableLayoutDelegate`.
    @IBInspectable public var rowHeight: CGFloat = 36 {
        didSet { invalidateLayoutIfChanged(rowHeight, fromOldValue: oldValue) }
    }
    /**
     * Constant row header height. This can be set per row using `collectionView:layout:rowHeaderHeightForTableRow:` in `CollectionViewTableLayoutDelegate`.
     * Setting this to 0 will mean the header is not used.
     * 
     * Headers are drawn above the row and given the full inset width of the collection view.
     * 
     * Defaults to 0 so headers are not shown.
     */
    @IBInspectable public var rowHeaderHeight: CGFloat = 0 {
        didSet { invalidateLayoutIfChanged(rowHeaderHeight, fromOldValue: oldValue) }
    }
    /**
     * Constant row footer height. This can be set per row using `collectionView:layout:rowFooterHeightForTableRow:` in `CollectionViewTableLayoutDelegate`.
     * Setting this to 0 will mean the footer is not used.
     *
     * Footers are drawn below the row and given the full inset width of the collection view.
     *
     * Defaults to 0 so footers are not shown.
     */
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
    /// Value is delta update, 0 means update but no change
    private var frozenColumnsUpdate: Int? = 0
    
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
        
        let context = context as! TableLayoutInvaldationContext
        
        if context.boundsChanged {
            everythingNeedsUpdate = true
        }
        
        if everythingNeedsUpdate {
            // Nothing to more to do
            return
        }
        
        columnHeaderYNeedsUpdate = context.invalidateColumnHeaderFreezeState
        rowSupplementaryViewXNeedsUpdate = context.invalidateRowSupplementaryViews
        frozenColumnsUpdate = context.frozenColumnsAdjustment
        
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
    }
    
    public override func invalidationContextForBoundsChange(newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        
        let context = super.invalidationContextForBoundsChange(newBounds) as! TableLayoutInvaldationContext

        if newBounds.size != collectionView?.bounds.size {
            // Calculate everything again
            context.boundsChanged = true
        } else {
            
            if newBounds.origin.x != collectionView?.bounds.origin.x {
                if !rowHeaderAttributes.isEmpty || !rowFooterAttributes.isEmpty {
                    // Need to update any headers and footers as these are full width
                    context.invalidateRowSupplementaryViews = true
                }
                
                if firstFrozenTableColumns > 0 {
                    context.frozenColumnsAdjustment = 0
                }
            }
            
            if frozenColumnHeaders && !columnHeaderAttributes.isEmpty {
                if newBounds.origin.y != collectionView?.bounds.origin.y {
                    // Need to move the column headers if we're frozen
                    context.invalidateColumnHeaderFreezeState = true
                }
            }
        
            if let collectionView = collectionView {
                
                let newInsetBounds = UIEdgeInsetsInsetRect(newBounds, collectionView.contentInset)
                
                // Check if we need to update the Y position of the column headers to keep them pinned to the top when scroll view is pull down too far
                if newInsetBounds.minY < 0 && !columnHeaderAttributes.isEmpty {
                    context.invalidateColumnHeaderFreezeState = true
                }

                if !rowHeaderAttributes.isEmpty || !rowFooterAttributes.isEmpty {
                    // Check if we need to update the X position of the row headers to keep them pinned to the left or right when scrolling too far
                    if newInsetBounds.minX < 0 {
                        context.invalidateRowSupplementaryViews = true
                    }
                    if !context.invalidateRowSupplementaryViews {
                        if newInsetBounds.maxX > collectionView.contentSize.width {
                            context.invalidateRowSupplementaryViews = true
                        }
                    }
                }
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
        
//        println("Everything updates: \(everythingNeedsUpdate)")
//        println("Row header/footer updates: \(rowSupplementaryViewXNeedsUpdate)")
//        println("Colunn updates: \(columnHeaderYNeedsUpdate)")
//        println("Frozen column delta: \(frozenColumnsUpdate)")
        
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
        
        let columnHeaderX: CGFloat = 0
        let columnHeaderY = calculateColumnHeaderY()
        
        if everythingNeedsUpdate {

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
                
                // If the data source doesn't provide supplementary views ignore teh heights of them
                let supplementaryViewDataSourceMethod = dataSource.respondsToSelector("collectionView:viewForSupplementaryElementOfKind:atIndexPath:")
                
                // Visible collection view
                var visibleRect = collectionView.bounds
                visibleRect.origin = collectionView.contentOffset
                
                // Get current row range
                var visibleRowLowerBounds: Int?
                var visibleRowUpperBounds: Int?
                
                var y = supplementaryViewDataSourceMethod ? columnHeaderHeight : 0
                
                // Set initial values in case there are no rows
                rowHeaderYOffsets[numberOfRows] = y
                rowYOffsets[numberOfRows] = y
                rowFooterYOffsets[numberOfRows] = y
                
                func resolveHeight(propertyValue: CGFloat, delegateValue: CGFloat?, zeroAllowed: Bool) -> CGFloat? {
                    
                    func isValueAllowed(value: CGFloat) -> Bool {
                        return zeroAllowed || value > 0
                    }
                    
                    if let delegateValue = delegateValue where isValueAllowed(delegateValue) {
                        return delegateValue
                    } else if isValueAllowed(propertyValue) {
                        return propertyValue
                    } else {
                        return nil
                    }
                }
                
                for row in 0..<numberOfRows {
                    rowHeaderYOffsets[row] = y
                    if let headerHeight = resolveHeight(rowHeaderHeight, delegate.collectionView?(collectionView, layout: self, rowHeaderHeightForTableRow: row), true) where supplementaryViewDataSourceMethod {
                        rowHeaderAttributes[row] = updateRowSupplementaryAttributes(newLayoutAttributesForSupplementaryRowHeaderView(row), withYOffset: y, height: headerHeight)
                        y += headerHeight
                    }
                    // Keep storing the last one
                    rowHeaderYOffsets[numberOfRows] = y
                    
                    rowYOffsets[row] = y
                    let height: CGFloat
                    if let h = resolveHeight(rowHeight, delegate.collectionView?(collectionView, layout: self, rowHeightForTableRow: row), false) {
                        height = h
                    } else {
                        println("Row \(row) has a height which is invalid, using a height of 80 instead")
                        height = 80
                    }
                    let intersects = visibleRect.intersects(CGRect(x: 0, y: y, width: 0, height: height))
                    if intersects {
                        if visibleRowLowerBounds == nil {
                            visibleRowLowerBounds = row
                            visibleRowUpperBounds = row + 1
                        } else {
                            visibleRowUpperBounds = row
                        }
                    }
                
                    y += height
                    // Keep storing the last one
                    rowYOffsets[numberOfRows] = y
                    
                    rowFooterYOffsets[row] = y
                    if let footerHeight = resolveHeight(rowFooterHeight, delegate.collectionView?(collectionView, layout: self, rowFooterHeightForTableRow: row), true) where supplementaryViewDataSourceMethod {
                        rowFooterAttributes[row] = updateRowSupplementaryAttributes(newLayoutAttributesForSupplementaryRowFooterView(row), withYOffset: y, height: footerHeight)
                        y += footerHeight
                    }
                    // Keep storing the last one
                    rowFooterYOffsets[numberOfRows] = y
                }
                
                let rowRange: Range<Int>?
                if let lower = visibleRowLowerBounds, upper = visibleRowUpperBounds {
                    rowRange = lower...upper
                } else {
                    rowRange = nil
                }
                
                /// Only adds attributes if `columnHeaderHeight` is greater than 0.
                func addColumnHeader(column: Int, var x: CGFloat, width: CGFloat) {
                    if columnHeaderHeight > 0 {
                        let attrs = newLayoutAttributesForSupplementaryColumnHeaderView(column)
                        attrs.frame = CGRect(x: x, y: columnHeaderY, width: width, height: columnHeaderHeight)
                        columnHeaderAttributes[column] = attrs
                    }
                }
                
                /// :returns: `true` if x is in the visible range of the collection view
                func isXInCollectionViewBounds(x: CGFloat) -> Bool {
                    return visibleRect.contains(CGPoint(x: x, y: visibleRect.midY))
                }
                
                var x: CGFloat = columnHeaderX
                for column in 0..<numberOfColumns {
                    var width = delegate.collectionView(collectionView, layout: self, columnWidthForTableColumn: column)
                    if width <= 0 {
                        println("Column \(column) has a width which is invalid, using a width of 80 instead")
                        width = 80
                    }
                    
                    // Add column header attribute
                    addColumnHeader(column, x, width)
                    
                    if let rowRange = rowRange where isXInCollectionViewBounds(x) {
                        // Pre calculate these items as they're going to be visible
                        for row in rowRange {
                            if let minY = rowYOffsets[row], maxY = rowFooterYOffsets[row] {                                let indexPath = NSIndexPath(forTableColumn: column, inTableRow: row)
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
            // Always update as these offsets are calculated above, but only do it if we've got frozen rows
            frozenColumnsUpdate = firstFrozenTableColumns > 0 ? 0 : nil
        }
        
        if rowSupplementaryViewXNeedsUpdate && !rowHeaderAttributes.isEmpty || !rowFooterAttributes.isEmpty {
            
            func updateRowSupplementaryViewSize(attributes: UICollectionViewLayoutAttributes?) {
                attributes?.frame.origin.x = rowSupplementaryViewX
                attributes?.size.width = bounds.width
            }
            
            for row in 0..<numberOfRows {
                updateRowSupplementaryViewSize(rowHeaderAttributes[row])
                updateRowSupplementaryViewSize(rowFooterAttributes[row])
            }
        }
        
        // Only relevant for frozen column headers
        if columnHeaderYNeedsUpdate && !columnHeaderAttributes.isEmpty {
            for column in 0..<numberOfColumns {
                let attr = columnHeaderAttributes[column]
                attr?.frame.origin.y = columnHeaderY
            }
        }
        
        // Only relevant for frozen columns
        if let frozenColumnsUpdate = frozenColumnsUpdate {
            
            func updateAttributesPosition(column: Int, var xOffset: CGFloat, attrs: UICollectionViewLayoutAttributes?) {
                if column < firstFrozenTableColumns && bounds.minX > 0 {
                    xOffset += bounds.minX
                }
                attrs?.frame.origin.x = xOffset
            }
            // Abs the delta as we need to update the old ones too
            let changedColumns = firstFrozenTableColumns + abs(frozenColumnsUpdate)
            for column in 0..<changedColumns {
                
                if let x = columnXOffsets[column] {
                    updateAttributesPosition(column, x, columnHeaderAttributes[column])
                
                    // Update all the rows
                    for row in 0..<numberOfRows {
                        let indexPath = NSIndexPath(forTableColumn: column, inTableRow: row)
                        updateAttributesPosition(column, x, itemAttributes[indexPath])
                    }
                }
            }
        }
        
        // Reset invalidation state
        everythingNeedsUpdate = false
        rowSupplementaryViewXNeedsUpdate = false
        columnHeaderYNeedsUpdate = false
        frozenColumnsUpdate = nil
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
            
//            println("Currently visible rows: \(visibleRows)")
//            println("Currently visible columns: \(visibleColumns)")
            
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
        
        return attributes
    }
    
    /// These are pre-calucated for the visible items in `prepareLayout` and then after that they are loaded as needed.
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
        return info.lookup[info.key]
    }
}

// MARK: - Calculations

private enum AttributeZIndex: Int {
    case ScrollBars = 0
    case FrozenColumnHeaders = -1
    case ColumnHeaders = -2
    case RowHeaders = -3
    case RowFooters = -4
    case FrozenItems = -5
    case Items = -6
}

private struct SupplementaryViewIndexes {
    static let ColumnHeader = -1
    static let RowHeader = 0
    static let RowFooter = 0
}

private extension CollectionViewTableLayout {
    
    /// Cached values or loaded on the fly
    func loadLayoutAttributesForItem(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes {
       
        if let attribute = itemAttributes[indexPath] {
            return attribute
        } else {
            let attribute = newLayoutAttributesForItem(indexPath)
            
            let column = indexPath.tableColumn
            let row = indexPath.tableRow
            // Bottom of cell is top of its footer
            if var minX = columnXOffsets[column], maxX = columnXOffsets[column + 1], minY = rowYOffsets[row], maxY = rowFooterYOffsets[row] {
                let width = maxX - minX
                if column < firstFrozenTableColumns {
                    if let collectionView = collectionView where (collectionView.bounds.minX + collectionView.contentInset.left) > 0 {
                        minX += collectionView.bounds.minX
                    }
                }
                attribute.frame = CGRect(x: minX, y: minY, width: width, height: maxY - minY)
            }
            
            itemAttributes[indexPath] = attribute
            return attribute
        }
    }
    
    /// Sets no position or size information
    func newLayoutAttributesForItem(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes {
        
        let attribute = newLayoutAttributesForItemAtIndexPath(indexPath)
        
        let zIndex: AttributeZIndex
        if indexPath.tableColumn < firstFrozenTableColumns {
            zIndex = .FrozenItems
        } else {
            zIndex = .Items
        }
        attribute.zIndex = zIndex.rawValue
        
        return attribute
    }
    
    /// Sets no position or size information
    func newLayoutAttributesForSupplementaryColumnHeaderView(column: Int) -> UICollectionViewLayoutAttributes {
        
        let attribute = newLayoutAttributesForSupplementaryViewOfKind(self.dynamicType.ElementKindColumnHeader, atIndexPath: NSIndexPath(forTableColumn: column, inTableRow: SupplementaryViewIndexes.ColumnHeader))
        
        let zIndex: AttributeZIndex
        if column < firstFrozenTableColumns {
            zIndex = .FrozenColumnHeaders
        } else {
            zIndex = .ColumnHeaders
        }
        attribute.zIndex = zIndex.rawValue
        
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

class TableLayoutInvaldationContext: UICollectionViewLayoutInvalidationContext {
    
    var boundsChanged = false
    var invalidateColumnHeaderFreezeState = false
    var frozenColumnsAdjustment: Int?
    var invalidateRowSupplementaryViews = false
}

// MARK: - Internal helper methods -

private extension CollectionViewTableLayout {
    
    func invalidateLayoutIfChanged<T: Equatable>(newValue: T, fromOldValue oldValue: T, contextCreator: (() -> TableLayoutInvaldationContext)? = nil) {
        if oldValue != newValue {
            invalidateWithContextCreator(contextCreator)
        }
    }
    
    func invalidateWithContextCreator(contextCreator: (() -> TableLayoutInvaldationContext)?) {
        if let context = contextCreator?() {
            invalidateLayoutWithContext(context)
        } else {
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