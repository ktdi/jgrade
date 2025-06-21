import Foundation
import SwiftUI

struct Student: Identifiable, Codable {
    let id: UUID
    var name: String
    var gradeLevel: Int
    
    init(name: String, gradeLevel: Int) {
        self.id = UUID()
        self.name = name
        self.gradeLevel = gradeLevel
    }
}

enum GradeType: String, Codable, CaseIterable {
    case test = "Test"
    case quiz = "Quiz"
    case homework = "Homework"
}

struct GradeEntry: Identifiable, Codable {
    var id = UUID()
    var studentId: UUID
    var subject: String
    var period: Int
    var value: String
    var type: GradeType
}

struct BackupData: Codable {
    let students: [Student]
    let testWeight: Double
    let quizWeight: Double
    let homeworkWeight: Double
    let grades: [GradeEntry]
}

class StudentManager: ObservableObject {
    @Published var students: [Student] = [] {
        didSet { saveStudents() }
    }
    
    @Published var testWeight: Double = 50 {
        didSet { saveWeights() }
    }
    
    @Published var quizWeight: Double = 17 {
        didSet { saveWeights() }
    }
    
    @Published var homeworkWeight: Double = 33 {
        didSet { saveWeights() }
    }
    
    @Published var allGrades: [GradeEntry] = [] {
        didSet { saveGrades() }
    }
    
    init() {
        loadStudents()
        loadWeights()
        loadGrades()
    }
    
    // MARK: - Student Methods
    
    func add(_ name: String, gradeLevel: Int) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        students.append(Student(name: trimmed, gradeLevel: gradeLevel))
    }
    
    func delete(at offsets: IndexSet) {
        let removedIds = offsets.map { students[$0].id }
        students.remove(atOffsets: offsets)
        allGrades.removeAll { grade in removedIds.contains(grade.studentId) }
    }
    
    // MARK: - Grade Methods
    
    func addGrade(_ grade: GradeEntry) {
        allGrades.append(grade)
    }
    
    func deleteGrade(_ grade: GradeEntry) {
        allGrades.removeAll { $0.id == grade.id }
    }
    
    func weight(for type: GradeType) -> Double {
        switch type {
        case .test: return testWeight
        case .quiz: return quizWeight
        case .homework: return homeworkWeight
        }
    }
    
    // MARK: - Persistence
    
    private let studentsKey = "SavedStudents"
    private let weightsKey = "SavedWeights"
    private let gradesKey = "SavedGrades"
    
    func saveStudents() {
        if let data = try? JSONEncoder().encode(students) {
            UserDefaults.standard.set(data, forKey: studentsKey)
        }
    }
    
    func loadStudents() {
        if let data = UserDefaults.standard.data(forKey: studentsKey),
           let decoded = try? JSONDecoder().decode([Student].self, from: data) {
            students = decoded
        }
    }
    
    func saveWeights() {
        let weights = [testWeight, quizWeight, homeworkWeight]
        UserDefaults.standard.set(weights, forKey: weightsKey)
    }
    
    func loadWeights() {
        let weights = UserDefaults.standard.array(forKey: weightsKey) as? [Double] ?? [50, 17, 33]
        if weights.count == 3 {
            testWeight = weights[0]
            quizWeight = weights[1]
            homeworkWeight = weights[2]
        }
    }
    
    func saveGrades() {
        if let data = try? JSONEncoder().encode(allGrades) {
            UserDefaults.standard.set(data, forKey: gradesKey)
        }
    }
    
    func loadGrades() {
        if let data = UserDefaults.standard.data(forKey: gradesKey),
           let decoded = try? JSONDecoder().decode([GradeEntry].self, from: data) {
            allGrades = decoded
        }
    }
    
    // MARK: - Backup & Restore
    
    func createBackupFile() -> URL? {
        let backup = BackupData(
            students: students,
            testWeight: testWeight,
            quizWeight: quizWeight,
            homeworkWeight: homeworkWeight,
            grades: allGrades
        )
        
        do {
            let data = try JSONEncoder().encode(backup)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("backup.json")
            try data.write(to: url)
            return url
        } catch {
            print("❌ Failed to create backup file: \(error)")
            return nil
        }
    }
    
    func restoreBackup(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            print("❌ Couldn't access file at: \(url)")
            return
        }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let data = try Data(contentsOf: url)
            let backup = try JSONDecoder().decode(BackupData.self, from: data)
            
            DispatchQueue.main.async {
                self.students = backup.students
                self.testWeight = backup.testWeight
                self.quizWeight = backup.quizWeight
                self.homeworkWeight = backup.homeworkWeight
                self.allGrades = backup.grades
            }
        } catch {
            print("❌ Failed to restore backup: \(error)")
        }
    }
}
