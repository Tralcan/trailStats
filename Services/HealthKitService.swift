import Foundation
import HealthKit
import CoreLocation

// MARK: - Activity Initializer Extension
// Extends the Activity model to allow initialization from a HealthKit HKWorkout object.
// This is necessary because the base Activity struct only has a Codable initializer for Strava data.
extension Activity {
    init(from workout: HKWorkout, sportType: String) {
        self.id = workout.uuid.hashValue
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let dateString = dateFormatter.string(from: workout.startDate)
        self.name = "\(sportType) - \(dateString)"
        
        self.sportType = sportType
        self.date = workout.startDate
        self.distance = workout.totalDistance?.doubleValue(for: .meter()) ?? 0.0
        self.duration = workout.duration
        
        // HKWorkout.totalElevationGained is not available on all supported iOS versions.
        // We default to 0.0 as the Activity model requires a non-optional Double.
        self.elevationGain = 0.0
        
        // These properties are not directly available on HKWorkout and require separate, more complex queries.
        // They are set to nil to ensure the basic activity can be created.
        self.averageHeartRate = nil
        self.averageCadence = nil
        self.averagePower = nil
        self.gradeAdjustedPace = nil
        self.verticalOscillation = nil
        self.groundContactTime = nil
        self.strideLength = nil
        self.verticalRatio = nil
        self.rpe = nil
        self.notes = nil
        self.tag = nil
        self.startCoordinate = nil
        self.polyline = nil
    }
}


// MARK: - Data Models
struct RunningDynamics {
    let verticalOscillation: Double?
    let groundContactTime: Double?
    let strideLength: Double?
    let verticalRatio: Double?
}

struct BodyMetrics {
    let weight: Double?
    let bodyFatPercentage: Double?
    let leanBodyMass: Double?
}

class HealthKitService {
    
    private let healthStore = HKHealthStore()
    
    // MARK: - Public Methods
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, HealthKitError.healthDataNotAvailable)
            return
        }

        // 1. Define the types to read from HealthKit
        let workoutType = HKObjectType.workoutType()

        // Running Dynamics Types
        guard let verticalOscillation = HKObjectType.quantityType(forIdentifier: .runningVerticalOscillation),
              let groundContactTime = HKObjectType.quantityType(forIdentifier: .runningGroundContactTime),
              let strideLength = HKObjectType.quantityType(forIdentifier: .runningStrideLength) else {
            completion(false, HealthKitError.dataTypeNotAvailable)
            return
        }
        
        // Body Metrics Types
        guard let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass),
              let bodyFatPercentage = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage),
              let leanBodyMass = HKObjectType.quantityType(forIdentifier: .leanBodyMass) else {
            completion(false, HealthKitError.dataTypeNotAvailable)
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            workoutType,
            verticalOscillation,
            groundContactTime,
            strideLength,
            bodyMass,
            bodyFatPercentage,
            leanBodyMass
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { (success, error) in
            DispatchQueue.main.async(execute: {
                completion(success, error)
            })
        }
    }
    
    func fetchLatestBodyMetrics(completion: @escaping (Result<BodyMetrics, Error>) -> Void) {
        let group = DispatchGroup()
        
        var weight: Double?
        var bodyFat: Double?
        var leanMass: Double?
        
        // Fetch Weight
        group.enter()
        fetchMostRecentSample(for: .bodyMass, unit: .gramUnit(with: .kilo)) { result in
            if case .success(let value) = result { weight = value }
            group.leave()
        }
        
        // Fetch Body Fat Percentage
        group.enter()
        fetchMostRecentSample(for: .bodyFatPercentage, unit: .percent()) { result in
            if case .success(let value) = result { bodyFat = value * 100 } // Convert to percentage
            group.leave()
        }
        
        // Fetch Lean Body Mass
        group.enter()
        fetchMostRecentSample(for: .leanBodyMass, unit: .gramUnit(with: .kilo)) { result in
            if case .success(let value) = result { leanMass = value }
            group.leave()
        }
        
        group.notify(queue: .main) {
            let bodyMetrics = BodyMetrics(
                weight: weight,
                bodyFatPercentage: bodyFat,
                leanBodyMass: leanMass
            )
            completion(.success(bodyMetrics))
        }
    }

    func fetchWorkouts(activityType: String, completion: @escaping (Result<[Activity], Error>) -> Void) {
        let workoutType = HKObjectType.workoutType()
        
        var hkActivityType: HKWorkoutActivityType
        switch activityType {
        case "Running":
            hkActivityType = .running
        case "Hike":
            hkActivityType = .hiking
        default:
            completion(.failure(HealthKitError.dataTypeNotAvailable))
            return
        }

        let predicate = HKQuery.predicateForWorkouts(with: hkActivityType)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: 50, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            let workItem = DispatchWorkItem {
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let workouts = samples as? [HKWorkout] else {
                    completion(.success([]))
                    return
                }

                let activities = workouts.map { workout -> Activity in
                    return Activity(from: workout, sportType: activityType)
                }
                completion(.success(activities))
            }
            DispatchQueue.main.async(execute: workItem)
        }
        healthStore.execute(query)
    }

    
    func fetchRunningDynamics(for activity: Activity, completion: @escaping (Result<RunningDynamics, Error>) -> Void) {
        // First, find the corresponding workout
        fetchWorkoutFor(activity: activity) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                completion(.failure(error))
                
            case .success(let workout):
                // If workout is found, fetch the metrics
                let group = DispatchGroup()
                
                var verticalOscillation: Double?
                var groundContactTime: Double?
                var strideLength: Double?
                
                // Fetch Vertical Oscillation
                group.enter()
                self.fetchAverageMetric(for: workout, typeIdentifier: .runningVerticalOscillation, unit: .meterUnit(with: .centi)) { result in
                    if case .success(let value) = result { verticalOscillation = value }
                    group.leave()
                }
                
                // Fetch Ground Contact Time
                group.enter()
                self.fetchAverageMetric(for: workout, typeIdentifier: .runningGroundContactTime, unit: .secondUnit(with: .milli)) { result in
                    if case .success(let value) = result { groundContactTime = value }
                    group.leave()
                }
                
                // Fetch Stride Length
                group.enter()
                self.fetchAverageMetric(for: workout, typeIdentifier: .runningStrideLength, unit: .meter()) { result in
                    if case .success(let value) = result { strideLength = value }
                    group.leave()
                }
                
                // When all metrics are fetched, calculate ratio and complete
                group.notify(queue: .main) {
                    var verticalRatio: Double? = nil
                    if let vo = verticalOscillation, let sl = strideLength, sl > 0 {
                        // VO is in cm, SL is in m. Convert SL to cm.
                        verticalRatio = (vo / (sl * 100)) * 100
                    }
                    
                    let dynamics = RunningDynamics(
                        verticalOscillation: verticalOscillation,
                        groundContactTime: groundContactTime,
                        strideLength: strideLength,
                        verticalRatio: verticalRatio
                    )
                    completion(.success(dynamics))
                }
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func fetchWorkoutFor(activity: Activity, completion: @escaping (Result<HKWorkout, Error>) -> Void) {
        let workoutType = HKObjectType.workoutType()
        
        // Create a predicate for the time frame of the activity
        // Add a small buffer (e.g., 1 minute) to account for slight timing differences
        let startDate = activity.date.addingTimeInterval(-60)
        let endDate = activity.date.addingTimeInterval(activity.duration + 60)
        let timePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        // Predicate for running workouts
        let workoutPredicate = HKQuery.predicateForWorkouts(with: .running)
        
        // Combine predicates
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [timePredicate, workoutPredicate])
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: workoutType, predicate: compoundPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            DispatchQueue.main.async(execute: {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let workouts = samples as? [HKWorkout] else {
                    completion(.failure(HealthKitError.workoutNotFound))
                    return
                }
                
                // Find the best match by comparing duration
                let bestMatch = workouts.min { (w1, w2) -> Bool in
                    abs(w1.duration - activity.duration) < abs(w2.duration - activity.duration)
                }
                
                if let workout = bestMatch {
                    completion(.success(workout))
                } else {
                    completion(.failure(HealthKitError.workoutNotFound))
                }
            })
        }
        
        healthStore.execute(query)
    }
    
    private func fetchAverageMetric(for workout: HKWorkout, typeIdentifier: HKQuantityTypeIdentifier, unit: HKUnit, completion: @escaping (Result<Double, Error>) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: typeIdentifier) else {
            completion(.failure(HealthKitError.dataTypeNotAvailable))
            return
        }
        
        // Predicate to get samples associated with the specific workout
        let workoutPredicate = HKQuery.predicateForObjects(from: workout)
        
        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: workoutPredicate, options: .discreteAverage) { (_, result, error) in
            DispatchQueue.main.async(execute: {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let result = result, let average = result.averageQuantity() else {
                    // It's not an error if no data exists, just complete with failure to indicate no value
                    completion(.failure(HealthKitError.metricNotAvailable))
                    return
                }
                
                completion(.success(average.doubleValue(for: unit)))
            })
        }
        
        healthStore.execute(query)
    }

    private func fetchMostRecentSample(for typeIdentifier: HKQuantityTypeIdentifier, unit: HKUnit, completion: @escaping (Result<Double, Error>) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: typeIdentifier) else {
            completion(.failure(HealthKitError.dataTypeNotAvailable))
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: quantityType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { (_, samples, error) in
            DispatchQueue.main.async(execute: {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    completion(.failure(HealthKitError.metricNotAvailable))
                    return
                }
                
                completion(.success(sample.quantity.doubleValue(for: unit)))
            })
        }
        
        healthStore.execute(query)
    }
}

// MARK: - HealthKitError Enum
enum HealthKitError: Error, LocalizedError {
    case healthDataNotAvailable
    case dataTypeNotAvailable
    case workoutNotFound
    case authorizationFailed
    case metricNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .healthDataNotAvailable:
            return "Health data is not available on this device."
        case .dataTypeNotAvailable:
            return "One or more HealthKit data types are not available on this device."
        case .workoutNotFound:
            return "Could not find a matching workout in HealthKit for the given activity."
        case .authorizationFailed:
            return "HealthKit authorization was denied or has not been requested yet."
        case .metricNotAvailable:
            return "The requested metric is not available for this workout."
        }
    }
}
