//
//  ViewController.swift
//  taskapp
//
//  Created by A I on 2023/09/29.
//

import UIKit
import RealmSwift   // Realmを使うために追加
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchFilterButton: UIButton!
    
    //★子（CategoryListView）から親（View）へ値を渡す
    var categoryNumFilter: [Int] = []
    var categoryFilter: [String] = []
    var categoryListViewController: CategoryListViewController?
    
    // Realmインスタンスを生成し、それをrealmに入れる
    let realm = try! Realm()
    
    // DB内のタスクが格納されるリスト。（Realmクラスのobjects(_:)メソッドでクラス（「型名.self」で型そのものを変数に入れて扱える。）を指定して一覧を取得）
    // 日付の近い順でソート：昇順（sorted(byKeyPath:ascending:)メソッド）
    // 以降内容をアップデートするとリスト内は自動的に更新される。taskArray＝DBに入っているデータのリストが入っている。
    //検索バーに何か入力されていれば、その値が含まれるカテゴリのタスクを、何も記載がなければタスク全てををtaskArrayリストへ代入。
    var taskArray: Results<Task> {
        if (searchBar.text != "") {
            
            let searchParameters = searchBar.text!.split(separator: ",")
            var getList: Results<Task>
            
            getList = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
            for searchParam in searchParameters {
                getList = getList.filter("category CONTAINS %@", searchParam)
            }
            return getList
        } else {
            return try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
        }
    }
    //DB内のドラフトタスクが格納されるリスト。
    var draftArray = try! Realm().objects(Draft.self)
    //DB内のカテゴリが格納されるリスト。
    var categoryArray = try! Realm().objects(Category.self)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //ナビゲーションバーの表示
        navigationItem.title = "一覧"
        
        //絞り込みボタンのデザイン
        searchFilterButton.layer.borderColor = UIColor(displayP3Red: 4/255, green: 99/255, blue: 128/255,alpha: 1.0).cgColor
        searchFilterButton.layer.borderWidth = 1.0
        searchFilterButton.layer.cornerRadius = 10

        //テーブルビュー
        //データを表示していない部分に罫線を表示。行の高さは自動で決まる。
        tableView.fillerRowHeight = UITableView.automaticDimension
        //テーブルビューの背景色を指定
        tableView.backgroundColor = UIColor(displayP3Red: 247/255, green: 242/255, blue: 224/255,alpha: 1.0)
        //UITableViewDelegateやUITableViewDataSourceに、tableViewのデリゲートメソッドが定義されている。
        //tableViewのデリゲートメソッドを実装しているのはself(ViewController)だと教えている（子から親を呼び出している）。
        //ここではtableViewが持っている、dataSourceとdelegateのプロパティが、
        //それぞれUITableViewDelegate型とUITableViewDataSource型のインスタンスを要求している。 
        tableView.delegate = self
        tableView.dataSource = self
        
        //デリゲート先を自分に設定
        searchBar.delegate = self
        //何も入力されていなくてもReturnキーを押せるようにする
        searchBar.enablesReturnKeyAutomatically = false
        //UISearchbarの背景に空のUIImageをセットする
        searchBar.backgroundImage = UIImage()
        
        // 背景をタップしたらdismissKeyboardメソッドを呼ぶように設定する
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    // データの数（＝セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //taskArray＝DBに入っているデータのリストが入っている。この数を返す。
        return taskArray.count
    }
    
    // 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能な cell を得る：Cell（画面の外にいったcellを再利用する）を再利用可能にしたものをcellに入れる
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        //背景色を透明にする
        cell.backgroundColor = UIColor.clear
        //これでセルをタップ時、色は変化しなくなる
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        
        //Cellに値を設定する
        //taskArray＝DBに入っているデータの配列をtaskに入れる。
        let task = taskArray[indexPath.row]
        //そのtaskのtitleを、cellのtextLabelのtextに入れる。
        cell.textLabel?.text = task.title
        
        //DateFormatter()のインスタンスを取得。そのフォーマットをyyyy-MM-dd HH:mmにする
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        //formatterのdateを、cellのdetailtextLabelのtextに入れる。
        let dateString:String = formatter.string(from: task.date)
        cell.detailTextLabel?.text = dateString
        
        //cellにはtitle, dateが入っている。
        return cell
    }

    // 各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //performSegue(withIdentifier: "cellSegue",sender: nil)
        let indexPath = self.tableView.indexPathForSelectedRow //self.tableView：プロパティのtableView。
        let selectedTask = taskArray[indexPath!.row]
        // senderに選択されたタスクを渡す
        performSegue(withIdentifier: "inputTask", sender: selectedTask)
    }

    // セルが削除が可能なことを伝えるメソッド
    //セルを右からスワイプすることで削除ボタンが出るようになる
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)-> UITableViewCell.EditingStyle {
        return .delete
    }

    // Delete ボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // 削除するタスクを取得する
            let task = self.taskArray[indexPath.row] //自明なのでself.なくてもOK
            // ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id.stringValue)])

            //データベースから削除する
            try! realm.write {
                self.realm.delete(self.taskArray[indexPath.row])
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            // 未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/---------------")
                    print(request)
                    print("---------------/")
                }
            }
        }
    }
    //+ボタンが押下された時のメソッド
    @IBAction func plusButton(_ sender: UIBarButtonItem) {
        //もし下書き保存があった場合
        if (!draftArray.isEmpty) {
            //draftの中身を全てtaskに代入する
            let draft = draftArray[0]
            let task = Task()
            task.id = draft.id
            task.title = draft.title
            task.contents = draft.contents
            task.date = draft.date
            task.category = draft.category
            
            //アラート表示
            let alert = UIAlertController(title: "前回の下書きから始めますか？", message: "", preferredStyle: .alert)
            let draftyes = UIAlertAction(title: "はい", style: .default, handler: { (action) -> Void in
                //senderにDraftから読み込んだタスクを渡す
                //let draftTask = task
                //self.performSegue(withIdentifier: "inputTask", sender: draftTask)
                self.performSegue(withIdentifier: "inputTask", sender: task) //selfは必要。クロージャの中でインスタンスのプロパティやメソッドを参照するときは誰のものかを明示する必要がある。
            })
            let draftno = UIAlertAction(title: "いいえ", style: .default, handler: { (action) -> Void in
                // senderに新規のタスク（Taskクラスのインスタンスを新しくして）渡す
                self.performSegue(withIdentifier: "inputTask", sender: Task())
            })
            alert.addAction(draftyes)
            alert.addAction(draftno)
            self.present(alert, animated: true, completion: nil)
        //もし下書き保存がなかった場合
        } else {
            // senderに新規のタスク（Taskクラスのインスタンスを新しくして）渡す
            performSegue(withIdentifier: "inputTask", sender: Task()) //クロージャの中なのでself不要（別途：インスタンスの寿命に関連★）
        }
    }
    
    //segueで画面遷移する時に呼ばれる。segueはキックされている。performSegueでどのsegueをキックするかを指定
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //＋またはセルを押した場合。performSegueやstoryboardでSegueを紐づけた。
        if segue.identifier == "inputTask" {
            //segueから遷移先のInputViewControllerを取得する
            let inputViewController:InputViewController = segue.destination as! InputViewController
            
            if let sourceTask = sender as? Task { //★senderがnilでない&&Task型にCastできたら。
                //as? = キャストしてアンラップ（非オプショナル型＝nil非許容にする）。キャストした結果失敗するとNil
                inputViewController.task = sourceTask
                //inputViewController.viewToInput = "view to input"
            } else {
                // performSegueを呼び出す際に必ずsenderにTaskが設定されているならば、キャストに失敗することはあり得ないため、ここのブロックには絶対に来ない。ただし、as?でキャストしている以上、キャスト失敗に備えるコードは実装上避けられないため、なんらかの実装は必要となる。
                inputViewController.task = Task()
            }
        //絞り込みボタンを押下した場合
        } else if segue.identifier == "categoryFilter" {
            //segueから遷移先のcategoryListViewを取得する
            let categoryListViewController:CategoryListViewController = segue.destination as! CategoryListViewController
            //categoryListViewの親は自分である旨記載
            categoryListViewController.parentViewCategryViewController = self
            
            //categoryTextFieldにすでに記載があった場合はcategoryListViewのnameArrayに入れる。
            if searchBar.text != "" {
                categoryListViewController.nameArray = searchBar.text!.components(separatedBy: ",")
                print(searchBar.text!)
            //categoryTextField.textが""の場合はnameArrayを空にする。
            } else {
                categoryListViewController.nameArray = []
            }
        }
    }
    
    //テキスト変更時の呼び出しメソッド
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        //テーブルを再読み込みする。
        tableView.reloadData()
    }
    
    //入力画面から戻って来た時に、TableViewを更新させる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //categoryFilterにはCategoryListViewのnameArray（チェックマークがついたセルの名前のリスト）が入っているので、それをカンマ区切りにしてSearchBarへ入力
        searchBar.text = categoryFilter.joined(separator: ",")
        
        tableView.reloadData()
    }
    
    @objc func dismissKeyboard(){
        // キーボードを閉じる
        view.endEditing(true)
    }
}

