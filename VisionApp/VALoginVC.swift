//
//  VALoginVC.swift
//  VisionApp
//
//  Created by Emilio Cubo Ruiz on 04/07/2019.
//  Copyright © 2019 VisionApp. All rights reserved.
//

import UIKit

class VALoginVC: UIViewController {
    
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var recoveryPasswordButton: UIButton!
    @IBOutlet weak var loginEmailButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var activityLoader: UIActivityIndicatorView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.userNameTextField.textContentType = .username
        self.userNameTextField.delegate = self
        
        self.passwordTextField.textContentType = .password
        // self.passwordTextField.passwordRules = UITextInputPasswordRules(descriptor: "minlength: 6;")
        self.passwordTextField.delegate = self
        
        self.loginEmailButton.isEnabled = false
        self.loginEmailButton.alpha = 0.4
        
        // self.cancelButton.setTitle(NSLocalizedString("Cancel", tableName: nil, bundle: Bundle(for: type(of: self)), value: "", comment: ""), for: .normal)

        let securityCodeTextField = UITextField()
        if #available(iOS 12.0, *) {
            securityCodeTextField.textContentType = .oneTimeCode
        }

        let tapGestureRecognizer : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyBoard))
        self.view.addGestureRecognizer(tapGestureRecognizer)
        
    }

    @objc func dismissKeyBoard() {
        self.userNameTextField.resignFirstResponder()
        self.passwordTextField.resignFirstResponder()
    }

    func isValidEmail(_ testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        let result = emailTest.evaluate(with: testStr)
        return result
    }

    @IBAction func revoceryPassword(_ sender: UIButton) {
        
        let alertController = UIAlertController(title: NSLocalizedString("Recovery password", tableName: nil, bundle: Bundle(for: type(of: self)), value: "", comment: ""), message: nil, preferredStyle: .alert)

        let recoveryPassAction = UIAlertAction(title: NSLocalizedString("Done", tableName: nil, bundle: Bundle(for: type(of: self)), value: "", comment: ""), style: .default) { (_) in
            let mailTextField = alertController.textFields![0] as UITextField
            self.recoveryPassword(mailTextField.text!)
        }
        recoveryPassAction.isEnabled = false

        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", tableName: nil, bundle: Bundle(for: type(of: self)), value: "", comment: ""), style: .cancel) { (_) in }

        alertController.addTextField { (textField) in
            textField.text = ""
            textField.placeholder = NSLocalizedString("E-Mail", tableName: nil, bundle: Bundle(for: type(of: self)), value: "", comment: "")
            textField.keyboardType = .emailAddress
            NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: OperationQueue.main) { (notification) in
                recoveryPassAction.isEnabled = self.isValidEmail(textField.text!)
            }
        }

        alertController.addAction(recoveryPassAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)

    }
    
    func recoveryPassword(_ email:String) {
        VARequestManager.shared.recoveryPassword(email: email) { (success, message) in
            if success {
                self.alertSuccessMessage(message: NSLocalizedString("An email has been sent to retrieve the password", tableName: nil, bundle: Bundle(for: type(of: self)), value: "", comment: ""))
            } else {
                self.alertErrorMessage(message: message)
            }
        }
    }
    
    @IBAction func loginWithEmail(_ sender: UIButton) {
        if loginEmailButton.isEnabled {
            self.activityLoader.startAnimating()
            self.recoveryPasswordButton.isEnabled = false
            self.cancelButton.isEnabled = false
            VARequestManager.shared.signInUser(userNameTextField.text, password: passwordTextField.text) { (success, message, user) in
                self.activityLoader.stopAnimating()
                self.recoveryPasswordButton.isEnabled = true
                self.cancelButton.isEnabled = true
                if let user = user {
                    VASessionManager.shared.setUserInfo(user)
                    self.gotoApp()
                } else {
                    self.alertErrorMessage(message: message)
                }
            }
        }
    }
    
    @IBAction func cancelLogin(_ sender: Any) {
        self.dismiss(animated: true) {
            VisionApp.shared.delegate?.cancelVALogin()
        }
    }
    
    func gotoApp() {
        if VASessionManager.shared.currentUser != nil {
            self.dismiss(animated: true) {
                VisionApp.shared.startTracking()
            }
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func alertSuccessMessage(message:String) {
        let alertController = UIAlertController(title: NSLocalizedString("Success", tableName: nil, bundle: Bundle(for: type(of: self)), value: "", comment: ""), message: message, preferredStyle: .alert)
        let doneAction = UIAlertAction(title: NSLocalizedString("Done", tableName: nil, bundle: Bundle(for: type(of: self)), value: "", comment: ""), style: .cancel, handler: nil)
        alertController.addAction(doneAction)
        self.present(alertController, animated: true, completion: nil)
    }

    func alertErrorMessage(message:String) {
        let alertController = UIAlertController(title: NSLocalizedString("Error", tableName: nil, bundle: Bundle(for: type(of: self)), value: "", comment: ""), message: message, preferredStyle: .alert)
        let doneAction = UIAlertAction(title: NSLocalizedString("Done", tableName: nil, bundle: Bundle(for: type(of: self)), value: "", comment: ""), style: .cancel, handler: nil)
        alertController.addAction(doneAction)
        self.present(alertController, animated: true, completion: nil)
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


extension VALoginVC: UITextFieldDelegate {
    
    func runAfterDelay(_ delay: TimeInterval, block: @escaping ()->()) {
        let time = DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time, execute: block)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.userNameTextField {
            self.userNameTextField.resignFirstResponder()
            self.passwordTextField.becomeFirstResponder()
        } else if loginEmailButton.isEnabled {
            self.dismissKeyBoard()
            runAfterDelay(0.1) {
                self.loginWithEmail(self.loginEmailButton)
            }
        }
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.loginEmailButton.isEnabled = false
        self.loginEmailButton.alpha = 0.4
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        var txtUser:NSString = (self.userNameTextField.text ?? "") as NSString
        var txtPassword:NSString = (self.passwordTextField.text ?? "") as NSString
        if textField == self.passwordTextField {
            txtPassword = (self.passwordTextField.text ?? "") as NSString
            txtPassword = txtPassword.replacingCharacters(in: range, with: string) as NSString
        } else {
            txtUser = (self.userNameTextField.text ?? "") as NSString
            txtUser = txtUser.replacingCharacters(in: range, with: string) as NSString
        }
        
        if !self.isValidEmail(txtUser as String) || (txtPassword as String) == "" {
            self.loginEmailButton.isEnabled = false
            self.loginEmailButton.alpha = 0.4
        } else {
            self.loginEmailButton.isEnabled = true
            self.loginEmailButton.alpha = 1
        }
        
        return true
    }
    
}
