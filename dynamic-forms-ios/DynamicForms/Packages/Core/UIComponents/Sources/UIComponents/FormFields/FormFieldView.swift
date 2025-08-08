import SwiftUI
import DesignSystem
import Domain
import Utilities

/// Form field view component that renders different field types
/// Following Single Responsibility Principle for field rendering
public struct DynamicFormFieldView: View {
    
    // MARK: - Properties
    private let field: FormField
    private let onValueChanged: (String) -> Void
    private let onNextField: (() -> Void)?
    private let validationError: String?
    
    // MARK: - State
    @State private var internalValue: String
    @FocusState private var isFocused: Bool
    
    // MARK: - Initialization
    public init(
        field: FormField,
        validationError: String? = nil,
        onValueChanged: @escaping (String) -> Void,
        onNextField: (() -> Void)? = nil
    ) {
        self.field = field
        self.validationError = validationError
        self.onValueChanged = onValueChanged
        self.onNextField = onNextField
        self._internalValue = State(initialValue: field.value)
    }
    
    // MARK: - Body
    public var body: some View {
        VStack(alignment: .leading, spacing: DFSpacing.Form.labelBottom) {
            fieldLabel
            fieldInput
            
            if let error = validationError {
                FieldErrorView(message: error)
            }
        }
        .padding(.vertical, DFSpacing.Form.fieldVertical)
        .onChange(of: field.value) { newValue in
            if newValue != internalValue {
                internalValue = newValue
            }
        }
    }
    
    // MARK: - Field Label
    private var fieldLabel: some View {
        HStack(spacing: DFSpacing.xs) {
            Text(field.label)
                .font(DFTypography.Form.fieldLabel)
                .foregroundColor(DFColors.onSurface)
            
            if field.required {
                Text("*")
                    .font(DFTypography.Form.fieldLabel)
                    .foregroundColor(DFColors.Form.requiredIndicator)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Field Input
    @ViewBuilder
    private var fieldInput: some View {
        switch field.type {
        case .text:
            textFieldView
        case .number:
            numberFieldView
        case .dropdown:
            dropdownFieldView
        case .description:
            descriptionFieldView
        case .checkbox:
            checkboxFieldView
        default:
            // All other types (email, password, textarea, date, file, radio, etc.) are treated as text
            textFieldView
        }
    }
    
    // MARK: - Text Field
    private var textFieldView: some View {
        TextField("", text: $internalValue)
            .font(DFTypography.Form.fieldInput)
            .foregroundColor(DFColors.Form.fieldText)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .padding(DFSpacing.Form.fieldInternalPadding)
            .background(DFColors.Form.fieldBackground)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.small)
                    .stroke(borderColor, lineWidth: 1)
            )
            .focused($isFocused)
            .onChange(of: internalValue) { newValue in
                onValueChanged(newValue)
            }
            .onSubmit {
                onNextField?()
            }
    }
    
    // MARK: - Number Field
    private var numberFieldView: some View {
        TextField("", text: $internalValue)
            .font(DFTypography.Form.fieldInput)
            .foregroundColor(DFColors.Form.fieldText)
            .keyboardType(.numberPad)
            .padding(DFSpacing.Form.fieldInternalPadding)
            .background(DFColors.Form.fieldBackground)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.small)
                    .stroke(borderColor, lineWidth: 1)
            )
            .focused($isFocused)
            .onChange(of: internalValue) { newValue in
                // Filter to only allow numbers
                let filtered = newValue.filter { $0.isNumber || $0 == "." }
                if filtered != newValue {
                    internalValue = filtered
                }
                onValueChanged(internalValue)
            }
            .onSubmit {
                onNextField?()
            }
    }
    
    // MARK: - Dropdown Field
    private var dropdownFieldView: some View {
        Menu {
            ForEach(field.options, id: \.value) { option in
                Button(option.label) {
                    internalValue = option.value
                    onValueChanged(option.value)
                }
            }
        } label: {
            HStack {
                Text(selectedOptionLabel)
                    .font(DFTypography.Form.fieldInput)
                    .foregroundColor(internalValue.isEmpty ? DFColors.Form.fieldPlaceholder : DFColors.Form.fieldText)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .foregroundColor(DFColors.Form.fieldPlaceholder)
                    .font(.system(size: 12))
            }
            .padding(DFSpacing.Form.fieldInternalPadding)
            .background(DFColors.Form.fieldBackground)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.small)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Description Field
    private var descriptionFieldView: some View {
        Group {
            if field.value.containsHTML {
                // Use enhanced HTML renderer for proper HTML content
                EnhancedHTMLView(htmlContent: field.value)
                    .clipped()
            } else {
                Text(field.value)
                    .font(DFTypography.bodyMedium)
                    .foregroundColor(DFColors.onSurface)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var borderColor: Color {
        if let _ = validationError {
            return DFColors.Form.fieldErrorBorder
        } else if isFocused {
            return DFColors.Form.fieldFocusedBorder
        } else {
            return DFColors.Form.fieldBorder
        }
    }
    
    private var selectedOptionLabel: String {
        if internalValue.isEmpty {
            return "Select an option"
        }
        return field.options.first { $0.value == internalValue }?.label ?? internalValue
    }
    
    private var isSingleCheckboxSelected: Bool {
        return !internalValue.isEmpty && internalValue != "false"
    }
    
    // MARK: - Checkbox Field
    private var checkboxFieldView: some View {
        VStack(alignment: .leading, spacing: DFSpacing.xs) {
            if field.options.isEmpty {
                // Single checkbox (like terms and conditions)
                HStack(spacing: DFSpacing.sm) {
                    Button(action: {
                        toggleSingleCheckbox()
                    }) {
                        Image(systemName: isSingleCheckboxSelected ? "checkmark.square.fill" : "square")
                            .foregroundColor(isSingleCheckboxSelected ? DFColors.primary : DFColors.Form.fieldBorder)
                            .font(.system(size: 20))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text(field.label)
                        .font(DFTypography.Form.fieldInput)
                        .foregroundColor(DFColors.Form.fieldText)
                        .onTapGesture {
                            toggleSingleCheckbox()
                        }
                    
                    Spacer()
                }
                .padding(.vertical, DFSpacing.xs)
            } else {
                // Multiple checkbox options
                ForEach(field.options, id: \.value) { option in
                    HStack(spacing: DFSpacing.sm) {
                        Button(action: {
                            toggleCheckboxOption(option.value)
                        }) {
                            Image(systemName: isOptionSelected(option.value) ? "checkmark.square.fill" : "square")
                                .foregroundColor(isOptionSelected(option.value) ? DFColors.primary : DFColors.Form.fieldBorder)
                                .font(.system(size: 20))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Text(option.label)
                            .font(DFTypography.Form.fieldInput)
                            .foregroundColor(DFColors.Form.fieldText)
                            .onTapGesture {
                                toggleCheckboxOption(option.value)
                            }
                        
                        Spacer()
                    }
                    .padding(.vertical, DFSpacing.xs)
                }
            }
        }
        .padding(DFSpacing.Form.fieldInternalPadding)
        .background(DFColors.Form.fieldBackground)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.small)
                .stroke(borderColor, lineWidth: 1)
        )
    }
    
    // MARK: - Date Field
    @State private var selectedDate = Date()
    
    private var dateFieldView: some View {
        DatePicker("", selection: $selectedDate, displayedComponents: .date)
            .datePickerStyle(.compact)
            .labelsHidden()
            .onChange(of: selectedDate) { newDate in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let dateString = formatter.string(from: newDate)
                internalValue = dateString
                onValueChanged(dateString)
            }
            .onAppear {
                if let date = internalValue.toDate {
                    selectedDate = date
                }
            }
            .padding(DFSpacing.Form.fieldInternalPadding)
            .background(DFColors.Form.fieldBackground)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.small)
                    .stroke(borderColor, lineWidth: 1)
            )
    }
    
    // MARK: - Helper Methods
    
    private func isOptionSelected(_ optionValue: String) -> Bool {
        let selectedValues = internalValue.components(separatedBy: ",").map { $0.trimmed }
        return selectedValues.contains(optionValue)
    }
    
    private func toggleCheckboxOption(_ optionValue: String) {
        var selectedValues = internalValue.components(separatedBy: ",").map { $0.trimmed }.filter { !$0.isEmpty }
        
        if let index = selectedValues.firstIndex(of: optionValue) {
            selectedValues.remove(at: index)
        } else {
            selectedValues.append(optionValue)
        }
        
        internalValue = selectedValues.joined(separator: ",")
        onValueChanged(internalValue)
    }
    
    private func toggleSingleCheckbox() {
        if isSingleCheckboxSelected {
            internalValue = ""
        } else {
            internalValue = "true"
        }
        onValueChanged(internalValue)
    }
}

// MARK: - Form Section View
public struct DynamicFormSectionView: View {
    private let section: FormSection
    private let fields: [FormField]
    @Binding private var fieldValues: [String: String]
    private let validationErrors: [String: String]
    private let onFieldChanged: (String, String) -> Void
    
    public init(
        section: FormSection,
        fields: [FormField],
        fieldValues: Binding<[String: String]>,
        validationErrors: [String: String] = [:],
        onFieldChanged: @escaping (String, String) -> Void
    ) {
        self.section = section
        self.fields = fields
        self._fieldValues = fieldValues
        self.validationErrors = validationErrors
        self.onFieldChanged = onFieldChanged
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: DFSpacing.Form.sectionSpacing) {
            sectionHeader
            sectionFields
        }
        .padding(.vertical, DFSpacing.md)
    }
    
    private var sectionHeader: some View {
        VStack(alignment: .leading, spacing: DFSpacing.sm) {
            if section.containsHTML {
                // For now, show plain text. In a real app, use AttributedString or WebView
                Text(section.plainTitle)
                    .font(DFTypography.Form.sectionTitle)
                    .foregroundColor(DFColors.onSurface)
            } else {
                Text(section.title)
                    .font(DFTypography.Form.sectionTitle)
                    .foregroundColor(DFColors.onSurface)
            }
            
            if !fields.isEmpty {
                SectionProgressView(
                    completed: completedFieldsCount,
                    total: requiredFieldsCount
                )
            }
        }
    }
    
    private var sectionFields: some View {
        LazyVStack(spacing: DFSpacing.Form.fieldVertical) {
            ForEach(fields, id: \.uuid) { field in
                let updatedField = field.updateValue(fieldValues[field.uuid] ?? "")
                DynamicFormFieldView(
                    field: updatedField,
                    validationError: validationErrors[field.uuid],
                    onValueChanged: { newValue in
                        onFieldChanged(field.uuid, newValue)
                    }
                )
            }
        }
    }
    
    private var completedFieldsCount: Int {
        fields.filter { field in
            let value = fieldValues[field.uuid] ?? ""
            return !value.isBlank
        }.count
    }
    
    private var requiredFieldsCount: Int {
        fields.filter { $0.required }.count
    }
}

// MARK: - Section Progress View
public struct SectionProgressView: View {
    private let completed: Int
    private let total: Int
    
    public init(completed: Int, total: Int) {
        self.completed = completed
        self.total = total
    }
    
    public var body: some View {
        if total > 0 {
            HStack(spacing: DFSpacing.sm) {
                ProgressView(value: Double(completed), total: Double(total))
                    .progressViewStyle(LinearProgressViewStyle(tint: DFColors.primary))
                    .frame(height: 4)
                
                Text("\(completed)/\(total)")
                    .font(DFTypography.labelSmall)
                    .foregroundColor(DFColors.onSurfaceVariant)
            }
        }
    }
}

// MARK: - Previews
#if DEBUG
struct DynamicFormFieldView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: DFSpacing.lg) {
            DynamicFormFieldView(
                field: FormField.textField(
                    uuid: "1",
                    name: "name",
                    label: "Full Name",
                    required: true
                ),
                onValueChanged: { _ in }
            )
            
            DynamicFormFieldView(
                field: FormField.numberField(
                    uuid: "2",
                    name: "age",
                    label: "Age",
                    required: false
                ),
                onValueChanged: { _ in }
            )
            
            DynamicFormFieldView(
                field: FormField.dropdownField(
                    uuid: "3",
                    name: "country",
                    label: "Country",
                    options: [
                        FieldOption(label: "USA", value: "us"),
                        FieldOption(label: "Canada", value: "ca")
                    ],
                    required: true
                ),
                onValueChanged: { _ in }
            )
            
            DynamicFormFieldView(
                field: FormField.descriptionField(
                    uuid: "4",
                    name: "info",
                    label: "Information",
                    content: "This is a description field with important information."
                ),
                onValueChanged: { _ in }
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Dynamic Form Fields")
    }
}
#endif
