import SwiftUI
import SafariServices
import Foundation

struct AllCryptoNewsView: View {
    @StateObject private var viewModel = CryptoNewsFeedViewModel()
    @State private var showingSafari = false
    @State private var selectedArticleURL: URL?

    // MARK: - Subviews

    private var listView: some View {
        List {
            ForEach(viewModel.fullArticlesCache, id: \.url) { article in
                Button(action: {
                    selectedArticleURL = article.url
                    showingSafari = true
                }) {
                    newsRow(article)
                }
                .buttonStyle(PlainButtonStyle())
            }
            if viewModel.isLoadingFull {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Button("Load More") {
                    Task { await viewModel.loadNextPage() }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(.white)
            }
        }
        .listStyle(PlainListStyle())
        .background(Color.black)
    }

    private func newsRow(_ article: CryptoNewsArticle) -> some View {
        // Precompute plain description and image URL string as before...
        let htmlDescription = article.description ?? ""
        let imgURLString: String? = {
            if let match = htmlDescription.firstMatch(of: /<img\s+src="([^"]+)"/) {
                return String(match.output.1)
            }
            return nil
        }()

        let plainText: String = {
            guard let html = article.description else { return "" }
            return html
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }()
        // Source domain and relative publish date
        let source = URLComponents(url: article.url, resolvingAgainstBaseURL: false)?.host ?? ""
        let publishedAgo: String = {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return formatter.localizedString(for: article.publishedAt, relativeTo: Date())
        }()

        return HStack(alignment: .top, spacing: 12) {
            // Thumbnail
            if let urlString = imgURLString, let imgURL = URL(string: urlString) {
                AsyncImage(url: imgURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 75, height: 75)
                .cornerRadius(8)
            } else {
                Rectangle().fill(Color.gray.opacity(0.3))
                    .frame(width: 75, height: 75)
                    .cornerRadius(8)
            }

            // Title and description
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)

                if !plainText.isEmpty {
                    Text(plainText)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(3)
                    HStack(spacing: 6) {
                        Text(source)
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(publishedAgo)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

    var body: some View {
        List {
            if viewModel.fullArticlesCache.isEmpty && !viewModel.isLoadingFull {
                ProgressView("Loading news…")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(viewModel.fullArticlesCache, id: \.url) { article in
                    Button(action: {
                        selectedArticleURL = article.url
                        showingSafari = true
                    }) {
                        newsRow(article)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                if viewModel.isLoadingFull {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Button("Load More") {
                        Task { await viewModel.loadNextPage() }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.white)
                }
            }
        }
        .listStyle(PlainListStyle())
        .background(Color.black)
        .accentColor(.white)
        .navigationTitle("All Crypto News")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: BookmarksView().environmentObject(viewModel)) {
                    Image(systemName: "bookmark")
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showingSafari) {
            if let url = selectedArticleURL {
                SafariView(url: url)
            }
        }
        .onAppear {
            if viewModel.fullArticlesCache.isEmpty {
                Task {
                    await viewModel.loadNextPage()
                }
            }
        }
    }
}


struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: – BookmarksView stub
struct BookmarksView: View {
    @EnvironmentObject var viewModel: CryptoNewsFeedViewModel

    var body: some View {
        List(viewModel.bookmarks, id: \.url) { article in
            Text(article.title)
                .foregroundColor(.white)
        }
        .listStyle(PlainListStyle())
        .background(Color.black)
        .navigationTitle("Bookmarks")
        .navigationBarTitleDisplayMode(.inline)
        .accentColor(.white)
    }
}
