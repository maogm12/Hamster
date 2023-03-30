//
//  AlphabetKeyboard.swift
//  HamsterKeyboard
//
//  Created by morse on 10/1/2023.
//

import Combine
import KeyboardKit
import SwiftUI

@available(iOS 14, *)
struct AlphabetKeyboard: View {
  var ivc: HamsterKeyboardViewController

  var appearance: KeyboardAppearance
  var actionHandler: KeyboardActionHandler

  @EnvironmentObject
  private var keyboardCalloutContext: KeyboardCalloutContext

  @EnvironmentObject
  private var keyboardContext: KeyboardContext

  @EnvironmentObject
  private var rimeEngine: RimeEngine

  @EnvironmentObject
  private var appSettings: HamsterAppSettings

  @Environment(\.openURL) var openURL

  init(keyboardInputViewController ivc: HamsterKeyboardViewController) {
    Logger.shared.log.debug("AlphabetKeyboard init")
    self.ivc = ivc
    self.appearance = ivc.keyboardAppearance
    self.actionHandler = ivc.keyboardActionHandler
  }

  var keyboard: some View {
    SystemKeyboard(
      controller: ivc,
      autocompleteToolbarMode: .none,
      buttonView: { layoutItem, keyboardWidth, inputWidth in
        SystemKeyboardButtonRowItem(
          content: HamsterKeyboardActionButtonContent(
            action: layoutItem.action,
            appearance: appearance,
            keyboardContext: keyboardContext,
            appSettings: appSettings
          ),
          item: layoutItem,
          actionHandler: actionHandler,
          keyboardContext: keyboardContext,
          calloutContext: keyboardCalloutContext,
          keyboardWidth: keyboardWidth,
          inputWidth: inputWidth,
          appearance: appearance
        )
      }
    )
  }

  var body: some View {
    VStack(spacing: 0) {
      if keyboardContext.keyboardType != .emojis {
        HStack(spacing: 0) {
          ZStack(alignment: .leading) {
            HamsterAutocompleteToolbar(ivc: ivc)

            if rimeEngine.userInputKey.isEmpty {
              HStack {
                // 主菜单功能暂未实现
                //                Image(systemName: "house.circle.fill")
                //                  .font(.system(size: 25))
                //                  .foregroundColor(Color.gray)
                //                  .frame(width: 25, height: 25)
                //                  .padding(.leading, 15)
                //                  .onTapGesture {}

                Spacer()

                if appSettings.showKeyboardDismissButton {
                  Image(systemName: "chevron.down.circle.fill")
                    .iconStyle()
                    .padding(.trailing, 15)
                    .onTapGesture {
                      ivc.dismissKeyboard()
                    }
                }
              }
            }
          }
        }
        .frame(minWidth: 0, maxWidth: .infinity)
      }

      keyboard.background(backgroudColor)
    }
  }

  var backgroudColor: Color {
    return rimeEngine.currentColorSchema.backColor ?? .clearInteractable
  }

  var width: CGFloat {
    // TODO: 横向的全面屏需要减去左右两边的听写键和键盘切换键
    return !keyboardContext.isPortrait && keyboardContext.hasDictationKey
      ? standardKeyboardWidth - 150 : standardKeyboardWidth
  }

  var standardKeyboardWidth: CGFloat {
    ivc.view.frame.width
  }
}

struct IconModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .font(.system(size: 24))
      .foregroundColor(Color.gray)
      .frame(width: 25, height: 25)
  }
}

extension View {
  func iconStyle() -> some View {
    modifier(IconModifier())
  }
}