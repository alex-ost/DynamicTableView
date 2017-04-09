//
//  DataSource.swift
//  DynamicTableViewExample
//
//  Created by Alexandr Ostrynskyi on 4/9/17.
//  Copyright © 2017 Alexandr Ostrynskyi. All rights reserved.
//

import UIKit

enum DataType: Int {
    case text, localImage, networkImage
    
    var key: String {
        switch self {
        case .text:
            return "Text"
        case .localImage:
            return "Local Images"
        case .networkImage:
            return "Image URLs"
        }
    }
}

struct DataContainer {
    let data : Any?
}

class DataSource {
    
    // MARK: Private var
    private var dataInfo: [String: AnyObject] = {
        if let path = Bundle.main.path(forResource: "DataInfo", ofType: "plist") {
            return NSDictionary(contentsOfFile: path) as! [String : AnyObject]
        }
        return [:]
    }()
    
    private var dataTasks: [UInt: URLSessionDataTask] = [:]
    
    // MARK: Public
    func numberOfItemsForType(_ dataType: DataType) -> UInt {
        return UInt(dataArrayForType(dataType).count)
    }
    
    func loadItem(atIndex index: UInt, forDataType dataType: DataType, withCompletion completion: @escaping ((DataContainer) -> Void)) {
        switch dataType {
        case .text:
            let dataArray = dataArrayForType(.text)
            let dataContainer = DataContainer(data: dataArray[Int(index)])
            completion(dataContainer)
            break
        case .localImage:
            let dataArray = dataArrayForType(.localImage)
            let imageName = dataArray[Int(index)]
            let dataContainer = DataContainer(data: UIImage(named: imageName))
            completion(dataContainer)
            break
        case .networkImage:
            performLoadData(atIndex: index, forDataType: dataType, withCompletion: { (data) in
                let dataContainer: DataContainer!
                if let data = data {
                    dataContainer = DataContainer(data: UIImage(data: data))
                } else {
                    dataContainer = DataContainer(data: nil)
                }
                completion(dataContainer)
            })
            break
        }
    }
    
    func cancelLoadItem(atIndex index: UInt, forDataType dataType: DataType) {
        switch dataType {
        case .text:
            break // Ignore because it's local data.
        case .localImage:
            break // Ignore because it's local data.
        case .networkImage:
            DispatchQueue.main.async {
                let dataTask: URLSessionDataTask? = self.dataTasks[index]
                dataTask?.cancel()
            }
            break
        }
    }
    
    func insert(item: DataContainer, atIndex index: UInt, forDataType dataType: DataType) {
        var array = dataArrayForType(dataType)
        array.insert(item.data! as! String, at: Int(index))
        self.dataInfo[dataType.key] = array as AnyObject?
    }
    
    func remove(itemAtIndex index: UInt, forDataType dataType: DataType) {
        var array = dataArrayForType(dataType)
        array.remove(at: Int(index))
        self.dataInfo[dataType.key] = array as AnyObject?
    }
    
    // MARK: Helpers
    private func dataArrayForType(_ dataType: DataType) -> [String] {
        switch dataType {
        case .text:
            return self.dataInfo[DataType.text.key] as! [String]
        case .localImage:
            return self.dataInfo[DataType.localImage.key] as! [String]
        case .networkImage:
            return self.dataInfo[DataType.networkImage.key] as! [String]
        }
    }
    
    private func performLoadData(atIndex index: UInt, forDataType dataType: DataType, withCompletion completion: @escaping ((Data?) -> Void)) {
        let dataArray = dataArrayForType(dataType)
        let imageURL = dataArray[Int(index)]
        if let url = URL(string: imageURL) {
            let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
                DispatchQueue.main.async {
                    self.dataTasks.removeValue(forKey: index)
                    completion(data)
                }
            }
            dataTasks[index] = dataTask
            dataTask.resume()
        } else {
            completion(nil)
        }
    }
}
