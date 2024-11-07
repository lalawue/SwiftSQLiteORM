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
    
    private enum TableKeys: String, DBTableKeys {
        case name
    }
    
    static var tableKeys: any DBTableKeys.Type {
        return Self.TableKeys.self
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

