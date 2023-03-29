//
//  Gym_JournalApp.swift
//  Gym Journal
//
//  Created by Sean Fay on 3/25/23.
//

import SwiftUI

// Workout Set
struct WorkoutSet: Identifiable, Codable {
    var id = UUID()
    let exercise: String
    let reps: Int
    let weight: Int
    
    enum CodingKeys: String, CodingKey {
        case exercise, reps, weight
    }
}

// Weight Lifting Workout
struct WeightLiftingWorkout: Identifiable, Codable {
    var id = UUID()
    let date: Date
    var sets: [WorkoutSet]
    
    enum CodingKeys: String, CodingKey {
        case date, sets
    }
}

@main
struct WeightLiftingJournalApp: App {
    @StateObject var workoutData = WorkoutData()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(workoutData)
        }
    }
}

struct ContentView: View {
    @StateObject var workoutData = WorkoutData()
    
    var body: some View {
        TabView {
            NavigationView {
                WorkoutView()
                    .environmentObject(workoutData)
            }
            .tabItem {
                Label("Workout", systemImage: "bolt.fill")
            }
            
            NavigationView {
                JournalView()
                    .environmentObject(workoutData)
            }
            .tabItem {
                Label("Journal", systemImage: "book.fill")
            }
        }
    }
}

// Workout Data ObservableObject
class WorkoutData: ObservableObject {
    @Published var workouts: [WeightLiftingWorkout] = []
    
    init() {
        loadWorkouts()
    }
    
    func loadWorkouts() {
        if let data = UserDefaults.standard.data(forKey: "Workouts") {
            let decoder = JSONDecoder()
            if let decodedWorkouts = try? decoder.decode([WeightLiftingWorkout].self, from: data) {
                workouts = decodedWorkouts
            }
        }
    }
    
    func saveWorkout(_ workoutSet: WorkoutSet) {
        if let index = workouts.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: Date()) }) {
            workouts[index].sets.append(workoutSet)
        } else {
            let newWorkout = WeightLiftingWorkout(date: Date(), sets: [workoutSet])
            workouts.append(newWorkout)
        }
        
        let encoder = JSONEncoder()
        if let encodedWorkouts = try? encoder.encode(workouts) {
            UserDefaults.standard.set(encodedWorkouts, forKey: "Workouts")
        }
    }
}

// Exercise Detail View
struct ExerciseDetailView: View {
    let exercise: String
    @State private var sets = 1
    @State private var reps = 1
    @State private var weight = 45
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var workoutData: WorkoutData
    
    var body: some View {
        VStack {
            // Exercise name
            Text(exercise)
                .font(.largeTitle)
                .padding()
            
            // Sets stepper
            Stepper(value: $sets, in: 1...10) {
                Text("Sets: \(sets)")
            }
            .padding()
            
            // Reps stepper
            Stepper(value: $reps, in: 1...20) {
                Text("Reps: \(reps)")
            }
            .padding()
            
            // Weight wheel picker
            Picker("Weight", selection: $weight) {
                ForEach(45...500, id: \.self) {
                    Text("\($0) lbs")
                }
            }
            .labelsHidden()
            .pickerStyle(WheelPickerStyle())
            .frame(maxHeight: 200)
            
            // Save Set button
            Button(action: {
                saveSet()
            }) {
                Text("Save Set")
                    .font(.title2)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
    
    // Save set to UserDefaults
    func saveSet() {
        let workoutSet = WorkoutSet(exercise: exercise, reps: reps, weight: weight)
        workoutData.saveWorkout(workoutSet)
        presentationMode.wrappedValue.dismiss()
    }
}

// Exercise Detail Wrapper
struct ExerciseDetailWrapper: View {
    var exercise: String?
    @EnvironmentObject var workoutData: WorkoutData
    
    var body: some View {
        Group {
            if let exercise = exercise {
                ExerciseDetailView(exercise: exercise)
            } else {
                EmptyView()
            }
        }
        .environmentObject(workoutData)
    }
}

struct JournalView: View {
    @EnvironmentObject var workoutData: WorkoutData
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(workoutData.workouts) { workout in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(dateFormatter.string(from: workout.date))
                            .font(.headline)
                        
                        ForEach(workout.sets) { workoutSet in
                            HStack {
                                Text("\(workoutSet.exercise):")
                                    .fontWeight(.bold)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                
                                Text("\(workoutSet.reps) reps @ \(workoutSet.weight) lbs")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Total Weight Moved:")
                                .fontWeight(.bold)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            
                            Text("\(totalWeightMoved(workout: workout)) lbs")
                                .font(.subheadline)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 4, x: 0, y: 2)
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 80)
            .padding(.horizontal, 16)
            .font(Font.system(size: min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) * 0.045, weight: .regular))
            .foregroundColor(.primary)
        }
        .background(Color(UIColor.systemGray6))
        .navigationBarTitle("Journal")
    }
    
    private func totalWeightMoved(workout: WeightLiftingWorkout) -> Int {
        return workout.sets.reduce(0) { total, workoutSet in
            total + (workoutSet.weight * workoutSet.reps)
        }
    }
}


// Workout View
struct WorkoutView: View {
    @State private var selectedExercise: String?
    @State private var showingExerciseDetail = false
    @EnvironmentObject var workoutData: WorkoutData
    
    var body: some View {
        VStack {
            List(exercises, id: \.self) { exercise in
                Button(action: {
                    selectedExercise = exercise
                    showingExerciseDetail = true
                }) {
                    Text(exercise)
                }
            }
        }
        .navigationBarTitle("Workout")
        .sheet(isPresented: $showingExerciseDetail, onDismiss: { selectedExercise = nil }) {
            ExerciseDetailView(exercise: selectedExercise ?? "")
                .environmentObject(workoutData)
        }
    }
    
    // Exercise list
    let exercises = [
        "Bench Press",
        "Deadlift",
        "Squat",
        "Shoulder Press",
        "Barbell Row"
    ]
}





