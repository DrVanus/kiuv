// NewsWebView.swift
// CSAI1
//
// Created by ChatGPT on 4/18/25.
// Native SwiftUI crypto‑news feed (no WKWebView).

import SwiftUI
import SafariServices
import UIKit

// Simple in-memory cache for downloaded UIImages
class ImageCache {
    static let shared = NSCache<NSURL, UIImage>()
}

/// View that downloads, caches, and displays an image from a URL
struct URLImage: View {
    let url: URL
    @State private var uiImage: UIImage?

    var body: some View {
        Group {
            if let img = uiImage {
                Image(uiImage: img)
                    .resizable()
            } else {
                ZStack {
                    Color.gray.opacity(0.3)
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.7))
                }
                .onAppear { loadImage() }
                .shimmeringEffect()
            }
        }
    }

    private func loadImage() {
        let key = url as NSURL
        if let cached = ImageCache.shared.object(forKey: key) {
            uiImage = cached
            return
        }
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 60)
        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data, let img = UIImage(data: data) {
                ImageCache.shared.setObject(img, forKey: key)
                DispatchQueue.main.async { uiImage = img }
            }
        }.resume()
    }
}

// MARK: - Custom Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.5),
                        Color.gray.opacity(0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase * 300)
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    /// Applies a shimmer animation to placeholder content.
    func shimmeringEffect() -> some View {
        modifier(ShimmerModifier())
    }
}

// Formatter for absolute dates
private let fullDateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "MMM d yyyy, h:mm a"
    return df
}()

/// Skeleton row view for loading state
struct SkeletonNewsRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 100, height: 60)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 20)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 14)
            }
        }
        .redacted(reason: .placeholder)
        .shimmeringEffect()
        .padding(.vertical, 4)
    }
}

// MARK: -- Error View

struct CryptoNewsErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(message)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)

            Button(action: onRetry) {
                Text("Retry")
                    .font(.caption2)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(6)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.red.opacity(0.8))
        .cornerRadius(8)
    }
}

// MARK: -- Data Model

struct CryptoNewsArticle: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String?
    let url: URL
    let urlToImage: URL?
    let publishedAt: Date
    let source: Source

    struct Source: Codable {
        let name: String
    }

    enum CodingKeys: String, CodingKey {
        case title, description, url, urlToImage, publishedAt, source
    }
}

// MARK: -- Networking via RSS

enum CryptoNewsAPIError: Error {
    case invalidURL
    case network(Error)
    case invalidResponse
    case parsing
}

actor CryptoNewsService {
    func fetchLatestNews() async throws -> [CryptoNewsArticle] {
        // Support multiple RSS feeds
        let feedInfo: [(url: String, sourceName: String)] = [
            ("https://www.coindesk.com/arc/outboundfeeds/rss/", "CoinDesk"),
            ("https://cryptoslate.com/feed/", "CryptoSlate")
            // Add more feeds here as desired
        ]
        var allItems: [(item: RSSItem, sourceName: String)] = []
        for (feedURLString, sourceName) in feedInfo {
            guard let url = URL(string: feedURLString) else { continue }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { continue }
            // Parse and tag each item with its source
            let parser = RSSParser(data: data)
            let parsed = parser.parse()
            let tagged = parsed.map { item in
                (item: item, sourceName: sourceName)
            }
            allItems.append(contentsOf: tagged)
        }
        // Sort everything by publication date descending
        allItems.sort { $0.item.pubDate > $1.item.pubDate }
        // Convert to CryptoNewsArticle, assigning the correct source for each feed
        var result: [CryptoNewsArticle] = []
        for (item, srcName) in allItems {
            result.append(
                CryptoNewsArticle(
                    title: item.title,
                    description: item.description,
                    url: item.link,
                    urlToImage: item.imageURL,
                    publishedAt: item.pubDate,
                    source: .init(name: srcName)
                )
            )
        }
        return result
    }
}

private struct RSSItem {
    let title: String
    let link: URL
    let description: String
    let pubDate: Date
    let imageURL: URL?
}

private class RSSParser: NSObject, XMLParserDelegate {
    private let parser: XMLParser
    private var items: [RSSItem] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentDescription = ""
    private var currentPubDate = ""
    private var currentImageURL: String?
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
        return df
    }()

    init(data: Data) {
        parser = XMLParser(data: data)
        super.init()
        parser.delegate = self
    }

    func parse() -> [RSSItem] {
        parser.parse()
        return items
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            currentTitle = ""
            currentLink = ""
            currentDescription = ""
            currentPubDate = ""
            currentImageURL = nil
        }
        if ["enclosure", "media:content", "media:thumbnail"].contains(elementName),
           let urlStr = attributeDict["url"] {
            currentImageURL = urlStr
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch currentElement {
        case "title": currentTitle += string
        case "link": currentLink += string
        case "description": currentDescription += string
        case "pubDate": currentPubDate += string
        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            // Fallback: If no enclosure or media image, try to extract <img src="..."> from description
            if currentImageURL == nil {
                if let match = currentDescription.range(of: "<img[^>]+src=[\"']([^\"']+)[\"']", options: .regularExpression) {
                    let imgTag = String(currentDescription[match])
                    if let urlMatch = imgTag.range(of: "src=[\"']([^\"']+)[\"']", options: .regularExpression) {
                        let srcString = String(imgTag[urlMatch])
                        let srcValue = srcString
                            .replacingOccurrences(of: "src=\"", with: "")
                            .replacingOccurrences(of: "src='", with: "")
                            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                        currentImageURL = srcValue
                    }
                }
            }
            guard let linkURL = URL(string: currentLink.trimmingCharacters(in: .whitespacesAndNewlines)),
                  let date = dateFormatter.date(from: currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines))
            else { return }
            let imageURL = currentImageURL.flatMap { URL(string: $0) }
            items.append(RSSItem(
                title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                link: linkURL,
                description: currentDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                pubDate: date,
                imageURL: imageURL
            ))
        }
    }
}

// MARK: -- ViewModel

@MainActor
class CryptoNewsFeedViewModel: ObservableObject {
    @Published var articles: [CryptoNewsArticle] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var bookmarks: [CryptoNewsArticle] = []
    @Published var readArticles: Set<UUID> = []

    @Published private(set) var page = 1
    private let pageSize = 25
    var displayedArticles: [CryptoNewsArticle] {
        Array(articles.prefix(page * pageSize))
    }

    private let service = CryptoNewsService()

    func loadNews() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let fetched = try await service.fetchLatestNews()
                articles = fetched
                page = 1
            } catch {
                errorMessage = "Failed to load: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    func toggleBookmark(_ article: CryptoNewsArticle) {
        if let idx = bookmarks.firstIndex(where: { $0.id == article.id }) {
            bookmarks.remove(at: idx)
        } else {
            bookmarks.append(article)
        }
    }
    func isBookmarked(_ article: CryptoNewsArticle) -> Bool {
        bookmarks.contains(where: { $0.id == article.id })
    }
    func toggleRead(_ article: CryptoNewsArticle) {
        if readArticles.contains(article.id) {
            readArticles.remove(article.id)
        } else {
            readArticles.insert(article.id)
        }
    }
    func isRead(_ article: CryptoNewsArticle) -> Bool {
        readArticles.contains(article.id)
    }
    func loadMore() {
        guard page * pageSize < articles.count else { return }
        page += 1
    }
}

// MARK: -- Row

struct CryptoNewsRow: View {
    @EnvironmentObject var viewModel: CryptoNewsFeedViewModel
    let article: CryptoNewsArticle

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if let imageURL = article.urlToImage {
                URLImage(url: imageURL)
                    .aspectRatio(16/9, contentMode: .fill)
                    .frame(width: 100, height: 60)
                    .cornerRadius(6)
                    .clipped()
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)
                Text("\(article.source.name) • \(article.publishedAt, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(article.title), source: \(article.source.name), published: \(fullDateFormatter.string(from: article.publishedAt))")
        .swipeActions(edge: .leading) {
            Button {
                viewModel.toggleRead(article)
            } label: {
                Label(viewModel.isRead(article) ? "Mark Unread" : "Mark Read",
                      systemImage: viewModel.isRead(article) ? "envelope.open" : "envelope.badge")
            }
            .tint(.blue)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                viewModel.toggleBookmark(article)
            } label: {
                Image(systemName: viewModel.isBookmarked(article) ? "bookmark.fill" : "bookmark")
                    .font(.title2)
                    .accessibilityLabel(viewModel.isBookmarked(article) ? "Remove Bookmark" : "Bookmark")
            }
            .tint(.orange)
            
            Button {
                UIPasteboard.general.url = article.url
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.title2)
                    .accessibilityLabel("Copy Link")
            }
            .tint(.gray)
            
            Button {
                UIApplication.shared.open(article.url)
            } label: {
                Image(systemName: "safari")
                    .font(.title2)
                    .accessibilityLabel("Open in Safari")
            }
            .tint(.blue)
        }
        .contextMenu {
            Button { UIApplication.shared.open(article.url) }
                label: { Label("Open in Safari", systemImage: "safari") }
            Button { UIPasteboard.general.url = article.url }
                label: { Label("Copy Link", systemImage: "doc.on.doc") }
            ShareLink(item: article.url) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: -- Main View

struct CryptoNewsView: View {
    @StateObject private var viewModel = CryptoNewsFeedViewModel()
    private let newsRowHeight: CGFloat = 72

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Preview list
            Group {
                if viewModel.isLoading {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(0..<5, id: \.self) { _ in
                                SkeletonNewsRow()
                            }
                        }
                    }
                    .frame(height: 3 * newsRowHeight)
                } else if let error = viewModel.errorMessage {
                    CryptoNewsErrorView(message: error) {
                        viewModel.loadNews()
                    }
                    .padding(.vertical)
                    .frame(height: 3 * newsRowHeight)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(viewModel.articles.prefix(6)) { article in
                                CryptoNewsRow(article: article)
                                    .environmentObject(viewModel)
                                    .onTapGesture { openSafari(article.url) }
                            }
                        }
                    }
                    .frame(height: 3 * newsRowHeight)
                }
            }

            // See All button
            if !viewModel.isLoading, viewModel.errorMessage == nil, viewModel.articles.count > 5 {
                HStack {
                    NavigationLink(destination: FullCryptoNewsView().environmentObject(viewModel)) {
                        Text("See All News")
                            .font(.headline)
                            .foregroundColor(.yellow)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
            }
        }
        .padding(.horizontal, 16)
        .onAppear { viewModel.loadNews() }
    }

    private func openSafari(_ url: URL) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else {
            return
        }
        let safari = SFSafariViewController(url: url)
        safari.modalPresentationStyle = .fullScreen
        root.present(safari, animated: true)
    }
}

// MARK: -- Preview

struct CryptoNewsView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CryptoNewsFeedViewModel()
        List {
            ForEach([
                CryptoNewsArticle(
                    title: "Bitcoin hits new high",
                    description: "Bitcoin price surges above $70k.",
                    url: URL(string: "https://example.com/bitcoin")!,
                    urlToImage: nil,
                    publishedAt: Date(),
                    source: .init(name: "CoinDesk")
                )
            ]) { article in
                CryptoNewsRow(article: article)
                    .environmentObject(viewModel)
            }
        }
    }
}

/// Full-screen list for “See All News”
struct FullCryptoNewsView: View {
    @EnvironmentObject var viewModel: CryptoNewsFeedViewModel
    @State private var searchText = ""

    // Filtered & paginated articles
    private var filteredArticles: [CryptoNewsArticle] {
        if searchText.isEmpty {
            return viewModel.articles
        } else {
            return viewModel.articles.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        List {
            ForEach(Array(filteredArticles.enumerated()), id: \.element.id) { index, article in
                CryptoNewsRow(article: article)
                    .environmentObject(viewModel)
                    .onTapGesture { openSafari(article.url) }
                    .onAppear {
                        // When hitting last row, load next page
                        guard searchText.isEmpty else { return }
                        if index == filteredArticles.count - 1 {
                            viewModel.loadMore()
                        }
                    }
            }
        }
        .listStyle(PlainListStyle())
        .navigationTitle("All Crypto News")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .tint(.white)
        .refreshable {
            viewModel.loadNews()
        }
        .searchable(text: $searchText, prompt: "Search News")
        .toolbar {
            NavigationLink(destination: BookmarksView().environmentObject(viewModel)) {
                Label("Bookmarks", systemImage: "bookmark")
            }
        }
    }

    /// Present a SFSafariViewController over the root window.
    private func openSafari(_ url: URL) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else {
            return
        }
        let safari = SFSafariViewController(url: url)
        root.present(safari, animated: true)
    }
}

struct BookmarksView: View {
    @EnvironmentObject var viewModel: CryptoNewsFeedViewModel
    var body: some View {
        List {
            ForEach(viewModel.bookmarks) { article in
                CryptoNewsRow(article: article)
                    .environmentObject(viewModel)
                    .onTapGesture { openSafari(article.url) }
            }
        }
        .navigationTitle("Bookmarks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .tint(.white)
    }
    private func openSafari(_ url: URL) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        root.present(SFSafariViewController(url: url), animated: true)
    }
}
