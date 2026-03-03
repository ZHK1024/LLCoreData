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
    
    /// 初始化 CoreData 数据模型
    /// - Parameter name: CoreData 模型文件名称 (.xcdatamodeld)
    /// - Returns: NSManagedObjectModel 对象
    static func loadModel(name: String) throws -> NSManagedObjectModel {
        // 如果已缓存则直接返回，避免重复 I/O
        if let model = model {
            return model
        }
        guard let modelURL = Bundle.main.url(forResource: name, withExtension: "momd") else {
            throw "数据库初始化失败: 未找到模型文件" as LLCoreDataError
        }
        guard let loadedModel = NSManagedObjectModel(contentsOf: modelURL) else {
            throw "数据库初始化失败: 数据库对象初始化出错" as LLCoreDataError
        }
        // 写回静态缓存，确保下次直接命中
        model = loadedModel
        return loadedModel
    }
    
    
    /// 初始化 CoreData 存储容器
    ///
    /// 统一使用 `NSPersistentCloudKitContainer`，通过 `useCloudKit` 参数控制是否开启 CloudKit 同步。
    /// - Parameters:
    ///   - name: 本地 Container 名称，即 `.xcdatamodeld` 文件名
    ///   - configuration: `.xcdatamodeld` 文件中 `CONFIGURATION` 名称，为 nil 时使用默认配置
    ///   - containerIdentifier: CloudKit Container 标识符（iCloud.xxx），仅 useCloudKit=true 时有效
    ///   - identifier: AppGroup 标识符，传入时数据库文件存储在 AppGroup 共享目录，支持多进程访问
    ///   - share: 是否同时启用 CloudKit 共享数据库（Shared Database），仅 useCloudKit=true 时生效
    ///   - useCloudKit: 是否开启 CloudKit 同步，默认 false；设为 true 时需同时提供 containerIdentifier
    /// - Throws: 初始化过程中发生的异常
    public static func registContainer(
        name: String,
        configuration: String? = nil,
        cloud containerIdentifier: String? = nil,
        group identifier: String? = nil,
        share: Bool = false,
        useCloudKit: Bool = false
    ) throws {
        let model = try loadModel(name: name)
        // 统一使用 NSPersistentCloudKitContainer，不需要 CloudKit 时不设置 cloudKitContainerOptions 即可
        let container = NSPersistentCloudKitContainer(name: name, managedObjectModel: model)

        // MARK: - 私有数据库配置
        let privateDescription = try persistentStoreDescription(name: name, group: identifier)
        /// 跟踪本地数据变化，多进程场景下用于接收对端写入的变更通知
        privateDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        /// 开启跨进程远程变更推送，App / Widget / Extension 均能感知对方的写入
        privateDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        /// 若指定了 configuration，则绑定到对应的 CONFIGURATION
        if let configuration = configuration {
            privateDescription.configuration = configuration
        }

        if useCloudKit {
            // 开启 CloudKit 同步时必须提供 containerIdentifier
            guard let containerIdentifier = containerIdentifier else {
                throw "CloudKit 初始化失败: 开启 useCloudKit 时必须提供 containerIdentifier" as LLCoreDataError
            }
            /// 设置私有数据库的 CloudKit 选项
            let privateOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: containerIdentifier)
            privateOptions.databaseScope = .private
            privateDescription.cloudKitContainerOptions = privateOptions

            if share {
                // MARK: - 共享数据库配置（useCloudKit=true && share=true）
                let shareDescription = try persistentStoreDescription(name: name, group: identifier, shared: true)
                shareDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                shareDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
                if let configuration = configuration {
                    shareDescription.configuration = configuration
                }
                /// 设置共享数据库的 CloudKit 选项
                let sharedOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: containerIdentifier)
                sharedOptions.databaseScope = .shared
                shareDescription.cloudKitContainerOptions = sharedOptions
                /// 同时加载私有数据库和共享数据库
                container.persistentStoreDescriptions = [privateDescription, shareDescription]
            } else {
                /// 仅加载私有数据库
                container.persistentStoreDescriptions = [privateDescription]
            }
        } else {
            // 不使用 CloudKit：禁用 cloudKitContainerOptions 确保不触发任何 CloudKit 同步
            privateDescription.cloudKitContainerOptions = nil
            container.persistentStoreDescriptions = [privateDescription]
        }

        // MARK: - 加载 Persistent Stores
        // loadPersistentStores 对本地 SQLite Store 是同步调用，CloudKit 后台同步异步进行
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
            /// 记录私有/共享数据库对应的 PersistentStore 引用，供外部区分数据来源
            if let options = storeDescription.cloudKitContainerOptions {
                switch options.databaseScope {
                case .private:
                    shared._privatePersistentStore = container.persistentStoreCoordinator.persistentStore(
                        for: storeDescription.url!
                    )
                case .shared:
                    shared._sharedPersistentStore = container.persistentStoreCoordinator.persistentStore(
                        for: storeDescription.url!
                    )
                case .public:
                    print("[LLCoreData] Public Database loaded")
                @unknown default:
                    print("[LLCoreData] Unknown Database scope")
                }
            }
        }

        // 所有 stores 加载完毕后再对外暴露 container，避免外部在初始化期间访问到未就绪的 context
        shared.persistentContainer = container

        // MARK: - Context 配置
        /// 冲突时以内存中的对象属性为准（适用于多进程并发写入的场景）
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        /// 自动合并来自父 context（backgroundContext）的变更
        container.viewContext.automaticallyMergesChangesFromParent = true
        /// 固定查询版本，保证同一次 fetch 结果一致性
        try container.viewContext.setQueryGenerationFrom(.current)

    }

    /// 主动将本地 CoreData Schema 推送到 CloudKit Development 环境
    ///
    /// **仅限 DEBUG 模式执行**，Release 包中调用此方法为安全空操作，不会产生任何效果。
    ///
    /// 使用时机：
    /// - 首次接入 CloudKit 时调用一次，让 CloudKit 服务端感知数据模型结构
    /// - Model 发生变更（新增/修改 Entity 或 Attribute）后再次调用
    ///
    /// ⚠️ 正式发布前，需要在 [CloudKit Dashboard](https://icloud.developer.apple.com/) 手动将
    /// Development Schema 部署到 Production，之后不要再在生产包中调用本方法。
    ///
    /// - Throws: 未使用 `useCloudKit: true` 初始化时抛出错误；CloudKit Schema 推送失败时抛出原始错误
    public static func initializeCloudKitSchema() throws {
#if DEBUG
        guard let container = shared.persistentContainer as? NSPersistentCloudKitContainer else {
            throw "initializeCloudKitSchema 失败: container 尚未初始化或未开启 useCloudKit" as LLCoreDataError
        }
        /// 打印并上传当前 Schema 到 CloudKit Development 环境
        try container.initializeCloudKitSchema(options: [.printSchema])
#endif
        /// Release 模式下此方法为空操作，编译器会将整个 #if DEBUG 块移除，不留任何调用痕迹
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
        containerURL.appendPathComponent("Library/LLCoreData")
        /// 如果文件夹不存在, 则创建 LLCoreData 文件夹
        let containerPath: String
        if #available(iOS 16.0, *) {
            containerPath = containerURL.path()
        } else {
            containerPath = containerURL.path
        }
        if FileManager.default.fileExists(atPath: containerPath) == false {
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
