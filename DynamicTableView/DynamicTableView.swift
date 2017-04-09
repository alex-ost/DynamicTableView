//
//  DynamicTableView.swift
//  DynamicTableView
//
//  Created by Alexandr Ostrynskyi on 4/8/17.
//  Copyright © 2017 Alexandr Ostrynskyi. All rights reserved.
//

import UIKit

internal class CellData: CustomDebugStringConvertible, CustomStringConvertible {
    var rect: CGRect = CGRect.zero
    var index: UInt = UInt.max
    var isValid: Bool = true
    
    init(rect: CGRect, index: UInt, isValid: Bool) {
        self.rect = rect
        self.index = index
        self.isValid = isValid
    }
    
    static func ==(lhs: CellData, rhs: CellData) -> Bool {
        return lhs.rect == rhs.rect &&
            lhs.index == rhs.index &&
            lhs.isValid == rhs.isValid
    }
    
    var debugDescription: String {
        return description
    }
    
    var description: String {
        return "\n rect: \(rect.debugDescription)\n index: \(index)\n isValid: \(isValid)"
    }
}

public class DynamicTableView : UIView {
 
    // MARK: Public var
    public var scrollView: UIScrollView = {
        var scrollView = UIScrollView()
        scrollView.backgroundColor = UIColor.clear
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 5
        return scrollView
    }()
    
    public weak var delegate: DynamicTableViewDelegate?
    public weak var dataSource: DynamicTableViewDataSource?
    
    public var indentBetweenCells: CGFloat = 0
    public var defaultCellHeight: CGFloat = 100
    public var cellAppearanceDuration: TimeInterval = 0.35
    
    public var visibleCells: [UInt] {
        get {
            return visibleCellsData.map{ $0.index }
        }
        set {}
    }
    
    // MARK: Private var
    internal var contentView: UIView = UIView()
    
    // index in array correspond cell index
    internal var cellsData: [CellData] = []
    internal var cellsCount: UInt = 0
    internal var cellsIndexForLayout: Set<UInt> = []
    internal var visibleCellsData: [CellData] = []
    
    // MARK: Overridden
    public override var frame: CGRect {
        didSet {
            updateFrames()
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateFrames()
    }
    
    private func updateFrames() {
        scrollView.frame = CGRect(origin: CGPoint.zero, size: frame.size)
        contentView.frame = CGRect(origin: CGPoint.zero, size: frame.size)
        contentView.subviews.forEach { (subview) in
            guard subview is DynamicTableViewCell else { return }
            // Change cell width
            subview.frame = CGRect(origin: subview.frame.origin, size: CGSize(width: frame.size.width, height: subview.frame.size.height))
        }
    }
    
    // MARK: Public func
    public func reloadData() {
        removeAllCells()
        loadCellsData()
        updateVisibleCells()
    }
    
    public func reloadCell(atIndex index: UInt) {
        cellsIndexForLayout.insert(index)
        updateVisibleCells()
    }
    
    // MARK: Initializers
    init() {
        super.init(frame: CGRect.zero)
        privateInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        privateInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        privateInit()
    }
    
    //MARK: Private func
    private func privateInit() {
        scrollView.delegate = self
        scrollView.addSubview(contentView)
        addSubview(scrollView)
    }
}

// MARK: Private Functionality
private extension DynamicTableView {
    func loadCellsData() {
        cellsCount = dataSource?.numberOfItemsInTableView(self) ?? 0
        var originY: CGFloat = 0
        for index in 0..<cellsCount {
            let cellHeight = delegate?.heightForCell?(self, atIndex: index) ?? defaultCellHeight
            let cellRect = CGRect(x: 0, y: originY, width: contentView.frame.width, height: cellHeight)
            cellsData.insert(CellData(rect: cellRect, index: index, isValid: true), at: Int(index))
            originY += cellHeight + indentBetweenCells
        }
        contentView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: originY - indentBetweenCells)
        scrollView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        scrollView.contentSize = CGSize(width: contentView.frame.size.width, height: contentView.frame.size.height)
    }
    
    func updateVisibleCells() {
        var alreadyInvisibleCells: [CellData] = visibleCellsData
        let cellsInRect = allVisibleCellsData()
        
        for cellData in cellsInRect {
            let cellIndex = cellData.index
            if cellsIndexForLayout.contains(cellIndex) {
               cellsIndexForLayout.remove(cellIndex)
                updateCell(atIndex: cellIndex)
            } else if cellData.isValid {
                let contains = visibleCellsData.contains(where: { (visibleCellData) -> Bool in
                    return visibleCellData == cellData
                })
                if contains {
                    if let index = alreadyInvisibleCells.index(where: { (visibleCellData) -> Bool in
                        return visibleCellData == cellData
                    }) {
                        alreadyInvisibleCells.remove(at: index)
                    }
                } else {
                    visibleCellsData.append(cellData)
                    addCell(toIndex: cellIndex)
                }
            } else {
                // Cell re-validation
                _removeCell(atIndex: cellIndex)
                addCell(toIndex: cellIndex)
                cellData.isValid = true
                cellsData.remove(at: Int(cellIndex))
                cellsData.insert(cellData, at: Int(cellIndex))
                updateVisibleCells()
                return
            }
        }
        
        for cellData in alreadyInvisibleCells {
            if let index = visibleCellsData.index(where: { (visibleCellData) -> Bool in
                return visibleCellData == cellData
            }) {
                let cellIndex = cellData.index
                visibleCellsData.remove(at: index)
                _removeCell(atIndex: cellIndex)
            }
        }
    }
    
    func addCell(toIndex index: UInt) {
        let cellData = cellsData[Int(index)]
        let cell: DynamicTableViewCell = dataSource!.cellView(self, forItemAtIndex: index)
        delegate?.willDisplayCell?(self, cell: cell, atIndex: index)
        
        cell.frame = cellData.rect
        cell.index = index
        cell.alpha = 0
        contentView.addSubview(cell)
        DispatchQueue.main.async {
            UIView.animate(withDuration: self.cellAppearanceDuration, animations: {
                cell.alpha = 1
            }, completion: { (complete) in
                self.delegate?.didDisplayCell?(self, cell: cell, atIndex: index)
            })
        }
    }
    
    func _removeCell(atIndex index: UInt) {
        guard let cellToRemove = visibleCell(atIndex: index) else { return }
        cellToRemove.removeFromSuperview()
        delegate?.didEndDisplayCell?(self, cell: cellToRemove, atIndex: index)
    }
    
    func updateCell(atIndex index: UInt) {
        guard let cellToUpdate = visibleCell(atIndex: index) else {
            print("Warning! Logic error: Try reload nearest cells of invsible cell.")
            return
        }
        
        let newCellHeight = delegate?.heightForCell?(self, atIndex: index) ?? defaultCellHeight
        let cellRect = CGRect(origin: cellToUpdate.frame.origin,
                              size: CGSize(width: contentView.frame.size.width, height: newCellHeight))
        cellsData.remove(at: Int(index))
        cellsData.insert(CellData(rect: cellRect, index: index, isValid: true), at: Int(index))
        cellToUpdate.removeFromSuperview()
        let newCell = dataSource!.cellView(self, forItemAtIndex: index)
        newCell.frame = cellRect
        newCell.index = index
        newCell.alpha = 0
        contentView.addSubview(newCell)
        DispatchQueue.main.async {
            UIView.animate(withDuration: self.cellAppearanceDuration, animations: {
                newCell.alpha = 1
            })
        }
        
        var originY: CGFloat = 0
        for i in 0..<cellsCount {
            let cellData = cellsData[Int(i)]
            let cellRectFromData = cellData.rect
            let cellRect = CGRect(x: cellRectFromData.origin.x,
                                  y: originY,
                                  width: cellRectFromData.size.width,
                                  height: cellRectFromData.size.height)
            cellsData.remove(at: Int(index))
            cellsData.insert(CellData(rect: cellRect, index: i, isValid: i <= index), at: Int(index)) /* all cells below this is invalid */
            originY += cellRectFromData.size.height + indentBetweenCells
        }
        contentView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height:originY);
        scrollView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height);
        scrollView.contentSize = CGSize(width: contentView.frame.size.width, height: contentView.frame.size.height);
        updateVisibleCells()
    }
    
    func removeAllCells() {
        for subview in contentView.subviews {
            guard subview is DynamicTableViewCell else { continue }
            subview.removeFromSuperview()
        }
        visibleCellsData.removeAll()
        cellsData.removeAll()
        cellsIndexForLayout.removeAll()
        cellsCount = 0
    }
}


// MARK: Convinient
private extension DynamicTableView {
    func allVisibleCellsData() -> [CellData] {
        return cellsData(inRect: scrollViewVisibleRect(scrollView))
    }
    
    func scrollViewVisibleRect(_ scrollView: UIScrollView) -> CGRect {
        return CGRect(x: scrollView.contentOffset.x / scrollView.zoomScale,
                      y: scrollView.contentOffset.y / scrollView.zoomScale,
                      width: scrollView.frame.size.width / scrollView.zoomScale,
                      height: scrollView.frame.size.height / scrollView.zoomScale)
    }
}


// MARK: Geometry 
private extension DynamicTableView {
    func cellsData(inRect rect: CGRect) -> [CellData] {
        return intersectsCells(cellsData, withRect: rect)
    }
    
    func visibleCellsData(inRect rect: CGRect) -> [CellData] {
        return intersectsCells(visibleCellsData, withRect: rect)
    }
    
    func intersectsCells(_ cells: [CellData], withRect rect: CGRect) -> [CellData] {
        var result: [CellData] = []
        for cellData: CellData in cells {
            guard rect.intersects(cellData.rect) else { continue }
            result.append(cellData)
        }
        return result.sorted(by: { (lhs, rhs) -> Bool in
            let lhsIndex = lhs.index
            let rhsIndex = rhs.index
            return lhsIndex < rhsIndex
        })
    }
    
    func visibleCellsData(aroundRect rect: CGRect) -> [CellData] {
        var result: [CellData] = visibleCellsData(aboveRect: rect)
        result.append(contentsOf: visibleCellsData(belowRect: rect))
        return result
    }
    
    func visibleCellsData(aboveRect rect: CGRect) -> [CellData] {
        var result: [CellData] = []
        let visibleCellsInRect = cellsData(inRect: rect)
        guard let topVisibleCellInRect: CellData = visibleCellsInRect.first else { return result }
        let allVisibleCells = allVisibleCellsData()
        
        for cellData in allVisibleCells {
            if cellData == topVisibleCellInRect {
                break
            } else {
                result.append(cellData)
            }
        }
        return result.sorted(by: { (lhs, rhs) -> Bool in
            let lhsIndex = lhs.index
            let rhsIndex = rhs.index
            return lhsIndex < rhsIndex
        })
    }
    
    func visibleCellsData(belowRect rect: CGRect) -> [CellData] {
        var result: [CellData] = []
        let visibleCellsInRect = cellsData(inRect: rect)
        guard let lastVisibleCellInRect: CellData = visibleCellsInRect.last else { return result }
        let allVisibleCells = allVisibleCellsData().sorted(by: { (lhs, rhs) -> Bool in
            let lhsIndex = lhs.index
            let rhsIndex = rhs.index
            return lhsIndex > rhsIndex
        }) // descending
        
        for cellData in allVisibleCells {
            if cellData == lastVisibleCellInRect {
                break
            } else {
                result.append(cellData)
            }
        }
        
        return result.sorted(by: { (lhs, rhs) -> Bool in
            let lhsIndex = lhs.index
            let rhsIndex = rhs.index
            return lhsIndex < rhsIndex
        })
    }
    
    func rectForCell(atIndex index: UInt) -> CGRect {
        return cellsData[Int(index)].rect
    }
    
    func cellData(atPoint point: CGPoint) -> CellData {
        let index = cellIndex(atPoint: point)
        return cellsData[Int(index)]
    }
    
    func cellIndex(atPoint point: CGPoint) -> UInt {
        return cell(atPoint: point)?.index ?? UInt.max
    }
    
    func cell(atPoint point: CGPoint) -> DynamicTableViewCell? {
        var result: DynamicTableViewCell?
        let relativePoint: CGPoint = scrollView.convert(CGPoint(x: point.x / self.scrollView.zoomScale, y: point.y / self.scrollView.zoomScale), from: contentView)
        for subview in contentView.subviews {
            guard subview.frame.contains(relativePoint) else { continue }
            result = (subview as! DynamicTableViewCell)
            break
        }
        return result
    }
    
    func cellIsVisible(atIndex index: UInt) -> Bool {
        var result = false
        for cellData in allVisibleCellsData() {
            guard cellData.index == index else { continue }
            result = true
            break
        }
        return result
    }
    
    func visibleCell(atIndex index: UInt) -> DynamicTableViewCell? {
        var result: DynamicTableViewCell?
        for subview in contentView.subviews {
            guard subview is DynamicTableViewCell && (subview as! DynamicTableViewCell).index == index else { continue }
            result = (subview as! DynamicTableViewCell)
            break
        }
        return result
    }
}


// MARK: UIScrollViewDelegate
extension DynamicTableView : UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard floor(scrollView.contentOffset.y) == scrollView.contentOffset.y else { return }
        updateVisibleCells()
    }
}
