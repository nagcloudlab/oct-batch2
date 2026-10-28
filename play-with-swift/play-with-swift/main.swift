// =====================================================================
//  Unit 5 · Lesson 5.3 — @MainActor
// =====================================================================
//  @MainActor = a special, global actor tied to the MAIN THREAD.
//  Mark UI-related code with it, and Swift guarantees it runs on main.
//
//  (Console app: our "screen" is a class that prints its status.)
// =====================================================================

import Foundation

func isMain() -> Bool { Thread.isMainThread }

// The bank API: an actor → runs OFF the main thread.
actor BankAPI {
    func process(_ amount: Int) async -> String {
        print("    bank working…           main thread? \(isMain())")
        try? await Task.sleep(for: .seconds(1))
        return "TXN-\(amount)"
    }
}

// ---------------------------------------------------------------------
// ❌ PROBLEM: UI state updated from a background thread
// ---------------------------------------------------------------------
// In a real app, UI must only be touched on the main thread.
final class UnsafeScreen: @unchecked Sendable {
    var status = "Ready" {
        didSet { print("    status = \(status)   main thread? \(isMain())") }
    }
}

print("❌ PROBLEM: nothing stops background code from updating the UI")
let unsafeScreen = UnsafeScreen()
await Task.detached {
    unsafeScreen.status = "Payment Successful"   // 💥 in UIKit/SwiftUI: bug or crash
}.value
print()


@MainActor
final class PaymentScreen {
    let bank = BankAPI()

    var status = "Ready" {
        didSet { print("    status = \(status)   main thread? \(isMain())") }
    }

    func sendTapped(amount: Int) async {
        status = "Processing ₹\(amount)..."         // on main
        let txn = await bank.process(amount)         // ⏸ hops to the bank actor
        status = "Paid ✅ \(txn)"                    // back on main automatically
    }
}

print("✅ SOLUTION: @MainActor class")
let screen = PaymentScreen()
await screen.sendTapped(amount: 500)
print()

// Background code now MUST hop to main to touch the screen:
await Task.detached {
    // screen.status = "Hacked"
    // ❌ error: main actor-isolated property 'status' can not be mutated from a nonisolated context

    await MainActor.run {                        // ✅ explicitly hop to main
        screen.status = "Updated from background, safely"
    }
}.value
print()
