//
//  CategoryCreateViewController.swift
//  taskapp
//
//  Created by A I on 2023/11/30.
//

import UIKit
import RealmSwift   // Realmを使うために追加

class CategoryCreateViewController: UIViewController {
    @IBOutlet weak var errorLabelTitle: UILabel!
    @IBOutlet weak var categoryNameTextField: UITextField!
    // Realmインスタンスを取得する
    let realm = try! Realm()
    var category = Category()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationItem.title = "カテゴリ作成"
        
        //TextFieldの見た目
        fieldappearance(categoryNameTextField)
        
        //エラーラベルの初期値
        errorLabelTitle.text = ""
        
        // 背景をタップしたらdismissKeyboardメソッドを呼ぶように設定する
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
    }
    
    func fieldappearance(_ sender:UITextField) {
        sender.placeholder = "入力してください"
        sender.layer.cornerRadius = 5
        sender.layer.borderColor = UIColor.lightGray.cgColor
        sender.layer.borderWidth = 1.0
    }
    
    
    @IBAction func saveCategoryNameButton(_ sender: Any) {
        //スペース入力不可、英語数字は半角のみ可、記号は入力不可。のチェック。だめならエラー。
        let categoryArray = try! Realm().objects(Category.self).filter("categoryName = %@", categoryNameTextField.text!)
        print(categoryArray.count)

        if self.categoryNameTextField.text!.isEmpty {
            categoryNameTextField.layer.borderColor = UIColor.red.cgColor
            errorLabelTitle.text = "必須項目です"
        } else if self.categoryNameTextField.text!.range(of: "[Ａ-Ｚａ-ｚ０-９　 ]", options: .regularExpression) != nil {
            categoryNameTextField.layer.borderColor = UIColor.red.cgColor
            errorLabelTitle.text = "全角英数字、全角/半角スペースは登録できません"
        } else if categoryArray.count != 0 {
            print(categoryArray.count)
            categoryNameTextField.layer.borderColor = UIColor.red.cgColor
            errorLabelTitle.text = "既に登録されています"
        } else {
            super.viewDidLoad()
            let alertsheet: UIAlertController = UIAlertController(title: "保存してもいいですか？", message: "", preferredStyle:  UIAlertController.Style.actionSheet)
            
            let save = UIAlertAction(title: "OK", style: .default, handler: { [self] (action) -> Void in
                try! self.realm.write {
                    self.category.categoryName = self.categoryNameTextField.text!
                    self.realm.add(self.category, update: .modified)
                }
                //★？
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
    /*
    func validate() -> (Int) {
        var validCategoryName = 0

        if self.categoryNameTextField.text!.isEmpty {
            validCategoryName = validCategoryName + 1
            return (validCategoryName)
        }
        //★全角英数字、全角スペース、半角スペースの場合NG。
        if self.categoryNameTextField.text!.range(of: "[Ａ-Ｚ０-９　 ]", options: .regularExpression) != nil {
            validCategoryName = validCategoryName + 1
            return (validCategoryName)
        }
        //★すでに登録されているものの場合NG。
        let categoryArray = try! Realm().objects(Task.self).filter("category CONTAINS %@", categoryNameTextField.text!)
        if categoryArray.isEmpty {
            validCategoryName = validCategoryName + 1
        return (validCategoryName)
        }
        return (validCategoryName)
    }
     */
    
    @objc func dismissKeyboard(){
        // キーボードを閉じる
        view.endEditing(true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
