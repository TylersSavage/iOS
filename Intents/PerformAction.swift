import Foundation
import Shared
import PromiseKit
import Intents

class PerformActionIntentHandler: NSObject, PerformActionIntentHandling {
    func handle(
        intent: PerformActionIntent,
        completion: @escaping (PerformActionIntentResponse) -> Void
    ) {
        guard let result = intent.action?.asActionWithUpdated() else {
            completion(.init(code: .failure, userActivity: nil))
            return
        }

        guard let api = Current.api() else {
            completion(.init(code: .failureRequiringAppLaunch, userActivity: nil))
            return
        }

        firstly {
            api.HandleAction(actionID: result.action.ID, source: .SiriShortcut)
        }.done {
            completion(.success(action: result.updated))
        }.catch { error in
            completion(.failure(error: error.localizedDescription))
        }
    }

    func resolveAction(
        for intent: PerformActionIntent, with completion:
        @escaping (IntentActionResolutionResult) -> Void
    ) {
        if let result = intent.action?.asActionWithUpdated() {
            completion(.success(with: result.updated))
        } else {
            completion(.needsValue())
        }
    }

    func provideActionOptions(
        for intent: PerformActionIntent,
        with completion: @escaping ([IntentAction]?, Error?) -> Void
    ) {
        let actions = Current.realm().objects(Action.self).sorted(byKeyPath: #keyPath(Action.Position))
        let performActions = Array(actions.map { IntentAction(action: $0) })
        Current.Log.info { () -> String in
            return "providing " + performActions.map {
                ($0.identifier ?? "?") + " (" + $0.displayString + ")"
            }.joined(separator: ", ")
        }
        completion(Array(performActions), nil)
    }

    @available(iOS 14, *)
    func provideActionOptionsCollection(
        for intent: PerformActionIntent,
        with completion: @escaping (INObjectCollection<IntentAction>?, Error?) -> Void
    ) {
        provideActionOptions(for: intent) { (actions, error) in
            completion(actions.flatMap { .init(items: $0) }, error)
        }
    }
}
