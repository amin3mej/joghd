enum Block: Equatable, Sendable {
    case codeBlock(String)
    case divider
    case heading(level: Int, text: InlineText)
    case listItem(InlineText)
    case paragraph(InlineText)
    case quote(InlineText)
}
