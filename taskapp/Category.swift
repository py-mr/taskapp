//
//  Category.swift
//  taskapp
//
//  Created by A I on 2023/11/23.
//

//import Foundation
import RealmSwift

//Realmの基本クラスである Object を継承して、Category クラスを作成
class Category: Object {
    // 管理用 ID。プライマリーキー
    @Persisted(primaryKey: true) var id: ObjectId
    
    //カテゴリ名
    @Persisted var categoryName:String = ""

}
