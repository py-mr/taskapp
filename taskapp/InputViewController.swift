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
    
    @IBOutlet weak var errorLabelCategory: UILabel!
    @IBOutlet weak var errorLabelTitle: UILabel!
    // Realmインスタンスを取得する
    let realm = try! Realm()
    //var task: Task!
    //var draft: Draft!
    var task = Task()
    var draft = Draft()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        //★もっと綺麗に書きたい
        titleTextField.placeholder = "入力してください"
        titleTextField.layer.cornerRadius = 5
        titleTextField.layer.borderColor = UIColor.lightGray.cgColor
        titleTextField.layer.borderWidth = 1.0
        //★https://qiita.com/REON/items/a5b2122785792f83f851
        //contentsTextView.placeholder = "入力してください"
        contentsTextView.layer.cornerRadius = 5
        contentsTextView.layer.borderColor = UIColor.lightGray.cgColor
        contentsTextView.layer.borderWidth = 1.0
        categoryTextField.placeholder = "入力してください"
        categoryTextField.layer.cornerRadius = 5
        categoryTextField.layer.borderColor = UIColor.lightGray.cgColor
        categoryTextField.layer.borderWidth = 1.0
        
        // 背景をタップしたらdismissKeyboardメソッドを呼ぶように設定する
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        titleTextField.text = task.title
        contentsTextView.text = task.contents
        datePicker.date = task.date
        categoryTextField.text = task.category
        print("(1-1)input表示後のtask.id", task.id)
        //★表示のタイミングでもともとのtask.idをもたせればよい？
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
    
    //（追加）「保存」ボタン押下で呼ばれるメソッド（バリデーションチェック、Realmに保存し、ViewControllerに戻る）
    @IBAction func saveButton(_ sender: Any) {
        //タイトル、日付、カテゴリは必須にする
        //★もっといい感じにしたいけど。。あと日付はチェックしなくていいのかな
        if self.titleTextField.text!.isEmpty || self.categoryTextField.text!.isEmpty {
            if self.titleTextField.text!.isEmpty && self.categoryTextField.text!.isEmpty{
                super.viewDidLoad() //呼び出さないといけないのおかしい
                titleTextField.layer.borderColor = UIColor.red.cgColor
                categoryTextField.layer.borderColor = UIColor.red.cgColor
                 //★これでいいのだろうか
                errorLabelTitle.text = "必須項目です"
                errorLabelCategory.text = "必須項目です"
            } else if self.titleTextField.text!.isEmpty && !self.categoryTextField.text!.isEmpty{
                super.viewDidLoad()
                titleTextField.layer.borderColor = UIColor.red.cgColor
                categoryTextField.layer.borderColor = UIColor.lightGray.cgColor
                errorLabelTitle.text = "必須項目です"
                errorLabelCategory.text = ""
            } else {
                super.viewDidLoad()
                titleTextField.layer.borderColor = UIColor.lightGray.cgColor
                categoryTextField.layer.borderColor = UIColor.red.cgColor
                errorLabelTitle.text = ""
                errorLabelCategory.text = "必須項目です"
            }

        } else {
            super.viewDidLoad()
            titleTextField.layer.borderColor = UIColor.lightGray.cgColor
            categoryTextField.layer.borderColor = UIColor.lightGray.cgColor
            errorLabelTitle.text = ""
            errorLabelCategory.text = ""
            let alertsheet: UIAlertController = UIAlertController(title: "保存してもいいですか？", message: "", preferredStyle:  UIAlertController.Style.actionSheet)
            
            let save = UIAlertAction(title: "OK", style: .default, handler: { [self] (action) -> Void in
                try! self.realm.write {
                    self.task.title = self.titleTextField.text!
                    self.task.contents = self.contentsTextView.text
                    self.task.date = self.datePicker.date
                    self.task.category = self.categoryTextField.text!
                    self.realm.add(self.task, update: .modified)
                    print("(1-3)保存した時のID", task.id)
                }

                //一時保存データAが存在する＆＆一時保存データAのID＝保存したデータのIDの時→一時保存データAを削除する
                //一時保存データAが存在する＆＆時保存データAのID!＝保存したデータのIDの時→一時保存データAは削除しない（何もしない）
                //一時保存データAが存在しない→何もしない
                let draftArray = try! Realm().objects(Draft.self)
                
                if !draftArray.isEmpty && draftArray[0].id == task.id {
                    try! realm.write {
                        self.realm.delete(draftArray)
                    }
                } else if !draftArray.isEmpty && draftArray[0].id != task.id {
                    print("何もしない")
                } else {
                    print("一時保存データがないなら何もしない")
                }
                 
                setNotification(task: task)
                self.navigationController?.popViewController(animated: true)
            })
            let cancel = UIAlertAction(title: "キャンセル", style: .cancel, handler: { (action) -> Void in
                //ポップアップを消すのみ（なのでこのまま何も書かなくてOK）
            })
            
            alertsheet.addAction(save)
            alertsheet.addAction(cancel)
            
            self.present(alertsheet, animated: true, completion: nil)
        }
    }
    
    func validate() -> Bool {
        /*
        if self.titleTextField.text!.isEmpty {
                //★エラーメッセージ出す
                //isValid = false
        }
        if self.categoryTextField.text!.isEmpty {
                //エラーメッセージ出す
                //isValid = false
            
        //isValidがtrueで下記実施
         */
        return true
    }
    
    //（追加）「キャンセル」ボタン押下でポップアップ（入力した情報を下書き保存しますか？下書き保存/破棄/編集を続ける）。下書き保存→１情報のみ保存しておく。ViewControllerで「＋」押下すると、保存しているものがあればそれが出てくる。破棄→ViewControllerへ戻る、編集を続ける→遷移しない
    @IBAction func cancelButton(_ sender: Any) {
        let alert = UIAlertController(title: "入力内容を下書き保存しますか？", message: "破棄すると入力内容が失われます", preferredStyle: .alert)
        
        let draftsave = UIAlertAction(title: "下書き保存する", style: .default, handler: { [self] (action) -> Void in
            print(self.titleTextField.text!)
            //★前保存していたものは削除する。（どうやろうかな）
            //データベースから削除する
            try! realm.write {
                let draftArray = try! Realm().objects(Draft.self)
                self.realm.delete(draftArray)
            }
            try! self.realm.write {
                self.draft.id = task.id
                self.draft.title = self.titleTextField.text!
                //★Optional型なので、ここでアンラップして非Optional型にしたものをdtaft.titleに設定している
                self.draft.contents = self.contentsTextView.text
                //★String! 強制アンラップされるOptional型のString→結果非Optional型のStringが返されるので!がいらない
                self.draft.date = self.datePicker.date
                self.draft.category = self.categoryTextField.text!
                self.realm.add(self.draft, update: .modified)
                print("(1-2)下書き保存した時のID", draft.id)
            }
            //何もせずそのままViewControllerへ戻る
            //アラートが消えるのと画面遷移が重ならないように0.1秒後に画面遷移するようにしてる
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 0.1秒後に実行したい処理
                self.navigationController?.popViewController(animated: true)
            }
        })
        
        let destroy = UIAlertAction(title: "破棄する", style: .destructive, handler: { (action) -> Void in
            //何もせずそのままViewControllerへ戻る
            //アラートが消えるのと画面遷移が重ならないように0.1秒後に画面遷移するようにしてる
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 0.1秒後に実行したい処理
                self.navigationController?.popViewController(animated: true)
            }
        })
        
        let edit = UIAlertAction(title: "編集を続ける", style: .cancel, handler: { (action) -> Void in
            //ポップアップを消すのみ（なのでこのまま何も書かなくてOK）
        })
        
        alert.addAction(draftsave)
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
