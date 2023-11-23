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
    
    // Realmインスタンスを生成し、それをrealmに入れる
    let realm = try! Realm()
    
    // DB内のタスクが格納されるリスト。（Realmクラスのobjects(_:)メソッドでクラス（「型名.self」で型そのものを変数に入れて扱える。）を指定して一覧を取得）
    // 日付の近い順でソート：昇順（sorted(byKeyPath:ascending:)メソッド）
    // 以降内容をアップデートするとリスト内は自動的に更新される。taskArray＝DBに入っているデータのリストが入っている。
    var taskArray: Results<Task> {
        if (searchBar.text != "") {
            return try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true).filter("category CONTAINS %@", searchBar.text!)
            
        } else {
            return try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
        }
    }
    
    var draftArray = try! Realm().objects(Draft.self)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //データを表示していない部分に罫線を表示するコードを追加
        tableView.fillerRowHeight = UITableView.automaticDimension        //★tableViewのfillerRowHeight（変数）のプロパティに、UITableViewのautomaticDimension（クラス）のプロパティを指定している？

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
        let indexPath = self.tableView.indexPathForSelectedRow
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
            let task = self.taskArray[indexPath.row]
            // ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id.stringValue)])

            //データベースから削除する
            try! realm.write {
                self.realm.delete(self.taskArray[indexPath.row])
                tableView.deleteRows(at: [indexPath], with: .fade) //←アニメーション付き削除？
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
        //＋が押下された場合は、Taskクラスのインスタンスを新しくしてそのまま渡す。
        //さらに、もし下書き保存があった場合は、その情報を返す。（その前にポップアップ出す）
        
        if (!draftArray.isEmpty) {
            let draft = draftArray[0]
            let task = Task()
            task.id = draft.id
            task.title = draft.title
            task.contents = draft.contents
            task.date = draft.date
            task.category = draft.category
            print(draftArray[0])

            let alert = UIAlertController(title: "前回の下書きから始めますか？", message: "", preferredStyle: .alert)
            let draftyes = UIAlertAction(title: "はい", style: .default, handler: { (action) -> Void in
                //senderにDraftから読み込んだタスクを渡す
                let draftTask = task
                self.performSegue(withIdentifier: "inputTask", sender: draftTask)
            })
            let draftno = UIAlertAction(title: "いいえ", style: .default, handler: { (action) -> Void in
                //inputViewController.task = Task()
                // senderに新規のタスクを渡す
                self.performSegue(withIdentifier: "inputTask", sender: Task())
            })
            alert.addAction(draftyes)
            alert.addAction(draftno)
            self.present(alert, animated: true, completion: nil)
        } else {
            // senderに新規のタスクを渡す
            performSegue(withIdentifier: "inputTask", sender: Task())
        }
    }
    
    //segueで画面遷移する時に呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //segueから遷移先のInputViewControllerを取得する
        let inputViewController:InputViewController = segue.destination as! InputViewController

        if let sourceTask = sender as? Task { //★senderがnilでない&&TaskにCastできたら。
            //as? = キャストしてアンラップ（非オプショナル型＝nil非許容にする）。キャストした結果失敗するとNil
            inputViewController.task = sourceTask
        } else {
            // performSegueを呼び出す際に必ずsenderにTaskが設定されているならば、キャストに失敗することはあり得ないため、ここのブロックには絶対に来ない。ただし、as?でキャストしている以上、キャスト失敗に備えるコードは実装上避けられないため、なんらかの実装は必要となる。
            inputViewController.task = Task()
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
        tableView.reloadData()
    }
}

