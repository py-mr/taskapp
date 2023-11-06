//
//  ViewController.swift
//  taskapp
//
//  Created by A I on 2023/09/29.
//

import UIKit
import RealmSwift   // Realmを使うために追加
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    
    // Realmインスタンスを取得する
    let realm = try! Realm()
    //インスタンス生成の時には必ずtry!しないといけないのか？→例外が発生しうる処理。普通のクラスでは発生しないがRealmでは発生する。作られるときにイニシャライザが呼び出されて、そこでthrowsが宣言されているので例外が発生しうる。do-try-catch（処理）ではないので、try!としか書けない。本来do-try-catchで例外が発生、それに対処しないといけない。例外は無視してはいけない。今回は無視しているが、例外の場合はアプリが落ちる。そこまでして使う必要があるならtry!を使ってもよい。リスクにみあうかどうか。
    
    // DB内のタスクが格納されるリスト。（Realmクラスのobjects(_:)メソッドでクラス（「型名.self」で型そのものを変数に入れて扱える。）を指定して一覧を取得）
    // 日付の近い順でソート：昇順（sorted(byKeyPath:ascending:)メソッド）
    // 以降内容をアップデートするとリスト内は自動的に更新される。taskArray＝DBに入っているデータのリストが入っている。
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
    //プロパティの初期値を入れるときに別のプロパティは使えない。初期化の順序は決められない（２１行、１５行どっちが早いかわからない）ので。処理ではなく宣言なので。順序決めたいのであればinit()の中でやれば非Optionalで順序だでてできる
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //データを表示していない部分に罫線を表示するコードを追加
        tableView.fillerRowHeight = UITableView.automaticDimension
        //★tableViewのfillerRowHeight（変数）のプロパティに、UITableViewのautomaticDimension（クラス）のプロパティを指定している？
        
        //tableViewのデリゲートメソッドを実装しているのはself(ViewController)だと教えている（子から親を呼び出している）。
        //ここではtableViewが持っている、dataSourceとdelegateのプロパティが、
        //それぞれUITableViewDelegate型とUITableViewDataSource型のインスタンスを要求している。 
        tableView.delegate = self
        tableView.dataSource = self
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
        //再利用？このcellは、indexPath分の”Cell”を再利用できるようにしたもの？
        //tableViewはdelegateを必要としている。tableViewは最低限何行つくるかは外部からはわからない。10行であれば11行あれば事足りる。tableViewは事足りる分しかセルのインスタンスを作らない。Cellのインスタンスを取得する(処理コストがかかるのであんまりやりたいわけではない)。ReuseQueueの中に何もない場合は新しくつくって返し、cellが溜まっていればそのセルのどれかを返す。
        //やってはいけない１：全体のセルがある前提をおいてはいけない。２：１行目のセルがずっと１行目のセルにあるという前提をおいてはいけない。なので、１番目のセルの、テキストを、変える、とかどういうことをしてはいけない。自前でためこんでおいて後から書き換えるということはできない。→元データのソース自体を更新すればよい。＆tableViewのリロードをかければよい、するとtableView()メソッドがまた実施される。リロードしたとしてもdeque...では見えているセルのインスタンスが再度作り替えられるわけではない。ので更新部分のみ更新されたようにみえる。correctionView（横並び/縦並び自由配置）も似ている
        
        //Cellに値を設定する
        //taskArray＝DB（ではない）に入っているデータのリストが入っている。taskにtaskArray1行ずつ入る
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
        performSegue(withIdentifier: "cellSegue",sender: nil)
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
    
    //segueで画面遷移する時に呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //segueから遷移先のInputViewControllerを取得する
        let inputViewController:InputViewController = segue.destination as! InputViewController
        //セルが押下された場合(segueのidentifierがcellSegueの場合)は、そのセルのRowを遷移先に渡す
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
        //＋が押下された場合は、Taskクラスのインスタンスを新しくしてそのまま渡す。
        } else {
            inputViewController.task = Task()
        }
    }
    
    //入力画面から戻って来た時に、TableViewを更新させる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
}

