//
//  SignUpController.swift
//  easyTaxi
//
//  Created by 黃梓峻 on 2021/8/8.
//

import UIKit
import Firebase
import GeoFire

class  SignUpController: UIViewController {
    
    // MARK: - UI
    
    private var location = LocationHandler.shared.locationManager.location
    
    private let titleLabel : UILabel = {
        let label = UILabel()
        label.text = "EASY TAXI"
        label.font = UIFont(name: "Avenir-Light", size: 36)
        label.textColor = UIColor(white: 1, alpha: 0.8)
        return label
    }()
    
    private lazy var emailContainerView:UIView = {
        let view = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_mail_outline_white_2x"), textField: emailTextField)
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return view
    }()
    
    private lazy var fullNameContainerView:UIView = {
        let view = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_person_outline_white_2x"), textField: fullnameTextField)
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return view
    }()
    
    private lazy var passwordContainerView:UIView = {
        let view = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_lock_outline_white_2x"), textField: passwordTextField)
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return view
    }()
    
    private lazy var accountTypeContainerView:UIView = {
        let view = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_account_box_white_2x"), segmentedControl: accountTypeSegmnetedControl)
        view.heightAnchor.constraint(equalToConstant: 80).isActive = true
        return view
    }()
    
    private let emailTextField: UITextField = {
        return UITextField().textField(withPlaceHolder: "Email", isSecureTextEntry: false)
    }()
    
    private let fullnameTextField: UITextField = {
        return UITextField().textField(withPlaceHolder: "Full name", isSecureTextEntry: false)
    }()
    
    private let passwordTextField: UITextField = {
        return UITextField().textField(withPlaceHolder: "Password", isSecureTextEntry: true)
    }()
    
    private let accountTypeSegmnetedControl:UISegmentedControl = {
        let sc = UISegmentedControl(items: ["一般","駕駛"])
        sc.backgroundColor = .backgroundColor
        sc.tintColor = UIColor(white: 1, alpha: 0.87)
        sc.selectedSegmentIndex = 0
        return sc
    }()
    
    private let signUpButton :AuthButton = {
        let button = AuthButton(type: .system)
        button.setTitle("註冊", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        return button
    }()
    
    let alreadyHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        let attributedTitle = NSMutableAttributedString(string: "已經有帳號了嗎？ ", attributes:[NSAttributedString.Key.font:UIFont.systemFont(ofSize: 16),
                                                                                                         NSAttributedString.Key.foregroundColor:UIColor.lightGray])
        attributedTitle.append(NSAttributedString(string: "登入", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16),
                                                                                 NSAttributedString.Key.foregroundColor:UIColor.mainBlueTint]))
        button.addTarget(self, action: #selector(handleShowLogin), for: .touchUpInside)
        button.setAttributedTitle(attributedTitle, for: .normal)
        return button
    }()
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        print("DEBUG: location \(location)")
    }
    
    // MARK: - Selectors
    @objc func handleShowLogin() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func handleSignUp() {
        guard let email = emailTextField.text else {return}
        guard let passwrod = passwordTextField.text else {return}
        guard let fullname = fullnameTextField.text else {return}
        let accountTypeIndex = accountTypeSegmnetedControl.selectedSegmentIndex
        //註冊電子信箱
        Auth.auth().createUser(withEmail: email, password: passwrod) { result, error in
            if let error = error {
                print("DEBUG: Failed to register user")
                return
            }
            //取得電子信箱的uid
            guard let uid = result?.user.uid else {return}
            //準備傳到DB 的欄位
            let values = ["email": email, "fullname":fullname, "accountType": accountTypeIndex] as [String : Any]
            
            //如果是駕駛的話
            if accountTypeIndex == 1{
                let geofire = GeoFire(firebaseRef: REF_DRIVER_LOCATIONS)
                guard let location = self.location else {return}
                geofire.setLocation(location, forKey: uid) { error in
                    self.uploadUserDataAndShowHomeController(uid: uid, values: values)
                }
            }else {
                self.uploadUserDataAndShowHomeController(uid: uid, values: values)
            }
            
        }
    }
    
    //MARK: - Helper Functions
    
    func uploadUserDataAndShowHomeController(uid: String, values: [String:Any]) {
        REF_USERS.child(uid).updateChildValues(values) { error, ref in
            print("成功註冊與存到data.")
            //如果成功登入的話就配置mapView
             guard let nav = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController
             else {return}
             guard let controller = nav.viewControllers.first as? HomeController else {return}
             controller.configure()
             self.dismiss(animated: true, completion: nil)
        }
    }
    
    func configureUI() {
        self.view.backgroundColor = .backgroundColor
        
        view.addSubview(titleLabel)
        titleLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor)
        titleLabel.centerX(inView: view)
        
        let stack = UIStackView(arrangedSubviews: [emailContainerView,fullNameContainerView,passwordContainerView,accountTypeContainerView,signUpButton])
        stack.axis = .vertical
        stack.distribution = .fillProportionally
        stack.spacing = 24
        
        view.addSubview(stack)
        stack.anchor(top: titleLabel.bottomAnchor,left: view.leftAnchor,right: view.rightAnchor, paddingTop:  40, paddingLeft: 16, paddingRight: 16)
        
        view.addSubview(alreadyHaveAccountButton)
        alreadyHaveAccountButton.centerX(inView: view)
        alreadyHaveAccountButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor,height: 32)
    }
}
