//
//  CalX.swift
//  CalXExtension
//

import AppIntents
import WidgetKit
import SwiftUI

// MARK: - Background Style

enum WidgetBackgroundStyle: String {
    case dark
    case midnight
    case charcoal
    case forest
    case ocean
    case plum
    case glass

    init(rawValue: String?) {
        switch rawValue {
        case "midnight": self = .midnight
        case "charcoal": self = .charcoal
        case "forest":   self = .forest
        case "ocean":    self = .ocean
        case "plum":     self = .plum
        case "glass":    self = .glass
        default:         self = .dark
        }
    }

    var tintColor: Color {
        switch self {
        case .dark:     return Color(red: 28/255, green: 28/255, blue: 34/255)
        case .midnight: return Color(red: 13/255, green: 13/255, blue: 26/255)
        case .charcoal: return Color(red: 22/255, green: 22/255, blue: 22/255)
        case .forest:   return Color(red: 14/255, green: 24/255, blue: 17/255)
        case .ocean:    return Color(red: 10/255, green: 20/255, blue: 38/255)
        case .plum:     return Color(red: 24/255, green: 14/255, blue: 30/255)
        case .glass:    return .clear
        }
    }

    var isGlass: Bool { self == .glass }
}

// MARK: - Card Background

private struct WidgetCardBackground: View {
    let backgroundStyle: WidgetBackgroundStyle

    var body: some View {
        if backgroundStyle.isGlass {
            Rectangle().fill(.ultraThinMaterial)
        } else {
            LinearGradient(
                colors: [
                    backgroundStyle.tintColor,
                    backgroundStyle.tintColor.opacity(0.82)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Quotes Data

struct QuoteItem {
    let text: String
    let author: String
}

private let allQuotes: [QuoteItem] = [

    // — Productivity & Action —
    QuoteItem(text: "Stay hungry, stay foolish.", author: "Steve Jobs"),
    QuoteItem(text: "Done is better than perfect.", author: "Sheryl Sandberg"),
    QuoteItem(text: "The secret of getting ahead is getting started.", author: "Mark Twain"),
    QuoteItem(text: "The future depends on what you do today.", author: "Mahatma Gandhi"),
    QuoteItem(text: "Nothing will work unless you do.", author: "Maya Angelou"),
    QuoteItem(text: "Action is the foundational key to all success.", author: "Pablo Picasso"),
    QuoteItem(text: "The way to get started is to quit talking and begin doing.", author: "Walt Disney"),
    QuoteItem(text: "A year from now you may wish you had started today.", author: "Karen Lamb"),
    QuoteItem(text: "Do the hard jobs first. The easy jobs will take care of themselves.", author: "Dale Carnegie"),
    QuoteItem(text: "If you spend too much time thinking about a thing, you'll never get it done.", author: "Bruce Lee"),
    QuoteItem(text: "There is no substitute for hard work.", author: "Thomas Edison"),
    QuoteItem(text: "Work hard in silence. Let success make the noise.", author: "Frank Ocean"),
    QuoteItem(text: "One day or day one. You decide.", author: "Unknown"),
    QuoteItem(text: "Either you run the day or the day runs you.", author: "Jim Rohn"),
    QuoteItem(text: "Motivation gets you going, but discipline keeps you growing.", author: "John C. Maxwell"),
    QuoteItem(text: "To begin, begin.", author: "William Wordsworth"),
    QuoteItem(text: "First we make our habits, then our habits make us.", author: "John Dryden"),
    QuoteItem(text: "A goal without a plan is just a wish.", author: "Antoine de Saint-Exupéry"),
    QuoteItem(text: "Success usually comes to those who are too busy to be looking for it.", author: "Henry David Thoreau"),
    QuoteItem(text: "Opportunity is missed by most because it is dressed in overalls and looks like work.", author: "Thomas Edison"),
    QuoteItem(text: "Amateurs sit and wait for inspiration. The rest of us just get up and go to work.", author: "Stephen King"),
    QuoteItem(text: "The key is not to prioritize what is on your schedule, but to schedule your priorities.", author: "Stephen Covey"),
    QuoteItem(text: "Lost time is never found again.", author: "Benjamin Franklin"),
    QuoteItem(text: "It is not enough to be busy. So are the ants. What are we busy about?", author: "Henry David Thoreau"),
    QuoteItem(text: "Ordinary things done consistently produce extraordinary results.", author: "Unknown"),
    QuoteItem(text: "You cannot build a reputation on what you are going to do.", author: "Henry Ford"),
    QuoteItem(text: "Productivity is never an accident.", author: "Paul J. Meyer"),
    QuoteItem(text: "Routine, in an intelligent person, is a sign of ambition.", author: "W. H. Auden"),
    QuoteItem(text: "Do less, but do it better.", author: "Unknown"),
    QuoteItem(text: "Deep work is the ability to focus without distraction.", author: "Cal Newport"),

    // — Persistence & Resilience —
    QuoteItem(text: "The only way out is through.", author: "Robert Frost"),
    QuoteItem(text: "It always seems impossible until it is done.", author: "Nelson Mandela"),
    QuoteItem(text: "No pressure, no diamonds.", author: "Thomas Carlyle"),
    QuoteItem(text: "Energy and persistence conquer all things.", author: "Benjamin Franklin"),
    QuoteItem(text: "A river cuts through rock not because of its power but its persistence.", author: "James Watkins"),
    QuoteItem(text: "Success is the sum of small efforts repeated day in and day out.", author: "Robert Collier"),
    QuoteItem(text: "If you are going through hell, keep going.", author: "Winston Churchill"),
    QuoteItem(text: "Never confuse a single defeat with a final defeat.", author: "F. Scott Fitzgerald"),
    QuoteItem(text: "The habit of persistence is the habit of victory.", author: "Herbert Kaufman"),
    QuoteItem(text: "Fall seven times, stand up eight.", author: "Japanese Proverb"),
    QuoteItem(text: "The greatest glory in living lies not in never falling, but in rising every time we fall.", author: "Nelson Mandela"),
    QuoteItem(text: "Success is not final. Failure is not fatal. It is the courage to continue that counts.", author: "Winston Churchill"),
    QuoteItem(text: "If there is no struggle, there is no progress.", author: "Frederick Douglass"),
    QuoteItem(text: "When you reach the end of your rope, tie a knot in it and hang on.", author: "Franklin D. Roosevelt"),
    QuoteItem(text: "In three words I can sum up everything I've learned about life: it goes on.", author: "Robert Frost"),

    // — Philosophy & Wisdom —
    QuoteItem(text: "Simplicity is the ultimate sophistication.", author: "Leonardo da Vinci"),
    QuoteItem(text: "What we think, we become.", author: "Buddha"),
    QuoteItem(text: "Wherever you go, go with all your heart.", author: "Confucius"),
    QuoteItem(text: "Fortune favors the bold.", author: "Virgil"),
    QuoteItem(text: "Well begun is half done.", author: "Aristotle"),
    QuoteItem(text: "The journey of a thousand miles begins with one step.", author: "Lao Tzu"),
    QuoteItem(text: "He who has a why to live can bear almost any how.", author: "Friedrich Nietzsche"),
    QuoteItem(text: "You are what you do, not what you say you'll do.", author: "Carl Jung"),
    QuoteItem(text: "You become what you give your attention to.", author: "Epictetus"),
    QuoteItem(text: "Knowing yourself is the beginning of all wisdom.", author: "Aristotle"),
    QuoteItem(text: "We are what we repeatedly do. Excellence is not an act, but a habit.", author: "Aristotle"),
    QuoteItem(text: "The unexamined life is not worth living.", author: "Socrates"),
    QuoteItem(text: "To live is the rarest thing in the world. Most people exist, that is all.", author: "Oscar Wilde"),
    QuoteItem(text: "Logic will get you from A to B. Imagination will take you everywhere.", author: "Albert Einstein"),
    QuoteItem(text: "In the middle of difficulty lies opportunity.", author: "Albert Einstein"),
    QuoteItem(text: "Life is not a problem to be solved, but a reality to be experienced.", author: "Kierkegaard"),
    QuoteItem(text: "The cave you fear to enter holds the treasure you seek.", author: "Joseph Campbell"),
    QuoteItem(text: "The man who moves a mountain begins by carrying away small stones.", author: "Confucius"),
    QuoteItem(text: "Great things are done by a series of small things.", author: "Vincent van Gogh"),
    QuoteItem(text: "The beginning is the most important part of the work.", author: "Plato"),
    QuoteItem(text: "Be yourself; everyone else is already taken.", author: "Oscar Wilde"),
    QuoteItem(text: "Two roads diverged in a wood, and I took the one less traveled by.", author: "Robert Frost"),

    // — Stoicism —
    QuoteItem(text: "You have power over your mind, not outside events.", author: "Marcus Aurelius"),
    QuoteItem(text: "Waste no more time arguing about what a good man should be. Be one.", author: "Marcus Aurelius"),
    QuoteItem(text: "The impediment to action advances action. What stands in the way becomes the way.", author: "Marcus Aurelius"),
    QuoteItem(text: "Accept the things to which fate binds you.", author: "Marcus Aurelius"),
    QuoteItem(text: "We suffer more often in imagination than in reality.", author: "Seneca"),
    QuoteItem(text: "Begin at once to live, and count each separate day as a separate life.", author: "Seneca"),
    QuoteItem(text: "Luck is what happens when preparation meets opportunity.", author: "Seneca"),
    QuoteItem(text: "He who is brave is free.", author: "Seneca"),
    QuoteItem(text: "Difficulties strengthen the mind, as labor does the body.", author: "Seneca"),
    QuoteItem(text: "Make the best use of what is in your power, and take the rest as it happens.", author: "Epictetus"),
    QuoteItem(text: "It's not what happens to you, but how you react to it that matters.", author: "Epictetus"),
    QuoteItem(text: "First say to yourself what you would be; then do what you have to do.", author: "Epictetus"),

    // — Business & Entrepreneurship —
    QuoteItem(text: "Innovation distinguishes between a leader and a follower.", author: "Steve Jobs"),
    QuoteItem(text: "Your most unhappy customers are your greatest source of learning.", author: "Bill Gates"),
    QuoteItem(text: "The best investment you can make is in yourself.", author: "Warren Buffett"),
    QuoteItem(text: "Risk comes from not knowing what you're doing.", author: "Warren Buffett"),
    QuoteItem(text: "Price is what you pay. Value is what you get.", author: "Warren Buffett"),
    QuoteItem(text: "It takes 20 years to build a reputation and five minutes to ruin it.", author: "Warren Buffett"),
    QuoteItem(text: "Business opportunities are like buses — there's always another one coming.", author: "Richard Branson"),
    QuoteItem(text: "The biggest risk is not taking any risk.", author: "Mark Zuckerberg"),
    QuoteItem(text: "If you're not embarrassed by your first version, you've launched too late.", author: "Reid Hoffman"),
    QuoteItem(text: "Chase the vision, not the money. The money will end up following you.", author: "Tony Hsieh"),
    QuoteItem(text: "The harder I work, the luckier I get.", author: "Samuel Goldwyn"),
    QuoteItem(text: "Be so good they cannot ignore you.", author: "Steve Martin"),
    QuoteItem(text: "The best way to predict the future is to create it.", author: "Peter Drucker"),
    QuoteItem(text: "Leadership is not about being in charge. It is about taking care of those in your charge.", author: "Simon Sinek"),
    QuoteItem(text: "People don't buy what you do; they buy why you do it.", author: "Simon Sinek"),
    QuoteItem(text: "Fail often so you can succeed sooner.", author: "Tom Kelley"),
    QuoteItem(text: "Your work is going to fill a large part of your life. Do what you believe is great work.", author: "Steve Jobs"),
    QuoteItem(text: "The function of leadership is to produce more leaders, not more followers.", author: "Ralph Nader"),
    QuoteItem(text: "Quality means doing it right when no one is looking.", author: "Henry Ford"),
    QuoteItem(text: "The successful warrior is the average man with laser-like focus.", author: "Bruce Lee"),

    // — Mindfulness & Inner Peace —
    QuoteItem(text: "The present moment is the only moment available to us, and it is the door to all moments.", author: "Thich Nhat Hanh"),
    QuoteItem(text: "Peace comes from within. Do not seek it without.", author: "Buddha"),
    QuoteItem(text: "The quieter you become, the more you can hear.", author: "Ram Dass"),
    QuoteItem(text: "You can't stop the waves, but you can learn to surf.", author: "Jon Kabat-Zinn"),
    QuoteItem(text: "Wherever you are, be all there.", author: "Jim Elliot"),
    QuoteItem(text: "Life is available only in the present moment.", author: "Thich Nhat Hanh"),
    QuoteItem(text: "Do not dwell in the past. Do not dream of the future. Concentrate the mind on the present moment.", author: "Buddha"),
    QuoteItem(text: "The mind is everything. What you think you become.", author: "Buddha"),
    QuoteItem(text: "If you are present, you are alive.", author: "Eckhart Tolle"),
    QuoteItem(text: "Almost everything will work again if you unplug it for a few minutes, including you.", author: "Anne Lamott"),
    QuoteItem(text: "Tension is who you think you should be. Relaxation is who you are.", author: "Chinese Proverb"),
    QuoteItem(text: "Within you, there is a stillness and a sanctuary to which you can retreat at any time.", author: "Hermann Hesse"),
    QuoteItem(text: "Breathe deeply, until sweet air extinguishes the burn of fear.", author: "Unknown"),

    // — Self-Growth & Courage —
    QuoteItem(text: "The only person you are destined to become is the person you decide to be.", author: "Ralph Waldo Emerson"),
    QuoteItem(text: "What lies within us is far greater than what lies behind or before us.", author: "Ralph Waldo Emerson"),
    QuoteItem(text: "Do not wait to strike till the iron is hot; make it hot by striking.", author: "William Butler Yeats"),
    QuoteItem(text: "Believe you can and you're halfway there.", author: "Theodore Roosevelt"),
    QuoteItem(text: "Do one thing every day that scares you.", author: "Eleanor Roosevelt"),
    QuoteItem(text: "No one can make you feel inferior without your consent.", author: "Eleanor Roosevelt"),
    QuoteItem(text: "You must be the change you wish to see in the world.", author: "Mahatma Gandhi"),
    QuoteItem(text: "Everything you've ever wanted is on the other side of fear.", author: "George Addair"),
    QuoteItem(text: "You cannot discover new oceans unless you have the courage to lose sight of the shore.", author: "André Gide"),
    QuoteItem(text: "Life is either a daring adventure or nothing at all.", author: "Helen Keller"),
    QuoteItem(text: "The only impossible journey is the one you never begin.", author: "Tony Robbins"),
    QuoteItem(text: "Do the thing and you will have the power.", author: "Ralph Waldo Emerson"),
    QuoteItem(text: "There are no shortcuts to any place worth going.", author: "Beverly Sills"),
    QuoteItem(text: "Dream big and dare to fail.", author: "Norman Vaughan"),
    QuoteItem(text: "Act as if what you do makes a difference. It does.", author: "William James"),
    QuoteItem(text: "Turn your wounds into wisdom.", author: "Oprah Winfrey"),
    QuoteItem(text: "If you look at what you have in life, you'll always have more.", author: "Oprah Winfrey"),
    QuoteItem(text: "You do not have to see the whole staircase, just take the first step.", author: "Martin Luther King Jr."),
    QuoteItem(text: "If you want to lift yourself up, lift up someone else.", author: "Booker T. Washington"),
    QuoteItem(text: "You miss one hundred percent of the shots you do not take.", author: "Wayne Gretzky"),
    QuoteItem(text: "Keep your eyes on the stars and your feet on the ground.", author: "Theodore Roosevelt"),
    QuoteItem(text: "It is never too late to be what you might have been.", author: "George Eliot"),
    QuoteItem(text: "The world belongs to the energetic.", author: "Ralph Waldo Emerson"),
    QuoteItem(text: "Courage is grace under pressure.", author: "Ernest Hemingway"),
    QuoteItem(text: "Make each day your masterpiece.", author: "John Wooden"),
    QuoteItem(text: "Light tomorrow with today.", author: "Elizabeth Barrett Browning"),
    QuoteItem(text: "Small deeds done are better than great deeds planned.", author: "Peter Marshall"),
    QuoteItem(text: "A little progress each day adds up to big results.", author: "Satya Nani"),
    QuoteItem(text: "What you do today can improve all your tomorrows.", author: "Ralph Marston"),
    QuoteItem(text: "The difference between ordinary and extraordinary is that little extra.", author: "Jimmy Johnson"),
    QuoteItem(text: "One finds limits by pushing them.", author: "Herbert Simon"),
    QuoteItem(text: "Skill is only developed by hours and hours of work.", author: "Usain Bolt"),
    QuoteItem(text: "Start where you are. Use what you have. Do what you can.", author: "Arthur Ashe"),
    QuoteItem(text: "An obstacle is often a stepping stone.", author: "Prescott Bush"),
    QuoteItem(text: "Keep going. Everything you need will come to you at the perfect time.", author: "Unknown"),
    QuoteItem(text: "The only limit to our realization of tomorrow is our doubts of today.", author: "Franklin D. Roosevelt"),
    QuoteItem(text: "Life is what happens to you while you're busy making other plans.", author: "John Lennon"),
    QuoteItem(text: "Spread love everywhere you go. Let no one ever come to you without leaving happier.", author: "Mother Teresa"),
    QuoteItem(text: "Do what you can, with what you have, where you are.", author: "Theodore Roosevelt"),
    QuoteItem(text: "Discipline is choosing between what you want now and what you want most.", author: "Abraham Lincoln"),
    QuoteItem(text: "The more I want to get something done, the less I call it work.", author: "Richard Bach"),
    QuoteItem(text: "Time is what we want most, but what we use worst.", author: "William Penn"),
    QuoteItem(text: "Without labor, nothing prospers.", author: "Sophocles"),
    QuoteItem(text: "There are no shortcuts to any place worth going.", author: "Beverly Sills"),
    QuoteItem(text: "He who knows others is wise. He who knows himself is enlightened.", author: "Lao Tzu"),
    QuoteItem(text: "Give me six hours to chop down a tree and I will spend the first four sharpening the axe.", author: "Abraham Lincoln"),
    QuoteItem(text: "The measure of intelligence is the ability to change.", author: "Albert Einstein"),
    QuoteItem(text: "Freedom lies in being bold.", author: "Robert Frost"),
    QuoteItem(text: "When you have a clear why, the how gets easier.", author: "Unknown"),
    QuoteItem(text: "The main thing is to keep the main thing the main thing.", author: "Stephen Covey"),
    QuoteItem(text: "Happiness depends upon ourselves.", author: "Aristotle"),
    QuoteItem(text: "Not what we have, but what we enjoy, constitutes our abundance.", author: "Epicurus"),
    QuoteItem(text: "Comparison is the thief of joy.", author: "Theodore Roosevelt"),
    QuoteItem(text: "He who laughs at himself never runs out of things to laugh at.", author: "Epictetus"),
    QuoteItem(text: "The quality of your life is the quality of your relationships.", author: "Tony Robbins"),
    QuoteItem(text: "You are enough just as you are.", author: "Unknown"),
]

// MARK: - Frequency Intent

enum QuoteFrequency: String, AppEnum {
    case daily   = "daily"
    case every6h = "every6h"
    case every3h = "every3h"

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Tần suất")
    static var caseDisplayRepresentations: [QuoteFrequency: DisplayRepresentation] = [
        .daily:   DisplayRepresentation(title: "Mỗi ngày"),
        .every6h: DisplayRepresentation(title: "Mỗi 6 giờ"),
        .every3h: DisplayRepresentation(title: "Mỗi 3 giờ"),
    ]

    var hoursPerSlot: Int {
        switch self {
        case .daily:   return 24
        case .every6h: return 6
        case .every3h: return 3
        }
    }
    var slotsPerDay: Int { 24 / hoursPerSlot }
}

struct CalXQuoteIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "CalX Quotes"
    static var description = IntentDescription("Tùy chỉnh tần suất đổi câu quote.")

    @Parameter(title: "Tần suất", default: .daily)
    var frequency: QuoteFrequency
}

// MARK: - Quote rotation

private func quoteIndex(for date: Date, frequency: QuoteFrequency) -> Int {
    let cal        = Calendar.current
    let dayOfYear  = cal.ordinality(of: .day, in: .year, for: date) ?? 1
    let hour       = cal.component(.hour, from: date)
    let slot       = hour / frequency.hoursPerSlot
    return ((dayOfYear - 1) * frequency.slotsPerDay + slot) % allQuotes.count
}

// MARK: - Timeline

struct CalXQuoteEntry: TimelineEntry {
    let date: Date
    let quote: QuoteItem
    let backgroundStyle: WidgetBackgroundStyle
    let frequency: QuoteFrequency
}

struct CalXQuoteProvider: AppIntentTimelineProvider {
    typealias Intent = CalXQuoteIntent

    func placeholder(in context: Context) -> CalXQuoteEntry {
        CalXQuoteEntry(date: Date(), quote: allQuotes[0], backgroundStyle: .dark, frequency: .daily)
    }

    func snapshot(for configuration: CalXQuoteIntent, in context: Context) async -> CalXQuoteEntry {
        let now = Date()
        return CalXQuoteEntry(
            date: now,
            quote: allQuotes[quoteIndex(for: now, frequency: configuration.frequency)],
            backgroundStyle: .dark,
            frequency: configuration.frequency
        )
    }

    func timeline(for configuration: CalXQuoteIntent, in context: Context) async -> Timeline<CalXQuoteEntry> {
        let now  = Date()
        let freq = configuration.frequency
        let cal  = Calendar.current

        // Sinh entries cho 24h tới, bước nhảy = hoursPerSlot
        let slots = freq.slotsPerDay
        let entries: [CalXQuoteEntry] = (0..<slots).compactMap { i in
            guard let entryDate = cal.date(byAdding: .hour, value: i * freq.hoursPerSlot, to: now) else { return nil }
            return CalXQuoteEntry(
                date: entryDate,
                quote: allQuotes[quoteIndex(for: entryDate, frequency: freq)],
                backgroundStyle: .dark,
                frequency: freq
            )
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
}

// MARK: - Localization

private var isVietnamese: Bool {
    Locale.preferredLanguages.first?.hasPrefix("vi") == true
}

private var widgetDisplayName: String {
    "CalX Quotes"
}

private var widgetDescription: String {
    isVietnamese
        ? "Câu trích dẫn truyền cảm hứng. Tuỳ chỉnh tần suất: mỗi ngày, 6h hoặc 3h."
        : "Inspiring quotes. Configure frequency: daily, every 6h or 3h."
}

// MARK: - Views

private struct SmallQuoteView: View {
    let entry: CalXQuoteEntry

    private var fontSize: CGFloat {
        let len = entry.quote.text.count
        if len < 55 { return 16 }
        if len < 90 { return 14 }
        return 12
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Dấu " ghim cố định góc top-left
            Text("\u{201C}")
                .font(.system(size: 34, weight: .black, design: .serif))
                .foregroundColor(.white.opacity(0.20))
                .padding(.top, 14)
                .padding(.leading, 14)

            // Quote + author căn giữa dọc độc lập
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.quote.text)
                    .font(.system(size: fontSize, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(2...3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("— \(entry.quote.author)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.40))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

private struct MediumQuoteView: View {
    let entry: CalXQuoteEntry

    private var fontSize: CGFloat {
        let len = entry.quote.text.count
        if len < 55  { return 20 }
        if len < 90  { return 17 }
        if len < 130 { return 15 }
        return 13
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Dấu " ghim cố định góc top-left
            Text("\u{201C}")
                .font(.system(size: 48, weight: .black, design: .serif))
                .foregroundColor(.white.opacity(0.18))
                .padding(.top, 14)
                .padding(.leading, 18)

            // Quote + author căn giữa dọc độc lập
            VStack(alignment: .leading, spacing: 10) {
                Text(entry.quote.text)
                    .font(.system(size: fontSize, weight: .semibold))
                    .foregroundColor(.white.opacity(0.94))
                    .lineLimit(2...3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("— \(entry.quote.author)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.40))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

private struct CalXQuoteWidgetView: View {
    let entry: CalXQuoteEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium:
            MediumQuoteView(entry: entry)
        default:
            SmallQuoteView(entry: entry)
        }
    }
}

// MARK: - Widget

struct CalXQuoteWidget: Widget {
    let kind = "CalXQuoteWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: CalXQuoteIntent.self, provider: CalXQuoteProvider()) { entry in
            CalXQuoteWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetCardBackground(backgroundStyle: entry.backgroundStyle)
                }
        }
        .contentMarginsDisabled()
        .configurationDisplayName(widgetDisplayName)
        .description(widgetDescription)
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Entry Point

@main
struct CalXWidgets: WidgetBundle {
    var body: some Widget {
        CalXQuoteWidget()
    }
}
