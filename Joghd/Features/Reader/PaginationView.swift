import SwiftUI

struct PaginationView: View {
    private static let lookAhead = 5

    let document: BookDocument
    let initialLocation: Location?
    let pageSize: CGSize
    let onPositionChange: (Location) -> Void

    @State private var paginator: BookPaginator?
    @State private var pages: [BookPage] = []
    @State private var currentPageID: Int?
    @State private var currentLocation: Location?
    @State private var isRestoring = false
    @State private var pendingResumeLocation: Location?
    @State private var fillTask: Task<Void, Never>?

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(pages.indices, id: \.self) { index in
                    PageTextView(text: pages[index].text)
                        .frame(
                            width: max(pageSize.width, 0),
                            height: max(pageSize.height, 0),
                            alignment: .topLeading
                        )
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $currentPageID)
        .scrollIndicators(.hidden)
        .onChange(of: pageSize, initial: true) { _, size in
            paginate(size)
        }
        .onChange(of: document) { _, _ in
            paginate(pageSize)
        }
        .onChange(of: currentPageID) { _, index in
            guard !isRestoring else {
                isRestoring = false
                return
            }
            reportPosition(at: index)
            startFill(after: index)
        }
        .onDisappear {
            fillTask?.cancel()
        }
    }

    private func paginate(_ size: CGSize) {
        fillTask?.cancel()
        let resumeLocation = currentLocation ?? initialLocation
        let newPaginator = BookPaginator(
            text: BookText.attributedString(of: document), pageSize: size
        )
        paginator = newPaginator
        pages = []
        let first = newPaginator.appendNextPage()
        if let first {
            pages.append(first)
        }
        let alreadyShowsResume = showsResumeLocation(first, target: resumeLocation)
        pendingResumeLocation = alreadyShowsResume ? nil : resumeLocation
        currentLocation = resumeLocation
        if currentPageID != 0 {
            isRestoring = true
            currentPageID = 0
        }
        startFill(after: 0)
    }

    private func showsResumeLocation(_ first: BookPage?, target: Location?) -> Bool {
        guard let first, let target else {
            return false
        }
        return first.contains(characterOffset: target.characterOffset)
    }

    private func startFill(after index: Int?) {
        guard let paginator else {
            return
        }
        fillTask?.cancel()
        let resumeTarget = pendingResumeLocation
        let lookAheadIndex = (index ?? 0) + Self.lookAhead
        fillTask = Task {
            await fill(paginator, resumeTarget: resumeTarget, lookAheadIndex: lookAheadIndex)
        }
    }

    private func fill(
        _ paginator: BookPaginator, resumeTarget: Location?, lookAheadIndex: Int
    ) async {
        while !Task.isCancelled {
            if let target = resumeTarget {
                guard let page = addPage(from: paginator) else {
                    pendingResumeLocation = nil
                    if let last = pages.indices.last {
                        jump(to: last)
                    }
                    return
                }
                if page.contains(characterOffset: target.characterOffset) {
                    pendingResumeLocation = nil
                    jump(to: pages.count - 1)
                    return
                }
            } else {
                if pages.count > lookAheadIndex {
                    return
                }
                guard addPage(from: paginator) != nil else {
                    return
                }
            }
            await Task.yield()
        }
    }

    @discardableResult
    private func addPage(from paginator: BookPaginator) -> BookPage? {
        guard let page = paginator.appendNextPage() else {
            return nil
        }
        pages.append(page)
        return page
    }

    private func jump(to index: Int) {
        guard currentPageID != index else {
            return
        }
        isRestoring = true
        currentPageID = index
    }

    private func reportPosition(at index: Int?) {
        guard let index, pages.indices.contains(index) else {
            return
        }
        let location = Location(characterOffset: pages[index].range.location)
        currentLocation = location
        onPositionChange(location)
    }
}
