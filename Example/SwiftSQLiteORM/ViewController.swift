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
    let index: Int
    let location: [String]
    
    typealias ORMKey = TableKey
    
    enum TableKey: String, DBTableKey {
        case name
        case index
        case location
    }
    
    static var primaryKey: TableKey? {
        return .name
    }
    
    static var tableVersion: Double {
        return 0.001
    }
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //DBWrapper.createTable(ABC.self)
        //let a = ABC(name: "b", index: 1)
        let a = ABC(name: "c", index: 2, location: ["xixi"])
        do {
            try DBMgnt.push([a])
            let array = try DBMgnt.fetch(ABC.self, .eq(.index, 1))
            NSLog("fetch array: \(array)")
        } catch {
            NSLog("failed to operate db: \(error.localizedDescription)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
