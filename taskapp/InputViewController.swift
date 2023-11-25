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
    //@IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var dateTextField: UITextField!
    
    @IBOutlet weak var errorLabelCategory: UILabel!
    @IBOutlet weak var errorLabelTitle: UILabel!
    @IBOutlet weak var errorLabelDate: UILabel!
    // Realmインスタンスを取得する
    let realm = try! Realm()
    //var task: Task!
    //var draft: Draft!
    var task = Task()
    var draft = Draft()
    var category = Category()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationItem.title = "タスク"

        //TextFieldの見た目
        fieldappearance(titleTextField)
        fieldappearance(categoryTextField)
        fieldappearance(dateTextField)
        fieldappearance(contentsTextView)

        // 背景をタップしたらdismissKeyboardメソッドを呼ぶように設定する
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        //★Taskクラスのデータ？を各フィールドに入力
        titleTextField.text = task.title
        contentsTextView.text = task.contents
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateTextField.text = dateFormatter.string(from: task.date)
        categoryTextField.text = task.category
        print("(1-1)input表示後のtask.id", task.date)
    }
    
    /*
    // UITextField編集直後に呼ばれるメソッド
    @objc func textFieldDidBeginEditing(textField: UITextField) {
        dateEditing(sender: dateTextField)
    }
    // 日付を入力する
    @objc func dateEditing(sender: UITextField) {
        let datePicker            = UIDatePicker()
        datePicker.datePickerMode = UIDatePicker.Mode.date
        datePicker.locale         = NSLocale(localeIdentifier: "ja_JP") as Locale
        sender.inputView          = datePicker
        datePicker.addTarget(self, action: Selector(("datePickerValueChanged:")), for: UIControl.Event.valueChanged)
    }
    
    // 日付を変更した際にUITextFieldに値を設定する
    @objc func datePickerValueChanged(sender:UIDatePicker) {
        let dateFormatter       = DateFormatter()
        dateFormatter.locale    = NSLocale(localeIdentifier: "ja_JP") as Locale
        //dateFormatter.dateStyle = DateFormatterStyle.MediumStyle
        dateTextField.text! = dateFormatter.string(from: sender.date)
    }
    */

    func fieldappearance(_ sender:UITextField) {
        sender.placeholder = "入力してください"
        sender.layer.cornerRadius = 5
        sender.layer.borderColor = UIColor.lightGray.cgColor
        sender.layer.borderWidth = 1.0
    }
    func fieldappearance(_ sender:UITextView) {
        //sender.placeholder = "入力してください"
        sender.layer.cornerRadius = 5
        sender.layer.borderColor = UIColor.lightGray.cgColor
        sender.layer.borderWidth = 1.0
    }
    
    //viewWillDisappear(_:)メソッドは遷移する際に、画面が非表示になるとき呼ばれるメソッド
    //（追加）画面が非表示になるときはanimatedのみ
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    //（追加）「<back」ボタン押下で呼ばれるメソッド（もし保存していないのであれば、ポップアップ（内容を保存していませんが、よろしいですか？いいえ/はい）。はい→ViewControllerへ戻る、いいえ→遷移しない。もし保存しているのであれば、そのまま遷移する。）

    //（追加）「保存」ボタン押下で呼ばれるメソッド（バリデーションチェック、Realmに保存し、ViewControllerに戻る）
    @IBAction func saveButton(_ sender: Any) {
        //タイトル、日付（チェック不要。非Optionalだし。けど過去はNGにする）、カテゴリは必須にする
        switch validate().validTitle {
        case 1:
            titleTextField.layer.borderColor = UIColor.red.cgColor
            errorLabelTitle.text = "必須項目です"
        default:
            titleTextField.layer.borderColor = UIColor.lightGray.cgColor
            errorLabelTitle.text = ""
        }
        switch validate().validCategory {
        case 1:
            categoryTextField.layer.borderColor = UIColor.red.cgColor
            errorLabelCategory.text = "必須項目です"
        default:
            categoryTextField.layer.borderColor = UIColor.lightGray.cgColor
            errorLabelCategory.text = ""
        }
        switch validate().validDate {
        case 1:
            errorLabelDate.text = "過去の日付は入力できません"
        default:
            errorLabelDate.text = ""
        }
        
        /*if self.titleTextField.text!.isEmpty || self.categoryTextField.text!.isEmpty {*/
        if validate().validTitle == 1 || validate().validCategory == 1 || validate().validDate == 1 {
            //何もしない
        } else {
            super.viewDidLoad()
            let alertsheet: UIAlertController = UIAlertController(title: "保存してもいいですか？", message: "", preferredStyle:  UIAlertController.Style.actionSheet)
            
            let save = UIAlertAction(title: "OK", style: .default, handler: { [self] (action) -> Void in
                try! self.realm.write {
                    self.task.title = self.titleTextField.text!
                    self.task.contents = self.contentsTextView.text
                    //self.task.date = self.datePicker.date
                    let dateFormatter = DateFormatter()
                    let dateDate = dateFormatter.date(from: self.dateTextField.text!)
                    self.task.date = dateDate!
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
                //★ただ、そもそもこれでいいのか？Bのデータを保存したらAのデータは削除すべきなのでは？
                
                
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
    
    func validate() -> (validTitle:Int, validCategory:Int, validDate:Int) {
        var validTitle = 0
        var validCategory = 0
        var validDate = 0
        let now = Date()
        let modifiedDate = Calendar.current.date(byAdding: .minute, value: -1, to: now)!

        if self.titleTextField.text!.isEmpty {
            validTitle = validTitle + 1
        }
        if self.categoryTextField.text!.isEmpty {
            validCategory = validCategory + 1
        }
        //if datePicker.date.compare(modifiedDate) == .orderedAscending {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let date = dateFormatter.date(from: dateTextField.text!)!
        if date.compare(modifiedDate) == .orderedAscending {
            validDate = validDate + 1
        }
        return (validTitle, validCategory, validDate)
        
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
                //self.draft.date = self.datePicker.date
                let dateFormatter = DateFormatter()
                let dateDate = dateFormatter.date(from: self.dateTextField.text!)
                self.draft.date = dateDate!
                //self.draft.date = self.dateTextField.text!
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
    
    
    @IBAction func makeCategoryButton(_ sender: UIButton) {
        
        let alert = UIAlertController(title: "新規カテゴリ名", message: "新規カテゴリ名を入力してください", preferredStyle: .alert)
        
        let save = UIAlertAction(title: "OK", style: .default, handler: { [self] (action) -> Void in
            //★？
           let text = alert.textFields?.first?.text ?? ""
            try! self.realm.write {
                self.category.categoryName = text
                self.realm.add(self.task, update: .modified)
                }
        })
        let cancel = UIAlertAction(title: "キャンセル", style: .cancel, handler: { (action) -> Void in
            //ポップアップを消すのみ（なのでこのまま何も書かなくてOK）
        })
        
        alert.addTextField{
            (textField) in
            textField.placeholder = "入力してください"
        }
        alert.addAction(save)
        alert.addAction(cancel)
        
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
