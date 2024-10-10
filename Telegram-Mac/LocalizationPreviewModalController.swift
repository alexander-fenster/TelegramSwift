//
//  LocalizationPreviewModalController.swift
//  Telegram
//
//  Created by Mikhail Filimonov on 11/12/2018.
//  Copyright © 2018 Telegram. All rights reserved.
//

import Cocoa
import TGUIKit
import TelegramCore


private final class LocalizationPreviewView : Control {
    
    private let textView: TextView = TextView()
    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        textView.isSelectable = false
        addSubview(textView)
    }
    
    func update(with info: LocalizationInfo, width: CGFloat) -> CGFloat {
        
        
        let text: String
        if info.isOfficial {
            text = strings().applyLanguageChangeLanguageOfficialText(info.title)
        } else {
            text = strings().applyLanguageChangeLanguageUnofficialText1(info.title, "\(Int(Float(info.translatedStringCount) / Float(info.totalStringCount) * 100.0))")
        }
        
        let attributedText = parseMarkdownIntoAttributedString(text, attributes: MarkdownAttributes(body: MarkdownAttributeSet(font: .normal(.text), textColor: theme.colors.text), bold: MarkdownAttributeSet(font: .bold(.text), textColor: theme.colors.text), link: MarkdownAttributeSet(font: .normal(.text), textColor: theme.colors.link), linkAttribute: { contents in
            return (NSAttributedString.Key.link.rawValue, inAppLink.callback(contents, { _ in
                execute(inapp: .external(link: info.platformUrl, false))
            }))
        })).mutableCopy() as! NSMutableAttributedString
        attributedText.detectBoldColorInString(with: .bold(.text))
        
        let textLayout = TextViewLayout(attributedText, alignment: .center, alwaysStaticItems: true)
        textLayout.measure(width: width - 40)
        
        textLayout.interactions = globalLinkExecutor
        
        textView.update(textLayout)
        
        return 40 + textLayout.layoutSize.height
    }
    
    override func layout() {
        super.layout()
        textView.centerX(y: 20)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LocalizationPreviewModalController: ModalViewController {
    private let context: AccountContext
    private let info: LocalizationInfo
    init(_ context: AccountContext, info: LocalizationInfo) {
        self.info = info
        self.context = context
        super.init(frame: NSMakeRect(0, 0, 320, 200))
        bar = .init(height: 0)
    }
    private var genericView:LocalizationPreviewView {
        return self.view as! LocalizationPreviewView
    }
    
    private func applyLocalization() {
        close()
        _ = showModalProgress(signal: context.engine.localization.downloadAndApplyLocalization(accountManager: context.sharedContext.accountManager, languageCode: info.languageCode), for: context.window).start()
    }
    
    override var modalInteractions: ModalInteractions? {
        return ModalInteractions(acceptTitle: strings().applyLanguageApplyLanguageAction, accept: { [weak self] in
            self?.applyLocalization()
        }, drawBorder: true, height: 50, singleButton: true)
    }
    
    override var modalHeader: (left: ModalHeaderData?, center: ModalHeaderData?, right: ModalHeaderData?)? {
        return (left: ModalHeaderData(image: theme.icons.modalClose, handler: { [weak self] in
            self?.close()
        }), center: ModalHeaderData(title: strings().applyLanguageChangeLanguageTitle), right: nil)
    }
    
    override func viewClass() -> AnyClass {
        return LocalizationPreviewView.self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let value = genericView.update(with: info, width: frame.width)
        self.modal?.resize(with:NSMakeSize(genericView.frame.width, value), animated: false)
        
        readyOnce()
        
    }
}
