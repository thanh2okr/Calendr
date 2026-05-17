//
//  CalendrWidget.swift
//  CalendrWidget
//

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
        ZStack {
            Color.black.opacity(0.85)

            if backgroundStyle.isGlass {
                Rectangle().fill(.ultraThinMaterial)
            } else {
                LinearGradient(
                    colors: [
                        backgroundStyle.tintColor.opacity(0.96),
                        backgroundStyle.tintColor.opacity(0.78)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            LinearGradient(
                colors: [
                    Color.white.opacity(0.06),
                    .clear,
                    Color.white.opacity(0.03)
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
    QuoteItem(text: "Stay hungry, stay foolish.", author: "Steve Jobs"),
    QuoteItem(text: "Simplicity is the ultimate sophistication.", author: "Leonardo da Vinci"),
    QuoteItem(text: "What we think, we become.", author: "Buddha"),
    QuoteItem(text: "Done is better than perfect.", author: "Sheryl Sandberg"),
    QuoteItem(text: "The only way out is through.", author: "Robert Frost"),
    QuoteItem(text: "Wherever you go, go with all your heart.", author: "Confucius"),
    QuoteItem(text: "Act as if what you do makes a difference. It does.", author: "William James"),
    QuoteItem(text: "Fortune favors the bold.", author: "Virgil"),
    QuoteItem(text: "Make each day your masterpiece.", author: "John Wooden"),
    QuoteItem(text: "Turn your wounds into wisdom.", author: "Oprah Winfrey"),
    QuoteItem(text: "Dream big and dare to fail.", author: "Norman Vaughan"),
    QuoteItem(text: "Well begun is half done.", author: "Aristotle"),
    QuoteItem(text: "Light tomorrow with today.", author: "Elizabeth Barrett Browning"),
    QuoteItem(text: "The secret of getting ahead is getting started.", author: "Mark Twain"),
    QuoteItem(text: "Courage is grace under pressure.", author: "Ernest Hemingway"),
    QuoteItem(text: "The best way out is always through.", author: "Robert Frost"),
    QuoteItem(text: "The future depends on what you do today.", author: "Mahatma Gandhi"),
    QuoteItem(text: "No pressure, no diamonds.", author: "Thomas Carlyle"),
    QuoteItem(text: "Nothing will work unless you do.", author: "Maya Angelou"),
    QuoteItem(text: "Energy and persistence conquer all things.", author: "Benjamin Franklin"),
    QuoteItem(text: "Action is the foundational key to all success.", author: "Pablo Picasso"),
    QuoteItem(text: "The harder I work, the luckier I get.", author: "Samuel Goldwyn"),
    QuoteItem(text: "Believe you can and you're halfway there.", author: "Theodore Roosevelt"),
    QuoteItem(text: "Great things are done by a series of small things.", author: "Vincent van Gogh"),
    QuoteItem(text: "Discipline is choosing between what you want now and what you want most.", author: "Abraham Lincoln"),
    QuoteItem(text: "Start where you are. Use what you have. Do what you can.", author: "Arthur Ashe"),
    QuoteItem(text: "Focus is a matter of deciding what things you are not going to do.", author: "John Carmack"),
    QuoteItem(text: "Do one thing every day that scares you.", author: "Eleanor Roosevelt"),
    QuoteItem(text: "Do not wait. The time will never be just right.", author: "Napoleon Hill"),
    QuoteItem(text: "Quality means doing it right when no one is looking.", author: "Henry Ford"),
    QuoteItem(text: "A river cuts through rock not because of its power but because of its persistence.", author: "James Watkins"),
    QuoteItem(text: "It always seems impossible until it is done.", author: "Nelson Mandela"),
    QuoteItem(text: "Be so good they cannot ignore you.", author: "Steve Martin"),
    QuoteItem(text: "Small deeds done are better than great deeds planned.", author: "Peter Marshall"),
    QuoteItem(text: "If there is no struggle, there is no progress.", author: "Frederick Douglass"),
    QuoteItem(text: "Success is the sum of small efforts repeated day in and day out.", author: "Robert Collier"),
    QuoteItem(text: "Do what you can, with what you have, where you are.", author: "Theodore Roosevelt"),
    QuoteItem(text: "The journey of a thousand miles begins with one step.", author: "Lao Tzu"),
    QuoteItem(text: "You miss one hundred percent of the shots you do not take.", author: "Wayne Gretzky"),
    QuoteItem(text: "Keep going. Everything you need will come to you at the perfect time.", author: "Unknown"),
    QuoteItem(text: "Success is not final. Failure is not fatal. It is the courage to continue that counts.", author: "Winston Churchill"),
    QuoteItem(text: "The man who moves a mountain begins by carrying away small stones.", author: "Confucius"),
    QuoteItem(text: "The only limit to our realization of tomorrow is our doubts of today.", author: "Franklin D. Roosevelt"),
    QuoteItem(text: "If you want to lift yourself up, lift up someone else.", author: "Booker T. Washington"),
    QuoteItem(text: "An obstacle is often a stepping stone.", author: "Prescott Bush"),
    QuoteItem(text: "Keep your eyes on the stars and your feet on the ground.", author: "Theodore Roosevelt"),
    QuoteItem(text: "The beginning is the most important part of the work.", author: "Plato"),
    QuoteItem(text: "You become what you give your attention to.", author: "Epictetus"),
    QuoteItem(text: "Skill is only developed by hours and hours of work.", author: "Usain Bolt"),
    QuoteItem(text: "The way to get started is to quit talking and begin doing.", author: "Walt Disney"),
    QuoteItem(text: "He who has a why to live can bear almost any how.", author: "Friedrich Nietzsche"),
    QuoteItem(text: "A year from now you may wish you had started today.", author: "Karen Lamb"),
    QuoteItem(text: "Do the hard jobs first. The easy jobs will take care of themselves.", author: "Dale Carnegie"),
    QuoteItem(text: "Amateurs sit and wait for inspiration. The rest of us just get up and go to work.", author: "Stephen King"),
    QuoteItem(text: "If you spend too much time thinking about a thing, you'll never get it done.", author: "Bruce Lee"),
    QuoteItem(text: "You do not have to see the whole staircase, just take the first step.", author: "Martin Luther King Jr."),
    QuoteItem(text: "There is no substitute for hard work.", author: "Thomas Edison"),
    QuoteItem(text: "Concentrate all your thoughts upon the work in hand.", author: "Alexander Graham Bell"),
    QuoteItem(text: "Deep work is the ability to focus without distraction.", author: "Cal Newport"),
    QuoteItem(text: "Freedom lies in being bold.", author: "Robert Frost"),
    QuoteItem(text: "Work hard in silence. Let success make the noise.", author: "Frank Ocean"),
    QuoteItem(text: "You are what you do, not what you say you'll do.", author: "Carl Jung"),
    QuoteItem(text: "Opportunity is missed by most people because it is dressed in overalls and looks like work.", author: "Thomas Edison"),
    QuoteItem(text: "The successful warrior is the average man with laser-like focus.", author: "Bruce Lee"),
    QuoteItem(text: "One day or day one. You decide.", author: "Unknown"),
    QuoteItem(text: "Do less, but do it better.", author: "Unknown"),
    QuoteItem(text: "Productivity is never an accident.", author: "Paul J. Meyer"),
    QuoteItem(text: "The key is not to prioritize what is on your schedule, but to schedule your priorities.", author: "Stephen Covey"),
    QuoteItem(text: "Lost time is never found again.", author: "Benjamin Franklin"),
    QuoteItem(text: "It is not enough to be busy. So are the ants. The question is: What are we busy about?", author: "Henry David Thoreau"),
    QuoteItem(text: "Do not confuse motion and progress.", author: "Alfred A. Montapert"),
    QuoteItem(text: "Either you run the day or the day runs you.", author: "Jim Rohn"),
    QuoteItem(text: "Ordinary things done consistently produce extraordinary results.", author: "Unknown"),
    QuoteItem(text: "The main thing is to keep the main thing the main thing.", author: "Stephen Covey"),
    QuoteItem(text: "To think too long about doing a thing often becomes its undoing.", author: "Eva Young"),
    QuoteItem(text: "Great acts are made up of small deeds.", author: "Lao Tzu"),
    QuoteItem(text: "You cannot build a reputation on what you are going to do.", author: "Henry Ford"),
    QuoteItem(text: "Motivation gets you going, but discipline keeps you growing.", author: "John C. Maxwell"),
    QuoteItem(text: "The difference between ordinary and extraordinary is that little extra.", author: "Jimmy Johnson"),
    QuoteItem(text: "If you are going through hell, keep going.", author: "Winston Churchill"),
    QuoteItem(text: "Never confuse a single defeat with a final defeat.", author: "F. Scott Fitzgerald"),
    QuoteItem(text: "The more I want to get something done, the less I call it work.", author: "Richard Bach"),
    QuoteItem(text: "The habit of persistence is the habit of victory.", author: "Herbert Kaufman"),
    QuoteItem(text: "One finds limits by pushing them.", author: "Herbert Simon"),
    QuoteItem(text: "You have power over your mind, not outside events.", author: "Marcus Aurelius"),
    QuoteItem(text: "Time is what we want most, but what we use worst.", author: "William Penn"),
    QuoteItem(text: "The only place where success comes before work is in the dictionary.", author: "Vidal Sassoon"),
    QuoteItem(text: "A little progress each day adds up to big results.", author: "Satya Nani"),
    QuoteItem(text: "It is never too late to be what you might have been.", author: "George Eliot"),
    QuoteItem(text: "What you do today can improve all your tomorrows.", author: "Ralph Marston"),
    QuoteItem(text: "The world belongs to the energetic.", author: "Ralph Waldo Emerson"),
    QuoteItem(text: "When you have a clear why, the how gets easier.", author: "Unknown"),
    QuoteItem(text: "To begin, begin.", author: "William Wordsworth"),
    QuoteItem(text: "First we make our habits, then our habits make us.", author: "John Dryden"),
    QuoteItem(text: "Routine, in an intelligent person, is a sign of ambition.", author: "W. H. Auden"),
    QuoteItem(text: "A goal without a plan is just a wish.", author: "Antoine de Saint-Exupery"),
    QuoteItem(text: "Without labor, nothing prospers.", author: "Sophocles"),
    QuoteItem(text: "Do the thing and you will have the power.", author: "Ralph Waldo Emerson"),
    QuoteItem(text: "There are no shortcuts to any place worth going.", author: "Beverly Sills"),
    QuoteItem(text: "Success usually comes to those who are too busy to be looking for it.", author: "Henry David Thoreau"),
]

// MARK: - Quote rotation (mỗi 3 giờ đổi 1 quote, xoay vòng theo ngày)

private func quoteIndex(for date: Date) -> Int {
    let cal = Calendar.current
    let dayOfYear = cal.ordinality(of: .day, in: .year, for: date) ?? 1
    let hour      = cal.component(.hour, from: date)
    let slot      = hour / 3                                   // 8 slot/ngày
    return ((dayOfYear - 1) * 8 + slot) % allQuotes.count
}

// MARK: - Timeline

struct CalendrQuoteEntry: TimelineEntry {
    let date: Date
    let quote: QuoteItem
    let backgroundStyle: WidgetBackgroundStyle
}

struct CalendrQuoteProvider: TimelineProvider {

    func placeholder(in context: Context) -> CalendrQuoteEntry {
        CalendrQuoteEntry(date: Date(), quote: allQuotes[0], backgroundStyle: .dark)
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendrQuoteEntry) -> Void) {
        let now = Date()
        completion(CalendrQuoteEntry(date: now, quote: allQuotes[quoteIndex(for: now)], backgroundStyle: .dark))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendrQuoteEntry>) -> Void) {
        let now = Date()
        // Tạo sẵn 8 entry (24h), mỗi entry cách nhau 3 giờ
        let entries = (0..<8).map { i -> CalendrQuoteEntry in
            let entryDate = Calendar.current.date(byAdding: .hour, value: i * 3, to: now) ?? now
            return CalendrQuoteEntry(
                date: entryDate,
                quote: allQuotes[quoteIndex(for: entryDate)],
                backgroundStyle: .dark
            )
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Views

private struct SmallQuoteView: View {
    let entry: CalendrQuoteEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "quote.closing")
                .font(.system(size: 16, weight: .black))
                .foregroundColor(.white.opacity(0.35))

            Text(entry.quote.text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
                .lineLimit(4)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

            Spacer(minLength: 0)

            Text("— \(entry.quote.author)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.45))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct MediumQuoteView: View {
    let entry: CalendrQuoteEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "quote.closing")
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.white.opacity(0.28))

            Text(entry.quote.text)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white.opacity(0.94))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

            Spacer(minLength: 0)

            Text("— \(entry.quote.author)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.45))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct CalendrQuoteWidgetView: View {
    let entry: CalendrQuoteEntry
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

struct CalendrQuoteWidget: Widget {
    let kind = "CalendrQuoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendrQuoteProvider()) { entry in
            CalendrQuoteWidgetView(entry: entry)
                .clipShape(ContainerRelativeShape())
                .containerBackground(for: .widget) {
                    WidgetCardBackground(backgroundStyle: entry.backgroundStyle)
                        .clipShape(ContainerRelativeShape())
                }
        }
        .contentMarginsDisabled()
        .configurationDisplayName("CalX Quotes")
        .description("Hiển thị câu trích dẫn truyền cảm hứng, đổi mới mỗi 3 giờ.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Entry Point

@main
struct CalendrWidgets: WidgetBundle {
    var body: some Widget {
        CalendrQuoteWidget()
    }
}
