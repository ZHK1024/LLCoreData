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
    
    
    /// 初始化 CoreData
    /// - Parameters:
    ///   - name: 本地 Container 名称 (.xcdatamodeld 名称)
    ///   - identifier: AppGroup 标识符
    /// - Throws: 异常信息
    public static func registContainer(name: String, group identifier: String? = nil) throws {
        let container = NSPersistentContainer(name: name)
        shared.persistentContainer = container
        /// 创建 NSPersistentStoreDescription 对象
        let description = try persistentStoreDescription(name: name, group: identifier)
        /// 跟踪本地数据变化 (用于更新视图)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            #if DEBUG
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            #endif
        })
    }
    
    /// 初始化 CoreData
    /// - Parameters:
    ///   - name: 本地 Container 名称 (.xcdatamodeld 名称)
    ///   - configuration: `.xcdatamodeld` 文件中 `CONFIGURATION` 名称
    ///   - containerIdentifier: CloudKit Container 标识符
    ///   - identifier: AppGroup 标识符
    @available(iOS 13.0, *)
    public static func registContainer(name: String, configuration: String, cloud containerIdentifier: String, group identifier: String? = nil) throws {
        let container = NSPersistentCloudKitContainer(name: name)
        shared.persistentContainer = container

        /// 创建 NSPersistentStoreDescription 对象
        let description = try persistentStoreDescription(name: name, group: identifier)
        /// configuration (对应 .xcdatamodeld 中 CONFIGURATION 名称)
        description.configuration = configuration
        /// 跟踪本地数据变化 (用于更新视图)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        /// 远程数据变化推送通知
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        /// 设置 CloudKit 标识符
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: containerIdentifier)
        container.persistentStoreDescriptions = [description]
        
        /// 加载容器
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            #if DEBUG
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            #endif
        })
        /// 主动把本地的 Model 同步到远程服务器
        /// 如果不调用的话, 在首次创建对应 Model 实例并同步成功才会把 Model 同步到远端服务器
//        try container.initializeCloudKitSchema(options: [.printSchema])
        
        /// `viewContext` 需要在 `loadPersistentStores` 之后调用
        /// 设置数据合并方式
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        try container.viewContext.setQueryGenerationFrom(.current)
    }
    
    /// 尝试保存修改, 如果保存失败则回滚
    @discardableResult
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
    
    /// 创建 NSPersistentStoreDescription 对象
    /// - Parameters:
    ///   - name: 数据库文件名称
    ///   - identifier: AppGroup 标识符
    /// - Throws: 异常信息
    /// - Returns: NSPersistentStoreDescription 对象
    private static func persistentStoreDescription(name: String, group identifier: String?) throws -> NSPersistentStoreDescription {
        var containerURL: URL!
        /// 如果传入 identifier 则在 AppGroup Container 内创建数据存储目录
        /// 否则在 Library 下创建数据存储目录
        if let group = identifier {
            guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else {
                throw "ContainerURL init failed!" as LLCoreDataError
            }
            containerURL = url
        } else {
            containerURL = URL(fileURLWithPath: NSHomeDirectory() + "/Library")
        }
        
        /// 拼接 LLCoreData 文件夹路径
        containerURL.appendPathComponent("LLCoreData")
        /// 如果文件夹不存在, 则创建 LLCoreData 文件夹
        if FileManager.default.fileExists(atPath: containerURL.absoluteString) == false {
            try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true, attributes: [:])
        }
        /// 拼接数据库文件路径
        containerURL.appendPathComponent("\(name).store")
        #if DEBUG
        print(containerURL ?? "containerURL is nil")
        #endif
        let description = NSPersistentStoreDescription(url: containerURL)
        return description
    }
}
