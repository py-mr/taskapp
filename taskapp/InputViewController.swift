//
//  InputViewController.swift
//  taskapp
//
//  Created by A I on 2023/09/29.
//

import UIKit
import RealmSwift // Realmを使うために追加
import UserNotifications

class InputViewController: UIViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentsTextView: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var categoryTextField: UITextField!
    
    // Realmインスタンスを取得する
    let realm = try! Realm()
    var task: Task!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        // 背景をタップしたらdismissKeyboardメソッドを呼ぶように設定する
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        titleTextField.text = task.title
        contentsTextView.text = task.contents
        datePicker.date = task.date
        categoryTextField.text = task.category
    }
    
    //viewWillDisappear(_:)メソッドは遷移する際に、画面が非表示になるとき呼ばれるメソッド
    //（追加）画面が非表示になるときはanimatedのみ
    override func viewWillDisappear(_ animated: Bool) {
        /*
        try! realm.write {
            self.task.title = self.titleTextField.text!
            self.task.contents = self.contentsTextView.text
            self.task.date = self.datePicker.date
            self.task.category = self.categoryTextField.text!
            self.realm.add(self.task, update: .modified)
        }
        setNotification(task: task)
         */
        
        super.viewWillDisappear(animated)
    }
    
    //（追加）「<back」ボタン押下で呼ばれるメソッド（もし保存していないのであれば、ポップアップ（内容を保存していませんが、よろしいですか？いいえ/はい）。はい→ViewControllerへ戻る、いいえ→遷移しない。もし保存しているのであれば、そのまま遷移する。）
    
    //（追加）「保存」ボタン押下で呼ばれるメソッド（Realmに保存し、ViewControllerに戻る）
    @IBAction func saveButton(_ sender: Any) {
        try! realm.write {
            self.task.title = self.titleTextField.text!
            self.task.contents = self.contentsTextView.text
            self.task.date = self.datePicker.date
            self.task.category = self.categoryTextField.text!
            self.realm.add(self.task, update: .modified)
        }
        setNotification(task: task)
        //super.viewWillDisappear(animated)
    }
    
    //（追加）「キャンセル」ボタン押下でポップアップ（入力した情報を下書き保存しますか？下書き保存/破棄/編集を続ける）。下書き保存→１情報のみ保存しておく。ViewControllerで「＋」押下すると、保存しているものがあればそれが出てくる。破棄→ViewControllerへ戻る、編集を続ける→遷移しない
    @IBAction func cancelButton(_ sender: Any) {
        let alert = UIAlertController(title: "入力内容を下書き保存しますか？", message: "破棄すると入力内容が失われます", preferredStyle: .alert)
        
        let draft = UIAlertAction(title: "下書き保存する", style: .default, handler: { (action) -> Void in
            //一番新しい情報のみ保存する。（すでに保存されているものは削除し、今回の情報のみ保存する）
        })
        
        let destroy = UIAlertAction(title: "破棄する", style: .destructive, handler: { (action) -> Void in
            //何もせずそのままViewControllerへ戻る
        })
        
        let edit = UIAlertAction(title: "編集を続ける", style: .cancel, handler: { (action) -> Void in
            //★ポップアップを消すのみ（なのでこのまま何も書かなくてOK？）
        })
        
        alert.addAction(draft)
        alert.addAction(destroy)
        alert.addAction(edit)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    //タスクのローカル通知を登録する
    func setNotification(task: Task) {
        let content = UNMutableNotificationContent()
        //タイトルと内容を設定(中身がない場合メッセージ無しで音だけの通知になるので「(xxなし)」を表示する)
        if task.title == "" {
            content.title = "(タイトルなし)"
        } else {
            content.title = task.title
        }
        if task.contents == "" {
            content.body = "(内容なし)"
        } else {
            content.body = task.contents
        }
        content.sound = UNNotificationSound.default

    
        // ローカル通知が発動するtrigger（日付マッチ）を作成
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: task.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // identifier, content, triggerからローカル通知を作成（identifierが同じだとローカル通知を上書き保存）
        let request = UNNotificationRequest(identifier: String(task.id.stringValue), content: content, trigger: trigger)
        
        // ローカル通知を登録
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error) in
            print(error ?? "ローカル通知登録 OK")  // error が nil ならローカル通知の登録に成功したと表示します。errorが存在すればerrorを表示します。
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
    
    @objc func dismissKeyboard(){
        // キーボードを閉じる
        view.endEditing(true)
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
