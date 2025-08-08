package com.example.dynamicforms.data.mapper

import com.example.dynamicforms.core.utils.logging.AppLogger
import com.example.dynamicforms.data.local.entity.FormEntity
import com.example.dynamicforms.domain.model.*
import com.google.gson.Gson
import com.google.gson.JsonArray
import com.google.gson.JsonObject
import com.google.gson.reflect.TypeToken
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class FormMapper @Inject constructor() {

    private val gson = Gson()

    fun toDomain(entity: FormEntity): DynamicForm {
        // Parse all fields from stored JSON
        val allFields = parseFields(entity.fieldsJson)

        // Create sections with their associated fields
        val sections = parseSections(entity.sectionsJson, allFields)

        // Extract only fields that are part of sections (consistent with fromJsonToDomain)
        val fieldsInSections = mutableSetOf<FormField>()
        sections.forEach { section ->
            fieldsInSections.addAll(section.fields)
        }
        val filteredFields = fieldsInSections.toList()

        // Reduce logging frequency - only log significant conversions
        AppLogger.d(
            "FormMapper", 
            "Entity -> Domain: '${entity.title}' (${allFields.size} fields, ${sections.size} sections)"
        )

        return DynamicForm(
            id = entity.id,
            title = entity.title,
            fields = filteredFields,
            sections = sections,
            createdAt = entity.createdAt,
            updatedAt = entity.updatedAt
        )
    }

    fun toEntity(domain: DynamicForm): FormEntity {
        return FormEntity(
            id = domain.id,
            title = domain.title,
            fieldsJson = serializeFields(domain.fields),
            sectionsJson = serializeSections(domain.sections),
            createdAt = domain.createdAt,
            updatedAt = domain.updatedAt
        )
    }

    fun fromJsonToDomain(jsonString: String): DynamicForm {
        val jsonObject = gson.fromJson(jsonString, JsonObject::class.java)

        val title = jsonObject.get("title")?.asString ?: "Untitled Form"
        val fieldsArray = jsonObject.getAsJsonArray("fields")
        val sectionsArray = jsonObject.getAsJsonArray("sections") ?: JsonArray()

        // Parse all fields from JSON temporarily
        val allFields = parseFieldsFromJsonArray(fieldsArray)

        // Create sections with their associated fields
        val sections = parseSectionsFromJsonArray(sectionsArray, allFields)

        // Extract only fields that are part of sections (based on from/to indices)
        val fieldsInSections = mutableSetOf<FormField>()
        sections.forEach { section ->
            fieldsInSections.addAll(section.fields)
        }
        val filteredFields = fieldsInSections.toList()

        // Consolidated logging for JSON parsing
        AppLogger.d(
            "FormMapper", 
            "JSON -> Domain: '${title}' (${allFields.size} fields, ${sections.size} sections, ${filteredFields.size} in sections)"
        )

        // Generate a unique ID for the form
        val formId = generateFormId(title)

        return DynamicForm(
            id = formId,
            title = title,
            fields = filteredFields,
            sections = sections
        )
    }

    private fun parseFields(fieldsJson: String): List<FormField> {
        val type = object : TypeToken<List<JsonObject>>() {}.type
        val fieldObjects: List<JsonObject> = gson.fromJson(fieldsJson, type) ?: emptyList()
        return fieldObjects.map { parseFormField(it) }
    }

    private fun parseFieldsFromJsonArray(fieldsArray: JsonArray): List<FormField> {
        return fieldsArray.map { parseFormField(it.asJsonObject) }
    }

    private fun parseFormField(fieldObject: JsonObject): FormField {
        val uuid = fieldObject.get("uuid")?.asString ?: ""
        val type = FieldType.fromString(fieldObject.get("type")?.asString ?: "text")
        val name = fieldObject.get("name")?.asString ?: ""
        val label = fieldObject.get("label")?.asString ?: ""
        val required = fieldObject.get("required")?.asBoolean ?: false

        val options = fieldObject.getAsJsonArray("options")?.map { optionJson ->
            val optionObject = optionJson.asJsonObject
            FieldOption(
                label = optionObject.get("label")?.asString ?: "",
                value = optionObject.get("value")?.asString ?: ""
            )
        } ?: emptyList()

        return FormField(
            uuid = uuid,
            type = type,
            name = name,
            label = label,
            required = required,
            options = options
        )
    }

    private fun parseSections(sectionsJson: String, allFields: List<FormField> = emptyList()): List<FormSection> {
        if (sectionsJson.isEmpty()) return emptyList()

        val type = object : TypeToken<List<JsonObject>>() {}.type
        val sectionObjects: List<JsonObject> = gson.fromJson(sectionsJson, type) ?: emptyList()
        return sectionObjects.map { parseFormSection(it, allFields) }
    }

    private fun parseSectionsFromJsonArray(sectionsArray: JsonArray, allFields: List<FormField>): List<FormSection> {
        return sectionsArray.map { parseFormSection(it.asJsonObject, allFields) }
    }

    private fun parseFormSection(sectionObject: JsonObject): FormSection {
        return parseFormSection(sectionObject, emptyList())
    }

    private fun parseFormSection(sectionObject: JsonObject, allFields: List<FormField>): FormSection {
        val from = sectionObject.get("from")?.asInt ?: 0
        val to = sectionObject.get("to")?.asInt ?: 0
        val title = sectionObject.get("title")?.asString ?: ""

        // Associate fields to this section based on indices
        val sectionFields = allFields.filterIndexed { index, _ ->
            index in from..to
        }

        // Only log if there are issues or in debug builds - reduce noise
        if (sectionFields.isEmpty() && (to - from) >= 0) {
            AppLogger.w("FormMapper", "Section '$title' has no fields despite range $from-$to")
        }

        return FormSection(
            uuid = sectionObject.get("uuid")?.asString ?: "",
            title = title,
            from = from,
            to = to,
            index = sectionObject.get("index")?.asInt ?: 0,
            fields = sectionFields
        )
    }

    private fun serializeFields(fields: List<FormField>): String {
        val fieldObjects = fields.map { field ->
            JsonObject().apply {
                addProperty("uuid", field.uuid)
                addProperty("type", field.type.name.lowercase())
                addProperty("name", field.name)
                addProperty("label", field.label)
                addProperty("required", field.required)

                if (field.options.isNotEmpty()) {
                    val optionsArray = JsonArray()
                    field.options.forEach { option ->
                        val optionObject = JsonObject().apply {
                            addProperty("label", option.label)
                            addProperty("value", option.value)
                        }
                        optionsArray.add(optionObject)
                    }
                    add("options", optionsArray)
                }
            }
        }
        return gson.toJson(fieldObjects)
    }

    private fun serializeSections(sections: List<FormSection>): String {
        val sectionObjects = sections.map { section ->
            JsonObject().apply {
                addProperty("uuid", section.uuid)
                addProperty("title", section.title)
                addProperty("from", section.from)
                addProperty("to", section.to)
                addProperty("index", section.index)
            }
        }
        return gson.toJson(sectionObjects)
    }

    private fun generateFormId(title: String): String {
        return title.lowercase()
            .replace(Regex("[^a-z0-9\\s]"), "")
            .replace(Regex("\\s+"), "_")
            .take(50)
            .let { it.ifEmpty { "form" } }
            .plus("_${System.currentTimeMillis()}")
    }
}