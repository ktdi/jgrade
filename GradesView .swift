import SwiftUI

struct GradesView: View {
    @EnvironmentObject var studentManager: StudentManager
    
    @State private var selectedGradeLevel = 1
    @State private var selectedPeriod = 1
    @State private var selectedSubject = "Math"
    @State private var newGradeInput: [UUID: String] = [:]
    @State private var selectedGradeType: GradeType = .test
    
    let subjects = ["Algebra", "Art", "Bible", "English", "Health", "History", "Literature", "Math", "Memory", "Music", "Penmanship", "Phonics", "Reading", "Recordkeeping", "Science", "Social Studies", "Spanish", "Spelling", "Typing", "Writing"]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Picker("Grade", selection: $selectedGradeLevel) {
                    ForEach(1...10, id: \.self) { Text("Grade \($0)").tag($0) }
                }
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(1...6, id: \.self) { Text("Period \($0)").tag($0) }
                }
                Picker("Subject", selection: $selectedSubject) {
                    ForEach(subjects, id: \.self) { Text($0).tag($0) }
                }
            }
            .padding()
            
            HStack(spacing: 30) {
                legend(color: .red, label: "Tests")
                legend(color: .blue, label: "Quizzes")
                legend(color: .gray, label: "Homework")
            }
            .padding(.bottom)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(filteredStudents()) { student in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 10) {
                                Text(student.name)
                                    .frame(width: 100, alignment: .leading)
                                    .font(.headline)
                                
                                TextField("Grade", text: Binding(
                                    get: { newGradeInput[student.id, default: "" ] },
                                    set: { newGradeInput[student.id] = String($0.prefix(3)) }
                                ))
                                .keyboardType(.decimalPad)
                                .frame(width: 60)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit {
                                    addGrade(for: student)
                                }
                                
                                Picker("Type", selection: $selectedGradeType) {
                                    ForEach(GradeType.allCases, id: \.self) {
                                        Text($0.rawValue).tag($0)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 220)
                                
                                Button("Add") {
                                    addGrade(for: student)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(gradesFor(student), id: \.id) { grade in
                                        HStack(spacing: 2) {
                                            VStack(spacing: 1) {
                                                Text(letterGrade(for: grade.value))
                                                    .font(.caption2)
                                                    .foregroundColor(.gray)
                                                Text(grade.value)
                                                    .font(.subheadline)
                                            }
                                            .frame(width: 42, height: 36)
                                            .background(backgroundColor(for: grade.type))
                                            .cornerRadius(4)
                                            
                                            Button("✕") {
                                                deleteGrade(grade)
                                            }
                                            .font(.caption2)
                                            .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                            
                            if let avg = percentAverage(for: student) {
                                Text("\(String(format: "%.1f", avg)) \(letterGrade(for: String(avg)))")
                                    .foregroundColor(.blue)
                                    .font(.subheadline)
                                    .padding(.leading, 100)
                            }
                            
                            Divider()
                        }
                    }
                    
                    if let classAvg = classAverage() {
                        HStack {
                            Spacer()
                            Text("📊 Class Average: \(String(format: "%.1f", classAvg)) \(letterGrade(for: String(classAvg)))")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            Spacer()
                        }
                        .padding(.top)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
    
    func legend(color: Color, label: String) -> some View {
        VStack {
            Circle()
                .fill(color.opacity(0.5))
                .frame(width: 20, height: 20)
            Text(label)
                .font(.caption)
        }
    }
    
    func filteredStudents() -> [Student] {
        studentManager.students.filter { $0.gradeLevel == selectedGradeLevel }
    }
    
    func gradesFor(_ student: Student) -> [GradeEntry] {
        studentManager.allGrades.filter {
            $0.studentId == student.id &&
            $0.subject == selectedSubject &&
            $0.period == selectedPeriod
        }
    }
    
    func addGrade(for student: Student) {
        let input = newGradeInput[student.id, default: ""].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }
        
        let newEntry = GradeEntry(
            studentId: student.id,
            subject: selectedSubject,
            period: selectedPeriod,
            value: input,
            type: selectedGradeType
        )
        
        studentManager.addGrade(newEntry)
        newGradeInput[student.id] = ""
    }
    
    func deleteGrade(_ grade: GradeEntry) {
        studentManager.deleteGrade(grade)
    }
    
    func percentAverage(for student: Student) -> Double? {
        let grades = gradesFor(student)
        guard !grades.isEmpty else { return nil }
        
        var typeScores: [GradeType: [Double]] = [:]
        
        for type in GradeType.allCases {
            let scores = grades
                .filter { $0.type == type }
                .compactMap { Double($0.value) }
            
            if !scores.isEmpty {
                typeScores[type] = scores
            }
        }
        
        let usedWeight = typeScores.keys.reduce(0.0) { total, type in
            total + studentManager.weight(for: type)
        }
        
        guard usedWeight > 0 else { return nil }
        
        let total = typeScores.reduce(0.0) { sum, entry in
            let (type, scores) = entry
            let avg = scores.reduce(0, +) / Double(scores.count)
            let adjustedWeight = studentManager.weight(for: type) / usedWeight
            return sum + avg * adjustedWeight
        }
        
        return total
    }
    
    func classAverage() -> Double? {
        let students = filteredStudents()
        guard !students.isEmpty else { return nil }
        
        let averages = students.compactMap { percentAverage(for: $0) }
        guard !averages.isEmpty else { return nil }
        
        return averages.reduce(0, +) / Double(averages.count)
    }
    
    func letterGrade(for grade: String) -> String {
        guard let value = Double(grade) else { return "—" }
        switch value {
        case 100: return "A+"
        case 96...99: return "A"
        case 94...95: return "A−"
        case 92...93: return "B+"
        case 88...91: return "B"
        case 86...87: return "B−"
        case 84...85: return "C+"
        case 79...83: return "C"
        case 76...78: return "C−"
        case 70...75: return "D"
        case 63...69: return "E"
        default: return "F"
        }
    }
    
    func backgroundColor(for type: GradeType) -> Color {
        switch type {
        case .test: return .red.opacity(0.2)
        case .quiz: return .blue.opacity(0.2)
        case .homework: return .gray.opacity(0.2)
        }
    }
}
