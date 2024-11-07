//
//  ViewController.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 11/05/2024.
//  Copyright (c) 2024 lalawue. All rights reserved.
//

import UIKit
import SwiftSQLiteORM

struct ABC: DBTableDef {
    
    let name: String
    
    typealias ORMKey = TableKey
    
    enum TableKey: String, DBTableKey {
        case name
    }
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //DBWrapper.createTable(ABC.self)
        NSLog("names: '\(ABC.tableName)'")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
