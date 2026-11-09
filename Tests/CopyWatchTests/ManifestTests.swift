import XCTest
@testable import CopyWatch

final class ManifestTests: XCTestCase {
    private var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("CopyWatchTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    private func records(_ count: Int) -> [FileRecord] {
        (0..<count).map {
            FileRecord(relativePath: "dir/file\($0).bin", size: 10,
                       modificationDate: Date(timeIntervalSinceReferenceDate: Double($0)))
        }
    }

    func testReplaceBatchAndCounters() throws {
        let manifests = ManifestStore(directory: root)
        let id = UUID()
        try manifests.replace(id, records: records(5))

        var done = records(5)[1]
        done.status = .verified
        done.bytesCopied = 10
        done.checksum = "abc"
        var failed = records(5)[3]
        failed.applyFailure(.init(title: "t", fix: "f", icon: "i"))
        manifests.apply(id, changes: [.init(index: 1, record: done), .init(index: 3, record: failed)])

        let loaded = try XCTUnwrap(manifests.load(id))
        XCTAssertEqual(loaded.map(\.relativePath), records(5).map(\.relativePath))
        XCTAssertEqual(loaded[1], done)
        XCTAssertEqual(loaded[0].modificationDate, records(5)[0].modificationDate)
        XCTAssertEqual(manifests.page(id, status: .failed, limit: 10).count, 1)
        XCTAssertEqual(manifests.firstDiagnosedFailure(id)?.errorFix, "f")

        let counters = manifests.counters(id)
        XCTAssertEqual(counters.doneFiles, 1)
        XCTAssertEqual(counters.doneBytes, 10)
        XCTAssertEqual(counters.verifiedFiles, 1)
        XCTAssertEqual(counters.failedFiles, 1)

        manifests.reset(id, failedOnly: true)
        XCTAssertEqual(manifests.count(id, status: .failed), 0)
        XCTAssertEqual(manifests.count(id, status: .verified), 1)
        manifests.reset(id, failedOnly: false)
        XCTAssertEqual(manifests.count(id, status: .pending), 5)

        manifests.delete(id)
        XCTAssertNil(manifests.load(id))
    }

    func testApplyCreatesManifestForDeviceJobs() throws {
        let manifests = ManifestStore(directory: root)
        let id = UUID()
        XCTAssertNil(manifests.load(id))
        manifests.apply(id, changes: [.init(index: 0, record: records(1)[0])])
        XCTAssertEqual(manifests.load(id)?.count, 1)
    }

    func testLegacyJobFileMigratesAndHeaderStaysSmall() throws {
        var job = makeJob(source: root.path, dest: root.path)
        job.files = records(50)
        job.totalFiles = 50
        let store = JobStore(root: root)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let url = root.appendingPathComponent("jobs/\(job.id.uuidString).json")
        try encoder.encode(job).write(to: url)

        let loaded = try XCTUnwrap(store.loadJobs().first)
        XCTAssertTrue(loaded.files.isEmpty)
        XCTAssertEqual(store.manifests.load(job.id)?.count, 50)

        let onDisk = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
        XCTAssertEqual((onDisk?["files"] as? [Any])?.count, 0)
        XCTAssertEqual(store.hydrated(loaded)?.files.count, 50)
    }

    func testHydratedRefusesMissingManifest() {
        var job = makeJob(source: root.path, dest: root.path)
        job.totalFiles = 3
        XCTAssertNil(JobStore(root: root).hydrated(job))
    }

    func testEngineStreamsRowsAndKeepsSnapshotsLight() throws {
        let source = root.appendingPathComponent("src")
        for i in 0..<200 {
            let dir = source.appendingPathComponent("d\(i % 10)")
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try Data("file \(i)".utf8).write(to: dir.appendingPathComponent("f\(i).txt"))
        }
        let destParent = root.appendingPathComponent("dst")
        try FileManager.default.createDirectory(at: destParent, withIntermediateDirectories: true)
        let dest = destParent.appendingPathComponent("src")

        let store = JobStore(root: root.appendingPathComponent("store"))
        var job = makeJob(source: source.path, dest: dest.path)
        let scanned = try Scanner.scan(root: source)
        try store.manifests.replace(job.id, records: scanned)
        job.totalFiles = scanned.count
        job.totalBytes = scanned.reduce(0) { $0 + $1.size }
        job.status = .ready

        let id = job.id
        let manifests = store.manifests
        let finished = expectation(description: "job finished")
        let lock = NSLock()
        var sawManifestInSnapshot = false
        let engine = JobEngine(
            job: job,
            loadManifest: { manifests.load(id) },
            onFilesChanged: { manifests.apply(id, changes: $0) }
        ) { snapshot in
            lock.lock()
            if !snapshot.files.isEmpty { sawManifestInSnapshot = true }
            lock.unlock()
            if snapshot.status == .completed || snapshot.status == .completedWithErrors {
                finished.fulfill()
            }
        }
        engine.start()
        wait(for: [finished], timeout: 60)

        XCTAssertFalse(sawManifestInSnapshot)
        XCTAssertEqual(manifests.count(id, status: .verified), 200)
        XCTAssertEqual(manifests.counters(id).doneFiles, 200)
        XCTAssertNotNil(manifests.load(id)?.first?.checksum)
    }

    private func makeJob(source: String, dest: String) -> CopyJob {
        CopyJob(id: UUID(), name: "test", sourceVolume: .forPath(source),
                destVolume: .forPath(dest), sourcePath: source, destPath: dest)
    }
}
