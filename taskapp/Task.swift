//Realmのモデル（データを表現するもの）クラス（Realmの基本クラスであるObjectを継承してTaskクラスを作成）
//
//  Task.swift
//  taskapp
//
//  Created by A I on 2023/10/03.
//

//import Foundation

import RealmSwift

//Realmの基本クラスである Object を継承して、Task クラスを作成
class Task: Object {
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
