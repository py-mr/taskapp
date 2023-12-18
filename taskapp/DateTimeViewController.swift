//
//  DateTimeViewController.swift
//  taskapp
//
//  Created by A I on 2023/11/30.
//

import UIKit

// NOTE:ここを追加
protocol DateTimeViewDelegate: AnyObject {
    func dateSelected(date: String)
}

class DateTimeViewController: UIViewController {

    @IBOutlet weak var datePicker: UIDatePicker!
    
    // NOTE:ここを変更
    weak var delegate: DateTimeViewDelegate?
    //var parentInputDateViewController: InputViewController?
    var hiduke = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        datePicker.date = dateFormatter.date(from: hiduke)!
    }
    
    @IBAction func commitButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        // NOTE:ここを変更。DateTimeViewDelegate型のクラスのdateSelectedメソッドを実行
        delegate?.dateSelected(date: dateFormatter.string(from: datePicker.date))
        //parentInputDateViewController?.dateSelected = dateFormatter.string(from: datePicker.date)
    }
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        //消えるだけで何もしない
    }
    
    //viewWillDisappear(_:)メソッドは遷移する際に、画面が非表示になるとき呼ばれるメソッド
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
