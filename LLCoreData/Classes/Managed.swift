//
//  Managed.swift
//  CoreData01
//
//  Created by ZHK on 2020/12/28.
//  
//

import CoreData

public protocol Managed: NSFetchRequestResult {
    
    static var entityName: String { get }
    
    static var sortDescriptors: [NSSortDescriptor] { get }
}

extension Managed where Self: NSManagedObject {
    
    public static var entityName: String {
        return entity().name!
    }
}

extension NSManagedObjectContext {
    
    /// 尝试保存修改 (保存失败则回滚操作)
    /// - Returns: 是否操作成功
    public func saveOrRollback() -> Bool {
        guard hasChanges else { return true }
        do {
            try save()
            return true
        } catch {
            rollback()
            #if DEBUG
            let nserror = error as NSError
            print("Unresolved error \(nserror), \(nserror.userInfo)")
            #endif
            return false
        }
    }
    
    /// 执行并保存修改
    /// - Parameter block: 执行逻辑
    public func performChanages(block: @escaping () -> ()) {
        perform {
            block()
            _ = self.saveOrRollback()
        }
    }
}

extension NSManagedObject {
    
    /// 更新对象
    /// - Parameter mergeChanges: 是否合并修改
    public func refresh(mergeChanges: Bool = true) {
        managedObjectContext?.refresh(self, mergeChanges: mergeChanges)
    }
}
