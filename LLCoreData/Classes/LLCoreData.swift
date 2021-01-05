//
//  LLCoreData.swift
//  LLCoreData
//
//  Created by ZHK on 2021/01/05.
//
//

import CoreData

open class LLCoreData: NSObject {
    
    /// 单利对象
    public static let shared = LLCoreData()
    
    /// 存储容器对象
    private var persistentContainer: NSPersistentContainer!
    
    /// 上下文对象
    public static var context: NSManagedObjectContext {
        shared.persistentContainer.viewContext
    }
    
    /// 初始化 CoreData
    /// - Parameter name: Container 名称
    public static func registContainer(name: String) {
        shared.persistentContainer = NSPersistentContainer(name: name)
        shared.persistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
            #if DEBUG
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            #endif
        })
    }
    
    
    /// 初始化 CoreData
    /// - Parameters:
    ///   - name: Container 名称
    ///   - cloudKit: 是否使用 CloudKit
    @available(iOS 13.0, *)
    public static func registContainer(name: String, use cloudKit: Bool) {
        if cloudKit {
            shared.persistentContainer = NSPersistentCloudKitContainer(name: name)
        } else {
            shared.persistentContainer = NSPersistentContainer(name: name)
        }
        shared.persistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
            #if DEBUG
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            #endif
        })
    }
    
    /// 尝试保存修改, 如果保存失败则回滚
    public static func saveOrRollback () -> Bool {
        guard context.hasChanges else { return true }
        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            return false
        }
    }
}
