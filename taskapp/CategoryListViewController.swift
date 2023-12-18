//
//  CategoryListViewController.swift
//  taskapp
//
//  Created by A I on 2023/11/30.
//

import UIKit
import RealmSwift

class CategoryListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var categoryAddButton: UIButton!
    var parentInputCategoryViewController: InputViewController?
    var parentViewCategryViewController:ViewController?
    
    // Realmインスタンスを生成し、それをrealmに入れる
    let realm = try! Realm()
    
    //チェックがついたカテゴリの配列
    var nameArray:[String] = []
    
    // DB内のタスクが格納されるリスト。（Realmクラスのobjects(_:)メソッドでクラス（「型名.self」で型そのものを変数に入れて扱える。）を指定して一覧を取得）
    // 名前順でソート：昇順（sorted(byKeyPath:ascending:)メソッド）
    // 以降内容をアップデートするとリスト内は自動的に更新される。
    var categoryArray = try! Realm().objects(Category.self).sorted(byKeyPath: "categoryName", ascending: true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationItem.title = "カテゴリ一覧"
        
        //テーブルビュー
        tableView.fillerRowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor(displayP3Red: 247/255, green: 242/255, blue: 224/255,alpha: 1.0)
        
        //カテゴリ選択ボタン
        categoryAddButton.layer.masksToBounds = true
        categoryAddButton.layer.cornerRadius = 30.0
    }
    
    // データの数（＝セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categoryArray.count
    }
    
    // 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能な cell を得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)
        
        cell.contentView.backgroundColor = UIColor.clear
        cell.backgroundColor = UIColor.clear
        
        // Cellに値を設定する
        let category = categoryArray[indexPath.row]
        cell.textLabel?.text = category.categoryName
        cell.detailTextLabel?.text = nil
        cell.selectionStyle = .none
        
        //numberArrayをもってきて、選択されているものには.checkmark
        //forEach：高階関数　配列の中をあげて繰り返し処理するもの
        //TableViewの内容決定の時に下記決定する必要がある。viewDidLoadに記載すると、TableViewメソッドの前に呼ばれてしまうかもしれないので。
        //nameArrayの中にcategoryArray[0...10(=indexPath.row)]があったら、
        //そのcellに対してcell.accessoryType = .checkmarkをする。
        if nameArray.contains(category.categoryName) {
            cell.accessoryType = .checkmark
        //チェックがついたcellが再利用されるかもしれないから、明示的にチェックを外す必要がある
        } else {
            cell.accessoryType = .none
        }
        return cell
    }

    // 各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        //選択したセルにチェックマークが無い場合
        if(cell?.accessoryType == UITableViewCell.AccessoryType.none){
            cell?.accessoryType = .checkmark
            //チェックマークがついたセルの番号を取得
            //numberArray += [indexPath.row]
            //チェックマークがついたセルの名前を取得
            nameArray += [categoryArray[indexPath.row].categoryName]
        //選択したセルにチェックマークがある場合
        }else{
            cell?.accessoryType = .none
            //numberArray.removeAll(where: {$0 == indexPath.row})
            nameArray.removeAll(where: {$0 == categoryArray[indexPath.row].categoryName})
        }
    }
    
    //CategoryCreate画面から戻って来た時に、TableViewを更新させる。
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    //viewWillDisappear(_:)メソッドは遷移する際に、画面が非表示になるとき呼ばれるメソッド
    //（追加）画面が非表示になるときはanimatedのみ
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //★input画面に遷移するタイミングでnameArrayを渡したい。
        if isMovingFromParent {
            //numberArray.sort()
            nameArray.sort()
            //parentInputCategoryViewController?.categoryNumSelected = numberArray
            parentInputCategoryViewController?.categorySelected = nameArray
            //★デリゲートをつくる？
            //parentViewCategryViewController?.categoryNumFilter = numberArray
            parentViewCategryViewController?.categoryFilter = nameArray
        } else {
            //★子画面に行く時：画面遷移が終わろうとしている時なので遅い。prepareで
        }

    }

}
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */


