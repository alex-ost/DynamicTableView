//
//  HomeViewController.swift
//  DynamicTableView
//
//  Created by Alexandr Ostrynskyi on 4/8/17.
//  Copyright © 2017 Alexandr Ostrynskyi. All rights reserved.
//

import UIKit
import DynamicTableView

class HomeViewController: UIViewController {

    // MARK: Vars
    var currentDataType: DataType = .text {
        didSet {
            reloadAction(nil)
        }
    }
    
    let dataSource: DataSource = DataSource()
    
    private let numberFormatter: NumberFormatter = {
        return NumberFormatter()
    }()
    
    // MAR: Outlets
    @IBOutlet weak var zoomLabel: UILabel!
    @IBOutlet weak var dynamicTableView: DynamicTableView!
    @IBOutlet weak var zoomSlider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dynamicTableView.delegate = self
        dynamicTableView.dataSource = self
        
        dynamicTableView.indentBetweenCells = 10
        dynamicTableView.scrollView.minimumZoomScale = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadAction(nil)
    }
    
    // MARK: Actions
    @IBAction func reloadAction(_ sender: Any?) {
        fixZoomAction(sender)
        dynamicTableView.reloadData()
    }
    
    @IBAction func fixZoomAction(_ sender: Any?) {
        dynamicTableView.scrollView.zoomScale = 1
        zoomSlider.value = 1
        self.zoomLabel.text = "Zoom: 1"
    }
    
    @IBAction func dataTypeChanged(_ sender: UISegmentedControl) {
        currentDataType = DataType(rawValue: sender.selectedSegmentIndex)!
    }
    
    @IBAction func zoomSliderAction(_ sender: UISlider) {
        let value = CGFloat(sender.value)
        dynamicTableView.scrollView.zoomScale = value
        self.zoomLabel.text = "Zoom: \(String(format: "%.2f", value))"
    }
}


// MARK: DynamicTableViewDelegate
extension HomeViewController: DynamicTableViewDelegate {
    // Height
    func heightForCell(_ tableView: DynamicTableView, atIndex index: UInt) -> CGFloat {
        switch currentDataType {
        case .text:
            return 200
        case .localImage:
            return tableView.frame.size.height
        case .networkImage:
            return tableView.frame.size.height
        }
    }
    
    // Display
    func willDisplayCell(_ tableView: DynamicTableView, cell: DynamicTableViewCell, atIndex index: UInt) {
        switch currentDataType {
        case .text:
            break
        case .localImage:
            break
        case .networkImage:
            let castedImageCell = cell as! DynamicTableViewImageCell
            castedImageCell.activityIndicator.startAnimating()
            dataSource.loadItem(atIndex: index, forDataType: currentDataType, withCompletion: { (dataContainer) in
                castedImageCell.activityIndicator.stopAnimating()
                castedImageCell.imageView.image = (dataContainer.data as? UIImage) ?? UIImage(named: "noData")
            })
            break
        }
    }
    
    func didDisplayCell(_ tableView: DynamicTableView, cell: DynamicTableViewCell, atIndex index: UInt) {
    }
    
    func didEndDisplayCell(_ tableView: DynamicTableView, cell: DynamicTableViewCell, atIndex index: UInt) {
        switch currentDataType {
        case .text:
            break
        case .localImage:
            break
        case .networkImage:
            dataSource.cancelLoadItem(atIndex: index, forDataType: currentDataType)
            break
        }
    }
}

// MARK: DynamicTableViewDataSource
extension HomeViewController: DynamicTableViewDataSource {
    func numberOfItemsInTableView(_ tableView: DynamicTableView) -> UInt {
        return dataSource.numberOfItemsForType(currentDataType)
    }
    
    func cellView(_ tableView: DynamicTableView, forItemAtIndex index: UInt) -> DynamicTableViewCell{
        var cell: DynamicTableViewCell!
        switch currentDataType {
        case .text:
            let textCell = UINib(nibName: "DynamicTableViewTextCell", bundle: nil).instantiate(withOwner: nil, options: nil).first as! DynamicTableViewTextCell
            dataSource.loadItem(atIndex: index, forDataType: currentDataType, withCompletion: { (dataContainer) in
                textCell.textView.text = dataContainer.data as! String
            })
            cell = textCell
            break
        case .localImage:
            let imageCell = UINib(nibName: "DynamicTableViewImageCell", bundle: nil).instantiate(withOwner: nil, options: nil).first as! DynamicTableViewImageCell
            dataSource.loadItem(atIndex: index, forDataType: currentDataType, withCompletion: { (dataContainer) in
                imageCell.imageView.image = (dataContainer.data as? UIImage) ?? UIImage(named: "noData")
            })
            cell = imageCell
            break
        case .networkImage:
            cell = UINib(nibName: "DynamicTableViewImageCell", bundle: nil).instantiate(withOwner: nil, options: nil).first as! DynamicTableViewImageCell
            // Data load logic in will display and end display.
            break
        }
        return cell
    }
}

