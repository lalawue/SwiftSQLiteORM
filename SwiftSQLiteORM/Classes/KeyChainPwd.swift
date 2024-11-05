//
//  KeyChainPwd.swift
//
//  Created by lalawue on 2024/11/05.
//

import Foundation
import LocalAuthentication

fileprivate let _FrameworkAccountName = "SwiftSQLiteORM.Framework"

enum KeyChainPwdData {
    
    static func getPwdString() -> String? {
        let access = SecAccessControlCreateWithFlags(nil,
                                                     kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                     .userPresence,
                                                     nil)
        
        let context = LAContext()
        context.touchIDAuthenticationAllowableReuseDuration = 300
        
        let query: [String : Any] = [kSecClass as String: kSecClassGenericPassword,
                                     kSecAttrAccount as String: _FrameworkAccountName,
                                     kSecAttrAccessControl as String: access as Any,
                                     kSecUseAuthenticationContext as String: context,
                                     kSecMatchLimit as String: kSecMatchLimitOne,
                                     kSecReturnAttributes as String: true,
                                     kSecReturnData as String: true]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {            
            return nil
        }

        guard let existingItem = item as? [String: Any] else {
              let account = existingItem[kSecAttrAccount as String] as? String,
              account == Self.frameworkAccountName,
              let pdata = existingItem[kSecValueData as String] as? Data,
              let pstr = String(data: pdata, encoding: .utf8) else {
            return nil
        }
        
        return pstr
    }
    
    func storePwdString(_ pstr: String) -> Bool {
        guard let pdata = pstr.data(using: .utf8) else {
            return false
        }
        
        let access = SecAccessControlCreateWithFlags(nil,
                                                     kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                     .userPresence,
                                                     nil)
        
        let context = LAContext()
        context.touchIDAuthenticationAllowableReuseDuration = 300
        
        let query: [String : Any] = [kSecClass as String: kSecClassGenericPassword,
                                     kSecAttrAccount as String: _FrameworkAccountName,
                                     kSecAttrAccessControl as String: access as Any,
                                     kSecUseAuthenticationContext as String: context,
                                     kSecValueData as String: pdata]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            return false
        }
        return true
    }
}
