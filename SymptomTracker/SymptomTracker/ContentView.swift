//
//  ContentView.swift
//  SymptomTracker
//
//  Created by singingstranger on 08.07.25.
//

import SwiftUI

extension Date {
    var shortenedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

struct Symptom: Identifiable, Hashable, Codable{
    let id = UUID ()
    let name: String
    let severity: Int
    let timestamp: Date
    
    init(id: UUID = UUID(), name: String, severity: Int, timestamp: Date){
        self.name = name
        self.severity = severity
        self.timestamp = timestamp
    }
}

struct Medication: Identifiable, Hashable, Codable{
    let id = UUID()
    let name: String
    let timestamp: Date
    
    init(id: UUID = UUID(), name: String, timestamp: Date){
        self.name = name
        self.timestamp = timestamp
    }
}

struct PeakFlowEntry: Identifiable, Hashable, Codable{
    let id = UUID()
    let value: Int
    let timestamp: Date
    
    init(id: UUID = UUID(), value: Int, timestamp: Date){
        self.value = value
        self.timestamp = timestamp
    }
}

struct ContentView: View {
    @State private var symptomName = ""
    @State private var selectedSeverity = 1
    @State private var loggedSymptom: [Symptom] = []
    @State private var selectedSymtpom: Symptom? = nil
    
    @State private var symptomPresets: [String] = ["Chest pain", "Chest tightness", "Coughing", "Wheezing"]
    @State private var selectedPreset: String = "Coughing"
    @State private var newSymptomName: String = ""
    
    @State private var loggedMedications: [Medication] = []
    @State private var medicationPresets: [String] = ["Albuterol", "Fostair"]
    @State private var selectedMedicationPreset: String = "Fostair"
    @State private var newMedicationName = ""
    
    @State private var selectedMedicationDate = Date()
    @State private var showingAddMedicationsEntry = false
    
    @State private var showPillAnimation = false
    @State private var pillOffsetY: CGFloat = 0
    @State private var pillOpacity: Double = 0
    
    @State private var peakFlowValue = ""
    @State private var loggedPeakflows: [PeakFlowEntry] = []
    @State private var showingPeakFlowView = false
    
    @State private var showingAddEntry = true
    @State private var showingDatesView = false
    
    @State private var currentMonth = Date()
    @State private var selectedCalendarDate: Date? = nil
    @State private var selectedDate = Date()
    
    @State private var symptomToDelete: Symptom? = nil
    @State private var showDeletionConfirmation = false
    
    private let symptomKey = "loggedSymptomData"
    private let medicationKey = "loggedMedicationData"
    private let peakflowKey = "loggedPeakFlowData"
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSymtpom) {
                ForEach(loggedSymptom) { symptom in
                    HStack{
                        VStack(alignment: .leading) {
                            Text(symptom.name).font(.headline)
                            Text("Severity: \(symptom.severity)").font(.subheadline).foregroundColor(.gray)
                            Text("\(symptom.timestamp.shortenedDate)").font(.subheadline)
                        }
                        Spacer()
                        Button {
                            symptomToDelete = symptom
                            showDeletionConfirmation = true
                        } label: {
                            Image(systemName: "trash").foregroundColor(.red)
                            
                        }.buttonStyle(BorderlessButtonStyle())
                        
                    }
                    .padding(4)
                }
                
            }
            .navigationTitle("Symptom Log")
            .alert("Delete Symptom?", isPresented: $showDeletionConfirmation, presenting: symptomToDelete) { item in
                Button("Delete", role: .destructive) {
                    deleteSymptomManually(item)
                }
                Button("Cancel", role: .cancel) {
                    symptomToDelete = nil
                }
            } message: { item in
                Text("Are you sure you want to delete \"\(item.name)\"?")
            }
        }
    detail: {
            VStack(alignment: .leading, spacing: 16) {
                if showingAddEntry {
                    logSymptomView
                } else if showingAddMedicationsEntry{
                    logMedicationView
                } else if showingDatesView {
                    showCalendarView
                } else if showingPeakFlowView {
                    logPeakFlowView
                } else {
                    Text("Select a view mode or add a symptom").foregroundColor(.secondary)
                }
            }
            
        }.toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: {
                    showingAddEntry = false
                    showingDatesView = false
                    showingAddMedicationsEntry = false
                    showingPeakFlowView = true
                }) {
                    Image(systemName: "plus")
                }
                Button("Symptoms") {
                    showingAddEntry = true
                    showingAddMedicationsEntry = false
                    showingDatesView = false
                    showingPeakFlowView = false
                }
                Button("Medication"){
                    showingAddEntry = false
                    showingDatesView = false
                    showingAddMedicationsEntry = true
                    showingPeakFlowView = false
                }
                Button("Calendar"){
                    showingAddEntry = false
                    showingDatesView = true
                    showingAddMedicationsEntry = false
                    showingPeakFlowView = false
                }
                
            }
        }
        .padding().navigationTitle("Asthma Tracker")
        .onAppear{ loadSymptom(); loadMedication(); loadPeakFlow() }
    }
    var logMedicationView: some View {
        ZStack{
            VStack(alignment: .leading, spacing: 16) {
                Text("Log Medication").font(.headline).padding()
                HStack {
                    TextField("New Medication Name", text: $newMedicationName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    Button("Add"){
                        addMedicationToPreset()
                    }.disabled(newMedicationName.isEmpty)
                }
                
                DatePicker("Time Taken", selection: $selectedMedicationDate, displayedComponents: [.date, .hourAndMinute])
                    .padding(.horizontal)
                
                Picker("Select: ", selection: $selectedMedicationPreset) {
                    ForEach(medicationPresets, id: \.self) {
                        preset in Text(preset)
                    }
                }
                .pickerStyle(MenuPickerStyle()).padding()
                Button("Log Medication") {
                    let newMedication = Medication(
                        name: newMedicationName,
                        timestamp: selectedMedicationDate
                    )
                    loggedMedications.append(newMedication)
                    saveMedication()
                    newMedicationName = ""
                    selectedMedicationDate = Date()
                    
                    pillOffsetY = 0
                    pillOpacity = 1

                    withAnimation(.easeOut(duration: 1.0)) {
                        pillOffsetY = -80
                        pillOpacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
                        showPillAnimation = false
                    }
                }
                .padding(.horizontal)
            }
            Image(systemName: "pills.fill")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(.purple)
                .offset(y: pillOffsetY)
                .opacity(pillOpacity)
        }
    }
    
    var showCalendarView: some View{
        let columns = Array(repeating: GridItem(.flexible()), count: 7)
        let daysOfWeek = Calendar.current.shortWeekdaySymbols
        
        return VStack(alignment: .leading) {
            HStack {
                Button(action: {
                    if let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
                        currentMonth = previousMonth
                    }
                }) {
                    Image(systemName: "chevron.left")
                }
                
                Spacer()
                
                Text(currentMonth.formatted(.dateTime.month().year()))
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                
                Spacer()
                
                Button(action: {
                    if let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) {
                        currentMonth = nextMonth
                    }
                }) {
                    Image(systemName: "chevron.right")
                }
            }
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day).fontWeight(.bold).frame(maxWidth: .infinity)
                }

                ForEach(generateDatesForMonth(currentMonth), id: \.self) { date in
                    if Calendar.current.isDate(date, equalTo: Date.distantPast, toGranularity: .day) {
                       
                        VStack {
                            Spacer()
                        }
                        .frame(height: 40)
                    } else {
                        let severity = maxSeverity(on: date)

                        let color: Color = {
                            switch severity {
                            case 1: return .blue
                            case 2: return .green
                            case 3: return .yellow
                            case 4: return .orange
                            case 5: return .red
                            default: return .clear
                            }
                        }()

                        VStack {
                            Text("\(Calendar.current.component(.day, from: date))")
                                .foregroundColor(severity == nil ? .primary : .white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Circle().fill(color))
                            if hasMedication(on: date) {
                                    Image(systemName: "pills.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 10, height: 10)
                                        .foregroundColor(.green)
                            }
                        }
                        .frame(height: 40)
                        .onTapGesture {
                            selectedCalendarDate = date
                        }
                    }
                }
            }
            
            if let selected = selectedCalendarDate {
                let symptoms = loggedSymptom.filter {
                    Calendar.current.isDate($0.timestamp, inSameDayAs: selected)
                }
                let meds = loggedMedications.filter {
                    Calendar.current.isDate($0.timestamp, inSameDayAs: selected)
                }
                let peakFlows = loggedPeakflows.filter {
                    Calendar.current.isDate($0.timestamp, inSameDayAs: selected)
                }
                
                Divider().padding(.vertical)
                
                HStack(alignment: .top, spacing: 16) {

                    VStack(alignment: .leading) {
                        Text("Symptoms")
                            .font(.headline)
                        if symptoms.isEmpty {
                            Text("No symptoms logged")
                                .foregroundColor(.secondary)
                        } else {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(symptoms) { entry in
                                        VStack(alignment: .leading) {
                                            Text("\(entry.name) - Severity \(entry.severity)")
                                            Text(entry.timestamp.shortenedDate)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.bottom, 4)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .scrollIndicators(.hidden)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: 200, alignment: .topLeading)
                    .background(Color(.black))
                    .cornerRadius(3)
                    
                    VStack(alignment: .leading) {
                        Text("Medications")
                            .font(.headline)
                        if meds.isEmpty {
                            Text("No medications logged")
                                .foregroundColor(.secondary)
                        } else {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(meds) { med in
                                        VStack(alignment: .leading) {
                                            Text(med.name)
                                            Text(med.timestamp.shortenedDate)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.bottom, 4)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .scrollIndicators(.hidden)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: 200, alignment: .topLeading)
                    .background(Color(.black))
                    .cornerRadius(3)
                    
                    VStack(alignment: .leading) {
                        Text("Peak Flow")
                            .font(.headline)
                        if peakFlows.isEmpty {
                            Text("No peak flow readings")
                                .foregroundColor(.secondary)
                        } else {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(peakFlows) { reading in
                                        VStack(alignment: .leading) {
                                            Text("\(reading.value) L/min")
                                            Text(reading.timestamp.shortenedDate)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.bottom, 4)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .scrollIndicators(.hidden)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: 200, alignment: .topLeading)
                    .background(Color(.black))
                    .cornerRadius(3)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    var logSymptomView: some View{
        VStack(alignment: .leading, spacing: 16){
            Text("Select a symptom").font(.headline).padding()
            HStack {
                TextField("Enter symptom (e.g. coughing, pain)", text:$newSymptomName).textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Add") {
                    addSymptomToPreset()
                }
                .disabled(newSymptomName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal)
            
            
            Picker("Symptom: ", selection: $selectedPreset) {
                ForEach(symptomPresets, id: \.self) {
                    preset in Text(preset)
                }
            }
            .pickerStyle(MenuPickerStyle()).padding()
            
            
            Picker("Severity:", selection: $selectedSeverity) {
                ForEach(1..<5){level in Text("\(level)").tag(level)}
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            DatePicker("Date and Time: ", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute]).padding(.horizontal)
            
            Button(action: logSymptom){
                Text("Log Symptom").frame(maxWidth: .infinity).padding().foregroundColor(.white).cornerRadius(10)
            }
            .padding(.horizontal)
        }
    }
    var medicationHistoryView: some View {
        VStack(alignment: .leading) {
            Text("Medication History").font(.headline).padding()

            List(loggedMedications.sorted(by: { $0.timestamp > $1.timestamp })) { med in
                VStack(alignment: .leading) {
                    Text("\(med.name)").font(.body)
                    Text(med.timestamp.shortenedDate).font(.caption).foregroundColor(.gray)
                }
                .padding(.vertical, 4)
            }
        }
    }
    var logPeakFlowView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Log Peak Flow").font(.headline).padding()

            TextField("Enter value (L/min)", text: $peakFlowValue)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button("Save") {
                if let value = Int(peakFlowValue) {
                    let newEntry = PeakFlowEntry(value: value, timestamp: Date())
                    loggedPeakflows.append(newEntry)
                    savePeakFlow()
                    peakFlowValue = ""
                }
            }
            .padding(.horizontal)

            Divider().padding(.vertical)

            Text("History").font(.headline).padding(.horizontal)

            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(loggedPeakflows.sorted(by: { $0.timestamp > $1.timestamp })) { entry in
                        HStack {
                            Text("\(entry.value) L/min")
                            Spacer()
                            Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    func hasMedication(on date: Date) -> Bool {
        loggedMedications.contains {
            Calendar.current.isDate($0.timestamp, inSameDayAs: date)
        }
    }
    
    func deleteSymptomManually(_ symptom: Symptom) {
        if let index = loggedSymptom.firstIndex(of: symptom) {
            loggedSymptom.remove(at: index)
            saveSymptom()
        }
    }
    
    func saveSymptom(){
        if let encoded = try? JSONEncoder().encode(loggedSymptom) {
            UserDefaults.standard.set(encoded, forKey: symptomKey)
        }
    }
    func loadSymptom(){
        if let savedData = UserDefaults.standard.data(forKey: symptomKey),
           let decoded = try? JSONDecoder().decode([Symptom].self, from: savedData) {
            loggedSymptom = decoded
        }
    }
    
    func deleteMedicationManually(_ medication: Medication){
        if let index = loggedMedications.firstIndex(of: medication) {
            loggedMedications.remove(at: index)
            saveMedication()
        }
    }
    func saveMedication() {
        if let encoded = try? JSONEncoder().encode(loggedMedications){
            UserDefaults.standard.set(encoded, forKey: medicationKey)
        }
    }
    func loadMedication(){
        if let savedData = UserDefaults.standard.data(forKey: medicationKey),
           let decoded = try? JSONDecoder().decode([Medication].self, from: savedData){
            loggedMedications = decoded
        }
    }
    
    func addMedicationToPreset(){
        let trimmed = newSymptomName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !medicationPresets.contains(trimmed) else {return}
        medicationPresets.append(trimmed)
        selectedMedicationPreset = trimmed
        newMedicationName = ""
    }
    
    
    func logSymptom(){
        guard !selectedPreset.isEmpty else {return}
        
        let newSymptom = Symptom(
            name: selectedPreset,
            severity: selectedSeverity,
            timestamp: selectedDate
        )
        loggedSymptom.append(newSymptom)
        selectedPreset = symptomPresets.first ?? ""
        
        selectedSeverity = 1
        saveSymptom()
        
    }
    
    func savePeakFlow() {
        if let encoded = try? JSONEncoder().encode(loggedPeakflows){
            UserDefaults.standard.set(encoded, forKey: peakflowKey)
        }
    }
    
    func loadPeakFlow() {
        if let savedData = UserDefaults.standard.data(forKey: peakflowKey),
           let decoded = try? JSONDecoder().decode([PeakFlowEntry].self, from: savedData) {
            loggedPeakflows = decoded
        }
    }
    
    func generateDatesForMonth(_ date: Date) -> [Date] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: monthInterval.start)) else {
            return []
        }
        
        var dates: [Date] = []
        var current = monthStart
        
        
        let weekday = calendar.component(.weekday, from: monthStart)
        for _ in 1..<weekday {
            dates.append(Date.distantPast)
        }
        
        while current < monthInterval.end {
            dates.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        
        return dates
    }
    
    func addSymptomToPreset(){
        let trimmed = newSymptomName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !symptomPresets.contains(trimmed) else {return}
        symptomPresets.append(trimmed)
        selectedPreset = trimmed
        newSymptomName = ""
    }
    
    func maxSeverity(on date: Date) -> Int? {
        let symptomsOnDate = loggedSymptom.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: date) }
        return symptomsOnDate.map { $0.severity }.max()
    }
}




struct SymptomEntryView: View{
    var symptom: Symptom
    
    var body: some View{
        VStack(alignment: .leading){
            HStack {
                Text(symptom.name).font(.headline)
                Spacer()
                Text("Severity: \(symptom.severity)").foregroundColor(.gray)
            }
            Text(symptom.timestamp, style: .date).font(.caption).foregroundColor(.secondary)
            
        }
        .padding()
        .background(.green)
        .cornerRadius(10)
    }
}

#Preview {
    ContentView()
}

import Foundation
