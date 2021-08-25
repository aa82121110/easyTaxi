//
//  LoactionInputView.swift
//  easyTaxi
//
//  Created by 黃梓峻 on 2021/8/12.
//

import UIKit

protocol LoactionInputViewDelegate: class {
    func dismissLoactionInputView()
    func executeSearch(query: String)
}

class LoactionInputView: UIView {
    
    //MARK: - Properties
    
    var user: User? {
        didSet{titleLabel.text = user?.fullname}
    }
    
    weak var delegate:LoactionInputViewDelegate?
    
    private let backButton:UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "baseline_arrow_back_black_36dp-1").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleBackTapped), for: .touchUpInside)
        return button
    }()
    
   private let titleLabel:UILabel = {
        let label = UILabel()
        label.textColor = .darkGray
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    
    private let startLocationIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()
    
    private let linkingView:UIView = {
       let view = UIView()
        view.backgroundColor = .darkGray
        return view
    }()
    
    private let destinationIndicatorView:UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    private lazy var stratingLocationTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "起始點"
        tf.backgroundColor = .groupTableViewBackground
        tf.isEnabled = false
        
        let paddingView = UIView()
        paddingView.setDimenSions(height: 30, width: 8)
        tf.leftView = paddingView
        tf.leftViewMode = .always
        
        return tf
    }()
    
    private lazy var destinationLocationTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "終點"
        tf.backgroundColor = .lightGray
        tf.returnKeyType = .search
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.delegate = self
        
        let paddingView = UIView()
        paddingView.setDimenSions(height: 30, width: 8)
        tf.leftView = paddingView
        tf.leftViewMode = .always
        
        return tf
    }()
    
    //MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
       
        backgroundColor = .white
        
        addSubview(backButton)
        backButton.anchor(top:topAnchor,left: leftAnchor,paddingTop: 44,paddingLeft: 12,width: 24,height: 25)
        addShadow()
        
        addSubview(titleLabel)
        titleLabel.centerY(inView: backButton)
        titleLabel.centerX(inView: self)
        
        addSubview(stratingLocationTextField)
        stratingLocationTextField.anchor(top: backButton.bottomAnchor,left: leftAnchor,right: rightAnchor,paddingTop: 4,paddingLeft: 40,paddingRight: 40,height: 30)
        
        addSubview(destinationLocationTextField)
        destinationLocationTextField.anchor(top: stratingLocationTextField.bottomAnchor,left: leftAnchor,right: rightAnchor,paddingTop: 12,paddingLeft: 40,paddingRight: 40,height: 30)
        
        addSubview(startLocationIndicatorView)
        startLocationIndicatorView.centerY(inView: stratingLocationTextField,leftAnchor: leftAnchor,paddingLeft: 20)
        startLocationIndicatorView.setDimenSions(height: 6, width: 6)
        startLocationIndicatorView.layer.cornerRadius = 6 / 2
        
        addSubview(destinationIndicatorView)
        destinationIndicatorView.centerY(inView: destinationLocationTextField,leftAnchor: leftAnchor,paddingLeft: 20)
        destinationIndicatorView.setDimenSions(height: 6, width: 6)
        destinationIndicatorView.layer.cornerRadius = 6 / 2
    
        addSubview(linkingView)
        linkingView.centerX(inView: startLocationIndicatorView)
        linkingView.anchor(top:startLocationIndicatorView.bottomAnchor,bottom: destinationIndicatorView.topAnchor,paddingTop: 4,paddingBottom: 4,width: 0.5)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Selectors
    @objc func handleBackTapped() {
        delegate?.dismissLoactionInputView()
    }
    
}

// MARK: -UITextFieldDelegate

extension LoactionInputView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let query = textField.text else {return false}
        delegate?.executeSearch(query: query)
        return true
    }
}
