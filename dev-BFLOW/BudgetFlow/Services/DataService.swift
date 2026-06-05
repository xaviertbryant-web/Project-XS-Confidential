import Foundation

class DataService {
    static let shared = DataService()
    private let defaults = UserDefaults.standard

    func saveProfile(_ profile: UserProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            defaults.set(data, forKey: "userProfile")
        }
    }

    func loadProfile() -> UserProfile {
        guard let data = defaults.data(forKey: "userProfile"),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data)
        else { return .default }
        return profile
    }

    func saveGoals(_ goals: [Goal]) {
        if let data = try? JSONEncoder().encode(goals) {
            defaults.set(data, forKey: "goals")
        }
    }

    func loadGoals() -> [Goal] {
        guard let data = defaults.data(forKey: "goals"),
              let goals = try? JSONDecoder().decode([Goal].self, from: data)
        else { return Goal.sampleData }
        return goals
    }

    func savePaycheckBudget(_ budget: PaycheckBudget) {
        if let data = try? JSONEncoder().encode(budget) {
            defaults.set(data, forKey: "paycheckBudget")
        }
    }

    func loadPaycheckBudget() -> PaycheckBudget {
        guard let data = defaults.data(forKey: "paycheckBudget"),
              let budget = try? JSONDecoder().decode(PaycheckBudget.self, from: data)
        else { return .default }
        return budget
    }
}
