//
//  SwitchRoomViewController.swift
//  TRTC-API-Example-Swift
//
//  Created by 唐佳宁 on 2022/7/4.
//  Copyright © 2022 Tencent. All rights reserved.
//

/*
 快速切换房间示例
 TRTC APP 支持快速切换房间功能
 本文件展示如何集成快速切换房间功能
 1、进入TRTC房间。 API:[self.trtcCloud enterRoom:params appScene:TRTCAppSceneLIVE];
 2、快速切换房间。  API:[self.trtcCloud switchRoom:self.switchRoomConfig];
 参考文档：https://cloud.tencent.com/document/product/647/32258
 */
/*
 Switching Rooms
 The TRTC app supports quick room switching.
 This document shows how to integrate the room switching feature.
 1. Enter a room: [self.trtcCloud enterRoom:params appScene:TRTCAppSceneLIVE]
 2. Switch rooms: [self.trtcCloud switchRoom:self.switchRoomConfig]
 Documentation: https://cloud.tencent.com/document/product/647/32258
 */


import Foundation
import UIKit
import TXLiteAVSDK_TRTC

class SwitchRoomViewController : UIViewController{

    override func viewDidLoad() {
        super.viewDidLoad()
        title = LocalizeReplace((Localize("TRTC-API-Example.SwitchRoom.Title")), roomIdTextField.text ?? "")
        view.backgroundColor = .black
        trtcCloud.delegate = self
        roomIdTextField.delegate = self
        setupDefaultUIConfig()
        activateConstraints()
        bindInteraction()
        addKeyboardObserver()

    }
    
    private func startPushStream(){
        title = LocalizeReplace(Localize("TRTC-API-Example.SwitchRoom.Title"), roomIdTextField.text ?? "")
        trtcCloud.startLocalPreview(true, view: view)
        
        let params = TRTCParams()
        params.sdkAppId = UInt32(SDKAppID)
        if let text = roomIdTextField.text{
            params.roomId = UInt32((text as NSString).intValue)
        }
        params.userId = String(arc4random()%(999999 - 100000 + 1)+100000)
        params.role = .anchor
        params.userSig = GenerateTestUserSig.genTestUserSig(identifier: params.userId ) as String
        
        
        trtcCloud.enterRoom(params, appScene: .LIVE)
        trtcCloud.startLocalAudio(.music)
        
        let encParams =  TRTCVideoEncParam()
        encParams.videoResolution = ._960_540
        encParams.videoFps = 24
        encParams.resMode = .portrait
        
        trtcCloud.setVideoEncoderParam(encParams)
        
    }
    
    private func stopPushStream(){
        title = LocalizeReplace(Localize("TRTC-API-Example.SwitchRoom.Title"), roomIdTextField.text ?? "")
        trtcCloud.stopLocalPreview()
        trtcCloud.stopLocalAudio()
        trtcCloud.exitRoom()
    }

    let trtcCloud = TRTCCloud.sharedInstance()
    let bottomConstraint = NSLayoutConstraint()
    let switchRoomConfig =  TRTCSwitchRoomConfig()

    let toastLabel:UILabel={
        let lable = UILabel(frame: .zero)
        lable.textColor = .white
        lable.adjustsFontSizeToFitWidth = true
        lable.text = Localize("TRTC-API-Example.SwitchRoom.inputRoomIDNumber")
//        lable.backgroundColor = .gray
        return lable
    }()

    let roomIdLabel:UILabel={
        let lable = UILabel(frame: .zero)
        lable.textColor = .white
        lable.adjustsFontSizeToFitWidth = true
//        lable.backgroundColor = .gray
        lable.text = Localize("TRTC-API-Example.SwitchRoom.roomId")

        return lable
    }()


    let roomIdTextField : UITextField={
        let filed = UITextField(frame: .zero)
        filed.keyboardAppearance = .default
        filed.text = String(arc4random()%(99999999 - 10000000 + 1)+10000000)
        filed.textColor = .black
        filed.backgroundColor = .white
        filed.returnKeyType = .done
        return filed
    }()

    let changeRoomButton : UIButton={
        let button = UIButton(frame: .zero)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.textColor = .white
        button.backgroundColor = .gray
        button.isEnabled = false
        button.setTitle(Localize("TRTC-API-Example.SwitchRoom.changeRoom"), for: .normal)
        return button
    }()

    let pushStreamButton : UIButton={
        let button = UIButton(frame: .zero)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.textColor = .white
        button.backgroundColor = .green
        button.setTitle(Localize("TRTC-API-Example.SwitchRoom.startPush"), for: .normal)
        button.setTitle(Localize("TRTC-API-Example.SwitchRoom.stopPush"), for: .selected)
        return button
    }()


    let toastView : UIView={
        let view = UIView(frame: .zero)
        view.alpha = 0

        return view
    }()

}

extension SwitchRoomViewController{
    private func setupDefaultUIConfig(){
        view.addSubview(toastLabel)
        view.addSubview(roomIdLabel)
        view.addSubview(roomIdTextField)
        view.addSubview(changeRoomButton)
        view.addSubview(pushStreamButton)
        view.addSubview(toastView)
    }

    private func activateConstraints(){

        toastLabel.snp.makeConstraints { make in
            make.width.equalTo(150)
            make.height.equalTo(30)
            make.centerX.equalTo(view)
            make.top.equalTo(view.snp.bottom).offset(-150)
        }

        roomIdLabel.snp.makeConstraints { make in
            make.width.equalTo(45)
            make.height.equalTo(25)
            make.left.equalTo(view.snp.left).offset(20)
            make.top.equalTo(toastLabel.snp.bottom).offset(10)
        }

        roomIdTextField.snp.makeConstraints { make in
            make.width.equalTo(150)
            make.height.equalTo(30)
            make.left.equalTo(roomIdLabel)
            make.top.equalTo(roomIdLabel.snp.bottom).offset(5)
        }

        changeRoomButton.snp.makeConstraints { make in
            make.width.equalTo((view.frame.width - 230)/2)
            make.height.equalTo(30)
            make.left.equalTo(roomIdTextField.snp.right).offset(20)
            make.top.equalTo(roomIdTextField)
        }

        pushStreamButton.snp.makeConstraints { make in
            make.width.equalTo(changeRoomButton)
            make.height.equalTo(changeRoomButton)
            make.top.equalTo(changeRoomButton)
            make.left.equalTo(changeRoomButton.snp.right).offset(20)
        }
    }
    private func bindInteraction(){
        changeRoomButton.addTarget(self, action: #selector(onChangeRoomClick), for: .touchUpInside)
        pushStreamButton.addTarget(self, action: #selector(onPushStreamClick), for: .touchUpInside)
    }
}
extension SwitchRoomViewController{
    @objc private func onChangeRoomClick(){
        if roomIdTextField.text?.count ?? 0 < 8{
            UIView.animate(withDuration: 0.35) {
                self.toastView.alpha = 1
            } completion: { finish in
                UIView.animate(withDuration: 0.35, delay: 1.5, options: .curveEaseInOut) {
                    self.toastView.alpha = 0
                } completion: { finish in
                }
                return

            }

        }
        if let text = roomIdTextField.text{
            switchRoomConfig.roomId = UInt32((text as NSString).intValue)
        }
        trtcCloud.switchRoom(switchRoomConfig)
        title = LocalizeReplace(Localize("TRTC-API-Example.SwitchRoom.Title"), roomIdTextField.text ?? "")
    }
    
    @objc private func onPushStreamClick(){
        pushStreamButton.isSelected = !pushStreamButton.isSelected
        if pushStreamButton.isSelected{
            startPushStream()
            changeRoomButton.backgroundColor = .green
            changeRoomButton.isEnabled = true
        }else{
            stopPushStream()
            changeRoomButton.backgroundColor = .gray
            changeRoomButton.isEnabled = false
        }
    }
    
    
    


}

extension SwitchRoomViewController{

    func addKeyboardObserver(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func removeKeyboardObserver(){
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }


    @objc func keyboardWillShow(_ noti:NSNotification){
        let animationDuration = noti.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey]
        let keyboardBounds = noti.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
        UIView.animate(withDuration: animationDuration as! TimeInterval) { [self] in
            self.bottomConstraint.constant = (keyboardBounds as! CGRect).size.height
        }
    }

    @objc func keyboardWillHide(_ noti:NSNotification){
        let animationDuration = noti.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey]

        UIView.animate(withDuration:animationDuration as! TimeInterval) { [self] in
            self.bottomConstraint.constant = 25
        }
    }

    func dealloc(){
        removeKeyboardObserver()
        trtcCloud.stopLocalAudio()
        trtcCloud.stopLocalPreview()
        trtcCloud.exitRoom()
        TRTCCloud.destroySharedIntance()
    }

}

extension SwitchRoomViewController:UITextFieldDelegate{
  
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        roomIdTextField.resignFirstResponder()
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return roomIdTextField.resignFirstResponder()
    }
}

extension SwitchRoomViewController:TRTCCloudDelegate{
    func onSwitchRoom(_ errCode: TXLiteAVError, errMsg: String?) {
        
    }
}




