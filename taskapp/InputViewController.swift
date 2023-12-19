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
    
    //Optionalなんだけど使うときに非Optionalに変換される
    @IBOutlet weak var titleTextField: UITextField!

    //@IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var contentsTextView: UITextView!
    
    @IBOutlet weak var errorLabelCategory: UILabel!
    @IBOutlet weak var errorLabelTitle: UILabel!
    @IBOutlet weak var errorLabelDate: UILabel!
    // Realmインスタンスを取得する
    let realm = try! Realm()
    var task = Task()
    var draft = Draft()
    var category = Category()
    var datePicker: UIDatePicker = UIDatePicker()
    
    //★子から親（inputView）へ値を渡す
    var categoryNumSelected: [Int] = []
    var categorySelected: [String] = []
    var categoryListViewController: CategoryListViewController?
    // NOTE:ここを削除
    //var dateSelected: String = ""
    var dateTimeViewController: DateTimeViewController?
    
    //★親（View）から子（Input）へ
    var viewToInput = ""
    
    //★ナビゲーションバーにボタン追加
    let button = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.

        //ナビゲーションバーの表示
        navigationItem.title = "タスク"
        //デフォルトの戻るボタン削除
        self.navigationItem.hidesBackButton = true
        
        //「＜一覧」ボタンカスタマイズ。キャンセルボタンを押下した時と同じメソッドを実施する。
        //「一覧」フォントサイズなど
        button.setTitle("一覧", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        //let size = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 30))
        //「＜」フォントサイズなど
        let sizeweight = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        button.setImage(UIImage(systemName: "chevron.backward", withConfiguration: sizeweight), for: .normal)
        //ナビゲーションバーの左にボタン配置。押下でcancelButtonメソッドを実行。
        let viewButtonItem = UIBarButtonItem(customView: button)
        navigationItem.leftBarButtonItem = viewButtonItem
        button.addTarget(self, action: #selector(cancelButton), for: .touchUpInside)
        
        //TextFieldの見た目
        fieldappearance(titleTextField)
        fieldappearance(categoryTextField)
        categoryTextField.isEnabled = false
        fieldappearance(dateTextField)
        fieldappearance(contentsTextView)
        
        // 背景をタップしたらdismissKeyboardメソッドを呼ぶように設定する
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)

        //Taskクラスのデータを各フィールドに入力
        titleTextField.text = task.title
        contentsTextView.text = task.contents
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateTextField.text = dateFormatter.string(from: task.date)
        categoryTextField.text = task.category
    }

    func fieldappearance(_ sender:UITextField) {
        if sender == categoryTextField {
            sender.placeholder = "選択してください"
        } else {
            sender.placeholder = "入力してください"
        }
        sender.layer.cornerRadius = 5
        sender.layer.borderColor = UIColor.lightGray.cgColor
        sender.layer.borderWidth = 1.0
    }
    func fieldappearance(_ sender:UITextView) {
        sender.layer.cornerRadius = 5
        sender.layer.borderColor = UIColor.lightGray.cgColor
        sender.layer.borderWidth = 1.0
    }
    
    @IBAction func dateTextFieldTouch(_ sender: Any) {
        //下から子Viewを出す。
        performSegue(withIdentifier: "SemiModal", sender: nil)
        //dateTextField.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //★View以外（CategoryList、DateTime）からの遷移の場合、viewToInputには何も入っていない
        //（★18）こういうやり方でいいのか？⇨よいプロパティある。isMovingToParentViewController
        if viewToInput == "" {
            //CategoryListからの遷移の場合
            categoryTextField.text = categorySelected.joined(separator: ",")
            // NOTE:ここを削除
            //DateTimeからの遷移の場合
            //dateTextField.text = dateSelected
        //Viewからの遷移の場合
        } else {
            //何もしない
            viewToInput = ""
        }
    }
    
    //「保存」ボタン押下で呼ばれるメソッド（バリデーションチェック、Realmに保存し、ViewControllerに戻る）
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
            dateTextField.layer.borderColor = UIColor.red.cgColor
            errorLabelDate.text = "過去の日付は入力できません"
        default:
            dateTextField.layer.borderColor = UIColor.lightGray.cgColor
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
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                    //let dateDate = dateFormatter.date(from: self.dateTextField.text!)
                    let dateDate = dateTextField.text!
                    self.task.date = dateFormatter.date(from: dateDate)!
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
    
    //キャンセルボタンタップ
    @IBAction func cancelButton(_ sender: Any) {
        let alert = UIAlertController(title: "入力内容を下書き保存しますか？", message: "破棄すると入力内容が失われます", preferredStyle: .alert)
        
        let draftsave = UIAlertAction(title: "下書き保存する", style: .default, handler: { [self] (action) -> Void in
            print(self.titleTextField.text!)
            //元のドラフトデータはデータベースから削除する
            try! realm.write { //クロージャ内なので、本来selfはひつよう。
                let draftArray = try! Realm().objects(Draft.self)
                self.realm.delete(draftArray)
            /*
            }
            try! self.realm.write { //一つのトランザクションでやって方がいいかも。delete成功してadd失敗の可能性もあるため。
             */
                self.draft.id = self.task.id
                self.draft.title = self.titleTextField.text! //IBOUtlet接続されたプロパティなのでクロージャの中ではselfいる
                //textがString?（Optional型）なので、ここでアンラップして非Optional型にしたものをdtaft.titleに設定する。
                self.draft.contents = self.contentsTextView.text
                //textがString!（強制アンラップされるOptional型のString）→結果非Optional型のStringが返されるので!がいらない。
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                let dateDate = self.dateTextField.text!
                self.draft.date = dateFormatter.date(from: dateDate)!
                
                self.draft.category = self.categoryTextField.text!
                self.realm.add(self.draft, update: .modified)
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
    
    //segueで画面遷移する時に呼ばれる。prepareは遷移が始まる前に呼ばれる、viewWillDisappearは遷移最中に呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CategoryList" {
            let categoryListViewController:CategoryListViewController = segue.destination as! CategoryListViewController //UIViewController⇨CategoryListViewControllerの型に変換している
            //categoryListViewの親が自分であると明示
            categoryListViewController.parentInputCategoryViewController = self
            
            //categoryTextFieldにすでに記載があった場合はcategoryListViewのnameArrayに入れる。
            if categoryTextField.text != "" {
                categoryListViewController.nameArray = categoryTextField.text!.components(separatedBy: ",")
            } else {
                categoryListViewController.nameArray = []
            }
        } else if segue.identifier == "SemiModal" { //⭐︎Identifierは全てにつけるべき
            let dateTimeViewController:DateTimeViewController = segue.destination as! DateTimeViewController
            // NOTE:ここを変更
            dateTimeViewController.delegate = self
            //dateTimeViewController.parentInputDateViewController = self
            dateTimeViewController.hiduke = dateTextField.text!
            
            //dateTextFieldTappedメソッドに書くことはできない？⇨遷移するときに次の画面を取得できるので、このメソッド内でしか書けない。
            //modal遷移先のPresentationをFull Screenにした上で、viewがない部分をclearにした。
            dateTimeViewController.view.backgroundColor = UIColor.clear
            dateTimeViewController.modalPresentationStyle = .overFullScreen
            //present(dateTimeViewController, animated: true) //★不要、performSegueがあるから？
        }
    }
    
    @objc func dismissKeyboard(){
        // キーボードを閉じる
        view.endEditing(true)
    }
}

// NOTE:ここを追加。inputviewcontrollerにdatetimeviewdelegateを継承させる。
extension InputViewController: DateTimeViewDelegate {
    
    func dateSelected(date: String) {
        dateTextField.text = date
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
