RDHCollectionViewTableLayout 
===========================
[![Build Status](https://travis-ci.org/rhodgkins/RDHCollectionViewTableLayout.svg?branch=master)](https://travis-ci.org/rhodgkins/RDHCollectionViewTableLayout)
[![Pod Version](http://img.shields.io/cocoapods/v/RDHCollectionViewTableLayout.svg)](http://cocoadocs.org/docsets/RDHCollectionViewTableLayout/)
[![Pod Platform](http://img.shields.io/cocoapods/p/RDHCollectionViewTableLayout.svg)](http://cocoadocs.org/docsets/RDHCollectionViewTableLayout/)
[![Pod License](http://img.shields.io/cocoapods/l/RDHCollectionViewTableLayout.svg)](http://opensource.org/licenses/MIT)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

Works and tested on iOS 8.0 to 8.4 (under both Xcode 6.2, 6.3 and 6.4), but if you find any issues please [report](https://github.com/rhodgkins/RDHCollectionViewTableLayout/issues) them!

Table layout for UICollectionView.
``` ruby 
pod 'RDHCollectionViewTableLayout', '~> 2.0'
```

This layout provides simple options for customisation of a collection view as a table layout consisting of rows and columns.

The dimensions of the rows and columns can be set as properties on the layout or can be returned in the `CollectionViewTableLayoutDelegate` delegate.

To specify the number of rows in the table, return the desired value from `numberOfSectionsInCollectionView:`.

To specify the number of columsn in the table, return your desired value from `collectionView:numberOfItemsInSection:`.
You must ensure you return a constant value from this method and reload the collection view to reflect any changes.

```swift
// Columns
func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    // Must always be the same number unless you reload the collection view
    return 5
}
// Rows
func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    // Number of rows
    return 10
}
```
