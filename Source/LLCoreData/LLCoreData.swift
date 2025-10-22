//
//  LLCoreData.swift
//  LLCoreData
//
//  Created by ZHK on 2021/01/05.
//
//

import CoreData
import CloudKit

open class LLCoreData: NSObject {
    
    /// 单利对象
    public static let shared = LLCoreData()
    
    /// 数据模型对象
    private static var model: NSManagedObjectModel?
    
    /// 存储容器对象
    private var persistentContainer: NSPersistentContainer?
    
    /// 上下文对象
    public static var context: NSManagedObjectContext {
        shared.persistentContainer!.viewContext
    }
    
    /// Conatiner (数据堆栈的容器)
    public static var container: NSPersistentContainer {
        shared.persistentContainer!
    }
    
    /// CloudKit 的 Container, 用来获取 CoreData 在 CloudKit 中的容器
    /// 方便获取 CoreData 记录对应的 CKRecord 对象
    public static var cloudContainer: NSPersistentCloudKitContainer? {
        return shared.persistentContainer as? NSPersistentCloudKitContainer
    }

    fileprivate var _privatePersistentStore: NSPersistentStore?
    static var privatePersistentStore: NSPersistentStore? {
        return shared._privatePersistentStore
    }

    fileprivate var _sharedPersistentStore: NSPersistentStore?
    public static var sharedPersistentStore: NSPersistentStore? {
        return shared._sharedPersistentStore
    }

//    var context: NSManagedObjectContext {
//        persistentContainer.viewContext
//    }
    
    public static func reset() {
        guard let container = shared.persistentContainer else { return }
            
        // 移除所有存储
        for store in container.persistentStoreCoordinator.persistentStores {
            do {
                try container.persistentStoreCoordinator.remove(store)
            } catch {
                print("Failed to remove persistent store: \(error)")
            }
        }
        
        /// 清理所有引用
        shared.persistentContainer = nil
        shared._privatePersistentStore = nil
        shared._sharedPersistentStore = nil
    }
    
    /// 初始化 CoreData
    /// - Parameter name: Container 名称
    static func loadModel(name: String) throws -> NSManagedObjectModel {
        if let model = model {
            return model
        }
        guard let modelURL = Bundle.main.url(forResource: name, withExtension: "momd") else {
            throw "数据库初始化失败: 未找到模型文件" as LLCoreDataError
        }

        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            throw "数据库初始化失败: 数据库对象初始化出错" as LLCoreDataError
        }
        return model
    }
    
    
    /// 初始化 CoreData
    /// - Parameters:
    ///   - name: 本地 Container 名称 (.xcdatamodeld 名称)
    ///   - identifier: AppGroup 标识符
    /// - Throws: 异常信息
    public static func registContainer(name: String, group identifier: String? = nil) throws {
        let model = try loadModel(name: name)
        let container = NSPersistentContainer(name: name, managedObjectModel: model)
        /// 创建 NSPersistentStoreDescription 对象
        let description = try persistentStoreDescription(name: name, group: identifier)
        /// 跟踪本地数据变化 (用于更新视图)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description.configuration = "iCloud"
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
//            #if DEBUG
            if let error = error as NSError? {
                print(error)
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
//            #endif
        })
        
        shared.persistentContainer = container
    }
    
    /// 初始化 CoreData
    /// - Parameters:
    ///   - name: 本地 Container 名称 (.xcdatamodeld 名称)
    ///   - configuration: `.xcdatamodeld` 文件中 `CONFIGURATION` 名称
    ///   - containerIdentifier: CloudKit Container 标识符
    ///   - identifier: AppGroup 标识符
    @available(iOS 13.0, *)
    public static func registContainer(name: String, configuration: String, cloud containerIdentifier: String, group identifier: String? = nil, share: Bool = false) throws {
        let model = try loadModel(name: name)
        let container = NSPersistentCloudKitContainer(name: name, managedObjectModel: model)
        shared.persistentContainer = container

        /// 创建 NSPersistentStoreDescription 对象
        let privateDescription = try persistentStoreDescription(name: name, group: identifier)
        /// configuration (对应 .xcdatamodeld 中 CONFIGURATION 名称)
        privateDescription.configuration = configuration
        /// 跟踪本地数据变化 (用于更新视图)
        privateDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        /// 远程数据变化推送通知
        privateDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        /// 设置 CloudKit 标识符
        let options = NSPersistentCloudKitContainerOptions(containerIdentifier: containerIdentifier)
        /// import CloudKit 之后 `databaseScope` 才能生效
        options.databaseScope = .private
        privateDescription.cloudKitContainerOptions = options
        
        if share {
            /// 初始化共享数据库配置信息
            let shareDescription = try persistentStoreDescription(name: name, group: identifier, shared: true)
            /// 跟踪本地数据变化 (用于更新视图)
            shareDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            /// 远程数据变化推送通知
            shareDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            let sharedOption = NSPersistentCloudKitContainerOptions(containerIdentifier: containerIdentifier)
            sharedOption.databaseScope = .shared
            shareDescription.configuration = configuration
            shareDescription.cloudKitContainerOptions = sharedOption
            /// 添加 `共享数据库` 和 `私有数据库` 配置
            container.persistentStoreDescriptions = [privateDescription, shareDescription]
            
        } else {
            /// 添加 `私有数据库` 配置
            container.persistentStoreDescriptions = [privateDescription]
        }

        /// 加载容器
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                fatalError("Unresolved error \(error)")
            } else if let options = storeDescription.cloudKitContainerOptions {
                switch options.databaseScope {
                case .private:
                    shared._privatePersistentStore = container.persistentStoreCoordinator.persistentStore(
                        for: storeDescription.url!
                    )
                case .public:
                    print("Public Database")
                case .shared:
                    shared._sharedPersistentStore = container.persistentStoreCoordinator.persistentStore(
                        for: storeDescription.url!
                    )
                @unknown default:
                    print("Unknown Database")
                }
            }
        })
        
        /// 主动把本地的 Model 同步到远程服务器
        /// 如果不调用的话, 在首次创建对应 Model 实例并同步成功才会把 Model 同步到远端服务器
        /// 只在测试时候使用. 在正式环境中不要调用
        /// 正式环境的 Schema 由手动去 CloudKit Dashboard 中同步到正式服务器
#if DEBUG
//        try container.initializeCloudKitSchema(options: [.printSchema])
#endif
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
    ///   - shared: 是否共享数据库
    /// - Throws: 异常信息
    /// - Returns: NSPersistentStoreDescription 对象
    private static func persistentStoreDescription(name: String, group identifier: String?, shared: Bool = false) throws -> NSPersistentStoreDescription {
        var containerURL: URL
        /// 如果传入 identifier 则在 AppGroup Container 内创建数据存储目录
        /// 否则在 Library 下创建数据存储目录
        if let group = identifier {
            guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else {
                throw "ContainerURL init failed!" as LLCoreDataError
            }
            containerURL = url
        } else {
            containerURL = URL(fileURLWithPath: NSHomeDirectory())
        }
        
        /// 拼接 LLCoreData 文件夹路径
        containerURL.appendPathComponent("/Library/LLCoreData")
        /// 如果文件夹不存在, 则创建 LLCoreData 文件夹
        if FileManager.default.fileExists(atPath: containerURL.absoluteString) == false {
            try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true, attributes: [:])
        }
        if shared {
            /// 拼接共享数据库文件路径
            containerURL.appendPathComponent("Shared_\(name).store")
        } else {
            /// 拼接私有数据库文件路径
            containerURL.appendPathComponent("\(name).store")
        }
        #if DEBUG
        print("containerURL: ", containerURL ?? "Is nil")
        #endif
        let description = NSPersistentStoreDescription(url: containerURL)
        return description
    }
}
