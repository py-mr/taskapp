//
//  Draft.swift
//  taskapp
//
//  Created by A I on 2023/11/13.
//

//import Foundation


import RealmSwift
//Realmの基本クラスである Object を継承して、Task クラスを作成
class Draft: Object {
    // 管理用 ID。プライマリーキー
    @Persisted(primaryKey: true) var id: ObjectId

    // タイトル
    @Persisted var title = ""

    // 内容
    @Persisted var contents = ""

    // 日時
    @Persisted var date = Date()
    
    //カテゴリ
    @Persisted var category:String = ""

}
