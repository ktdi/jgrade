import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var studentManager: StudentManager
    
    @State private var newName = ""
    @State private var selectedGradeLevel = 1
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var isImporting = false
    
    var totalWeight: Double {
        studentManager.testWeight + studentManager.quizWeight + studentManager.homeworkWeight
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Student")
                .font(.title2)
                .padding(.top)
            
            HStack {
                TextField("Student Name", text: $newName)
                    .textFieldStyle(.roundedBorder)
                
                Picker("Grade", selection: $selectedGradeLevel) {
                    ForEach(1...10, id: \.self) { Text("Grade \($0)").tag($0) }
                }
                .frame(width: 120)
                
                Button("Add") {
                    studentManager.add(newName, gradeLevel: selectedGradeLevel)
                    newName = ""
                    selectedGradeLevel = 1
                }
                .buttonStyle(.borderedProminent)
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            
            Divider()
            
            Text("Students")
                .font(.headline)
            
            if studentManager.students.isEmpty {
                Text("No students added yet")
                    .foregroundColor(.gray)
            } else {
                List {
                    ForEach(studentManager.students) { student in
                        HStack {
                            Text(student.name)
                            Spacer()
                            Text("Grade \(student.gradeLevel)")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                    .onDelete(perform: studentManager.delete)
                }
            }
            
            Divider()
            
            Text("Assignment Weights")
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 10) {
                weightSlider(title: "Test", value: $studentManager.testWeight)
                weightSlider(title: "Quiz", value: $studentManager.quizWeight)
                weightSlider(title: "Homework", value: $studentManager.homeworkWeight)
                
                Text("Total: \(Int(totalWeight))%")
                    .fontWeight(.bold)
                    .foregroundColor(totalWeight == 100 ? .green : .red)
            }
            
            Divider()
            
            HStack(spacing: 20) {
                Button("📤 Backup") {
                    if let url = studentManager.createBackupFile() {
                        exportURL = url
                        isExporting = true
                    }
                }
                .buttonStyle(.bordered)
                
                Button("📥 Restore") {
                    isImporting = true
                }
                .buttonStyle(.borderedProminent)
            }
            
            Spacer()
        }
        .padding()
        .fileExporter(
            isPresented: $isExporting,
            document: exportURL.map { BackupDocument(fileURL: $0) },
            contentType: .json,
            defaultFilename: "GradeBookBackup"
        ) { result in
            if case .failure(let error) = result {
                print("❌ Export failed: \(error)")
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                print("✅ Selected URLs: \(urls)") // Add this line
                if let url = urls.first {
                    studentManager.restoreBackup(from: url)
                }
            case .failure(let error):
                print("❌ Import failed: \(error)")
            }
        }
    }
    
    func weightSlider(title: String, value: Binding<Double>) -> some View {
        HStack {
            Text("\(title) Weight")
                .frame(width: 100, alignment: .leading)
            Slider(value: value, in: 0...100, step: 1)
            Text("\(Int(value.wrappedValue))%")
                .frame(width: 40, alignment: .trailing)
        }
    }
}

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var fileURL: URL?
    
    init(fileURL: URL?) {
        self.fileURL = fileURL
    }
    
    init(configuration: ReadConfiguration) throws {
        // Not used — this document is write-only
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let url = fileURL,
              let data = try? Data(contentsOf: url) else {
            throw CocoaError(.fileNoSuchFile)
        }
        return FileWrapper(regularFileWithContents: data)
    }
}
