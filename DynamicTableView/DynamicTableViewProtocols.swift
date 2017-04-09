//
//  DynamicTableViewProtocols.swift
//  DynamicTableView
//
//  Created by Alexandr Ostrynskyi on 4/8/17.
//  Copyright © 2017 Alexandr Ostrynskyi. All rights reserved.
//

import UIKit

@objc public protocol DynamicTableViewDelegate: class {
    // Height
    @objc optional func heightForCell(_ tableView: DynamicTableView, atIndex index: UInt) -> CGFloat
    
    // Display
    @objc optional func willDisplayCell(_ tableView: DynamicTableView, cell: DynamicTableViewCell, atIndex index: UInt)
    @objc optional func didDisplayCell(_ tableView: DynamicTableView, cell: DynamicTableViewCell, atIndex index: UInt)
    @objc optional func didEndDisplayCell(_ tableView: DynamicTableView, cell: DynamicTableViewCell, atIndex index: UInt)
}

public protocol DynamicTableViewDataSource: class {
    func numberOfItemsInTableView(_ tableView: DynamicTableView) -> UInt
    func cellView(_ tableView: DynamicTableView, forItemAtIndex index: UInt) -> DynamicTableViewCell
}
