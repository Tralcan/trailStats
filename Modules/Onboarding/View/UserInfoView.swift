import SwiftUI

struct UserInfoView: View {
    @StateObject var viewModel: UserInfoViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(NSLocalizedString("Welcome!", comment: "Welcome section header"))) {
                    TextField(NSLocalizedString("Your Name", comment: "Your Name textfield placeholder"), text: $viewModel.userName)
                }

                Section(header: Text(NSLocalizedString("Activity Preference", comment: "Activity Preference section header"))) {
                    Picker(NSLocalizedString("Preferred Activity for Trail", comment: "Preferred activity picker label"), selection: $viewModel.selectedActivity) {
                        ForEach(viewModel.activityTypes, id: \.self) { activityType in
                            Text(NSLocalizedString(activityType, comment: "Activity type option")).tag(activityType)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section {
                    Button(action: {
                        viewModel.savePreferences()
                        dismiss()
                    }) {
                        Text(NSLocalizedString("Continue", comment: "Continue button"))
                    }
                    .disabled(viewModel.userName.isEmpty)
                }
            }
            .navigationTitle(NSLocalizedString("Setup", comment: "Setup navigation title"))
            .navigationBarItems(trailing: Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                dismiss()
            })
        }
    }
}
