//
//  InputSchemaViewModel.swift
//  Hamster
//
//  Created by morse on 2023/6/13.
//
import Combine
import HamsterKeyboardKit
import HamsterUIKit
import OSLog
import ProgressHUD
import RimeKit
import UIKit

public class InputSchemaViewModel {
  // MARK: properties

  public let rimeContext: RimeContext

  public var reloadTableStateSubject = PassthroughSubject<Bool, Never>()
  public var reloadTableStatePublisher: AnyPublisher<Bool, Never> {
    reloadTableStateSubject.eraseToAnyPublisher()
  }

  public var presentDocumentPickerPublisher: AnyPublisher<Bool, Never> {
    presentDocumentPickerSubject.eraseToAnyPublisher()
  }

  /// 注意: 这是私有属性，在 View 中订阅上面的 presentDocumentPickerPublisher 响应是否打开文档View
  /// 而在 ViewModel 内部使用 presentDocumentPickerSubject 发布状态
  private let presentDocumentPickerSubject = PassthroughSubject<Bool, Never>()

  public var errorMessagePublisher: AnyPublisher<ErrorMessage, Never> {
    errorMessageSubject.eraseToAnyPublisher()
  }

  private let errorMessageSubject = PassthroughSubject<ErrorMessage, Never>()

  // MARK: methods

  public init(rimeContext: RimeContext) {
    self.rimeContext = rimeContext
  }
}

extension InputSchemaViewModel {
  @objc func openDocumentPicker() {
    presentDocumentPickerSubject.send(true)
  }

  /// 选择 InputSchema
  func checkboxForInputSchema(_ schema: RimeSchema) async throws {
    let selectSchemas = await rimeContext.selectSchemas
    if !selectSchemas.contains(schema) {
      await rimeContext.appendSelectSchema(schema)
    } else {
      if selectSchemas.count == 1 {
        throw "需要保留至少一个输入方案。"
      }
      await rimeContext.removeSelectSchema(schema)
    }
    reloadTableStateSubject.send(true)
  }

  /// 导入zip文件
  public func importZipFile(fileURL: URL) async {
    Logger.statistics.debug("file.fileName: \(fileURL.path)")

    await ProgressHUD.show("方案导入中……", interaction: false)
    do {
      // 检测 Rime 目录是否存在
      try FileManager.createDirectory(override: false, dst: FileManager.sandboxUserDataDirectory)
      try await FileManager.default.unzip(fileURL, dst: FileManager.sandboxUserDataDirectory)

      var hamsterConfiguration = HamsterAppDependencyContainer.shared.configuration

      await ProgressHUD.show("方案部署中……", interaction: false)
      try await rimeContext.deployment(configuration: hamsterConfiguration)

      // 读取 Rime 目录下 hamster.yaml 配置文件，如果存在
      if let configuration =
        try? HamsterConfigurationRepositories.shared.loadFromYAML(FileManager.hamsterConfigFileOnUserDataSupport)
      {
        hamsterConfiguration = configuration
      }

      // 读取 Rime 目录下 hamster.custom.yaml 配置文件(如果存在)，并对相异的配置做 merge （已 hamster.custom.yaml 文件为主）
      if let patchConfiguration =
        try? HamsterConfigurationRepositories.shared.loadPatchFromYAML(yamlPath: FileManager.hamsterPatchConfigFileOnUserDataSupport),
        let configuration = patchConfiguration.patch
      {
        hamsterConfiguration = try hamsterConfiguration.merge(with: configuration, uniquingKeysWith: { $1 })
      }

      HamsterAppDependencyContainer.shared.configuration = hamsterConfiguration

      // 发布
      reloadTableStateSubject.send(true)
      await ProgressHUD.showSuccess("导入成功", interaction: false, delay: 1.5)
    } catch {
      await ProgressHUD.dismiss()
      Logger.statistics.debug("zip \(error)")
      errorMessageSubject.send(ErrorMessage(title: "导入Zip文件", message: "导入失败, \(error.localizedDescription)"))
    }
  }
}
