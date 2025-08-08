package com.example.dynamicforms.features.formdetail.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.ClickableText
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.material3.Typography
import coil.compose.AsyncImage
import coil.compose.SubcomposeAsyncImage
import coil.request.ImageRequest
import androidx.compose.ui.platform.LocalContext
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsColors
import com.example.dynamicforms.core.designsystem.theme.DynamicFormsTypography

/**
 * Enhanced HTML renderer for Description fields using DynamicForms Design System
 * 
 * Typography: Uses DynamicFormsTypography from core:designsystem
 * - H1: headlineLarge (32sp)
 * - H2: headlineMedium (28sp) 
 * - H3: headlineSmall (24sp)
 * - H4-H6: titleLarge (22sp)
 * 
 * Supported HTML tags: <p>, <h1-h6>, <strong>, <em>, <br>, <b>, <i>, <u>, <img>
 * HTML entities decoded: &amp;, &#39;, &quot;, &lt;, &gt;, &nbsp;, &#XXX;
 * Images: Renders real images using Coil AsyncImage
 */
@Composable
fun HtmlText(
    modifier: Modifier = Modifier,
    html: String,
    color: Color = DynamicFormsColors.OnSurface
) {
    // Note: color parameter reserved for future text styling customization
    // Using DynamicFormsTypography from Design System via MaterialTheme
    val typography = DynamicFormsTypography
    
    // Performance optimization: Cache expensive parsing operations
    val elements = remember(html) {
        // First decode HTML entities
        val decodedHtml = decodeHtmlEntities(html)
        
        // Parse HTML into elements (text and images) - cached by html content
        parseHtmlElements(decodedHtml, typography)
    }
    
    // Render elements in a column
    Column(modifier = modifier) {
        elements.forEach { element ->
            when (element) {
                is HtmlElement.TextElement -> {
                    ClickableText(
                        text = element.annotatedString,
                        modifier = Modifier.fillMaxWidth(),
                        onClick = { /* Handle link clicks if needed */ }
                    )
                }
                is HtmlElement.ImageElement -> {
                    AsyncImageWithStates(
                        src = element.src,
                        alt = element.alt,
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(200.dp)
                            .padding(vertical = 8.dp)
                            .clip(RoundedCornerShape(8.dp))
                    )
                }
                is HtmlElement.SpacerElement -> {
                    // Add vertical spacing
                    if (element.height > 0) {
                        androidx.compose.foundation.layout.Spacer(
                            modifier = Modifier.height(element.height.dp)
                        )
                    }
                }
            }
        }
    }
}

/**
 * Represents different types of HTML elements that can be rendered
 */
sealed class HtmlElement {
    data class TextElement(val annotatedString: androidx.compose.ui.text.AnnotatedString) : HtmlElement()
    data class ImageElement(val src: String, val alt: String) : HtmlElement()
    data class SpacerElement(val height: Int) : HtmlElement()
}

/**
 * Parse HTML into a list of renderable elements (text and images)
 */
private fun parseHtmlElements(
    html: String,
    typography: Typography
): List<HtmlElement> {
    val elements = mutableListOf<HtmlElement>()
    var currentHtml = html
    var startIndex = 0
    
    while (startIndex < currentHtml.length) {
        // Find next image tag
        val imgTagStart = currentHtml.indexOf("<img", startIndex, ignoreCase = true)
        
        if (imgTagStart == -1) {
            // No more images, process remaining text
            val remainingText = currentHtml.substring(startIndex)
            if (remainingText.trim().isNotEmpty()) {
                val annotatedString = buildAnnotatedString {
                    parseHtml(remainingText, typography)
                }
                if (annotatedString.text.trim().isNotEmpty()) {
                    elements.add(HtmlElement.TextElement(annotatedString))
                }
            }
            break
        }
        
        // Process text before image
        if (imgTagStart > startIndex) {
            val textBeforeImage = currentHtml.substring(startIndex, imgTagStart)
            if (textBeforeImage.trim().isNotEmpty()) {
                val annotatedString = buildAnnotatedString {
                    parseHtml(textBeforeImage, typography)
                }
                if (annotatedString.text.trim().isNotEmpty()) {
                    elements.add(HtmlElement.TextElement(annotatedString))
                }
            }
        }
        
        // Find end of image tag
        val imgTagEnd = currentHtml.indexOf('>', imgTagStart)
        if (imgTagEnd == -1) break
        
        // Extract image tag
        val imgTag = currentHtml.substring(imgTagStart, imgTagEnd + 1)
        val src = extractImageSrc(imgTag)
        val alt = extractImageAlt(imgTag)
        
        if (src.isNotEmpty()) {
            elements.add(HtmlElement.ImageElement(src, alt))
            elements.add(HtmlElement.SpacerElement(8)) // Add spacing after image
        }
        
        startIndex = imgTagEnd + 1
    }
    
    return elements
}

private fun androidx.compose.ui.text.AnnotatedString.Builder.parseHtml(
    html: String, 
    typography: Typography
) {
    var text = html
    var startIndex = 0

    // Remove HTML tags and apply styling
    while (startIndex < text.length) {
        val nextTag = findNextTag(text, startIndex)
        
        if (nextTag == null) {
            // No more tags, add remaining text
            append(text.substring(startIndex))
            break
        }
        
        // Add text before tag
        if (nextTag.start > startIndex) {
            append(text.substring(startIndex, nextTag.start))
        }
        
        when (nextTag.tag.lowercase()) {
            "p" -> {
                if (nextTag.isClosing) {
                    append("\n\n")
                }
            }
            "br", "br/" -> {
                append("\n")
            }
            "h1" -> {
                if (nextTag.isClosing) {
                    pop()
                    append("\n\n")
                } else {
                    val style = typography.headlineLarge.toSpanStyle()
                    pushStyle(style.copy(fontWeight = FontWeight.Bold))
                }
            }
            "h2" -> {
                if (nextTag.isClosing) {
                    pop()
                    append("\n\n")
                } else {
                    val style = typography.headlineMedium.toSpanStyle()
                    pushStyle(style.copy(fontWeight = FontWeight.Bold))
                }
            }
            "h3" -> {
                if (nextTag.isClosing) {
                    pop()
                    append("\n\n")
                } else {
                    val style = typography.headlineSmall.toSpanStyle()
                    pushStyle(style.copy(fontWeight = FontWeight.Bold))
                }
            }
            "h4", "h5", "h6" -> {
                if (nextTag.isClosing) {
                    pop()
                    append("\n\n")
                } else {
                    val style = typography.titleLarge.toSpanStyle()
                    pushStyle(style.copy(fontWeight = FontWeight.Bold))
                }
            }
            "strong", "b" -> {
                if (nextTag.isClosing) {
                    pop()
                } else {
                    pushStyle(SpanStyle(fontWeight = FontWeight.Bold))
                }
            }
            "em", "i" -> {
                if (nextTag.isClosing) {
                    pop()
                } else {
                    pushStyle(SpanStyle(fontStyle = FontStyle.Italic))
                }
            }
            "u" -> {
                if (nextTag.isClosing) {
                    pop()
                } else {
                    pushStyle(SpanStyle(textDecoration = TextDecoration.Underline))
                }
            }
            "img" -> {
                // Images are handled separately in parseHtmlElements
                // Skip image tags in text parsing
            }
        }
        
        startIndex = nextTag.end
    }
}

private data class HtmlTag(
    val tag: String,
    val isClosing: Boolean,
    val start: Int,
    val end: Int,
    val fullTag: String
)

private fun findNextTag(text: String, startIndex: Int): HtmlTag? {
    val tagStart = text.indexOf('<', startIndex)
    if (tagStart == -1) return null
    
    val tagEnd = text.indexOf('>', tagStart)
    if (tagEnd == -1) return null
    
    val tagContent = text.substring(tagStart + 1, tagEnd).trim()
    val fullTag = text.substring(tagStart, tagEnd + 1)
    val isClosing = tagContent.startsWith("/")
    val tagName = if (isClosing) {
        tagContent.substring(1).trim()
    } else {
        tagContent.split(" ")[0].trim()
    }
    
    return HtmlTag(
        tag = tagName,
        isClosing = isClosing,
        start = tagStart,
        end = tagEnd + 1,
        fullTag = fullTag
    )
}

/**
 * Decode common HTML entities to their characters
 */
private fun decodeHtmlEntities(html: String): String {
    return html
        .replace("&amp;", "&")
        .replace("&lt;", "<")
        .replace("&gt;", ">")
        .replace("&quot;", "\"")
        .replace("&#39;", "'")
        .replace("&#x27;", "'")
        .replace("&apos;", "'")
        .replace("&nbsp;", " ")
        // Handle numeric entities like &#39;
        .replace(Regex("&#(\\d+);")) { matchResult ->
            val code = matchResult.groupValues[1].toIntOrNull()
            if (code != null && code in 32..126) {
                code.toChar().toString()
            } else {
                matchResult.value
            }
        }
}

/**
 * Extract src URL from img tag
 */
private fun extractImageSrc(imgTag: String): String {
    val srcMatch = Regex("src\\s*=\\s*[\"']([^\"']*)[\"']").find(imgTag)
    return srcMatch?.groupValues?.get(1) ?: ""
}

/**
 * Extract alt text from img tag
 */
private fun extractImageAlt(imgTag: String): String {
    val altMatch = Regex("alt\\s*=\\s*[\"']([^\"']*)[\"']").find(imgTag)
    return altMatch?.groupValues?.get(1) ?: ""
}

/**
 * Async Image component with loading states and error handling
 * Optimized for smooth, non-blocking image loading
 */
@Composable
private fun AsyncImageWithStates(
    src: String,
    alt: String,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    
    SubcomposeAsyncImage(
        model = ImageRequest.Builder(context)
            .data(src)
            .crossfade(true) // Smooth transition animation
            .crossfade(300)  // 300ms animation duration
            .memoryCacheKey(src) // Cache optimization
            .diskCacheKey(src)   // Disk cache optimization
            .build(),
        contentDescription = alt,
        modifier = modifier,
        contentScale = ContentScale.Crop,
        loading = {
            // Loading placeholder - smooth spinner
            Box(
                modifier = Modifier.fillMaxWidth(),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(32.dp),
                        color = DynamicFormsColors.Primary,
                        strokeWidth = 3.dp
                    )
                    androidx.compose.foundation.layout.Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "Loading image...",
                        style = DynamicFormsTypography.bodySmall,
                        color = DynamicFormsColors.SectionHeader
                    )
                }
            }
        },
        error = {
            // Error placeholder - friendly broken image icon
            Box(
                modifier = Modifier.fillMaxWidth(),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Icon(
                        imageVector = Icons.Default.Warning,
                        contentDescription = "Failed to load image",
                        modifier = Modifier.size(48.dp),
                        tint = DynamicFormsColors.SectionHeader.copy(alpha = 0.6f)
                    )
                    androidx.compose.foundation.layout.Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "Image unavailable",
                        style = DynamicFormsTypography.bodySmall,
                        color = DynamicFormsColors.SectionHeader
                    )
                    if (alt.isNotEmpty()) {
                        Text(
                            text = alt,
                            style = DynamicFormsTypography.bodySmall,
                            color = DynamicFormsColors.SectionHeader.copy(alpha = 0.7f)
                        )
                    }
                }
            }
        },
        success = { success ->
            // Success state - optimized image rendering with crossfade
            androidx.compose.foundation.Image(
                painter = success.painter,
                contentDescription = alt,
                modifier = Modifier.fillMaxWidth(),
                contentScale = ContentScale.Crop
            )
        }
    )
}