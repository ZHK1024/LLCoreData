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
    
    /// Conatiner (数据堆栈的容器)
    public static var container: NSPersistentContainer {
        shared.persistentContainer
    }
    
    /// 初始化 CoreData
    /// - Parameter name: Container 名称
    public static func registContainer(name: String, with groupIdentifier: String? = nil) {
        shared.persistentContainer = NSPersistentContainer(name: name)
        _ = shared.configGroupStoreDescription(name: name, groupIdentifier: groupIdentifier)
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
    public static func registContainer(name: String, use cloudKit: Bool, with groupIdentifier: String? = nil) {
        if cloudKit {
            shared.persistentContainer = NSPersistentCloudKitContainer(name: name)
        } else {
            shared.persistentContainer = NSPersistentContainer(name: name)
        }
        _ = shared.configGroupStoreDescription(name: name, groupIdentifier: groupIdentifier)
        shared.persistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
            #if DEBUG
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            #endif
        })
        
        shared.persistentContainer.newBackgroundContext()
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

extension LLCoreData {
    
    /// 配置存储容器的 AppGroup 信息
    /// - Parameters:
    ///   - name: 数据库文件名
    ///   - groupIdentifier: AppGroup 标识符
    /// - Returns: 是否配置成功
    private func configGroupStoreDescription(name: String, groupIdentifier: String?) -> Bool {
        guard let identifier = groupIdentifier,
              var containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) else {
            return false
        }
        /// 拼接 LLCoreData 文件夹路径
        containerURL.appendPathComponent("LLCoreData")
        /// 如果文件夹不存在, 则创建 LLCoreData 文件夹
        if FileManager.default.fileExists(atPath: containerURL.absoluteString) == false {
            do {
                try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true, attributes: [:])
            } catch {
                #if DEBUG
                print(error)
                #endif
                return false
            }
        }
        /// 拼接数据库文件路径
        containerURL.appendPathComponent("\(name).sqlite")
        #if DEBUG
        print(containerURL)
        #endif
        persistentContainer.persistentStoreDescriptions = [NSPersistentStoreDescription(url: containerURL)]
        return true
    }
}
